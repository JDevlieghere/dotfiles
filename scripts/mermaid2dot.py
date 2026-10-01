#!/usr/bin/env python3
"""Convert Mermaid flowcharts to Graphviz DOT."""

import argparse
import re
import sys

# (opener, closer, DOT attributes)
SHAPES = [
    ("(((", ")))", {"shape": "doublecircle"}),
    ("([", "])", {"shape": "box", "style": "rounded"}),
    ("((", "))", {"shape": "circle"}),
    ("[[", "]]", {"shape": "box", "peripheries": "2"}),
    ("[(", ")]", {"shape": "cylinder"}),
    ("[/", "/]", {"shape": "parallelogram"}),
    ("[/", "\\]", {"shape": "trapezium"}),
    ("[\\", "\\]", {"shape": "parallelogram"}),
    ("[\\", "/]", {"shape": "invtrapezium"}),
    ("{{", "}}", {"shape": "hexagon"}),
    ("(", ")", {"shape": "box", "style": "rounded"}),
    ("[", "]", {"shape": "box"}),
    ("{", "}", {"shape": "diamond"}),
    (">", "]", {"shape": "cds"}),
]

NODE_ID = re.compile(r"\s*(\w+(?:-\w+)*)")
CLASS_SUFFIX = re.compile(r":::([\w-]+)")
AMP = re.compile(r"\s*&")
EDGE = re.compile(
    r"""\s*(?P<l><)?(?:
        (?P<a>--|==|-\.)(?![ox]\b)\s*(?P<t>[^\s|>.=-][^|]*?)\s*
        (?P<b>-{2,}|={2,}|\.-+)(?P<r>[>ox])?
      | (?P<s>-{2,}|={2,}|-\.+-|~{3,})(?P<r2>>|[ox]\b)?
    )\s*(?:\|(?P<p>[^|]*)\|)?""",
    re.X,
)
HEADS = {">": "normal", "o": "odot", "x": "tee"}
DIRECTIONS = {"TB": "TB", "TD": "TB", "BT": "BT", "LR": "LR", "RL": "RL"}


class Subgraph:
    def __init__(self, id, title):
        self.id = id
        self.title = title
        self.children = []  # node ids and Subgraphs


class Converter:
    def __init__(self):
        self.rankdir = "TB"
        self.title = None
        self.nodes = {}  # id -> {"label", "attrs", "classes"}
        self.edges = []  # (src, dst, attrs)
        self.root = Subgraph(None, None)
        self.stack = [self.root]
        self.subgraphs = {}
        self.class_defs = {}
        self.styles = {}
        self.link_styles = {}

    # Parsing.

    def node(self, id):
        if id not in self.nodes:
            self.nodes[id] = {"label": None, "attrs": {}, "classes": []}
            self.stack[-1].children.append(id)
        return self.nodes[id]

    def parse_node(self, s, pos):
        m = NODE_ID.match(s, pos)
        if not m:
            raise SyntaxError(f"expected node at: {s[pos:]!r}")
        id, pos = m.group(1), m.end()
        node = self.node(id)
        shape = self.parse_shape(s, pos)
        if shape:
            node["label"], node["attrs"], pos = shape
        m = CLASS_SUFFIX.match(s, pos)
        if m:
            node["classes"].append(m.group(1))
            pos = m.end()
        return id, pos

    def parse_shape(self, s, pos):
        best = None
        for opener, closer, attrs in SHAPES:
            if not s.startswith(opener, pos):
                continue
            start = pos + len(opener)
            end = -1
            if s.startswith('"', start):
                q = s.find('"', start + 1)
                if q >= 0 and s.startswith(closer, q + 1):
                    end = q + 1
            if end < 0:
                end = s.find(closer, start)
            if end < 0:
                continue
            key = (-len(opener), end)
            if best is None or key < best[0]:
                best = (key, s[start:end], dict(attrs), end + len(closer))
        return best and best[1:]

    def parse_group(self, s, pos):
        ids = []
        while True:
            id, pos = self.parse_node(s, pos)
            ids.append(id)
            m = AMP.match(s, pos)
            if not m:
                return ids, pos
            pos = m.end()

    def parse_edge(self, s, pos):
        m = EDGE.match(s, pos)
        if not m:
            return None, pos
        seg = m["a"] or m["s"]
        head = m["r"] or m["r2"]
        attrs = {}
        if "~" in seg:
            attrs["style"] = "invis"
        elif "." in seg:
            attrs["style"] = "dotted"
        elif "=" in seg:
            attrs["penwidth"] = "2"
        if m["l"] and head:
            attrs["dir"] = "both"
            attrs["arrowtail"] = "normal"
            attrs["arrowhead"] = HEADS[head]
        elif m["l"]:
            attrs["dir"] = "back"
        elif head:
            attrs["arrowhead"] = HEADS[head]
        else:
            attrs["dir"] = "none"
        label = m["t"] or m["p"]
        if label:
            attrs["label"] = clean_label(label)
        return attrs, m.end()

    def parse_statement(self, s):
        word, _, rest = s.partition(" ")
        rest = rest.strip()
        if word == "subgraph":
            self.begin_subgraph(rest)
        elif word == "end" and not rest:
            if len(self.stack) == 1:
                raise SyntaxError("'end' without 'subgraph'")
            self.stack.pop()
        elif word == "classDef":
            names, _, css = rest.partition(" ")
            for name in names.split(","):
                self.class_defs[name] = css_attrs(css)
        elif word == "class":
            ids, _, cls = rest.rpartition(" ")
            for id in ids.split(","):
                self.node(id.strip())["classes"].append(cls)
        elif word == "style":
            id, _, css = rest.partition(" ")
            self.styles.setdefault(id, {}).update(css_attrs(css))
        elif word == "linkStyle":
            idxs, _, css = rest.partition(" ")
            for i in idxs.split(","):
                self.link_styles[i] = css_attrs(css, edge=True)
        elif word in ("click", "direction"):
            pass
        else:
            self.parse_chain(s)

    def parse_chain(self, s):
        srcs, pos = self.parse_group(s, 0)
        while pos < len(s):
            attrs, pos = self.parse_edge(s, pos)
            if attrs is None:
                raise SyntaxError(f"unexpected: {s[pos:]!r}")
            dsts, pos = self.parse_group(s, pos)
            for a in srcs:
                for b in dsts:
                    self.edges.append((a, b, dict(attrs)))
            srcs = dsts

    def begin_subgraph(self, rest):
        m = re.match(r"(\w[\w-]*)\s*\[(.*)\]$", rest)
        if m:
            id, title = m[1], clean_label(m[2])
        elif re.fullmatch(r"\w[\w-]*", rest):
            id = title = rest
        else:
            id, title = f"_sg{len(self.subgraphs)}", clean_label(rest)
        sg = Subgraph(id, title)
        self.subgraphs[id] = sg
        self.stack[-1].children.append(sg)
        self.stack.append(sg)

    def parse(self, text):
        text = self.strip_front_matter(text)
        header = True
        for line in text.splitlines():
            line = re.sub(r"%%.*", "", line)
            for stmt in split_statements(line):
                if header:
                    m = re.fullmatch(r"(?:graph|flowchart)(?:\s+(\w+))?", stmt)
                    if not m:
                        raise SyntaxError(f"only flowcharts are supported: {stmt!r}")
                    self.rankdir = DIRECTIONS.get(m[1] or "TB", "TB")
                    header = False
                else:
                    self.parse_statement(stmt)

    def strip_front_matter(self, text):
        m = re.match(r"\s*---\n(.*?)\n---\n", text, re.S)
        if not m:
            return text
        t = re.search(r"^title:\s*(.+)$", m[1], re.M)
        if t:
            self.title = t[1].strip().strip("\"'")
        return text[m.end() :]

    # Emission.

    def first_node(self, sg):
        for c in sg.children:
            if isinstance(c, Subgraph):
                n = self.first_node(c)
                if n:
                    return n
            elif c not in self.subgraphs:
                return c
        return None

    def emit(self):
        out = ["digraph G {", f"  rankdir={self.rankdir};"]
        if self.title:
            out.append(f"  label={q(self.title)};\n  labelloc=t;")
        if any(a in self.subgraphs or b in self.subgraphs for a, b, _ in self.edges):
            out.append("  compound=true;")
        default = {"shape": "box", **self.class_defs.get("default", {})}
        out.append(f"  node {fmt(default)};")
        self.emit_children(self.root, out, "  ")
        for i, (a, b, attrs) in enumerate(self.edges):
            attrs.update(self.link_styles.get("default", {}))
            attrs.update(self.link_styles.get(str(i), {}))
            if a in self.subgraphs:
                attrs["ltail"] = f"cluster_{a}"
                a = self.first_node(self.subgraphs[a])
            if b in self.subgraphs:
                attrs["lhead"] = f"cluster_{b}"
                b = self.first_node(self.subgraphs[b])
            if a and b:
                out.append(f"  {q(a)} -> {q(b)}{' ' + fmt(attrs) if attrs else ''};")
        out.append("}")
        return "\n".join(out) + "\n"

    def emit_children(self, sg, out, indent):
        for c in sg.children:
            if isinstance(c, Subgraph):
                out.append(f"{indent}subgraph {q('cluster_' + c.id)} {{")
                out.append(f"{indent}  label={q(c.title)};")
                self.emit_children(c, out, indent + "  ")
                out.append(f"{indent}}}")
            elif c not in self.subgraphs:
                out.append(f"{indent}{q(c)} {fmt(self.node_attrs(c))};")

    def node_attrs(self, id):
        n = self.nodes[id]
        attrs = dict(n["attrs"])
        attrs["label"] = clean_label(n["label"]) if n["label"] is not None else id
        for cls in n["classes"]:
            merge_style(attrs, self.class_defs.get(cls, {}))
        merge_style(attrs, self.styles.get(id, {}))
        return attrs


def split_statements(line):
    """Split on ';' outside of quotes."""
    parts = re.findall(r'(?:"[^"]*"|[^;"])+', line)
    return [p.strip() for p in parts if p.strip()]


def clean_label(s):
    s = s.strip()
    if len(s) >= 2 and s[0] == s[-1] == '"':
        s = s[1:-1]
    if len(s) >= 2 and s[0] == s[-1] == "`":
        s = s[1:-1]
    s = re.sub(r"<br\s*/?>", "\n", s, flags=re.I)
    return s.replace("#quot;", '"')


def css_attrs(css, edge=False):
    attrs = {}
    for decl in css.rstrip(";").split(","):
        k, _, v = decl.partition(":")
        k, v = k.strip(), v.strip()
        if k == "fill" and not edge:
            attrs["fillcolor"] = v
            attrs["style"] = "filled"
        elif k == "stroke":
            attrs["color"] = v
        elif k == "color":
            attrs["fontcolor"] = v
        elif k == "stroke-width":
            attrs["penwidth"] = v.removesuffix("px")
        elif k == "stroke-dasharray":
            attrs["style"] = "dashed"
    return attrs


def merge_style(attrs, extra):
    """Merge attributes, combining 'style' values."""
    for k, v in extra.items():
        if k == "style" and "style" in attrs and v not in attrs["style"]:
            attrs["style"] += "," + v
        else:
            attrs[k] = v


def q(s):
    s = s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
    return f'"{s}"'


def fmt(attrs):
    return "[" + ", ".join(f"{k}={q(v)}" for k, v in attrs.items()) + "]"


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("input", nargs="?", type=argparse.FileType("r"), default=sys.stdin)
    p.add_argument("-o", "--output", type=argparse.FileType("w"), default=sys.stdout)
    args = p.parse_args()
    c = Converter()
    try:
        c.parse(args.input.read())
    except SyntaxError as e:
        sys.exit(f"error: {e}")
    args.output.write(c.emit())


if __name__ == "__main__":
    main()

"""Figure primitives and the base stylesheet of the house language. Baselines
are positioned explicitly (no dominant-baseline) so text centers the same in
Chrome, Safari, and Keynote."""

import html
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import palette  # noqa: E402

SANS = (
    "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Helvetica Neue', sans-serif"
)
MONO = "'SF Mono', ui-monospace, Menlo, monospace"
W, H = 860, 600  # figure beside points
FW, FH = 1456, 600  # figure under a title
BW, BH = 1456, 756  # figure alone on a slide
GAP = 20  # between tiles
R = 28  # corner radius of a tile
CAP = 0.36  # baseline offset, in em, that centers SF caps and x-height
MIN = 16  # smallest text, in px on a 1600×900 slide

C = dict(palette.COLORS)
_GRADS = {}


def use(theme):
    """Switch every later call to `theme`, a map from `palette.theme()`."""
    C.clear()
    C.update(theme)


def esc(s):
    return html.escape(s, quote=True)


def tw(s, size, mono=False, weight=400):
    """Rough rendered width of a single line."""
    k = 0.6 if mono else (0.56 if weight >= 600 else 0.53)
    return len(s) * size * k


def grad(*names):
    """A paint that runs through the named colors, for hero type only. One
    name runs the accent into its neighbor hue."""
    stops = (
        [C[n] for n in names]
        if len(names) > 1
        else [C[names[0]], C[names[0] + "_blend"]]
    )
    key = "g-" + "-".join(s[1:] for s in stops)
    _GRADS[key] = stops
    return f"url(#{key})"


def defs():
    """The gradients drawn so far. A document needs one copy, in an SVG that
    is rendered: a display:none SVG does not serve its paints."""
    out = []
    for key, stops in _GRADS.items():
        n = len(stops) - 1
        out.append(
            f'<linearGradient id="{key}" x1="0" y1="0" x2="1" y2="0">'
            + "".join(
                f'<stop offset="{i / n:.3f}" stop-color="{c}"/>'
                for i, c in enumerate(stops)
            )
            + "</linearGradient>"
        )
    return "<defs>" + "".join(out) + "</defs>"


def defs_svg():
    """`defs()` wrapped for an HTML page. Place it once, after the figures."""
    return (
        '<svg width="0" height="0" style="position:absolute" aria-hidden="true">'
        + defs()
        + "</svg>"
    )


def text(
    x,
    y,
    s,
    size=24,
    color="fg2",
    anchor="middle",
    weight=400,
    mono=False,
    halo=False,
    lh=1.25,
    spacing=None,
    opacity=1,
):
    """Text whose block of lines is vertically centered on y. `color` is a
    theme name or a `grad()` paint. Display sizes are tracked tight."""
    assert size >= MIN, f"{s!r} at {size}px is below the {MIN}px floor"
    if spacing is None:
        spacing = -0.028 * size if size >= 40 and not mono else 0
    lines = s.split("\n")
    step = size * lh
    y0 = y - (len(lines) - 1) * step / 2 + size * CAP
    spans = "".join(
        f'<tspan x="{x}" y="{y0 + i * step:.1f}">{esc(l)}</tspan>'
        for i, l in enumerate(lines)
    )
    extra = ""
    if halo:
        extra += (
            f' stroke="{C["bg"]}" stroke-width="10" stroke-linejoin="round" '
            'paint-order="stroke"'
        )
    if spacing:
        extra += f' letter-spacing="{spacing:.2f}"'
    if opacity != 1:
        extra += f' fill-opacity="{opacity}"'
    fill = color if color.startswith("url(") else C[color]
    return (
        f'<text xml:space="preserve" font-family="{MONO if mono else SANS}" '
        f'font-size="{size}" font-weight="{weight}" fill="{fill}" '
        f'text-anchor="{anchor}"{extra}>{spans}</text>'
    )


def label(x, y, s, color="fg4", anchor="start", size=18, opacity=1):
    """Small caps label, such as a concept name above a tile's content."""
    return text(
        x, y, s.upper(), size, color, anchor, 700, spacing=size * 0.11, opacity=opacity
    )


def rect(x, y, w, h, fill="bg3", stroke=None, r=R, sw=2, dashed=False, opacity=1):
    f = "none" if fill is None else C[fill]
    s = "none" if stroke is None else C[stroke]
    d = ' stroke-dasharray="9 8"' if dashed else ""
    o = f' fill-opacity="{opacity}"' if opacity != 1 else ""
    return (
        f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" '
        f'rx="{min(r, w / 2, h / 2):.1f}" fill="{f}"{o} stroke="{s}" stroke-width="{sw}"{d}/>'
    )


def surface(x, y, w, h, accent=None, focus=False, dim=False, r=R):
    """A flat tile at one of four levels of emphasis, and the colors its
    title, body, and label take. Dim is context, plain is a thing, tinted
    belongs to a concept, and solid is what the slide is about."""
    if dim or not accent:
        assert not focus, "focus needs an accent"
        return (
            (rect(x, y, w, h, "bg2", r=r), ("fg4", "fg4", "fg4"))
            if dim
            else (rect(x, y, w, h, "bg3", r=r), ("fg", "fg3", "fg4"))
        )
    if focus:
        on = palette.on_solid(C, accent)
        return rect(x, y, w, h, accent, r=r), (on, on, on)
    readable = palette.contrast(C[accent], C[f"{accent}_wash"]) >= palette.AA_LARGE
    return rect(x, y, w, h, f"{accent}_wash", r=r), (
        "fg",
        "fg2",
        accent if readable else "fg2",
    )


def card(
    x,
    y,
    w,
    h,
    title,
    sub=None,
    accent=None,
    name=None,
    focus=False,
    dim=False,
    mono=False,
    size=32,
    align="middle",
):
    """A tile with a title and an optional subtitle. `name` adds a caps label
    above them and aligns the card left."""
    shape, (ct, cs, cl) = surface(x, y, w, h, accent, focus, dim)
    out = [shape]
    if name:
        align = "start"
    tx = x + w / 2 if align == "middle" else x + 32
    ss = min(28, max(20, round(size * 0.72)))
    hl = (title.count("\n") + 1) * size * 1.2
    hs = (sub.count("\n") + 1) * ss * 1.3 + 6 if sub else 0
    hn = 34 if name else 0
    top = y + (h - hl - hs - hn) / 2
    if name:
        out.append(label(tx, top + 9, name, cl, opacity=0.75 if focus else 1))
    top += hn
    out.append(
        text(
            tx, top + hl / 2, title, size, ct, align, 500 if mono else 700, mono, lh=1.2
        )
    )
    if sub:
        out.append(
            text(
                tx,
                top + hl + 6 + (hs - 6) / 2,
                sub,
                ss,
                cs,
                align,
                500,
                lh=1.3,
                opacity=0.8 if focus else 1,
            )
        )
    return "".join(out)


def chip(cx, cy, s, accent="muted", size=20, focus=False, mono=False, anchor="middle"):
    """A pill, which names or tags a thing."""
    w = tw(s, size, mono, 600) + size * 1.5
    h = size * 1.9
    x = cx - w / 2 if anchor == "middle" else cx
    if focus:
        fill, col = accent, palette.on_solid(C, accent)
    else:
        fill = f"{accent}_wash"
        readable = palette.contrast(C[accent], C[fill]) >= palette.AA_LARGE
        col = accent if readable else "fg"
    return rect(x, cy - h / 2, w, h, fill, r=h / 2) + text(
        x + w / 2, cy, s, size, col, weight=600, mono=mono
    )


def region(x, y, w, h, name, accent="muted", right=False):
    """A dashed boundary, such as a process or a machine, named in a corner."""
    lx, a = (x + w - 26, "end") if right else (x + 26, "start")
    return rect(x, y, w, h, None, f"{accent}_outline", R + 8, 2, dashed=True) + text(
        lx, y + 32, name, 22, palette.ink(C, accent, large=True), a, 600
    )


def arrow(
    pts,
    color="fg4",
    dashed=False,
    both=False,
    sw=3,
    lab=None,
    at=None,
    lcolor="fg3",
    lsize=20,
    head=True,
):
    """A polyline with an arrowhead. `lab` at `at` says what the arrow means."""

    def tip(p, q):
        a = math.atan2(q[1] - p[1], q[0] - p[0])
        l, hw = 5.2 * sw, 2.7 * sw
        bx, by = q[0] - l * math.cos(a), q[1] - l * math.sin(a)
        px, py = -math.sin(a) * hw, math.cos(a) * hw
        return (
            f'<polygon points="{q[0]:.1f},{q[1]:.1f} {bx + px:.1f},{by + py:.1f} '
            f'{bx - px:.1f},{by - py:.1f}" fill="{C[color]}"/>'
        )

    def trim(p, q):
        a = math.atan2(q[1] - p[1], q[0] - p[0])
        return (q[0] - 4.5 * sw * math.cos(a), q[1] - 4.5 * sw * math.sin(a))

    line = list(pts)
    if head:
        line[-1] = trim(pts[-2], pts[-1])
    if both:
        line[0] = trim(pts[1], pts[0])
    d = ' stroke-dasharray="9 8"' if dashed else ""
    p = " ".join(f"{x:.1f},{y:.1f}" for x, y in line)
    out = [
        f'<polyline points="{p}" fill="none" stroke="{C[color]}" stroke-width="{sw}"{d} '
        'stroke-linejoin="round" stroke-linecap="round"/>'
    ]
    if head:
        out.append(tip(pts[-2], pts[-1]))
    if both:
        out.append(tip(pts[1], pts[0]))
    if lab:
        out.append(text(at[0], at[1], lab, lsize, lcolor, halo=True))
    return "".join(out)


def line(x1, y1, x2, y2, color="border", sw=2, dashed=False):
    d = ' stroke-dasharray="9 8"' if dashed else ""
    return (
        f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{C[color]}" '
        f'stroke-width="{sw}"{d}/>'
    )


def mark(cx, cy, ok, r=16):
    """A verdict: ✓ for True, ✕ for False, ? for None."""
    a = {True: "ok", False: "error", None: "warn"}[ok]
    on = palette.on_solid(C, a)
    k = r * 0.4
    if ok is None:
        glyph = text(cx, cy, "?", max(MIN, round(r * 1.25)), on, weight=700)
    else:
        pts = (
            [(-k, 0.05 * r), (-k / 3, k * 0.75), (k, -k * 0.7)]
            if ok
            else [(-k, -k), (k, k), (0, 0), (k, -k), (-k, k)]
        )
        p = " ".join(f"{cx + x:.1f},{cy + y:.1f}" for x, y in pts)
        glyph = (
            f'<polyline points="{p}" fill="none" stroke="{C[on]}" '
            f'stroke-width="{r * 0.2:.1f}" stroke-linecap="round" stroke-linejoin="round"/>'
        )
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{C[a]}"/>' + glyph


def dot(cx, cy, accent, r=7):
    """Marks a small thing as part of a concept."""
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{C[accent]}"/>'


def strip(x, y, w, h, names):
    """A band of flat color blocks, one per name."""
    bw = w / len(names)
    return "".join(
        f'<rect x="{x + i * bw:.1f}" y="{y}" width="{bw + 0.5:.1f}" height="{h}" '
        f'fill="{C[n]}"/>'
        for i, n in enumerate(names)
    )


def code_height(n, size=26):
    return n * size * 1.55 + 60


def code(x, y, w, lines, hi=(), accent="accent", size=26, panel=True):
    """Source code at a large size. Lines in `hi` are highlighted and the rest
    are dimmed. A leading `+` or `-` colors a line as added or removed."""
    step = size * 1.55
    out = [rect(x, y, w, code_height(len(lines), size))] if panel else []
    for i, l in enumerate(lines):
        cy = y + 30 + step * (i + 0.5)
        col = "fg" if i in hi else "fg4" if hi else "fg2"
        if l[:1] in ("+", "-"):
            col = "ok" if l[0] == "+" else "error"
        if i in hi:
            out.append(
                rect(x + 12, cy - step / 2, w - 24, step, f"{accent}_wash", r=10)
                + rect(x + 12, cy - step / 2 + 8, 4, step - 16, accent, r=2)
            )
        out.append(
            text(x + 36, cy, l, size, col, "start", 500 if i in hi else 400, mono=True)
        )
    return "".join(out)


def stat(x, y, value, caption, accent, size=240, anchor="start"):
    """One number as the hero, with what it measures underneath. `accent` is
    one name, or several for a gradient through them."""
    names = (accent,) if isinstance(accent, str) else accent
    half = (caption.count("\n") + 1) * 30 * 1.3 / 2
    return text(
        x, y, value, size, grad(*names), anchor, 700, spacing=-size * 0.045
    ) + text(x, y + size * 0.56 + 20 + half, caption, 30, "fg3", anchor, lh=1.3)


def bars(x, y, w, rows, focus=0, accent="accent", lw=200, bh=56, gap=24, accents=None):
    """Horizontal bars, labeled directly. rows: (label, value, shown value).
    The `focus` row carries the accent and the rest stay neutral. With
    `accents`, one name per row, every bar wears its own color instead."""
    top = max(v for _, v, _ in rows)
    out = []
    for i, (name, v, shown) in enumerate(rows):
        cy = y + i * (bh + gap) + bh / 2
        bw = max((w - lw - 130) * v / top, bh)
        on = accents is not None or i == focus
        a = accents[i] if accents else accent
        out += [
            text(
                x + lw - 22,
                cy,
                name,
                24,
                "fg" if on else "fg3",
                "end",
                600 if on else 400,
            ),
            rect(x + lw, cy - bh / 2, bw, bh, a if on else "bg4", r=bh / 2),
            text(
                x + lw + bw + 18,
                cy,
                shown,
                24,
                "fg" if accents else a if on else "fg3",
                "start",
                700 if on else 400,
            ),
        ]
    return "".join(out)


def chain(cx, cy, items, accent="muted", focus=None, size=26, gap=64):
    """A chain of pills joined by arrows. `focus` is the index of the step that
    matters."""
    ws = [tw(s, size, weight=600) + size * 1.5 for s in items]
    x = cx - (sum(ws) + gap * (len(items) - 1)) / 2
    out = []
    for i, (s, w) in enumerate(zip(items, ws)):
        if i:
            out.append(arrow([(x - gap + 12, cy), (x - 12, cy)]))
        out.append(chip(x, cy, s, accent, size, focus == i, anchor="start"))
        x += w + gap
    return "".join(out)


def tree(x, y, rows, accent="muted", size=26, step=None):
    """A file tree in mono, its first row centered on y. rows: (depth, name,
    tag), where a tag is a pill after the name, or None."""
    step = step or size * 1.8
    ind = size * 1.2
    ys = [y + i * step for i in range(len(rows))]
    out = []
    for i, (d, name, tag) in enumerate(rows):
        nx = x + d * ind
        if d:
            # The connector runs down from the previous sibling, or from under the parent.
            j = max(k for k in range(i) if rows[k][0] <= d)
            top = ys[j] + (size * 0.6 if rows[j][0] < d else 0)
            cx = nx - ind + size * 0.3
            out.append(
                f'<polyline points="{cx:.1f},{top:.1f} {cx:.1f},{ys[i]:.1f} '
                f'{nx - size * 0.3:.1f},{ys[i]:.1f}" fill="none" stroke="{C["fg4"]}" '
                'stroke-width="2"/>'
            )
        out.append(text(nx, ys[i], name, size, "fg", "start", 500, mono=True))
        if tag:
            out.append(
                chip(
                    nx + tw(name, size, True) + size * 0.6,
                    ys[i],
                    tag,
                    accent,
                    max(MIN, round(size * 0.75)),
                    anchor="start",
                )
            )
    return "".join(out)


def grid(x, y, w, h, cols, rows=1, gap=GAP):
    """A tile grid. The result maps (column, row, column span, row span) to
    the (x, y, w, h) of that tile, so every figure uses the same spacing."""
    cw, rh = (w - gap * (cols - 1)) / cols, (h - gap * (rows - 1)) / rows

    def cell(c, r=0, cs=1, rs=1):
        return (
            x + c * (cw + gap),
            y + r * (rh + gap),
            cw * cs + gap * (cs - 1),
            rh * rs + gap * (rs - 1),
        )

    return cell


def svg(*els, w=W, h=H):
    return (
        f'<svg viewBox="0 0 {w} {h}" xmlns="http://www.w3.org/2000/svg" '
        f'font-family="{SANS}">' + "".join(els) + "</svg>"
    )


def inset(fig, x, y, w, h):
    """`fig` scaled into a box of another figure, to show a real figure small."""
    return fig.replace("<svg ", f'<svg x="{x}" y="{y}" width="{w}" height="{h}" ', 1)


def miniature(draw, theme=None, pad=56):
    """`draw()` as a small slide: on its page color, in a hairline frame, ready
    for `inset()`. With `theme`, it is drawn in that theme whatever theme the
    deck runs in."""
    saved = dict(C)
    if theme:
        use(theme)
    try:
        fig = draw()
        w, h = (float(v) for v in fig.split('viewBox="0 0 ')[1].split('"')[0].split())
        return svg(
            rect(0, 0, w + 2 * pad, h + 2 * pad, "bg", "border", 44, 3),
            inset(fig, pad, pad, w, h),
            w=w + 2 * pad,
            h=h + 2 * pad,
        )
    finally:
        use(saved)


def standalone(fig, pad=40):
    """`fig` as a self-contained SVG file on the page background."""
    vb = fig.split('viewBox="')[1].split('"')[0]
    x, y, w, h = (float(v) - pad * k for v, k in zip(vb.split(), (1, 1, -2, -2)))
    head, body = fig.replace(
        f'viewBox="{vb}"', f'viewBox="{x} {y} {w} {h}" width="{w}" ' f'height="{h}"', 1
    ).split(">", 1)
    return (
        f'{head}>{defs()}<rect x="{x}" y="{y}" width="{w}" height="{h}" '
        f'fill="{C["bg"]}"/>{body}'
    )


def base_css():
    """Variables and element styles for an HTML page. Decks build on it. An
    element takes a concept's color with `style="--accent: var(--pink)"`, and
    its gradient with `--accent-blend: var(--pink-blend)` beside it."""
    v = "".join(f'--{n.replace("_", "-")}: {c}; ' for n, c in C.items())
    return f"""
:root {{ {v}--sans: {SANS}; --mono: {MONO}; --r: {R}px; }}
* {{ box-sizing: border-box; }}
body {{ margin: 0; background: var(--bg); color: var(--fg2); font: 20px/1.6 var(--sans);
  -webkit-font-smoothing: antialiased; }}
h1, h2, h3 {{ color: var(--fg); font-weight: 700; letter-spacing: -.028em; line-height: 1.08; }}
b, strong {{ color: var(--fg); font-weight: 600; }}
a {{ color: var(--accent); text-decoration: none; }}
code, pre {{ font-family: var(--mono); font-size: .88em; }}
code {{ color: var(--fg); background: var(--bg3); padding: 1px 7px; border-radius: 7px; }}
pre {{ background: var(--bg3); border-radius: var(--r); padding: 28px 32px; overflow-x: auto;
  white-space: pre; }}
pre code {{ background: none; padding: 0; font-size: 1em; }}
.kicker {{ font-size: .8em; font-weight: 700; letter-spacing: .12em; text-transform: uppercase;
  color: var(--accent); }}
.card {{ background: var(--bg3); border-radius: var(--r); padding: 28px 32px; }}
.card.tint, .pill {{ background: color-mix(in srgb, var(--accent) 20%, var(--bg)); }}
.card.focus {{ background: var(--accent); color: var(--on, var(--bg)); }}
.card.focus * {{ color: inherit; }}
.pill {{ display: inline-block; border-radius: 99px; padding: 3px 16px; color: var(--accent);
  font-weight: 600; font-size: .88em; }}
.grad {{ background: var(--grad, linear-gradient(90deg, var(--accent), var(--accent-blend)));
  -webkit-background-clip: text; background-clip: text; color: transparent; }}
svg {{ overflow: visible; }}
table {{ border-collapse: collapse; }}
th {{ text-align: left; font-size: .8em; font-weight: 700; letter-spacing: .12em;
  text-transform: uppercase; color: var(--fg4); }}
th, td {{ padding: 14px 24px 14px 0; border-bottom: 2px solid var(--bg3); }}
"""


if __name__ == "__main__":
    # A theme with other accent names drives every component through roles alone.
    use(
        palette.theme(
            accent={"teal": "#40c8e0", "coral": "#ff6b5e", "ash": "#98989d"},
            role={
                r: "ash" if r == "muted" else "coral" if r == "error" else "teal"
                for r in palette.ROLE
            },
        )
    )
    g = grid(0, 0, 100, 50, 2, 2, 10)
    assert g(1, 1) == (55, 30, 45, 20) and g(0, 0, 2, 2) == (0, 0, 100, 50)
    fig = svg(
        card(*g(0), "a", "b", "teal", name="n", focus=True),
        card(0, 0, 9, 9, "a"),
        chip(0, 0, "c"),
        region(0, 0, 9, 9, "r"),
        mark(0, 0, True),
        mark(0, 0, None),
        code(0, 0, 9, ["+ a", "b"], hi=(1,)),
        stat(0, 0, "1", "c", ("coral", "teal")),
        bars(0, 0, 900, [("a", 1, "1"), ("b", 2, "2")]),
        chain(0, 0, ["a", "b"], focus=0),
        bars(0, 0, 900, [("a", 1, "1")], accents=["coral"]),
        strip(0, 0, 9, 9, ["teal"]),
        arrow([(0, 0), (9, 9)]),
        text(0, 0, "hero", 96, grad("teal")),
    )
    t = tree(0, 0, [(0, "a/", None), (1, "b/", "tag"), (2, "c", None), (1, "d", None)])
    assert t.count("<polyline") == 3 and t.count("<text") == 5, t
    assert "g-ff6b5e-40c8e0" in defs() and "--teal:" in base_css()
    assert "viewBox" in standalone(inset(fig, 1, 2, 3, 4))
    assert (
        'viewBox="0 0 972.0 712.0"' in miniature(lambda: fig, palette.COLORS)
        and "teal" in C
    )
    print("ok")

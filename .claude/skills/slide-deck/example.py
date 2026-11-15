#!/usr/bin/env python3
"""A deck about the house style, built with it: every slide type and every
component. Start a new deck from a copy.

Usage: python3 example.py deck.html [--theme paper] [--svg DIR]"""

import argparse
import os
import sys

sys.path.insert(0, os.path.expanduser("~/.claude/skills/slide-deck"))
from deck import (
    BH,
    BW,
    C,
    FH,
    FW,
    H,
    W,
    arrow,
    bars,
    card,
    chain,
    chip,
    code,  # noqa: E402
    code_height,
    dim,
    dot,
    flood,
    grad,
    grid,
    hue,
    inset,
    label,
    line,
    mark,
    miniature,
    page,
    palette,
    rect,
    region,
    slide,
    standalone,
    stat,
    statement,
    surface,
    svg,
    text,
    title_slide,
    tree,
    use,
)

args = argparse.ArgumentParser()
args.add_argument("out")
args.add_argument("--theme", choices=("dark", "paper"), default="dark")
args.add_argument("--svg")
args = args.parse_args()

# A second theme: the same accent names in other colors, on a light page.
PAPER = {
    "fg": "#1d1d1f",
    "fg2": "#424245",
    "fg3": "#5a5a5f",
    "fg4": "#86868b",
    "border": "#d2d2d7",
    "bg": "#f5f5f7",
    "bg2": "#e8e8ed",
    "bg3": "#ffffff",
    "bg4": "#dcdce1",
}
INK = {
    "indigo": "#5856d6",
    "blue": "#0071e3",
    "orange": "#f56300",
    "gray": "#6e6e73",
    "pink": "#e3185a",
    "green": "#1d9d48",
    "red": "#de1d1d",
    "yellow": "#b88600",
    "slate": "#aeaeb2",
}
DARK, PAPER_THEME = dict(palette.COLORS), palette.theme(neutral=PAPER, accent=INK)
if args.theme == "paper":
    use(PAPER_THEME)

# The legend: one accent per concept, used for every part of it.
STORY, LAYOUT, LANGUAGE, THEME = "green", "orange", "indigo", "blue"
CONCEPTS = [
    ("Story", STORY),
    ("Layouts", LAYOUT),
    ("Language", LANGUAGE),
    ("Theme", THEME),
]
SPECTRUM = (THEME, LANGUAGE, "pink", LAYOUT)
STRIP = ("blue", "indigo", "pink", "red", "orange", "yellow", "green")


def f_layers():
    layers = [
        ("Story", "what a slide says", "presentation", STORY),
        ("Layouts", "where it goes", "slide-deck", LAYOUT),
        ("Language", "how it looks", "kit.py", LANGUAGE),
        ("Theme", "which colors", "palette.py", THEME),
    ]
    g = grid(0, 0, FW, FH, 1, 4, 24)
    out = []
    for i, (name, job, file, a) in enumerate(layers):
        x, y, w, h = g(0, i)
        shape, (on, _, _) = surface(x, y, w, h, a, focus=True, r=36)
        out += [
            shape,
            text(x + 48, y + h / 2, name, 64, on, "start", 700),
            text(x + 560, y + h / 2, job, 34, on, "start", 500, opacity=0.8),
            text(
                x + w - 48, y + h / 2, file, 26, on, "end", 500, mono=True, opacity=0.65
            ),
        ]
    return svg(*out, w=FW, h=FH)


def f_files():
    """A diagram: seven cards at four levels, folders as regions, every arrow
    labeled, and the one thing the slide is about solid."""

    def file(x, y, w, name, sub, **kw):
        return card(x, y, w, 112, name, sub, mono=True, size=34, **kw)

    def rel(pts, lab, at):
        return arrow(pts, lab=lab, at=at, lsize=24)

    out = [
        region(0, 0, 360, 600, "slide-deck/"),
        region(470, 330, 986, 270, "house-style/"),
        file(30, 72, 300, "example.py", "the target", dim=True),
        file(480, 72, 340, "my_deck.py", "your story", accent=STORY, focus=True),
        file(30, 434, 300, "deck.py", "slide layouts", accent=LAYOUT),
        file(500, 434, 260, "kit.py", "the language", accent=LANGUAGE),
        file(860, 434, 260, "palette.py", "the theme", accent=THEME),
        file(1196, 434, 228, "shoot.sh", "the check"),
        rect(920, 0, 536, 290),
        tree(
            960,
            52,
            [
                (0, "out/", None),
                (1, "deck.html", "present"),
                (1, "svg/", "Keynote"),
                (2, "layers.svg", None),
                (2, "numbers.svg", None),
            ],
            step=47,
        ),
        rel([(330, 128), (480, 128)], "copy", (420, 102)),
        rel([(820, 128), (920, 128)], "writes", (870, 102)),
        rel([(650, 184), (650, 280), (180, 280), (180, 434)], "imports", (520, 280)),
        rel([(330, 490), (500, 490)], "imports", (415, 464)),
        rel([(760, 490), (860, 490)], "imports", (810, 464)),
        rel([(1310, 434), (1310, 290)], "screenshots", (1310, 380)),
    ]
    return svg(*out, w=FW, h=FH)


def f_flat():
    """A deck drawn from a palette alone: hairline boxes, small text, color as dots."""
    out = []
    for i, x in enumerate((40, 518, 996)):
        for j, y in enumerate((50, 245, 440)):
            out += [
                rect(x, y, 420, 110, None, "border", 14, 2),
                dot(x + 28, y + 30, (STORY, LAYOUT, LANGUAGE, THEME)[(i + j) % 4], 6),
                text(x + 210, y + 46, "Component", 22, "fg3", weight=600),
                text(x + 210, y + 78, "does a thing", 17, "fg4"),
            ]
            if i:
                out.append(arrow([(x - 58, y + 55), (x, y + 55)], "border", sw=2))
    return svg(*out, w=FW, h=FH)


def f_before_after():
    sides = [
        (f_flat, "Before", None, "Palette only: every box weighs the same."),
        (f_layers, "After", LANGUAGE, "With the language, color carries meaning."),
    ]
    g = grid(0, 0, FW, 322, 2, gap=40)
    out = []
    for i, (fig, name, a, cap) in enumerate(sides):
        x, y, w, h = g(i)
        out += [
            inset(miniature(fig), x, y, w, h),
            label(x, 376, name, palette.ink(C, a, large=True) if a else "fg4", size=20),
            text(x, 424, cap, 30, "fg" if a else "fg3", "start", 500),
        ]
    return svg(*out, w=FW, h=456)


def f_numbers():
    g = grid(0, 0, BW, BH, 4, 2)
    x, y, w, h = g(0, 0, 2, 2)
    shape, (on, _, _) = surface(x, y, w, h, STORY, focus=True, r=40)
    out = [
        shape,
        label(x + 52, y + 64, "Story", on, size=20, opacity=0.7),
        text(
            x + 52,
            y + h - 196,
            "Three numbers\nshape every\ntalk.",
            92,
            on,
            "start",
            700,
            lh=1.04,
        ),
    ]
    x, y, w, h = g(2, 0, 2)
    out += [
        rect(x, y, w, h, r=40),
        text(x + 48, y + h / 2, "1", 300, grad(STORY), "start", 700),
        text(x + 270, y + h / 2 - 34, "idea per talk", 44, "fg", "start", 700),
        text(
            x + 270,
            y + h / 2 + 40,
            "The audience can repeat\nit afterwards.",
            26,
            "fg3",
            "start",
            lh=1.3,
        ),
    ]
    for i, (n, head) in enumerate(
        [("3", "seconds\nper slide"), ("7", "boxes per\ndiagram")]
    ):
        x, y, w, h = g(2 + i, 1)
        out += [
            rect(x, y, w, h, r=40),
            text(x + 40, y + 124, n, 210, grad(STORY), "start", 700),
            text(x + 44, y + 284, head, 34, "fg", "start", 700, lh=1.2),
        ]
    return svg(*out, w=BW, h=BH)


def f_types():
    a, on = LAYOUT, palette.on_solid(C, LAYOUT)
    head = [(36, 40, 190, 14, "fg")]
    types = [
        ("Title", [(36, 40, 64, 9, a), (36, 76, 300, 36, "fg"), (36, 124, 230, 36, a)]),
        ("Statement", [(36, 62, 360, 32, "fg"), (36, 108, 270, 32, "fg4")]),
        ("Flood", [(36, 62, 330, 32, on), (36, 108, 250, 32, on)]),
        (
            "Figure",
            head
            + [
                (36, 76, 124, 110, "bg4"),
                (174, 76, 124, 110, a),
                (312, 76, 124, 110, "bg4"),
            ],
        ),
        (
            "Figure and points",
            head
            + [
                (36, 84, 130, 10, "fg4"),
                (36, 110, 150, 10, "fg4"),
                (36, 136, 110, 10, "fg4"),
                (222, 76, 100, 110, "bg4"),
                (336, 76, 100, 110, a),
            ],
        ),
        (
            "Full bleed",
            [
                (36, 36, 190, 150, a),
                (242, 36, 194, 67, "bg4"),
                (242, 119, 194, 67, "bg4"),
            ],
        ),
    ]
    g = grid(0, 0, FW, FH, 3, 2)
    out = []
    for i, (name, blocks) in enumerate(types):
        x, y, w, h = g(i % 3, i // 3)
        is_flood = name == "Flood"
        shape, (ct, _, _) = surface(x, y, w, h, a if is_flood else None, is_flood)
        out.append(shape)
        out += [
            rect(x + dx, y + dy, bw, bh, col, r=min(bh / 2, 8))
            for dx, dy, bw, bh, col in blocks
        ]
        out.append(text(x + 36, y + h - 46, name, 28, ct, "start", 700))
    return svg(*out, w=FW, h=FH)


def f_levels():
    levels = [
        (dict(dim=True), "Context", "Dim", "not the subject", "dim=True"),
        (dict(), "A thing", "Plain", "has no concept", "card()"),
        (dict(accent=LANGUAGE), "A concept", "Tinted", "wears its color", "accent="),
        (
            dict(accent=LANGUAGE, focus=True),
            "The point",
            "Solid",
            "one per slide",
            "focus=True",
        ),
    ]
    g = grid(0, 0, FW, FH, 4)
    out = []
    for i, (kw, name, title, sub, arg) in enumerate(levels):
        x, y, w, h = g(i)
        shape, (ct, cb, cl) = surface(x, y, w, h, r=36, **kw)
        quiet = 0.75 if kw.get("focus") else 1
        out += [
            shape,
            label(x + 36, y + 52, name, cl, size=20, opacity=quiet),
            text(x + w - 36, y + 52, arg, 20, cl, "end", 500, mono=True, opacity=quiet),
            text(x + 36, y + h - 118, title, 72, ct, "start", 700),
            text(x + 36, y + h - 54, sub, 28, cb, "start", 500),
        ]
    return svg(*out, w=FW, h=FH)


def f_shapes():
    a = LANGUAGE
    specs = [
        ("Thing", "a card"),
        ("Name", "a pill"),
        ("Boundary", "a dashed outline"),
        ("Relation", "a labeled arrow"),
        ("Verdict", "a mark"),
    ]
    g = grid(0, 0, FW, FH, 5)
    out = []
    for i, (word, cap) in enumerate(specs):
        x, y, w, h = g(i)
        cx, cy = x + w / 2, y + 200
        out.append(rect(x, y, w, h, r=36))
        out.append(
            [
                rect(cx - 84, cy - 60, 168, 120, a, r=24),
                chip(cx, cy, "kit.py", a, 28, mono=True),
                rect(cx - 88, cy - 64, 176, 128, None, a, 28, 3, dashed=True),
                arrow([(cx - 90, cy + 16), (cx + 90, cy + 16)], a, sw=5)
                + text(cx, cy - 24, "imports", 24, "fg2"),
                mark(cx, cy, True, 56),
            ][i]
        )
        out += [
            text(x + 32, y + h - 112, word, 40, "fg", "start", 700),
            text(x + 32, y + h - 58, cap, 24, "fg3", "start"),
        ]
    return svg(*out, w=FW, h=FH)


def f_color():
    xs = (0, 470, 800, 1000, 1270)
    out = [
        label(x, 14, c) for x, c in zip(xs, ("Word", "Tile", "Pill", "Arrow", "Kicker"))
    ]
    for r, (name, a) in enumerate(CONCEPTS):
        y = 110 + r * 140
        if r:
            out.append(line(0, y - 70, FW, y - 70, "bg3"))
        out += [
            text(xs[0], y, name.lower(), 72, grad(a), "start", 700),
            card(xs[1], y - 48, 240, 96, name, accent=a, focus=True, size=30),
            chip(xs[2], y, name.lower(), a, 24, anchor="start"),
            arrow([(xs[3], y), (xs[3] + 180, y)], a, sw=5),
            label(xs[4], y, name, palette.ink(C, a, large=True), size=22),
        ]
    return svg(*out, w=FW, h=FH)


def f_code():
    lines = ["card(x, y, w, h, 'Kit',", "     accent=LANGUAGE, focus=True)"]
    hc = code_height(len(lines), 28)
    return svg(
        code(0, 0, W, lines, size=28),
        arrow([(W / 2, hc + 18), (W / 2, hc + 82)], sw=4),
        card(
            0, hc + 100, W, H - hc - 100, "Kit", accent=LANGUAGE, focus=True, size=160
        ),
    )


def f_contrast():
    vals = sorted(
        ((n, palette.contrast(C[n], C["bg"])) for n in palette.ACCENT),
        key=lambda p: -p[1],
    )
    rows = [(n, v, f"{v:.1f}:1") for n, v in vals]
    passing = sum(v >= palette.AA for _, v in vals)
    x0, y0, lw, w, bh, gap = 600, 40, 210, 856, 42, 20
    scale = (w - lw - 130) / vals[0][1]
    xt = x0 + lw + scale * palette.AA
    out = [
        stat(
            0,
            170,
            f"{palette.AA}:1",
            "The floor for body text.\ntheme() refuses less.",
            THEME,
            size=210,
        ),
        line(xt, y0 - 8, xt, y0 + passing * (bh + gap) - gap + 8, "fg4", dashed=True),
        text(xt, 12, "floor", 20, "fg3"),
        bars(x0, y0, w, rows, accents=[n for n, _ in vals], lw=lw, bh=bh, gap=gap),
    ]
    for i, (n, v) in enumerate(vals):
        cy = y0 + i * (bh + gap) + bh / 2
        out.append(text(x0, cy, "Aa", 30, n, "start", 700))
        if v < palette.AA:
            end = x0 + lw + max(scale * v, bh)
            out += [
                mark(end + 124, cy, False, 15),
                text(end + 150, cy, "fills only", 24, "fg3", "start"),
            ]
    return svg(*out, w=FW, h=FH)


def f_swap():
    themes = [(DARK, "The default theme"), (PAPER_THEME, "The same figure, on paper")]
    g = grid(0, 0, FW, 322, 2, gap=40)
    out = []
    for i, (theme, name) in enumerate(themes):
        x, y, w, h = g(i)
        out += [
            inset(miniature(f_layers, theme), x, y, w, h),
            text(x, 366, name, 28, "fg3", "start", 500),
        ]
    out.append(
        code(0, 420, FW, ["kit.use(palette.theme(neutral=PAPER, accent=INK))"], size=34)
    )
    return svg(*out, w=FW, h=420 + code_height(1, 34))


def f_check():
    out = [
        chain(
            FW / 2,
            40,
            ["draw", "shoot", "read", "compare", "fix"],
            LAYOUT,
            focus=3,
            size=40,
        )
    ]
    g = grid(0, 130, FW, 300, 2, gap=160)
    for i, name in enumerate(("The example", "Your slide")):
        x, y, w, h = g(i)
        out += [
            inset(miniature(f_levels), x, y, w, h),
            text(x, 474, name, 28, "fg3", "start", 500),
        ]
    out.append(mark(FW / 2, 280, True, 44))
    return svg(*out, w=FW, h=500)


FIGURES = [
    f_before_after,
    f_layers,
    f_files,
    f_numbers,
    f_types,
    f_levels,
    f_shapes,
    f_color,
    f_code,
    f_contrast,
    f_swap,
    f_check,
]

SLIDES = [
    title_slide(
        f'One language.<br>{hue("Any palette.", *SPECTRUM)}',
        "A house style for technical decks",
        "House style",
        LANGUAGE,
        STRIP,
        raw=True,
    ),
    statement(
        f'The palette carried over.<br>{dim("The look did not.")}',
        "The problem",
        THEME,
        raw=True,
    ),
    slide(
        f_before_after(),
        "Problem",
        "A palette alone becomes flat boxes",
        color=LANGUAGE,
    ),
    flood(
        f'Fix the language.<br>{dim("Swap the palette.")}',
        "The idea",
        LANGUAGE,
        raw=True,
    ),
    slide(f_layers(), "Architecture", "Four layers, one job each", color=LANGUAGE),
    slide(
        f_files(),
        "Architecture · files",
        "One script writes the whole deck",
        color=STORY,
    ),
    slide(f_numbers(), color=STORY),
    slide(
        f_types(),
        "Layouts",
        "Six slide types set the rhythm",
        color=LAYOUT,
        minimap=(4, 1),
    ),
    slide(
        f_levels(),
        "Language · emphasis",
        "Four levels of emphasis",
        color=LANGUAGE,
        minimap=(4, 2),
    ),
    slide(
        f_shapes(),
        "Language · shapes",
        "Each shape means one thing",
        color=LANGUAGE,
        minimap=(4, 2),
    ),
    slide(
        f_color(),
        "Language · color",
        "A concept keeps its color everywhere",
        color=LANGUAGE,
        minimap=(4, 2),
    ),
    slide(
        f_code(),
        "Language · code",
        "The language ships as code",
        [
            "A deck asks for a **thing** at a **level**. The kit decides how it looks.",
            "Text under **16px** and titles over **44 characters** fail the build.",
            "So does body text under **4.5:1**.",
        ],
        LANGUAGE,
        minimap=(4, 2),
    ),
    slide(
        f_contrast(),
        "Theme · contrast",
        "Every contrast ratio is computed",
        color=THEME,
        minimap=(4, 3),
    ),
    slide(
        f_swap(),
        "Theme · swap",
        "A new palette is one call",
        color=THEME,
        minimap=(4, 3),
    ),
    slide(
        f_check(),
        "Layouts · check",
        "Every slide is checked by eye",
        color=LAYOUT,
        minimap=(4, 1),
    ),
    title_slide(
        f'Start from<br>{hue("example.py", *SPECTRUM)}',
        "Copy it. Declare the legend. Check every slide.",
        "Next",
        LANGUAGE,
        STRIP,
        raw=True,
    ),
]

with open(args.out, "w") as f:
    f.write(page(SLIDES, "One language, any palette"))
if args.svg:
    os.makedirs(args.svg, exist_ok=True)
    for fig in FIGURES:
        with open(os.path.join(args.svg, fig.__name__[2:] + ".svg"), "w") as f:
            f.write(standalone(fig()))
print(f"{args.out}: {len(SLIDES)} slides, {args.theme} theme")

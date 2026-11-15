"""House theme. Import from scripts; run to print CSS variables."""

import colorsys

NEUTRAL = {
    # Foreground
    "fg": "#f5f5f7",  # titles, primary text
    "fg2": "#d1d1d6",  # body text
    "fg3": "#a1a1a6",  # secondary text, captions
    "fg4": "#86868b",  # dim text, comments, disabled
    "border": "#38383a",  # hairlines, separators, outlines
    # Background
    "bg": "#050506",  # page, terminal
    "bg2": "#141416",  # cards
    "bg3": "#1f1f22",  # raised cards, panels
    "bg4": "#2c2c2e",  # controls, pills, hover
}

ACCENT = {
    "indigo": "#6e6cff",
    "blue": "#0a84ff",
    "orange": "#ff9f0a",
    "gray": "#98989d",
    "pink": "#ff375f",
    "green": "#30d158",
    "red": "#ff453a",
    "yellow": "#ffd60a",
    "slate": "#636366",
}

# Meanings that hold in every deck. A role is an alias for an accent. `accent`
# is the color of a deck's only concept, or of a thing with no concept.
ROLE = {
    "accent": "blue",
    "new": "yellow",
    "ok": "green",
    "error": "red",
    "warn": "orange",
    "muted": "gray",
}

# The neighbor hue each accent runs into, for gradient type.
BLEND = {
    "indigo": "#bf5af2",
    "blue": "#64d2ff",
    "orange": "#ffd60a",
    "gray": "#d1d1d6",
    "pink": "#ff9f0a",
    "green": "#63e6e2",
    "red": "#ff9f0a",
    "yellow": "#ff9f0a",
    "slate": "#98989d",
}

AA = 4.5  # WCAG AA contrast for body text
AA_LARGE = 3.0  # and for text of 24px, or 19px bold, and up


def mix(c, pct, base=NEUTRAL["bg"]):
    """`c` at `pct` percent over `base`, like CSS color-mix in srgb."""
    a, b = (bytes.fromhex(x[1:]) for x in (c, base))
    return (
        "#"
        + bytes(round((x * pct + y * (100 - pct)) / 100) for x, y in zip(a, b)).hex()
    )


def contrast(a, b):
    """WCAG contrast ratio of two hex colors."""

    def lum(c):
        ch = [x / 255 for x in bytes.fromhex(c[1:])]
        r, g, b = (
            x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in ch
        )
        return 0.2126 * r + 0.7152 * g + 0.0722 * b

    hi, lo = sorted((lum(a), lum(b)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)


def rotate(c, deg=35):
    """`c` with its hue turned by `deg` degrees."""
    h, l, sat = colorsys.rgb_to_hls(*(x / 255 for x in bytes.fromhex(c[1:])))
    return (
        "#"
        + bytes(
            round(x * 255) for x in colorsys.hls_to_rgb((h + deg / 360) % 1, l, sat)
        ).hex()
    )


def theme(neutral=NEUTRAL, accent=ACCENT, role=ROLE, blend=None):
    """A flat map from name to hex. Each accent and role also gets `_wash`,
    `_outline`, and `_blend`. Raises if body text would be unreadable on a
    surface."""
    if blend is None:
        blend = BLEND if accent is ACCENT else {}
    c = dict(neutral)
    for fg in ("fg", "fg2", "fg3"):
        for bg in ("bg", "bg2", "bg3", "bg4"):
            assert contrast(c[fg], c[bg]) >= AA, f"{fg} on {bg} is below {AA}:1"
    c.update(accent)
    c.update({r: accent[a] for r, a in role.items()})
    for n in (*accent, *role):
        c[f"{n}_wash"] = mix(c[n], 20, c["bg"])
        c[f"{n}_outline"] = mix(c[n], 50, c["bg"])
        c[f"{n}_blend"] = blend.get(role.get(n, n)) or rotate(c[n])
    return c


def ink(c, name, on="bg", large=False):
    """`name` if it is readable as text on `on`, else body text."""
    return name if contrast(c[name], c[on]) >= (AA_LARGE if large else AA) else "fg2"


def on_solid(c, name):
    """The text color for a shape filled with `name`. Text on a fill is
    large, so the lighter of `fg` and `bg` wins wherever it is readable."""
    light, dark = sorted(("fg", "bg"), key=lambda t: -contrast(c[t], "#000000"))
    return light if contrast(c[light], c[name]) >= AA_LARGE else dark


COLORS = theme()

if __name__ == "__main__":
    assert mix("#ffffff", 50, "#000000") == "#808080"
    assert round(contrast("#ffffff", "#000000")) == 21
    print(":root {")
    for n, c in COLORS.items():
        print(f'  --{n.replace("_", "-")}: {c};')
    print("}")
    for a in ACCENT:
        ok = [b for b in ("bg", "bg2", "bg3", "bg4") if ink(COLORS, a, b) == a]
        print(
            f'/* {a}: text on {", ".join(ok) or "nothing"}, solid takes '
            f"{on_solid(COLORS, a)} */"
        )

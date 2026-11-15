---
name: house-style
description: House visual language for slides, diagrams, HTML pages, and UI. Poster-like, with huge type and flat vivid color, shipped as a Python kit and a stylesheet over a swappable theme. Load before designing or styling anything visual.
---

# House style

Every slide, figure, and page should look as if a full-time design team made it for a flagship launch. If it looks like the output of a diagram tool, with small text in equal boxes, it is not done.

Decide what picture each slide is before picking components.

The style has two layers. The language is fixed and makes work recognisable across decks. The theme is the palette and can change with the subject.

Before designing, build `~/.claude/skills/slide-deck/example.py` and screenshot it. Its slides are the target.

## Language

- Make the type large. Hero type runs 120 to 300px, heavy and tight, and one number or one sentence can fill a slide. Body text is 28px or more, and nothing is under 16px.
- Fill tiles and whole slides with flat, vivid color. Most of a deck stays black, which makes the color stand out.
- Do not put a gradient, glow, shadow, or outline on a shape or behind one. They read as decoration and they band on a video call.
- Use a gradient only in hero type. `grad()` runs a concept's color into its neighbor hue, or through several concepts.
- Show the thing itself. A specimen, a real number, or a `miniature()` of the actual figure says more than a labeled box.
- Give each concept one accent, declared in a legend at the top of the script. Every part of the concept uses it: its kicker, tile, pill, arrow, and its word in a statement. An overview shows every concept in its color. A detail slide colors one concept and leaves the rest neutral.
- Put every tile at one of four levels of emphasis.

  | Level | Looks | Means |
  |-------|-------|-------|
  | Dim | darkest tile, gray text | context the view is not about |
  | Plain | neutral tile | a thing with no concept |
  | Tinted | tile washed in the concept's color | part of a concept |
  | Solid | tile filled with the concept's color | the point |

- Roles mean the same in every deck. `new` marks what is new, and `ok`, `error`, and `warn` are verdicts. `muted` is for what is not the point, and `accent` is the default when there is one concept.
- Give each shape one meaning. A card is a thing, a pill names or tags one, a dashed outline is a boundary, an arrow is a labeled relation, and a mark is a verdict.
- Use one grid, with 72px margins, 20px gaps, and 28px corners. `grid()` places the tiles, and a figure fills its box.

## Theme

`palette.py` holds `NEUTRAL` (the `fg` and `bg` ramps), `ACCENT`, `ROLE`, and `BLEND`. `theme()` builds a flat map from name to hex and adds `_wash`, `_outline`, and `_blend` per accent. It raises if body text would miss 4.5:1 on a surface.

- Keep the default theme unless the subject calls for another.
- Swap with `kit.use(palette.theme(neutral={...}, accent={...}))` before drawing. If the accent names stay the same, the deck script does not change.
- `python3 palette.py` prints the CSS variables and where each accent may be text. `ink()` and `on_solid()` answer the same in code.
- Refer to colors by name and never inline a hex value.

## Kit

`kit.py` draws the language. Colors and levels are arguments, so a deck never restyles a shape.

```python
sys.path.insert(0, os.path.expanduser('~/.claude/skills/house-style'))
from kit import FH, FW, grad, grid, rect, svg, text
g = grid(0, 0, FW, FH, 3)                      # three tiles across a figure
x, y, w, h = g(0)
svg(rect(x, y, w, h), text(x + 44, y + 170, '3', 300, grad('green'), 'start', 700),
    text(x + 44, y + h - 76, 'seconds per slide', 40, 'fg', 'start', 700), w=FW, h=FH)
```

- For tiles, `surface` gives a tile and its text colors at a level, `card` adds a title, subtitle, and name, and `rect` is the raw shape.
- The other shapes are `chip`, `region`, `arrow`, `mark`, `dot`, `line`, and `strip`.
- Content comes from `text`, `label`, `code` (highlighted lines, `+`/`-` diffs), `stat`, `bars`, `chain`, and `tree` (a file tree with tags).
- `grid` lays out tiles. `inset` and `miniature` show a real figure small, in any theme.
- `svg()` returns a figure for inline use, and `standalone()` returns an SVG file.
- For an HTML page, put `base_css()` in a `<style>` and `defs_svg()` once at the end of the body. The classes are `.kicker`, `.card` with `.tint` or `.focus`, `.pill`, and `.grad`. Set a concept's color with `style="--accent: var(--pink); --accent-blend: var(--pink-blend)"`.
- Add a missing component to the kit so every deck gets it. `python3 kit.py` runs its self-check.

## Check

Screenshot every view with `shoot.sh page.html outdir N...`, read the PNG, and compare it with the example's slides. It is wrong if:

- Nothing is large. The biggest element should dwarf the rest.
- It is mostly gray, or the color is only in dots and labels.
- The boxes are the same size and weight, with small text inside.
- A shape has a glow, a shadow, a gradient, or a bare outline.
- A concept changes color, or a color has no meaning.
- Part of the frame is empty while the figure is small.
- Shapes overlap, text leaves its box, or gaps are uneven.

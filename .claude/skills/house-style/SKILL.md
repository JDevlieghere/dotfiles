---
name: house-style
description: House color palette. Dark theme with a foreground ramp, background ramp, and accent colors. Load when choosing colors for a diagram, slide, web page, or UI.
---

# House style

Dark theme. Colors live in `palette.py` next to this file; read it for names,
values, and roles. `fg` and `bg` are the extremes; each higher number steps
toward the middle.

- CSS: `python3 ~/.claude/skills/house-style/palette.py` prints `:root` variables.
- Python: `sys.path.insert(0, os.path.expanduser('~/.claude/skills/house-style'))`,
  then `from palette import COLORS`.
- Keynote and other tools without variables: take the hex from the CSS output.

## Rules

- Use these names everywhere. Never inline other hex values.
- Text sits on `bg`–`bg3`. Pick the foreground by importance, not by decoration.
- Tinted boxes and pills fill with `<accent>_wash` and outline with
  `<accent>_outline` (`--blue-wash` in CSS).
- Give each concept one accent and use it for all its parts.
- Yellow marks what is new. Red is errors, green is success, orange is warnings.
- Gray and slate are neutral accents for things that are not the point.

## Contrast

Body text needs 4.5:1 (WCAG AA).

- On `bg4`, use `fg`–`fg3`; `fg4` drops to 3.8:1.
- Accent text only on `bg` or `bg2`; indigo drops to 4.1:1 on `bg3`.
- Text on a solid accent is `bg`, except on slate, where it is `fg`.
- Text on a wash is `fg2` or the accent itself, except indigo (4.3:1).
- Slate is never text (3.4:1 at best).

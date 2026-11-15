---
name: slide-deck
description: HTML slide decks generated from Python, in the house style. Load when asked to make a presentation, slides, or a deck, or to turn a document into a presentation.
---

# Slide deck

Load the `house-style` and `presentation` skills first. `house-style` covers the visual language, the figure kit, and SVG export. `presentation` covers story, slide, and diagram principles.

A deck is one Python script that imports `deck.py`, next to this file, which adds slide layouts to the house-style kit. The script writes a self-contained HTML deck and, on request, standalone SVGs that the user drops into Keynote. `example.py` uses every slide type and component, in two themes. Its slides are the target, so build it and screenshot it before designing. Start new decks from a copy of it.

```bash
python3 example.py out/deck.html          # the target, to screenshot and read
python3 my_deck.py deck.html --svg svg/   # HTML deck, plus one .svg per figure
```

## Workflow

1. Ask whether the deck is presented or read alone, unless the user said. The answer decides the slide anatomy below.
2. Outline the argument before drawing anything, for example: question, problem, architecture, user experience, opens. Each slide makes one claim.
3. Storyboard the deck. Decide what picture each slide is: a sentence, a number, a specimen, a diagram, or a miniature. Vary the slide types so neighboring slides do not look alike.
4. Name the concepts in a legend at the top of the script and give each an accent: `STORY, THEME = 'green', 'blue'`.
5. Build each figure as a function that returns `svg(...)`, and write the page with `page(slides, title)`.
6. Check every slide you change with house-style's `shoot.sh deck.html outdir N...`. Read the PNGs and compare them with the example's slides. Headless Chrome must run unsandboxed. If the sandbox blocks it, ask the user to allow it.
7. Export figures with `standalone(fig())` when the user wants SVGs. The user maintains any Keynote deck themselves: never script Keynote or overwrite a `.key`.

## Slide types

Slides are 1600×900 with 72px margins.

- `title_slide()` opens and closes. `strip` names the accents of the color band on the bottom edge.
- `statement()` is one sentence alone on black, at 124px. Break it in two lines and `dim()` the second for a two-tone statement.
- `flood()` is one sentence on a slide filled with a concept's color: the idea, or the start of a section. Use it once or twice.
- `slide(fig, kicker, title)` puts a 1456×600 figure (`FW`, `FH`) under the claim.
- `slide(fig, kicker, title, points)` puts two or three points beside an 860×600 figure (`W`, `H`). It is for decks read alone.
- `slide(fig)` gives a bento of tiles the whole slide, 1456×756 (`BW`, `BH`). One tile carries the claim.
- `minimap=(layers, lit)` shows which layer of the architecture a slide is about.
- In a statement or title, `==word==` takes the slide's gradient. With `raw=True`, `hue(word, *accents)` picks the colors.

## Slide anatomy

- The kicker is a caps label in the slide's `color`, written `Section · topic`. Add `· to chase down` for an open question.
- The title is the slide's claim as a sentence, in sentence case. It has at most 44 characters so it fits on one line.
- In a presented deck, the speaker says the words and the figure carries the slide. Leave out points, so the audience listens instead of reading.
- In a deck read alone, points are full sentences at 30px with the important words in `**bold**`, so the slide stands on its own.
- The figure shows the claim as a picture and fills its box. Do not draw boxes that repeat the points.
- A diagram follows `f_files` in the example: at most seven cards, each at a level, titles of 32px or more, labeled arrows, dashed regions for boundaries, and one solid card for the point.
- Work Today/New tags into the story rather than adding separate "new" slides.

## Writing

- Few words. Say the claim, not a setup for it.
- Present agreements as facts and opens as "To chase down". Don't list every open.
- Don't invent facts. Flag anything not in the user's sources, such as licenses, counts, or command syntax, as an assumption.
- No em dashes, staged one-liners, or fragments. Don't name individuals.
- A presented deck always gets presenter notes, as a separate Markdown file: talking points and likely questions per slide. A deck read alone gets them when asked.
- To turn a dense deck into one to present, move its text to the notes and redraw each figure to show the claim. Do not merge points into longer ones.

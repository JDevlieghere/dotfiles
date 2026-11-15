---
name: presentation
description: Principles for technical talks, covering story, slide design, and diagrams, independent of the tool. Load when outlining a talk, writing or reviewing slides, or drawing a diagram for a slide. The `slide-deck` skill covers generating the deck.
---

# Presentation

A talk has one idea the audience can repeat afterwards. Write it down as one sentence before outlining, and cut whatever does not support it.

Decide first whether the deck is presented or read alone. These rules assume a presenter. A deck read alone needs full-sentence points. `slide-deck` builds both.

## Talk

- Pitch to what the audience already knows, and say why they should care in the first two minutes.
- Tell it as problem, why it is hard, insight, and result. Do not tell it in the order the work happened.
- Go deep on a little instead of covering everything, and put the details in backup slides.
- For every number, give the baseline and the unit. Give each chart one takeaway.
- Record a fallback for every demo.
- End by restating the idea and what the audience should do next. Do not end on a "Questions?" slide.

## Slides

A slide is a backdrop for the speaker, and the audience should understand it in about three seconds.

- Make one point per slide, and write its title as the claim ("Memoizing cut link time 4x"), not the topic ("Performance").
- Give the slide one focal point and make it the largest or brightest thing.
- Leave whitespace. Split a crowded slide in two.
- Keep titles, body, and figures in the same place on every slide.
- Use type of at least 24pt. If the text does not fit, cut words instead of shrinking it. Use two fonts at most, a sans-serif and a monospace.
- When the deck is presented, write fragments and keep full sentences for the title.
- Follow `house-style` for color. Never encode with color alone: pair it with a label or shape.
- Show ten lines of code at most and elide the rest with `...`. Highlight the line under discussion and dim the others.
- In a chart, state the conclusion in the title and label lines directly instead of using a legend. Leave out gridlines, borders, and 3D. Make axis labels as large as body text.
- Use motion only to show change, such as a build step or a before and after.
- Leave out logos and repeated decoration. Keep slide numbers for Q&A.

## Diagrams

A diagram answers one question. Name the question before drawing.

| Question | Type |
|----------|------|
| What are the parts? | Block diagram |
| What happens in what order? | Sequence diagram or timeline |
| How does data move? | Pipeline, with arrows as data |
| What states exist? | State machine |
| What is laid out where? | Layout map (sections, stack frames, DIEs) |

- Stay at one level of abstraction. Do not mix processes, classes, and bytes.
- Use seven boxes at most. Past that, group or split.
- Omit what the talk does not mention.
- Give each encoding one meaning. Shape, color, line style, and arrowhead each mean one thing for the whole talk.
- Label the arrows. An unlabeled arrow could mean calls, owns, sends, or becomes.
- Pick one flow direction, left to right or top to bottom, and let time and causality follow it.
- Use position. Things that are close are related, and a thing inside another belongs to it.
- Do not let lines cross. Rearrange the boxes until none do.
- Show the architecture once as a base diagram, then return to it with the relevant part highlighted.
- Keep positions fixed between builds. A box that moves makes the audience parse the diagram again.
- Build incrementally, revealing each piece as it is discussed.
- For a before and after, keep the layout and put only the change in the accent color.
- Use real examples: a real address, symbol name, or packet instead of `foo` or "Module A".
- Annotate the one spot that matters with a callout.
- Draw in vector, in the slide's fonts and colors, with labels as large as body text. Do not paste screenshots of tools.

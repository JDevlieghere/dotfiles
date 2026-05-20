---
name: comments
description: Conventions for writing source code comments. Load when adding or editing comments in code, reviewing a diff for comment quality, or deciding whether a comment belongs at all. Covers when a comment earns its place, the WHY-not-WHAT rule, banning prompt/task references, and the tone and length to aim for.
---

# Comments

Default to writing no comment. A comment is only worth keeping if removing it would leave a future reader genuinely confused or at risk of breaking something.

## The bar

Add a comment only when it captures something the code itself cannot:

- A **hidden constraint** the compiler won't enforce (ordering requirement, lock that must be held, ABI boundary).
- A **subtle invariant** a careful reader might still miss.
- A **workaround** for a specific bug or quirk in another system — name the system and, if possible, the symptom.
- **Surprising behavior** — a branch that looks dead but isn't, a value chosen for a non-obvious reason, an early return that prevents a later footgun.
- A **reference** that saves the reader a long hunt — spec section, RFC, bug ID, paper.

If none of these apply, delete the comment. Self-explanatory code with good names is the goal.

## WHY, not WHAT

Never describe what the code does — the code already does that. Explain *why* it has to be that way.

Bad (restates the code):
```cpp
// Increment the counter
++count;

// Loop over each element in the vector
for (auto &elem : elements) { ... }
```

Good (explains the why):
```cpp
// DWARF 5 requires the abbrev offset to be section-relative, not
// compile-unit-relative; older readers tolerate either.
WriteSectionRelative(AbbrevOffset);
```

If the "why" is obvious from the surrounding code, no comment is needed.

## Do not anchor comments to the current task

A comment lives in the codebase for years. The prompt, ticket, PR, or conversation you're working in does **not**. Understand *why* the code has to behave this way, and write that — not "added for the X flow" or "fixes the bug from issue 1234".

Banned framings:
- "Added to handle the case from <ticket>"
- "Used by <caller>" / "Called from <file>"
- "Fix for the regression introduced in <commit>"
- "Per the user's request" / "As discussed"
- "TODO: revisit after <task>"

If a ticket or commit genuinely needs to be findable, it belongs in the commit message or PR description, not the source. The one exception: a comment that documents a workaround for an *external* bug can cite that external tracker (e.g. `// Workaround for LLVM bug 12345`), because the reference is about the foreign system, not your local task.

## Tone and length

- **One line if one line suffices.** Most good comments are a sentence.
- **Plain prose**, complete sentences, no decoration. No banners, no ASCII art, no `// ===== SECTION =====` separators.
- **No marketing language** ("cleanly handles", "robust", "elegant solution").
- **No apologies or narration** ("we have to do this ugly thing because...", "note that..."). State the constraint directly.
- **Present tense, declarative.** "The buffer is reused across calls" beats "We're going to reuse the buffer".

Multi-paragraph comments are rare and almost always belong at the top of a function or class explaining a non-obvious contract — not scattered inside a function body.

## Doc comments vs. inline comments

Doc comments (Doxygen `///`, Python docstrings, JSDoc) on public API document the *contract*: what callers must guarantee, what they get back, what can go wrong. They follow the same WHY-over-WHAT rule but are allowed to restate the signature when it clarifies semantics (units, ownership, nullability, lifetime). Keep them as short as the contract allows. If the function name and types fully describe the contract, skip the doc comment.

Inline comments inside a function body should be rarer. If you reach for one, first ask whether a better name, a small helper, or an `assert` would express the same thing without prose.

## When editing existing code

- If you change code that a comment described, update or delete the comment in the same edit. A stale comment is worse than no comment.
- Don't leave `// removed X` or `// was: ...` breadcrumbs. The git history is the record of what changed.
- Don't add a comment to explain a change you just made ("Changed to use Y because..."). That explanation goes in the commit message.

## Quick self-check before keeping a comment

Ask, in order:

1. Does the code already say this? → delete.
2. Would a better name remove the need? → rename instead.
3. Does it reference the current task/prompt/PR rather than a durable reason? → rewrite around the durable reason, or delete.
4. Is the "why" still non-obvious to a reader who doesn't know the history? → keep, as tight as possible.

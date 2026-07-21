---
name: comments
description: Conventions for writing source code comments. Load when adding or editing comments in code, reviewing a diff for comment quality, or deciding whether a comment belongs at all. Covers when a comment earns its place, the WHY-not-WHAT rule, lifting rationale to general principles rather than concrete examples (never reciting the reproduction of a fixed bug), banning prompt/task references, and the tone and length to aim for.
---

# Comments

Default to writing no comment. A comment is only worth keeping if removing it would leave a future reader genuinely confused or at risk of breaking something. When one does earn its place, keep it concise and focused on the durable *why*.

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

## Lift the rationale to a principle, not a concrete example

A comment that justifies code by pointing to a specific caller, input, platform version, or incident reads as narration of how the code was discovered. Rewrite it as the underlying rule the code enforces — the principle outlives the example.

**Never illustrate a comment with a concrete example of the issue the code fixes.** Do not spell out the specific input, sequence of calls, value, or scenario that triggered the bug ("crashes when the list has exactly one element", "returns garbage if the path ends in a slash"). The reproduction is an artifact of how the defect was found, not a durable reason the code must stay this way, and it goes stale the moment the trigger changes. State the invariant or contract the code guarantees instead; a reader who understands the rule needs no worked example to believe it.

The test: if the cited example were removed, replaced, or fixed upstream, would the comment still describe why the code must stay this way? If not, raise the altitude until it does.

Bad (anchored to a concrete instance):
```cpp
// The FooBar API sometimes returns an empty array for users with no
// orders, so we have to guard against that here.
if (items.empty()) return;

// On iOS 13 the keyboard notification fires twice in a row.
if (Now() - last_event < kDebounce) return;

// Crashes when the input is exactly "a/b/" because the trailing
// slash makes the split produce an empty final segment.
if (segment.empty()) continue;
```

Good (general principle):
```cpp
// Empty input is a valid state, not an error: callers may invoke
// this before any items have been registered.
if (items.empty()) return;

// Coalesce duplicate notifications: the platform may deliver the
// same event more than once within a short window.
if (Now() - last_event < kDebounce) return;

// A trailing separator yields an empty trailing segment, which is
// not a path component.
if (segment.empty()) continue;
```

The good versions still hold if FooBar's API changes or iOS 13 disappears. The bad versions become misleading the moment the example moves on.

This applies to every layer:
- **Don't name the bug, name the invariant** the bug exposed.
- **Don't recite the reproduction** (the input, count, or sequence that triggered the failure), state the property the code now guarantees for *all* inputs.
- **Don't name the caller**, describe the contract the function offers any caller.
- **Don't name the platform version**, describe the class of platforms or behaviors that need the workaround.
- **Don't name the test that caught it**, describe the property under test.

The one place a concrete reference is appropriate is when it points at an *external* tracker the reader genuinely needs to consult (e.g. `// Workaround for LLVM bug 12345`) — there the citation is the principle, because the foreign system is the load-bearing fact.

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
4. Does it cite a concrete example (caller, bug, platform version) or recite the reproduction of the issue it fixes instead of the underlying principle? → raise the altitude.
5. Is the "why" still non-obvious to a reader who doesn't know the history? → keep, as tight as possible.

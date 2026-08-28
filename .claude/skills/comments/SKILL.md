---
name: comments
description: Conventions for writing source code comments. Load when adding or editing comments, reviewing a diff for comment quality, or deciding whether a comment belongs at all. Covers when a comment earns its place, WHY-not-WHAT, raising rationale to a principle instead of reciting the bug reproduction, banning prompt/task references, and strict brevity and declarative tone.
---

# Comments

Default to no comment. A comment earns its place only if removing it would leave a future reader confused or at risk of breaking something. When one does, spend the fewest words that carry the durable *why*.

## The bar

Comment only what the code cannot say:

- A **hidden constraint** the compiler won't enforce (ordering, a lock that must be held, an ABI boundary).
- A **subtle invariant** a careful reader might miss.
- A **workaround** for a bug or quirk in another system — name the system and the symptom.
- **Surprising behavior** — a branch that looks dead but isn't, a value chosen for a non-obvious reason, an early return that prevents a later footgun.
- A **reference** that saves a long hunt — spec section, RFC, bug ID, paper.

Otherwise delete it. Self-explanatory code with good names is the goal.

## WHY, not WHAT

Never describe what the code does. Explain why it has to be that way. If the why is obvious from context, write nothing.

Bad:
```cpp
// Increment the counter
++count;
```

Good:
```cpp
// DWARF 5 requires the abbrev offset to be section-relative, not
// compile-unit-relative; older readers tolerate either.
WriteSectionRelative(AbbrevOffset);
```

## Raise the altitude

Justifying code with a specific caller, input, platform version, or incident narrates how the code was discovered. Write the rule the code enforces instead; the principle outlives the example.

**Never illustrate a comment with the reproduction of the bug it fixes** — not the input, the sequence, the count, or the scenario. The repro is an artifact of how the defect was found and goes stale the moment the trigger changes.

Test: if the cited example were fixed upstream or disappeared, would the comment still explain why the code must stay? If not, raise the altitude.

Bad:
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

Good:
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

At every layer: the invariant, not the bug; the property guaranteed for all inputs, not the repro; the contract offered any caller, not the caller; the class of behaviors needing the workaround, not the platform version; the property under test, not the test.

## Do not anchor to the current task

A comment lives for years; the prompt, ticket, PR, or conversation does not. Banned:

- "Added to handle the case from <ticket>"
- "Used by <caller>" / "Called from <file>"
- "Fix for the regression introduced in <commit>"
- "Per the user's request" / "As discussed"
- "TODO: revisit after <task>"

Tickets and commits belong in the commit message or PR description.

One exception, covering this rule and the one above: a workaround may cite an *external* tracker (`// Workaround for LLVM bug 12345`). There the foreign system is the load-bearing fact.

## Tone and length

Brevity ranks second only to correctness. If a word can go without losing meaning, it goes.

- **One line if one line suffices.** Two is already unusual.
- **No filler**: "note that", "basically", "in order to", "it is worth mentioning", "for clarity".
- **No hedging.** "This may possibly need" → state the constraint or delete.
- **Plain prose**, complete sentences. No banners, ASCII art, or `// ===== SECTION =====`.
- **No marketing** ("cleanly handles", "robust", "elegant solution").
- **No apologies or narration** ("we have to do this ugly thing because...").
- **Present tense, declarative, no first person.** "The buffer is reused across calls", not "We reuse the buffer".

Wordy:
```cpp
// It is worth noting here that, in order to keep the cache consistent,
// we basically need to make sure that this map is cleared out before
// we go ahead and reload the modules from disk again.
ClearCache();
```

Tight:
```cpp
// The cache outlives the modules it indexes; reloading invalidates it.
ClearCache();
```

Multi-paragraph comments are rare and belong at the top of a function or class, documenting a non-obvious contract — never scattered through a body.

## Doc comments vs. inline comments

Doc comments (`///`, docstrings, JSDoc) on public API document the contract: what callers must guarantee, what they get back, what can go wrong. Same WHY-over-WHAT rule, but restating the signature is allowed where it clarifies semantics (units, ownership, nullability, lifetime). If the name and types already say it, skip the doc comment.

Inline comments are rarer still. Before writing one, ask whether a better name, a small helper, or an `assert` says it without prose.

## When editing existing code

- Changed code a comment described? Update or delete the comment in the same edit. A stale comment is worse than none.
- No `// removed X` or `// was: ...` breadcrumbs. Git history is the record.
- No comment explaining a change you just made. That goes in the commit message.

## Self-check

1. Does the code already say this? → delete.
2. Would a better name remove the need? → rename.
3. Does it reference the current task, prompt, or PR? → rewrite around the durable reason, or delete.
4. Does it cite a concrete example or repro instead of the principle? → raise the altitude.
5. Still non-obvious to a reader who doesn't know the history? → keep, as tight as possible.
6. Can any word be cut? → cut it, and repeat.

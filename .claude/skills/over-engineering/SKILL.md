---
name: over-engineering
description: Catches complexity that doesn't pay for itself — speculative abstraction, single-implementation layers, parameters nobody varies, defensive code for impossible states, machinery built for scale that doesn't exist. Load before writing new code or finalizing a plan, when reviewing a diff for over-engineering, or when a change grew larger than the problem it solves.
---

# Over-engineering

Every construct costs: something to read, to keep true, to change. Complexity is
paid for by a need that exists **today**, in this tree, with a caller you can name.
Speculation is not a need.

The default answer to "should I add this?" is no. The default fix when you find one
is deletion, not rearrangement.

## The test

For each construct a change introduces:

1. **Who needs it now?** Name the caller, the input, the bug. "Someone might" is not an answer.
2. **What breaks if it's deleted?** If the answer is "nothing until a hypothetical future", delete it.
3. **Is the machinery smaller than the problem?** Forty lines of framework for a six-line job is a loss, however elegant the framework.

Failing one is enough.

## Patterns

### Speculative generality

An abstraction whose second user does not exist. Templates, type parameters, and
`std::function` hooks added so the code "could" work with something else.

Test: name the second caller today. Can't → write the concrete thing. Generalizing
later is cheap; the abstraction is right there in front of you when the second case
arrives, and it will fit the two real cases better than the guess.

### A layer with one implementation

A base class with one subclass, an interface with one conformer, a wrapper that
forwards, a factory returning one type.

```cpp
class Formatter {
public:
  virtual ~Formatter() = default;
  virtual std::string Format(const Value &V) = 0;
};
class DefaultFormatter : public Formatter { ... };
```

Ship `DefaultFormatter` alone. Introduce the base when the second formatter lands.

### A parameter nobody varies

An argument, template parameter, setting, or `#define` that has the same value at
every call site.

```cpp
// Every caller passes true.
void Load(Module &M, bool VerifyChecksum);
```

Drop it and make the behavior unconditional. A `bool` parameter that switches
between two bodies is two functions wearing a trenchcoat — split it and name each
half.

### A knob instead of a decision

Making something configurable to avoid choosing. Each option multiplies the states
that must work, and users now have to make the call you dodged. Pick the right
behavior; add the setting when someone asks with a reason.

### Defensive code for impossible states

Null checks on references, error paths for errors the API cannot return,
re-validating an invariant the caller already guarantees. Dead code that looks
alive: a reader can't tell it never runs, so they maintain it forever.

Use `assert` for what must be true, error handling for what can actually happen.

### State that could be recomputed

A cache, a copy, or a member that trades one problem for a harder one —
invalidation. Worth it only when the cost it removes was measured. Recompute until
the profile says otherwise.

### Machinery for scale that doesn't exist

A thread for work measured in microseconds, a pool for two objects, an index for a
list of four, a plugin registry for two built-ins. Cost of coordination beats the
work being coordinated.

### Ceremony

A builder for a two-field struct. A "Manager" or "Helper" class holding no state and
wrapping one function. A helper extracted after one use and named for where it was
cut from. Three inline lines can beat three lines behind a name.

### Deduplication of things that only look alike

Two similar bodies merged, then a flag added when they diverge, then another. Wait
for the third occurrence, and merge only what is the same *reason*, not the same
shape.

### Scope creep

The change is bigger than the request: a refactor smuggled into a bug fix, a
rename riding along, an adjacent cleanup. Land it separately or not at all — a
reviewer can't tell which lines are the fix.

## Tells

`Manager`, `Helper`, `Handler`, `Base`, `Impl`, `Wrapper` in a new name. `virtual`
with one override. A parameter defaulted at every call site. A comment saying "for
now" or "in case we need". An interface added in the same commit as its only
implementation. A plan step justified by a requirement nobody stated.

## Not over-engineering

Simplicity is fewer moving parts, not fewer characters. Do not "simplify" into:

- Clever one-liners, dense expressions, or one-letter names.
- Removing error handling for errors that actually occur.
- Dropping edge cases that correctness requires.
- Fewer tests. Test count is not complexity.
- Inlining a helper that had two real callers.

An abstraction with two live callers today is not speculative. Named constants,
early returns, and structure that serves the reader are not ceremony.

## Acting on it

In your own change, delete before sending. In review, cite `file:line`, name the
pattern, and propose the specific deletion — "drop the base class, keep
`DefaultFormatter`" — not "consider simplifying". Say what capability is lost, if
any; usually none.

Simplification that changes no behavior goes in its own commit, tagged NFC, separate
from the fix.

## Self-check

1. Can this be deleted with no behavior change? → delete it.
2. Does it exist for a caller that doesn't exist? → delete it.
3. Is a level of indirection carrying exactly one thing? → collapse it.
4. Is there a branch that can't be taken? → assert or remove.
5. Did the change outgrow the request? → split it.
6. Would the simplest thing that could work have worked? → say so, and do that.

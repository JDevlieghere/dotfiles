# Reviewer personas

The roster the orchestrator selects from. Each reviewer owns exactly one axis;
issues outside it belong to another reviewer. Every reviewer also follows
`reviewer-rules.md` (shared rules + output contract) — this file only describes
*what each axis owns*.

When the **LLVM C++ layer** is active (the orchestrator says so in your prompt),
read the listed `llvm-development` reference files **before** reviewing, and apply
the extra LLVM red flags noted for your axis. When it is not active, ignore the
LLVM notes entirely — they do not apply to other languages.

---

## Always-on personas

Spawned on every review.

### correctness

**Owns:** logic bugs, wrong/edge-case behavior, state and ordering bugs, error and
exception handling, resource/lifetime/dangling references, null and uninitialized
use, off-by-one, inverted conditions, ownership transfer, basic thread-safety
hazards, and **non-determinism in user-visible output**.

**Does NOT own:** style, naming, API shape (unless the shape causes a bug), missing
tests.

**Categories:** `[logic]` `[error]` `[lifetime]` `[null]` `[uninit]` `[safety]`
`[determinism]`

**LLVM refs:** `errors.md` (Error/Expected, cantFail/consumeError, casts, lifetime
hazards, thread safety), `lldb.md` (ConstString pool leak, Status-vs-Error, fatal
errors, logging). **Extra LLVM red flags:** `formatv`/`LLDB_LOG`/`LLVM_DEBUG` format
indices (`{0}`,`{1}`,…) must match the argument count — check every new format
string; iteration over `DenseMap`/`DenseSet` that feeds diagnostics, file output,
or hashes is non-deterministic (wants `MapVector`/`SetVector`/a sort).

### design

**Owns:** architecture and the public surface — parameter and return types,
container choice, layering, coupling, extensibility, over- and under-abstraction,
dead code, and complexity the change adds or could have deleted.

**Does NOT own:** mechanical style, correctness bugs, missing tests, claim
verification.

**Categories:** `[design]` `[api]` `[type]` `[container]` `[layering]` `[deadcode]`
`[complexity]`

**LLVM refs:** `adt.md` (string/container type choice and parameter conventions),
`lldb.md` (SB-API stability, plugin boundaries, extensibility red flags),
`style.md` (header-layering red flags). **Extra LLVM red flags:** a heavy
`#include` or a non-trivial inline method added to a widely-used public header
(rebuild blast radius); an unexplained new `friend`; closed enums with no room to
grow; a base-class virtual implemented by only one subclass; wrong string/container
type at an API boundary (`const char *` where `StringRef` fits, `std::vector` where
`ArrayRef`/`SmallVectorImpl&` fits).

### tests-and-docs

**Owns:** test coverage for new code paths, test quality (exercises behavior, not
just links the symbol), a regression test that fails without the fix, doc/comment
accuracy for changed behavior, and API documentation on new public surface.

**Does NOT own:** code correctness, API shape, adversarial claim checking.

**Categories:** `[test]` `[doc]` `[comment]`

**LLVM refs:** `lldb.md` (Testing — unit/shell/API test homes; a bug fix needs a
test that fails without the fix), `style.md` (Comments and Doxygen on new public
APIs: `///`, `\brief`, `\param`, `\returns`). **Extra LLVM red flags:** changed
behavior whose nearby comment/docstring was not updated; a tutorial or `.md` doc
whose documented command/API name no longer matches what the code exposes.

---

## Conditional personas

Spawn only when the diff warrants the axis (orchestrator judgment).

### conventions

Mechanical conventions. **Select** for any code diff with a real style surface;
skip for pure prose/config diffs.

**Owns:** naming, formatting, include order, line length, indentation, brace rules,
comment markers, and other tool-checkable mechanics.

**Does NOT own:** semantic bugs, design, missing tests.

**Method:** run the project's tools first and hand-flag only what they cannot see.
- *LLVM layer:* read `naming.md` and `style.md` (and `lldb.md`'s naming delta if
  LLDB). Prefer `clang-format --dry-run --Werror` and `clang-tidy -p <build>` on
  changed files; if no build dir, still run `clang-format --dry-run`. Do not invent
  pseudo-rules.
- *Other languages:* apply the project's documented standards (root and nested
  `CLAUDE.md`/`AGENTS.md`, `.editorconfig`, linter configs) and run whatever linter
  the repo ships. Flag a convention only when it is written down or the tool
  reports it.

**Categories:** `[naming]` `[format]` `[include]` `[comment]` `[lint]`

### security

**Select** when the diff touches auth, permission checks, public/untrusted input,
secrets, deserialization, file/path handling, command/SQL construction, or unsafe
memory operations.

**Owns:** injection, missing authorization, unsafe input handling, secret exposure,
unsafe buffer/pointer arithmetic, TOCTOU.
**Categories:** `[authz]` `[injection]` `[input]` `[secret]` `[memory-safety]`

### performance

**Select** when the diff touches hot loops, large data transforms, allocations on a
hot path, caching, async/concurrent work, or a data-structure choice in a perf-
sensitive area.

**Owns:** avoidable allocations/copies, wrong container or algorithm for the access
pattern, redundant work in a loop, N+1 patterns.
**Does NOT own:** micro-optimizations with no measured impact (those are nits at
most). A perf claim without a benchmark is a `question`.
**Categories:** `[alloc]` `[algo]` `[copy]` `[hotpath]`

### concurrency

**Select** when the diff adds or changes threads, locks, atomics, shared mutable
state, async callbacks, or ordering assumptions.

**Owns:** data races, missing/!excessive locking, deadlock/lock-ordering, atomicity
gaps, unsafe lazy init, assumptions about callback threads.
**Categories:** `[race]` `[lock]` `[atomic]` `[ordering]`

### api-and-abi

**Select** when the diff changes a public/exported surface — library headers,
exported symbols, serialized formats, protocol/event schemas, versioned routes.

**Owns:** backward-incompatible signature/behavior changes, missing versioning,
serialization compat, surface that leaks internals.
**LLVM refs:** `lldb.md` (SB-API stability). **Extra LLVM red flags:** new public
SB method without Doxygen; `lldb_private::` types leaked through an SB header;
adding a virtual to an SB/base class (vtable/ABI break); magic sentinel return
(`return UINT32_MAX;`) where `Expected<T>` or an out-param is clearer; an SB name
that diverges from the internal API for no reason.
**Categories:** `[abi]` `[compat]` `[api]` `[serialization]`

### adversarial

**Select** for a substantial change (>~50 changed executable lines) or any change
touching security, data mutation, process/resource lifecycle, or external
integrations.

**Owns:** stress-testing the author's claims and the unstated. Read the PR/intent
first and extract every claim ("fixes X", "NFC", "safe because Y"). For each, find
code that supports or contradicts it; unverifiable → `question`. Probe edges the
author didn't mention: empty/null/max input, unicode, concurrent access, error
paths, mid-iteration mutation, recursion into the same path, save/restore, and (for
LLVM/LLDB) out-of-tree plugins implementing the same interface. Check scope: does
the diff do more or less than the intent says? Verify every "NFC" by looking hard
for behavioral differences. Use `Read`/`gh`/`git` aggressively to verify.

End your output with a `## Unresolved questions (top 3)` section.
**Categories:** `[claim]` `[edge-case]` `[scope]` `[assumption]` `[recursion]`

### first-principles

**Select** for a non-trivial change with real design latitude (a new feature, hook,
plugin, or data-flow change). Skip for trivial/mechanical diffs (return
"Converged — trivial").

This reviewer stays **above the diff** and returns a design note, **not** line
findings.

**Method:**
1. **Understand the problem.** Read the intent and the most relevant existing code.
   Write a one-paragraph problem statement in your own words. If the problem isn't
   clear, that itself is the finding.
2. **Design your own solution before reading the diff in detail.** Sketch the
   shape: what would you add, where would it live, what's the public surface, what's
   the simplest thing that works? Would you push back on the framing?
3. **Now read the change's solution.** Compare axis by axis: public surface, where
   the logic lives, data flow, extensibility, blast radius, maintenance burden,
   test surface.
4. **Render a verdict:** `Converged` | `Diverged-PR-better` |
   `Diverged-alternative-better` | `Diverged-tradeoff`, with 2-5 sentences. If
   recommending a change, be concrete ("move X from the header to the .cpp and
   register through a factory").

**Return:** the verdict label, a one-line summary, and the output file path.

---

## Selection rules

1. Always spawn `correctness`, `design`, `tests-and-docs`.
2. For each conditional persona, read the diff and decide whether its domain is
   genuinely present — judgment, not extension matching. Don't spawn a reviewer
   just because one file matched a pattern.
3. Count only executable code lines toward size thresholds; instruction-prose and
   config diffs skip `adversarial` unless they describe security or data behavior.
4. Announce the team before spawning, with a one-line justification per conditional
   reviewer.

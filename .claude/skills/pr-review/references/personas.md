# Reviewer personas

The roster the orchestrator selects from, organized into two **waves**. Wave 1 is
the fast, high-signal pass whose merged output drives the *interim* report; Wave 2
adds completeness. Each reviewer owns one axis (some own a **merged** axis covering
a few related concerns — use the category tags from every area they own); issues
outside it belong to another reviewer. Every reviewer also follows
`reviewer-rules.md` (shared rules + output contract) — this file only describes
*what each axis owns*.

When the **LLVM C++ layer** is active (the orchestrator says so in your prompt),
read the listed `llvm-development` reference files **before** reviewing, and apply
the extra LLVM red flags noted for your axis. When it is not active, ignore the
LLVM notes entirely — they do not apply to other languages.

---

## Wave 1 — fast, high-signal (always spawned)

The three reviewers below run first, in parallel (**never more than 3 agents at
once**). They target the issues that decide whether the PR is worth more
investment: real bugs, false claims, and structural problems. Their findings drive
the interim report, so look hard and look fast.

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

### adversarial

The reviewer that stress-tests the change. Always runs — this is the highest-value
axis for deciding whether a PR is sound.

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

### design

**Merged axis: design + API/ABI.** Stays above the line-by-line and judges shape.

**Owns:** architecture and the public surface — parameter and return types,
container choice, layering, coupling, extensibility, over- and under-abstraction,
dead code, and complexity the change adds or could have deleted. **And, when the
change touches an exported/public/serialized surface** (library headers, exported
symbols, serialized formats, protocol/event schemas, versioned routes):
backward-incompatible signature/behavior changes, missing versioning,
serialization compat, and surface that leaks internals.

**Does NOT own:** mechanical style, correctness bugs, missing tests, claim
verification.

**Categories:** `[design]` `[api]` `[type]` `[container]` `[layering]` `[deadcode]`
`[complexity]` `[abi]` `[compat]` `[serialization]`

**LLVM refs:** `adt.md` (string/container type choice and parameter conventions),
`lldb.md` (SB-API stability, plugin boundaries, extensibility red flags),
`style.md` (header-layering red flags). **Extra LLVM red flags:** a heavy
`#include` or a non-trivial inline method added to a widely-used public header
(rebuild blast radius); an unexplained new `friend`; closed enums with no room to
grow; a base-class virtual implemented by only one subclass; wrong string/container
type at an API boundary (`const char *` where `StringRef` fits, `std::vector` where
`ArrayRef`/`SmallVectorImpl&` fits); a new public SB method without Doxygen;
`lldb_private::` types leaked through an SB header; adding a virtual to an SB/base
class (vtable/ABI break); a magic sentinel return (`return UINT32_MAX;`) where
`Expected<T>` or an out-param is clearer; an SB name that diverges from the internal
API for no reason.

---

## Wave 2 — completeness (spawned after the interim report)

These reviewers add coverage the fast pass intentionally skipped. **Never more than
3 agents at once** across the whole run, and Wave 2 starts only once the interim
report is rendered.

### tests-docs-conventions

**Merged axis: tests-and-docs + conventions.** Always spawned for any diff with a
real code or docs surface.

**Owns:** test coverage for new code paths, test quality (exercises behavior, not
just links the symbol), a regression test that fails without the fix, doc/comment
accuracy for changed behavior, and API documentation on new public surface. **And**
mechanical conventions: naming, formatting, include order, line length,
indentation, brace rules, comment markers, and other tool-checkable mechanics.

**Does NOT own:** code correctness, API/design shape, adversarial claim checking.

**Method (conventions half):** run the project's tools first and hand-flag only
what they cannot see; don't invent pseudo-rules.
- *LLVM layer:* prefer `clang-format --dry-run --Werror` and `clang-tidy -p <build>`
  on changed files; if no build dir, still run `clang-format --dry-run`.
- *Other languages:* run whatever linter the repo ships; flag a convention only when
  it is written down (root/nested `CLAUDE.md`/`AGENTS.md`, `.editorconfig`, linter
  configs) or the tool reports it.

**Categories:** `[test]` `[doc]` `[comment]` `[naming]` `[format]` `[include]`
`[lint]`

**LLVM refs:** `lldb.md` (Testing — unit/shell/API test homes; a bug fix needs a
test that fails without the fix), `style.md` (Comments and Doxygen on new public
APIs: `///`, `\brief`, `\param`, `\returns`), `naming.md`. **Extra LLVM red flags:**
changed behavior whose nearby comment/docstring was not updated; a tutorial or `.md`
doc whose documented command/API name no longer matches what the code exposes.

### runtime-risks

**Merged axis: security + performance + concurrency.** Conditional — spawn only
when the diff genuinely touches one of these domains. The orchestrator **names the
applicable sub-axes** in your prompt; review only those.

- **security** — select when the diff touches auth, permission checks,
  public/untrusted input, secrets, deserialization, file/path handling,
  command/SQL construction, or unsafe memory operations. *Owns:* injection, missing
  authorization, unsafe input handling, secret exposure, unsafe buffer/pointer
  arithmetic, TOCTOU.
- **performance** — select when the diff touches hot loops, large data transforms,
  allocations on a hot path, caching, async/concurrent work, or a data-structure
  choice in a perf-sensitive area. *Owns:* avoidable allocations/copies, wrong
  container or algorithm for the access pattern, redundant work in a loop, N+1
  patterns. Micro-optimizations with no measured impact are nits at most; a perf
  claim without a benchmark is a `question`.
- **concurrency** — select when the diff adds or changes threads, locks, atomics,
  shared mutable state, async callbacks, or ordering assumptions. *Owns:* data
  races, missing/excessive locking, deadlock/lock-ordering, atomicity gaps, unsafe
  lazy init, assumptions about callback threads.

**Categories:** `[authz]` `[injection]` `[input]` `[secret]` `[memory-safety]`
`[alloc]` `[algo]` `[copy]` `[hotpath]` `[race]` `[lock]` `[atomic]` `[ordering]`

---

## Selection rules

1. Always spawn the Wave-1 trio: `correctness`, `adversarial`, `design`.
2. Wave 2: spawn `tests-docs-conventions` for any diff with a real code or docs
   surface (skip only a trivial mechanical-only diff). Spawn `runtime-risks` only
   when its domain is genuinely present — judgment, not extension matching — and
   name the applicable sub-axes in its prompt.
3. Count only executable code lines toward size thresholds; pure prose/config diffs
   skip `runtime-risks` unless they describe security or data behavior.
4. **Never more than 3 reviewer/validator agents in flight at once.** The waves are
   sequential: do not start Wave 2 until Wave 1's interim report is rendered.
5. Announce the team before spawning, with a one-line justification per conditional
   reviewer.

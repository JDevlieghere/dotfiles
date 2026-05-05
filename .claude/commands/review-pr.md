# Review GitHub PR

Orchestrate a multi-agent review of a GitHub pull request against LLVM/LLDB coding standards and design best practices.

**Usage**: `/review-pr <PR number or URL>`

## Role

You are the **orchestrator**. You do not review the diff yourself. Your job is to fetch the PR, dispatch six specialist reviewers **in parallel** (one message with six `Agent` tool calls), then merge, dedupe, rank, and render their findings. Each specialist owns exactly one review axis. The main conversation never loads the reference material.

**Do NOT modify any files. Only read, analyze, and delegate.**

---

## Step 1: Fetch PR context

```
gh pr view $ARGUMENTS --json number,title,body,baseRefName,headRefName,author,files
gh pr diff $ARGUMENTS
```

Save the diff to `/tmp/review-<number>.diff` and the metadata to `/tmp/review-<number>.meta.json` so specialists can read them by path (keeps your context and theirs lean).

For a size overview, use:
```
gh pr view $ARGUMENTS --json files --jq '.files[] | "\(.additions + .deletions)\t\(.path)"' | sort -rn
```
(Do NOT use `gh pr diff --stat` — that flag does not exist.)

If the diff is huge (>~2000 changed lines total), also pass per-file diffs for the top ~10 files to each specialist and tell them to focus there.

---

## Step 2: Shared rules every specialist prompt must include

Copy this block verbatim into every Agent prompt (filling in the axis-specific parts):

```
HARD RULES
- Review ONLY your axis. Other issues are owned by other reviewers — ignore them.
- Only flag issues in changed/added lines. Do not flag pre-existing style in unchanged context.
- Golden Rule: match surrounding style. If the diff is consistent with the file around it, do not flag it.

SEVERITY — use EXACTLY these four labels, nothing else:
  error    Definite bug, broken API, will cause problems in production.
  warning  Real violation or bad pattern that should be fixed before merge.
  nit      Minor suggestion, cosmetic, debatable preference.
  question Claim or assumption you could not verify from the code alone.
(Do NOT use "critical", "blocker", "high", "medium", "low" — they don't exist.)

FORMAT — every finding is a single line:
  **path/to/file.cpp:LINE** [category] (severity) Description.
- Use the NEW-file line number from the diff (the `+` side), not an approximation.
- Never use `~` prefix. If you truly can't pin a line, name the function/symbol instead of guessing.
- One finding per line. No multi-paragraph commentary.

OUTPUT
- Write full findings to the file path you are given.
- End with a single line: `Self-assessment: <one sentence on coverage confidence>`.
- Return to the caller ONLY: count by severity, self-assessment line, file path. Nothing else.
```

---

## Step 3: Dispatch the six specialists in parallel

Send one message with six `Agent` tool calls (subagent_type: `general-purpose`). The diff file path, metadata file path, and output file path go into each prompt.

### Agent 1 — Style & formatting

**Owns**: mechanical style rules only. Naming conventions, include order, 80 cols, indentation, brace rules, `auto *`/`auto &`, comment markers, error-message casing.

**Does NOT own**: `formatv` index mismatches (correctness owns those), heavy-include decisions (architecture owns those), missing Doxygen on new public APIs (tests/docs owns that). Don't manufacture pseudo-rules (e.g., `return {}` vs `return T()` is not a rule; `eg` vs `e.g.` is not a rule).

**Reference** (paste into prompt):

- LLVM: types `CamelCase`; variables/params `CamelCase` (upper-first); functions `camelBack`; enumerators `CamelCase` with abbreviated-enum prefix if unscoped. No Hungarian.
- **LLDB differs**: variables `snake_case`; functions/methods `UpperCamelCase`; prefixes `s_` (static) / `g_` (global) / `m_` (member). Function-local statics use `s_`, not `g_`.
- Include order: main header → local → LLVM project → system; blank line between groups; sorted lexicographically.
- Header guards: `LLVM_ANALYSIS_UTILS_LOCAL_H`.
- 80 cols. 2-space indent. No tabs. No trailing whitespace.
- No indentation inside `namespace {...}`; out-of-line defs in `.cpp` use qualified names, don't reopen the namespace.
- `//` normal comments. `/* */` only for inline-param docs like `/*Prefix=*/nullptr`. Comment-out code with `#if 0`/`#endif`.
- Error/warning messages: lowercase first letter, no trailing period.
- Control flow: prefer early `return`/`continue`; no `else` after `return`/`break`/`continue`; cache `end()`; preincrement; range-based `for`; no `default:` in fully-covered enum switches.
- `auto` only when it makes code more readable. Always `auto *` for pointers, `auto &` for references.
- Braces: omit on simple single-statement bodies; if any branch braces, all do.
- C++17 only. No `dynamic_cast`. No C++ exceptions. No `<iostream>`. No `std::endl` (use `'\n'`). Prefer C++-style casts. `struct` if all members public else `class`. No braced init lists for constructor calls. No unnecessary `inline`. `llvm::sort`. `[[maybe_unused]]` for assert-only vars. Virtual anchor for classes with vtables in headers.
- Asserts: `assert(cond && "message")`. `llvm_unreachable("msg")` over `assert(false && "msg")`.
- Anonymous namespaces: keep small; prefer `static` for file-local; never in headers.

**Categories**: `[naming]` `[include]` `[format]` `[comment]` `[auto]` `[braces]` `[assert]`

### Agent 2 — Architecture & API design

**Owns**: public surface (SB/Target/Utility APIs), parameter and return types (StringRef/ArrayRef/SmallVectorImpl), container choice, layering (heavy includes in headers, forward-declare opportunities, circular dep risk), backward compat / SB-ABI stability, extensibility points, over-/under-abstraction, vtable widening on base classes.

**Does NOT own**: style. Correctness bugs. Missing tests. Claim verification.

**Reference**:

- Strings: `StringRef` (pass by value, preferred param); `Twine` (`const Twine &`, never store); `SmallString<N>` (stack scratch); `std::string` (ownership); avoid `const char *`.
- Containers: `SmallVector<T,N>` default (pass as `SmallVectorImpl<T>&`); `ArrayRef<T>` read-only param; `DenseMap`/`DenseSet` default (never `std::unordered_*`); `StringMap<V>` for string keys; `SetVector`/`MapVector` when deterministic iteration matters; `SmallPtrSet<T*,N>` for ptr sets; `function_ref<Sig>` for non-owning callbacks.
- Layering red flags: `#include` of a heavy header into a widely-included public header; an inline non-trivial method in a public header that forces rebuilds; a new friend declaration whose reason isn't present in this PR.
- SB/public-ABI red flags: new method without Doxygen; leaks `lldb_private` types through public headers; magic integer sentinel returns; non-const-ref params that could be const; names that diverge from the underlying internal API.
- Extensibility: closed enums without room to grow; hardcoded limits; base-class virtuals that only one subclass ever implements (should live on the subclass).

**Categories**: `[design]` `[type]` `[container]` `[api]` `[layering]` `[compat]` `[abi]`

### Agent 3 — Correctness & safety

**Owns**: logic bugs. Cast patterns. Error/Expected handling. Lifetime/dangling refs. Thread safety. Determinism in user-visible output. Debug macro side effects. **`formatv` / `LLDB_LOG` / `LLVM_DEBUG` index-vs-arg mismatches** (e.g. `{1}` with one arg). Null-pointer hazards. Uninitialized variables. Inverted boolean logic. Off-by-one. Raw `new` + ownership transfer.

**Does NOT own**: style opinions. Naming. API shape (unless the shape causes a bug).

**Reference**:

- LLVM casting: `isa<T>`, `cast<T>`, `dyn_cast<T>` (`if (auto *X = dyn_cast<T>(val))`); `dyn_cast_if_present` accepts null; never `isa` then `cast` (use `dyn_cast`); never `dynamic_cast`.
- No C++ exceptions: use `Error`/`Expected<T>`. `Error` must be checked (`true`=error); `Expected` `true`=success.
- `cantFail()` only if provably infallible; undefined in release otherwise — flag unjustified uses.
- `consumeError()` to explicitly discard. Never leave unchecked.
- Library code must not `exit` on recoverable errors.
- LLDB: prefer `Error`/`Expected` over `Status`. Avoid `report_fatal_error`/`abort`.
- LLDB-specific: `ConstString` comparisons must be against an existing `ConstString`, never a freshly-built temporary (leaks the string pool).
- Lifetimes: no dangling `StringRef`/`ArrayRef`/`Twine` past source; no returning ref to local; no storing `Twine`.
- Thread safety: shared mutable state without a mutex; function-local `static` counters without `std::atomic`.
- Determinism: iteration over `DenseMap`/`DenseSet` feeding diagnostics, files, or hashes.
- Debug macros must have no side effects.
- **`formatv` / `LLDB_LOG` format indices `{0}`, `{1}`, … MUST match the argument count. Check every new format string.**

**Categories**: `[cast]` `[error]` `[safety]` `[thread]` `[lifetime]` `[determinism]` `[format-arg]` `[null]` `[uninit]` `[logic]`

### Agent 4 — Adversarial assumptions

**Owns**: stress-testing the PR description and author's claims. Unstated edge cases. Description-vs-code mismatches. Scope drift.

**Does NOT own**: style. Architecture opinions. Missing tests (that's tests/docs).

**Method** (paste into prompt):

- Read the PR body first. Extract every factual claim ("fixes X", "improves Y", "safe because Z", "needed for W", "NFC").
- For each claim, find code that supports or contradicts it. If unverifiable, it's a `question`.
- Probe edges the author didn't mention: empty input, null, max size, unicode, concurrent access, error paths, mid-iteration mutation, recursion into the same code path, session save/restore, out-of-tree plugins that implement the same interface.
- Check scope: does the diff do more or less than the description says? Any added friend declarations or new includes that imply work not mentioned?
- Perf or correctness claims without a benchmark/test → `question`.
- "NFC" (non-functional change) — look hard for behavioral differences.

**You are encouraged to use `Read`, `Bash` (`gh api`, `grep` over `gh api`), and `WebFetch` aggressively to verify claims against the actual repo.** The diff alone is rarely enough. Budget ~5–8 minutes of tool calls for a medium PR.

End your output with a `## Unresolved questions (top 3)` section listing the most important claims you couldn't verify.

**Categories**: `[assumption]` `[justification]` `[edge-case]` `[claim]` `[scope]` `[recursion]`

### Agent 5 — Tests & documentation

**Owns**: test coverage for new code paths. Test quality (exercises behavior vs just links symbol). Regression tests for bug fixes. Doxygen on new public APIs. Updated comments/docstrings on changed behavior. PR description accuracy for the README/tutorial angle (docs changes). LDBG/LLVM_DEBUG placement. `formatv` vs printf preference (NOT index correctness — that's correctness's lane).

**Does NOT own**: code correctness. API shape. Adversarial claim checking (though "description doesn't match tests" overlaps — mention it concisely if you find it).

**Reference**:

- Every new code path should have a test. Missing test = `warning` (or `error` for non-trivial logic).
- Test that exercises the code in question, not just imports the symbol.
- Bug-fix tests should fail without the fix.
- New public APIs (SB, Target, public Utility headers) need Doxygen: `///`, `\brief`, `\param`, `\returns`.
- Changed behavior should update nearby comments/docstrings.
- Tutorials and `.md` docs: does the documented command/API name match what the CLI actually exposes?
- `LDBG() << "msg"` or `LLVM_DEBUG(dbgs() << "msg\n")` for debug output. `DEBUG_TYPE` after all includes. No side effects in debug macros.
- `formatv("{0}", val)` preferred over printf-style in new code.
- `zip_equal`, `enumerate`, `make_early_inc_range` — flag hand-rolled equivalents.

**Categories**: `[test]` `[doc]` `[comment]` `[pr-desc]` `[docs-vs-code]`

### Agent 6 — First-principles alternative

**Owns**: designing a solution to the problem the PR is trying to solve, *before* looking at how the PR solved it, then comparing. The output is not line-level findings — it's a short design document and a recommendation.

**Does NOT own**: nitpicks on the PR's code. Style. Correctness bugs. This agent stays above the diff.

**Method** (paste into prompt):

1. **Understand the problem.** Read the PR body and linked issues/bugs (`gh issue view`, `gh pr view --comments`). Read the most relevant existing code — the files the PR touches, their nearest neighbors, and any existing extension points that the PR is working around or building upon. Write a one-paragraph problem statement in your own words. If the problem isn't clear from the PR body, that itself is a finding.
2. **Design your own solution** *before* reading the PR diff in detail. Sketch the shape: what class/function/hook would you add? Where would it live? What's the public surface? What's the simplest thing that could work? Would you solve it at all, or push back on the framing? Write this as a "Proposed approach" section with 3–8 bullets.
3. **Now read the PR's solution.** Compare axis by axis: public API shape, where the hook lives, data flow, extensibility, blast radius, maintenance burden, test surface.
4. **Render the verdict** as one of:
   - **Converged** — PR approach matches yours (or is a superset). Say so plainly, note the minor differences, stop.
   - **Diverged, PR is better** — your alternative had a flaw the PR's design avoids. Explain what you got wrong and why the PR is the right call.
   - **Diverged, alternative is better** — give a concrete recommendation to redo the PR. Explain what you'd change.
   - **Diverged, tradeoff** — both are defensible. Produce a pros/cons table and a recommendation (which to take, or "either is fine").

**Budget**: this agent can read more code than the others. Use `Read`, `gh api`, and `gh issue view` liberally — ~5–10 minutes of tool calls for a non-trivial PR. If the PR is trivial (typo, one-line fix, mechanical refactor), return a one-line "Converged — trivial" and stop.

**Output format** — write to the given path:

```
# First-principles review — PR #<number>

## Problem statement (in my own words)
<one paragraph>

## Proposed approach (designed before reading the PR)
- Bullet 1
- Bullet 2
...

## PR's approach
<one paragraph summarizing what the PR actually does>

## Comparison
| Axis | My design | PR's design | Which is better |
|------|-----------|-------------|-----------------|
| Public API shape | ... | ... | ... |
| Hook location | ... | ... | ... |
| Extensibility | ... | ... | ... |
| ... | ... | ... | ... |

## Verdict
**<Converged | Diverged-PR-better | Diverged-alternative-better | Diverged-tradeoff>**

<2–5 sentences justifying the verdict. If recommending changes, be concrete: "I'd move X from Target.h to Target.cpp and make the registration go through a factory function."

Self-assessment: <one line on how confident you are>
```

Return to the caller ONLY: the verdict label, a one-line summary, and the output file path.

**Categories (used only if Comparison table rows become explicit findings later)**: `[alt-design]` `[alt-api]` `[alt-scope]`

---

## Step 4: Merge, dedupe, rank

Read all six output files. Agent 6's output is **not** folded into the findings list — it's rendered separately in Step 5. The other five specialists produce findings that you dedupe and rank as follows:

1. **Dedupe**. Two findings collide when they share the same `file:line` within ±3 lines OR reference the same symbol name AND describe the same root cause. Keep the highest-severity version, combine the category tags (`[layering][api]`), and note which specialists flagged it.
2. **Retire noise**. Drop nits that are already covered by a warning/error finding on the same line. Drop pseudo-rule flags (if any specialist manufactured one).
3. **Normalize severity**. If a specialist used `critical`/`blocker`/`high`/`medium`/`low`, re-map: critical/blocker → error; high → error or warning based on description; medium → warning; low → nit.
4. **Rank**. Compute a "Top issues" list: the 3–7 findings most likely to matter (bugs > broken ABI > missing test for main path > layering > nits). Prefer things that block merge.

---

## Step 5: Render the final report

```
# Review: <PR title> (#<number>)

**Summary**: <one sentence — what the PR claims to do, grounded in the diff>

**Description honesty**: <one to two sentences — does the PR body match the diff? any unmentioned side-effects, extra friendships, heavy includes, scope expansion?>

## Top issues
1. **path:line** [cats] (severity) — one-sentence issue + why it matters.
2. …
(3 to 7 items, most blocking first.)

## First-principles alternative
<Paste Agent 6's report here — the Problem statement, Proposed approach, Comparison table, and Verdict. If the verdict is "Converged — trivial" on a tiny PR, collapse this to a single line.>

## Findings by file
<grouped by file, then by line; one line per finding in the canonical format>

## Severity summary
| Severity | Count |
|----------|-------|
| error    | N     |
| warning  | N     |
| nit      | N     |
| question | N     |

## Actionable changes
- Fix A — file:line.
- Fix B — file:line.
(Bulleted list. Mechanical fixes together, design/arch changes together.)

## Top 3 unresolved questions
1. …
2. …
3. …

## Overall assessment
`approve` / `request changes` / `comment` — one sentence of reasoning. If Agent 6's verdict is "Diverged, alternative is better," that should dominate the recommendation (`request changes` with the alternative as the ask).
```

If any specialist self-assessment reported low coverage confidence, add a one-line caveat at the very top of the report.

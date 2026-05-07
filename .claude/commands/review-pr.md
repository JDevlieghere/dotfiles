# Review GitHub PR

Orchestrate a multi-agent review of a GitHub pull request against LLVM/LLDB coding standards and design best practices.

**Usage**: `/review-pr <PR number or URL>`

## Role

You are the **orchestrator**. You do not review the diff yourself. Your job is to fetch the PR, dispatch six specialist reviewers **in parallel** (one message with six `Agent` tool calls), then merge, dedupe, rank, and render their findings. Each specialist owns exactly one review axis. The main conversation never loads the reference material.

**Do NOT modify any files. Only read, analyze, and delegate.**

---

## Step 1: Fetch PR context and materialize the PR branch

Line numbers in reviews have historically drifted because specialists read files from the user's current checkout (which is `origin/main`, not the PR). Fix it at the source: check out the PR into a disposable worktree, and require every specialist to read files from there.

```bash
NUM=$ARGUMENTS   # strip any URL prefix if present
REPO=$(gh pr view "$NUM" --json headRepository,headRepositoryOwner --jq '.headRepositoryOwner.login + "/" + .headRepository.name' 2>/dev/null)
WT=/tmp/review-$NUM-worktree
rm -rf "$WT"
gh pr checkout "$NUM" --repo "$REPO" --detach 2>/dev/null || true  # ensures the ref is fetched
HEAD_SHA=$(gh pr view "$NUM" --repo "$REPO" --json headRefOid --jq .headRefOid)
BASE_SHA=$(gh pr view "$NUM" --repo "$REPO" --json baseRefOid --jq .baseRefOid)
git worktree add --detach "$WT" "$HEAD_SHA"

gh pr view "$NUM" --repo "$REPO" --json number,title,body,baseRefName,headRefName,author,files > /tmp/review-$NUM.meta.json
gh pr diff "$NUM" --repo "$REPO" > /tmp/review-$NUM.diff
gh pr view "$NUM" --json files --jq '.files[] | "\(.additions + .deletions)\t\(.path)"' | sort -rn > /tmp/review-$NUM.sizes
```

Pass to every specialist: `$WT` (worktree root, for `Read`), `/tmp/review-$NUM.diff` (diff with hunk headers), `/tmp/review-$NUM.meta.json`, `$BASE_SHA` (so they can run `git -C $WT diff $BASE_SHA -- <path>` for per-file diffs).

(Do NOT use `gh pr diff --stat` — that flag does not exist. Use the `sizes` file above.)

Clean up the worktree at the end of the run: `git worktree remove --force "$WT"`.

If the diff is huge (>~2000 changed lines total), tell each specialist to focus on the top ~10 files by size.

---

## Step 2: Shared rules every specialist prompt must include

Copy this block verbatim into every Agent prompt (filling in the axis-specific parts):

```
HARD RULES
- Review ONLY your axis. Other issues are owned by other reviewers — ignore them.
- Only flag issues in changed/added lines. Do not flag pre-existing style in unchanged context.
- Golden Rule: match surrounding style. If the diff is consistent with the file around it, do not flag it.

LINE NUMBERS — non-negotiable:
- The PR branch is checked out at the worktree path you are given. Read files ONLY from under that path; never from the user's main checkout.
- Every line number you cite MUST be one you have actually `Read` from the worktree. Before you emit a finding, re-read a small window around the line to confirm the content matches your claim. If you did not verify it, do not cite a number — name the function/symbol instead.
- Do not use `~`, do not approximate, do not cite a line past the end of the file. A wrong line number is worse than no line number.

SEVERITY — use EXACTLY these four labels, nothing else:
  error    Definite bug, broken API, will cause problems in production.
  warning  Real violation or bad pattern that should be fixed before merge.
  nit      Minor suggestion, cosmetic, debatable preference.
  question Claim or assumption you could not verify from the code alone.
(Do NOT use "critical", "blocker", "high", "medium", "low" — they don't exist.)

FORMAT — every finding is a single line:
  **path/to/file.cpp:LINE** [category] (severity) What's wrong + why it matters + concrete fix, in one sentence.
- "What's wrong" alone is not enough. A reader looking only at this line must know what action to take.
- Bad:  **foo.cpp:42** [logic] (error) Missing null check.
- Good: **foo.cpp:42** [logic] (error) `bar->Frobulate()` is called before the `bar != nullptr` guard on line 38 takes effect for the early-return path; move the guard above line 40 or early-return when null.
- One finding per line. No multi-paragraph commentary.

OUTPUT
- Write full findings to the file path you are given.
- End with a single line: `Self-assessment: <one sentence on coverage confidence>`.
- Return to the caller ONLY: count by severity, self-assessment line, file path. Nothing else.
```

---

## Step 3: Dispatch the six specialists in parallel

Send one message with six `Agent` tool calls (subagent_type: `general-purpose`). Each prompt must pass:
- `$WT` — the worktree path where the PR is checked out. **All file reads go here.** This is the only way line numbers line up with the PR on GitHub.
- `/tmp/review-$NUM.diff` — the diff (useful for hunk headers and for spotting which lines are `+` vs context).
- `/tmp/review-$NUM.meta.json` — PR metadata.
- `$BASE_SHA` — so the specialist can run `git -C $WT diff $BASE_SHA -- <path>` for a per-file diff.
- Output file path (`/tmp/review-$NUM-<axis>.md`).

The LLVM/LLDB coding conventions the first three specialists need are packaged in the `llvm-development` skill at `~/.claude/skills/llvm-development/` (or `~/dotfiles/.claude/skills/llvm-development/` in this repo). Each specialist prompt should tell the sub-agent to **read the relevant reference file(s) from that skill first**, since sub-agents do not inherit the parent's skill context. Pass absolute paths.

### Agent 1 — Style & formatting

**Owns**: mechanical style rules only. Naming conventions, include order, 80 cols, indentation, brace rules, `auto *`/`auto &`, comment markers, error-message casing.

**Does NOT own**: `formatv` index mismatches (correctness owns those), heavy-include decisions (architecture owns those), missing Doxygen on new public APIs (tests/docs owns that). Don't manufacture pseudo-rules (e.g., `return {}` vs `return T()` is not a rule; `eg` vs `e.g.` is not a rule).

**Reference**: tell the sub-agent to read, before reviewing:
- `.claude/skills/llvm-development/references/naming.md`
- `.claude/skills/llvm-development/references/style.md`
- `.claude/skills/llvm-development/references/lldb.md` (only the "Naming delta" section, if the PR touches LLDB)

**Tools**: the sub-agent should prefer running `clang-format --dry-run --Werror` and `clang-tidy -p <build>` on changed files (if a build dir is discoverable) to catch mechanical violations, and only hand-flag what the tools can't see. If no build dir is available, still run `clang-format --dry-run` on the changed files from the diff.

**Categories**: `[naming]` `[include]` `[format]` `[comment]` `[auto]` `[braces]` `[assert]`

### Agent 2 — Architecture & API design

**Owns**: public surface (SB/Target/Utility APIs), parameter and return types (StringRef/ArrayRef/SmallVectorImpl), container choice, layering (heavy includes in headers, forward-declare opportunities, circular dep risk), backward compat / SB-ABI stability, extensibility points, over-/under-abstraction, vtable widening on base classes.

**Does NOT own**: style. Correctness bugs. Missing tests. Claim verification.

**Reference**: tell the sub-agent to read, before reviewing:
- `.claude/skills/llvm-development/references/adt.md`
- `.claude/skills/llvm-development/references/lldb.md` (the "SB API stability" and "Plugin boundaries" sections, if the PR touches LLDB)

Additional design red flags (not in the skill because they're review-specific):
- Layering: a heavy `#include` added to a widely-used public header; an inline non-trivial method added to a public header that forces rebuilds; a new `friend` declaration whose reason isn't explained in this PR.
- Extensibility: closed enums without room to grow; hardcoded limits; base-class virtuals implemented by only one subclass (should live on the subclass instead).

**Categories**: `[design]` `[type]` `[container]` `[api]` `[layering]` `[compat]` `[abi]`

### Agent 3 — Correctness & safety

**Owns**: logic bugs. Cast patterns. Error/Expected handling. Lifetime/dangling refs. Thread safety. Determinism in user-visible output. Debug macro side effects. **`formatv` / `LLDB_LOG` / `LLVM_DEBUG` index-vs-arg mismatches** (e.g. `{1}` with one arg). Null-pointer hazards. Uninitialized variables. Inverted boolean logic. Off-by-one. Raw `new` + ownership transfer.

**Does NOT own**: style opinions. Naming. API shape (unless the shape causes a bug).

**Reference**: tell the sub-agent to read, before reviewing:
- `.claude/skills/llvm-development/references/errors.md`
- `.claude/skills/llvm-development/references/lldb.md` (the "ConstString", "Status vs Error", and "Debug and logging" sections, if the PR touches LLDB)

Additional correctness checks (not in the skill because they're review-specific):
- **`formatv` / `LLDB_LOG` format indices `{0}`, `{1}`, … MUST match the argument count.** Check every new format string.
- Determinism: iteration over `DenseMap`/`DenseSet` feeding diagnostics, files, or hashes.

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
2. **Retire noise**. Drop nits that are already covered by a warning/error finding on the same line. Drop pseudo-rule flags (if any specialist manufactured one). Drop any finding whose line number you cannot verify by reading the file in the worktree — a wrong line number means the specialist was hallucinating, so distrust the whole item.
3. **Normalize severity**. If a specialist used `critical`/`blocker`/`high`/`medium`/`low`, re-map: critical/blocker → error; high → error or warning based on description; medium → warning; low → nit.
4. **Rank**. Compute a "Top issues" list: the 3–7 findings most likely to matter (bugs > broken ABI > missing test for main path > layering > nits). Prefer things that block merge.
5. **Write the appendix**. Write the full deduped findings to `/tmp/review-<number>-findings.md`, grouped by file then by line, one finding per line in the canonical format. This file is linked from the main report but not pasted into it.

---

## Step 5: Render the final report

Keep the main report short. The reader should be able to act on "Actionable changes" alone without scrolling up — every bullet must be self-contained. The full per-file findings already live in the appendix you wrote in Step 4 (`/tmp/review-<number>-findings.md`); do not paste them here.

Print this to the user, and nothing else:

```
# Review: <PR title> (#<number>)

**Summary**: <one sentence — what the PR actually does, grounded in the diff>.
**Description honesty**: <one sentence — does the body match the diff? If yes, say "matches"; if no, name the biggest omission and stop>.

## Top issues
1. **path:line** [cats] (severity) — <one sentence stating the bug + the concrete fix>.
2. …
(3–7 items max. Errors and merge-blocking warnings only. No nits here.)

## First-principles alternative
**Verdict**: <Converged | Diverged-PR-better | Diverged-alternative-better | Diverged-tradeoff> — <one sentence>.
<If Diverged: 2–4 bullets naming the concrete structural difference and which side wins on each. Skip the full comparison table; it's in the appendix if you wrote one.>

## Actionable changes

Each bullet must be self-contained: a reader who has NOT read the Top issues or the appendix must still know what to do and why. Format:

  - **path:line** — <imperative fix in a full sentence>. <Why, in one clause>.

Examples of well-formed bullets:
  - **src/foo/Bar.cpp:142** — Restore the `if (handle != kInvalidHandle)` guard around the seek/write/restore block so an invalid handle early-returns the "invalid handle" error. Without it the subsequent `::seek(-1, …)` silently clobbers the caller's `offset` with `-1`.
  - **include/module.modulemap** — Register the newly added public header alongside the existing sibling entry. Modular builds fail with "header not in a module" until it's listed.

Examples of BAD bullets (do not emit these):
  - "Fix the regression in Bar.cpp:142."        ← requires the reader to go look up what the regression is
  - "Add the missing module map entry."         ← no path, no reason
  - "Reconsider the virtual surface."            ← not actionable

Group bullets under these headers (omit any that are empty):

  **Must fix before merge** — errors and merge-blocking warnings.
  **Design/arch** — changes that reshape the approach, not individual bugs.
  **Tests & docs** — missing coverage, missing Doxygen, PR body gaps.
  **Mechanical** — include order, doxygen paths, typedef→using, stray blank lines. One bullet per *category* if there are many (e.g. "Reorder includes in FilePosix.cpp and FileWindows.cpp to main/project/LLVM/system"), not one per file.

## Overall assessment

`approve` / `request changes` / `comment` — one sentence. If Agent 6's verdict was "Diverged, alternative is better," that drives `request changes` with the alternative as the ask.

---

**Counts**: <N errors / N warnings / N nits / N questions>. Full findings: `/tmp/review-<number>-findings.md`.

<If any specialist reported low coverage confidence, add one line here: "Coverage caveat: <what wasn't covered>.">
<If Agent 4 produced unresolved questions AND any of them could change the verdict, list up to 3. Otherwise omit.>
```

Hard limits on the main report: no severity table, no per-file findings section, no restating the Top issues under Actionable changes (the bullets should stand alone so repetition adds nothing). Everything that doesn't fit these sections goes to the appendix file.

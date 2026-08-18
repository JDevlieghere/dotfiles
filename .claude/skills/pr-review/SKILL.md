---
name: pr-review
description: Multi-agent, read-only code review of a GitHub PR, a branch, or the current working-tree diff. Kicks the slow adversarial reviewer off in the background first, then runs the fast axes (correctness, design, tests/conventions, plus conditional security/performance/concurrency) in the foreground and merges, gates, and validates their findings while the adversarial pass is still working. Emits one ranked report at the end. Never stalls: no agent is retried more than once, retries never block, and a dead axis is dropped with a note. For C++ in an LLVM/Clang/LLDB tree it leans on the llvm-development skill so reviewers apply LLVM conventions and run clang-format/clang-tidy. Never edits, commits, or pushes. Load when asked to review a PR, review changes before opening a PR, or get feedback on a diff.
argument-hint: "[blank = current branch, or a PR number / URL / branch name]"
---

# Code review

Orchestrate a multi-agent review of a code change. You are the **orchestrator**:
you fetch the change, launch the adversarial reviewer in the **background**, run
the remaining reviewers in the **foreground**, and do the merging, gating, and
validation yourself while the background agent is still working. Each specialist
owns one review axis; you own scope, selection, validation, and synthesis.

**The adversarial axis is the long pole, so it never gates anything.** It gets the
strong model and a license to dig across the tree, which makes it slow. Launching
it first and joining it last means its cost overlaps everything else instead of
adding to it. There are no waves: every other reviewer starts immediately after it.

**Never stall.** This skill's failure mode is waiting forever, so the rules that
prevent it are absolute:
- **No agent is retried more than once**, and a retry always goes to the
  background so it cannot block the pipeline.
- **A dead or missing axis is dropped**, not chased. Name it in the Coverage line
  and ship the report.
- **Never re-spawn an agent that is still pending.** A pending agent returns via a
  completion notification; you do not write that notification yourself and you do
  not poll for it in a loop.
- **Only the final report is a deliverable.** No interim findings report — the one
  status line in Stage 7 is the only output before it.

**Read-only. Do NOT modify, commit, or push anything.** Only read, analyze, and
delegate. The deliverable is a report, never an edit.

The reviewers and their shared rules live in `references/` next to this file.
Reviewer sub-agents do **not** inherit your loaded skills, so you pass them the
absolute paths to read.

## Stage 1: Determine scope

Pick one path by the argument.

### Remote PR (a PR number or GitHub URL is given)

Materialize the PR in a disposable worktree so every cited line number matches the
PR on GitHub and reviewers can run `clang-format`/`clang-tidy`/build against real
files. **Do this without mutating the user's checkout** — never run `gh pr
checkout` / `git checkout` / `git switch`; they move the user's HEAD and working
tree. Fetch the PR head and lay it down in a *separate* detached worktree.

The worktree must be created from a local clone of the PR's repository (the PR
objects live there). Set `REPO_DIR` to that clone: the current directory if it is a
clone of the PR's repo, otherwise an existing checkout of it — e.g. an
`llvm-project` checkout for an LLVM PR. If the cwd is not the right repo, locate a
clone (or ask the user where one is) before proceeding.

```bash
NUM=$ARGUMENTS   # a bare PR number, or parse owner/repo + number from a full URL
REPO_DIR=.       # a clone of the PR's repo (see above) — NOT necessarily the cwd
REPO=$(git -C "$REPO_DIR" remote get-url origin | sed -E 's#^(git@github.com:|https://github.com/)##; s#\.git$##')   # base repo, e.g. llvm/llvm-project
WT=/tmp/pr-review-$NUM-worktree

HEAD_SHA=$(gh pr view "$NUM" --repo "$REPO" --json headRefOid --jq .headRefOid)
BASE_SHA=$(gh pr view "$NUM" --repo "$REPO" --json baseRefOid --jq .baseRefOid)

# Fetch the PR head into REPO_DIR's object store WITHOUT moving its HEAD/working
# tree. `pull/<n>/head` is a ref on the PR's base repo; `origin` is assumed to point
# there. (If origin is a fork, fetch by URL: ... fetch --no-tags https://github.com/$REPO "pull/$NUM/head".)
git -C "$REPO_DIR" fetch --no-tags origin "pull/$NUM/head" 2>/dev/null
rm -rf "$WT"
git -C "$REPO_DIR" worktree add --detach "$WT" "$HEAD_SHA"

gh pr view "$NUM" --repo "$REPO" --json number,title,body,baseRefName,headRefName,author,files > /tmp/pr-review-$NUM.meta.json
gh pr diff "$NUM" --repo "$REPO" > /tmp/pr-review-$NUM.diff
gh pr view "$NUM" --repo "$REPO" --json files --jq '.files[] | "\(.additions + .deletions)\t\(.path)"' | sort -rn > /tmp/pr-review-$NUM.sizes
```

Pass to every reviewer: `$WT` (the tree to `Read` from), `/tmp/pr-review-$NUM.diff`
(diff with hunk headers), `/tmp/pr-review-$NUM.meta.json`, and `$BASE_SHA` (so they
can run `git -C $WT diff $BASE_SHA -- <path>` for a per-file diff).
(`gh pr diff --stat` does not exist — use the `.sizes` file for per-file sizes.)

**The worktree must outlive the background reviewer.** Remove it only in Stage 10,
after every agent — including the backgrounded adversarial one — has returned or
been dropped. Deleting it while an agent is still reading from it produces a
reviewer that silently finds nothing.

If a bare branch name is given, first try `gh pr view <branch> --json number` — if
it maps to an open PR, use this path with that number. Otherwise fall to the local
path below, diffing `origin/<branch>` (fetch if needed) instead of `HEAD`.

### Local branch / standalone (no argument, or reviewing the current checkout)

Review the working tree in place — no checkout, nothing mutated.

```bash
BASE_REF=$(gh pr view --json baseRefName --jq .baseRefName 2>/dev/null)        # the current branch's PR base, if any
BASE_REF=${BASE_REF:-$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's@^origin/@@')}
BASE_REF=${BASE_REF:-main}
git fetch --no-tags origin "$BASE_REF" 2>/dev/null || true
BASE=$(git merge-base HEAD "origin/$BASE_REF" 2>/dev/null || git merge-base HEAD "$BASE_REF")
git diff --name-only $BASE > /tmp/pr-review-local.files
git diff -U10 $BASE > /tmp/pr-review-local.diff
git diff --numstat $BASE | sort -rn > /tmp/pr-review-local.sizes
```

Reviewers `Read` from the current working tree. If no base resolves, **stop** and
say so — do not fall back to `git diff HEAD`, which would miss all committed work.

### Both paths

Compute the file list and diff once. If the diff is large (>~2000 changed lines),
tell each reviewer to focus on the top ~10 files by size from the `.sizes` file.

## Stage 2: Intent and domain

Both come from data Stage 1 already fetched — keep this to a couple of reads so the
background agent launches sooner.

**Intent.** Write a 2-3 line summary of what the change is trying to do. Sources:
PR title/body for a PR; `git log $BASE..HEAD --oneline` plus conversation context
for a branch/standalone review. Extract any factual claims ("fixes X", "NFC", "safe
because Y") — the adversarial reviewer will stress-test them. Pass the intent to
every reviewer; it shapes *how hard each one looks*, not which reviewers run.

**LLVM C++ layer.** Active when the change is C++ under an LLVM monorepo — paths
under `llvm/`, `clang/`, `lldb/`, `mlir/`, etc.; includes of
`llvm/…`/`clang/…`/`lldb/…`; or a repo-root `.clang-format`/`.clang-tidy`. When
active, the reviewers that have an LLVM mapping in `personas.md` are told to read
the relevant `~/.claude/skills/llvm-development/references/*.md` files first and to
prefer running `clang-format`/`clang-tidy` on changed files.

## Stage 3: Launch the adversarial reviewer (background, first)

Spawn it **now**, before selecting the rest of the team — it is the longest-running
agent and everything else is designed to overlap it.

- `subagent_type: general-purpose`, **`model: 'opus'`**, **`run_in_background: true`**.
- Note the agent id/name the tool returns; that is how you join it in Stage 8.
- Its prompt follows the same contract as every other reviewer (Stage 4), with the
  axis name `adversarial` and output file `/tmp/pr-review-<scope>-adversarial.md`.
- It is the **only** reviewer allowed unbounded exploration; cross-tree
  claim-checking is its whole value. Do not bound it to save time — its time is
  already free.

Then move straight on. Do not wait, do not poll, do not mention it again until the
Stage 7 status line.

## Stage 4: Select and spawn the fast reviewers (foreground)

Read the diff and file list and decide the rest of the team — this is judgment, not
keyword matching. The roster, per-axis ownership, and the LLVM reference mapping
are in **`references/personas.md`**; read it now.

**Always:** `correctness`, `design`, `tests-docs-conventions` (skip the last only
for a trivial mechanical-only diff).
**Conditional:** `runtime-risks`, only when the diff genuinely touches security,
performance, or concurrency — name the applicable sub-axes in its prompt. Count
only executable code lines toward any size threshold; a pure prose/config diff
skips it unless it describes security or data-handling behavior.

**Announce the team** before spawning, one justification line per conditional
reviewer (progress reporting, not a confirmation prompt):

```
Review team:
- adversarial            (background, opus — deep cross-tree claim-checking; joined last)
- correctness            (sonnet)
- design                 (sonnet) — also covers the new public SBTarget method (API/ABI)
- tests-docs-conventions (sonnet) — LLVM C++ diff; will run clang-format/clang-tidy
- runtime-risks          (sonnet) — 600 lines touching process launch; security + concurrency sub-axes
```

Spawn all of them in **one message** so they run concurrently, each
`subagent_type: general-purpose`, **`model: 'sonnet'`** (do not let them inherit
your session model — a large high-effort model turns a bounded axis into a 10-minute
one), and **`run_in_background: false`** (the Agent tool backgrounds by default;
these must be foreground so you get their results in this turn).

**Fan-out cap: at most 4 foreground agents plus the one background adversarial.**
Never spawn a fifth foreground reviewer, and never split the foreground batch
across messages — sequencing them is what made earlier versions slow.

Each prompt must include:

- **Scope context:** the tree to read from (`$WT` for a PR, else the working
  tree), `$BASE_SHA`/`$BASE`, the diff file path, and the file list. For a large
  diff, the "top 10 files" instruction.
- **Intent summary** from Stage 2, and PR title/body when reviewing a PR.
- **Paths to read first** (sub-agents don't inherit your skills):
  - `~/.claude/skills/pr-review/references/reviewer-rules.md` — the shared rules
    and the output contract every reviewer follows.
  - `~/.claude/skills/pr-review/references/personas.md` — "read your axis's
    section: `<axis>`."
  - For `tests-docs-conventions` when the diff adds or reworks source comments:
    `~/.claude/skills/comments/SKILL.md` — the comment-quality conventions it
    applies (repetitive, over-specific, and verbose comments).
  - When the LLVM layer is active and the axis has an LLVM mapping: the specific
    `~/.claude/skills/llvm-development/references/*.md` files listed for that axis.
- The reviewer's **axis name** and the **output file path** for its full findings:
  `/tmp/pr-review-<scope>-<axis>.md` (use the PR number or `local` as `<scope>`).

Each reviewer returns to you only its compact findings (per `reviewer-rules.md`),
its `self_assessment` line, and its output file path.

## Stage 5: Merge, gate, rank the foreground findings

Do this as soon as the foreground batch returns — the adversarial agent is still
running and this window is free.

1. **Dedupe.** Two findings collide when they share `file:line` within ±3 lines, or
   name the same symbol and the same root cause. Keep the highest severity, combine
   the category tags, and note which reviewers flagged it.
2. **Cross-reviewer agreement.** When 2+ independent reviewers flag the same issue,
   raise its confidence one step (`low→medium`, `medium→high`).
3. **Confidence gate.** Drop `low`-confidence findings — **except** an
   `error`-severity `low`-confidence finding is **kept but downgraded to a
   `question`** (a critical-but-uncertain issue must never be silently dropped).
   Record how many were suppressed.
4. **Drop noise.** Drop nits already covered by a warning/error on the same line.

## Stage 6: Validate them yourself

You are the validator — no validator sub-agent. The rubric is in
**`references/validation.md`**; read it and apply it to every surviving `error` and
`warning`. In short: confirm the cited line by reading a window around it, decide
whether the finding is real and introduced by this change, and return one of
`confirm` / `demote` / `reject` for each.

Keep it local and bounded: a small window per finding, roughly 15 reads total. A
claim you cannot settle from the cited location and its immediate neighbors becomes
a `question` — do not launch a wide investigation to chase it. `nit` and `question`
findings skip validation unless the surviving set is small (≤ ~5 total).

Record demotions and drops with their reason for the Coverage line.

## Stage 7: Status line

Print exactly one line, then stop producing output until the final report:

```
Fast axes done: 2 errors / 3 warnings / 4 nits (validated); adversarial still running.
```

If the adversarial agent has already returned by this point, skip the line entirely
and go straight to the report. Do not print findings here — this line exists so the
reader knows the review is alive, not to preview it.

## Stage 8: Join the adversarial reviewer

Wait for the outstanding background agents (adversarial, plus any Stage-9 retry).
Their results arrive as completion notifications — never invent one, and never
re-spawn a pending agent.

When adversarial returns, fold its findings into the Stage 5 merge and validate
them with Stage 6's rubric, exactly as you did for the foreground set. Its
`## Unresolved questions (top 3)` section feeds the report's questions.

**Cut it loose rather than hang:** if the user sends any message while you are
waiting, deliver the report immediately with the adversarial axis marked as not
returned, and `TaskStop` the pending agent. Shipping a report with a named gap
always beats an open-ended wait.

## Stage 9: When an agent dies

An agent that dies on an API error gets **one** retry, spawned with
`run_in_background: true` so it cannot block anything. Continue with Stages 5-8
while it re-runs; fold its findings in if it lands before the report.

If the retry also dies — or the agent is still pending when you are ready to
report — **drop that axis** and name it in the Coverage line ("design axis failed;
not reviewed"). Never retry twice, never serialize the pipeline behind a retry, and
never silently omit a missing axis from the report.

## Stage 10: Render the final report

Print this and nothing else. Keep it short: a reader should be able to act on
**Actionable changes** alone, so every bullet must stand on its own.

```
# Review: <title> (<#NUM or branch>)

**Summary**: <one sentence — what the change actually does, grounded in the diff>.
**Description honesty**: <does the body/intent match the diff? "matches", or name the biggest gap>.

## Top issues
1. **path:line** [cats] (severity) — <the bug + the concrete fix, one sentence>.
(3-7 items max — errors and merge-blocking warnings only, no nits.)

## Actionable changes
<Group under the headers below; omit empty groups. Each bullet is self-contained —
a reader who saw nothing else still knows what to do and why:>
  - **path:line** — <imperative fix in a full sentence>. <why, in one clause>.

  **Must fix before merge** — errors and merge-blocking warnings.
  **Design / architecture** — changes that reshape the approach.
  **Tests & docs** — missing coverage, regression tests, Doxygen, doc gaps.
  **Mechanical** — formatting, includes, naming. One bullet per category when many.

## Overall assessment
<approve | request changes | comment> — one sentence.

---
**Counts**: <N errors / N warnings / N nits / N questions>.
<Coverage caveat only if needed: axes that failed or were dropped, validation drops
and demotions, suppressed low-confidence findings, files skipped, or low reviewer
confidence.>
```

Do not emit a per-finding severity table, do not restate Top issues inside
Actionable changes, and do not include time estimates.

## Stage 11: Clean up

Only now, with every agent returned or dropped, remove the worktree from the same
clone: `git -C "$REPO_DIR" worktree remove --force "$WT"`, then
`git -C "$REPO_DIR" worktree prune`. Confirm the PR's checkout was never moved
(HEAD unchanged) and no files were modified in it.

## Fallback

If the harness cannot background a sub-agent, run adversarial in the foreground
**last**, after the report's other inputs are validated — the overlap is lost but
nothing else changes. If it cannot run parallel sub-agents at all, run the fast
axes sequentially in the Stage 4 order. If a spawn fails for capacity, treat it as
backpressure: that is the one retry from Stage 9, not a reason to widen fan-out.

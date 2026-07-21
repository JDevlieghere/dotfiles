---
name: pr-review
description: Multi-agent, read-only code review of a GitHub PR, a branch, or the current working-tree diff. Runs a fast high-signal pass (correctness, adversarial, design/API) and renders an interim report early so you can decide whether the change is worth more effort, then a deeper pass (tests/docs/conventions plus conditional security/performance/concurrency), gates findings by confidence, validates them in a batched independent pass, and renders a ranked final report. Caps parallel agents hard to stay fast and avoid rate limits. For C++ in an LLVM/Clang/LLDB tree it leans on the llvm-development skill so reviewers apply LLVM conventions and run clang-format/clang-tidy. Never edits, commits, or pushes. Load when asked to review a PR, review changes before opening a PR, or get feedback on a diff.
argument-hint: "[blank = current branch, or a PR number / URL / branch name]"
---

# Code review

Orchestrate a multi-agent review of a code change. You are the **orchestrator**:
you fetch the change, then dispatch specialist reviewers in **two waves** — a fast
high-signal Wave 1 (correctness, adversarial, design) whose findings you render as
an **interim report**, then a deeper Wave 2 — and finally merge, gate, validate,
and render the full findings. Each specialist owns one review axis; you own scope,
selection, and synthesis.

**Speed is a feature.** This review must give accurate feedback *early* and must
not stall. Two levers keep it fast, and both matter — bounded fan-out **and**
bounded per-agent cost:
- **Fan-out:** never more than 3 reviewer/validator agents in flight at once, and
  never spawn every reviewer in a single message. The waves are sequential — Wave 2
  starts only after the interim report is rendered. ~5–7 agents total, not dozens.
- **Per-agent cost:** subagents otherwise inherit your session model — which may be
  a large, high-effort Opus that spends 10+ minutes and 30 tool-calls on one axis.
  A focused reviewer does not need that. **Pin each reviewer's model explicitly**
  (Stages 4/6/8) and keep its exploration **bounded** (`reviewer-rules.md`). The
  one exception is `adversarial`, which earns a stronger model and room to dig
  because cross-tree claim-checking is its whole value. One unbounded reviewer on a
  heavy model can outlast the entire rest of the run.

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

**Always remove the worktree at the end of the run** (Stage 10) from the same
`REPO_DIR`. The fetch + detached worktree never touches the user's checkout.

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

## Stage 2: Discover intent

Write a 2-3 line summary of what the change is trying to do. Sources: PR
title/body for a PR; `git log $BASE..HEAD --oneline` plus conversation context
for a branch/standalone review. Extract any factual claims ("fixes X", "NFC",
"safe because Y") — the adversarial reviewer will stress-test them. Pass the
intent to every reviewer; it shapes *how hard each one looks*, not which reviewers
run.

## Stage 3: Detect domain and select the team

Read the diff and file list. Decide the reviewer team — this is judgment, not
keyword matching. The roster, per-axis ownership, wave assignment, and the LLVM
reference mapping are in **`references/personas.md`**; read it now.

**Detect the LLVM C++ layer.** It is active when the change is C++ under an LLVM
monorepo — paths under `llvm/`, `clang/`, `lldb/`, `mlir/`, etc.; includes of
`llvm/…`/`clang/…`/`lldb/…`; or a repo-root `.clang-format`/`.clang-tidy`. When
active, the reviewers that have an LLVM mapping in `personas.md` are told to read
the relevant `~/.claude/skills/llvm-development/references/*.md` files first and to
prefer running `clang-format`/`clang-tidy` on changed files.

**Wave 1 (always):** `correctness`, `adversarial`, `design`.
**Wave 2:** `tests-docs-conventions` for any diff with a real code or docs surface;
`runtime-risks` only when the diff genuinely touches security, performance, or
concurrency — name the applicable sub-axes in its prompt. Count only executable
code lines toward any size threshold — a pure prose/config diff skips
`runtime-risks` unless it describes security or data-handling behavior.

**Announce the team** before spawning, one justification line per conditional
reviewer (progress reporting, not a confirmation prompt):

```
Review team (Wave 1 → interim report, then Wave 2):
- correctness            (Wave 1, sonnet)
- adversarial            (Wave 1, opus — deep cross-tree claim-checking)
- design                 (Wave 1, sonnet) — also covers the new public SBTarget method (API/ABI)
- tests-docs-conventions (Wave 2, sonnet) — LLVM C++ diff; will run clang-format/clang-tidy
- runtime-risks          (Wave 2, sonnet) — 600 lines touching process launch; security + concurrency sub-axes
```

## Stage 4: Wave 1 — spawn the high-signal reviewers

Spawn the three Wave-1 reviewers in **one message (3 agents — that is the cap)**,
each `subagent_type: general-purpose`, **with its model pinned** (do not let them
inherit your session model):

- `correctness` and `design` → **`model: 'sonnet'`** — fast, bounded exploration
  (`reviewer-rules.md` caps them to ~10 reads).
- `adversarial` → **`model: 'opus'`** — it is allowed to dig across the tree to
  verify the author's claims, so it gets the stronger model and a looser budget.

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

## Stage 5: Interim report (early feedback)

The moment Wave 1 returns, render a short interim report — **no extra agents**.
This is the early signal that tells the reader whether the change is sound enough
to keep investing in. Prepare it quickly:

1. Dedupe and confidence-gate the Wave-1 findings (Stage 7 rules, applied lightly).
2. **Confirm cited line numbers yourself** by `Read`ing a small window around each
   `error`/`warning` you're about to show; drop any whose line you can't confirm.
   This is the only validation before the interim — do not spawn validator agents
   yet.

Then print, clearly labeled preliminary:

```
## Interim findings (Wave 1 — preliminary, deep pass still running)
**Summary**: <one sentence — what the change actually does, grounded in the diff>.
1. **path:line** [cats] (severity) — <the bug + the concrete fix, one sentence>.
(Top errors/warnings only. Not yet independently validated; Wave 2 may add to or
adjust these.)
```

If Wave 1 found nothing merge-blocking, say that in one line — it is useful early
signal too. Then continue to Wave 2.

## Stage 6: Wave 2 — completeness

Spawn the Wave-2 reviewers selected in Stage 3 (`tests-docs-conventions`, plus
`runtime-risks` if warranted) the same way as Wave 1 — same prompt contract, same
**≤3-agents-in-flight** cap. Pin both to **`model: 'sonnet'`** with bounded
exploration (they review the changed files, not the whole tree). For
`runtime-risks`, name the applicable sub-axes (security / performance /
concurrency) in its prompt so it reviews only those. Skip Wave 2 entirely only for
a trivial mechanical-only diff.

## Stage 7: Merge, gate, rank (all findings)

Combine the Wave 1 and Wave 2 returns. The Wave-1 findings already shown in the
interim are re-merged here with everything else — the final report supersedes the
interim.

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
   Drop any finding whose cited line you cannot confirm by reading the tree — a
   wrong line number means the reviewer was guessing; distrust the item.

## Stage 8: Validate (batched independent pass)

Hand the surviving `error` and `warning` findings to a **single validator
sub-agent** (`subagent_type: general-purpose`, **`model: 'sonnet'`**) using
**`references/validator.md`**. It re-verifies every finding from scratch against
the reviewed tree and returns one verdict per finding. The validator stays **local
and fast** — it confirms each finding at its cited line and immediate context and
must **not** re-explore the tree to re-derive a cross-file claim (`validator.md`
enforces this; a claim it can't confirm locally is demoted to `question`, not
chased). Split across **two** validators only when more than ~10 findings survive —
never more than two, never one-per-finding. **Skip validation entirely** when ≤2
findings survive; just confirm those yourself by reading the cited lines.

Each finding comes back with one of three verdicts:

- **`confirm`** — real, introduced by this change, and correctly severitied. Keep
  it unchanged.
- **`demote`** — real, but mis-severitied: a `warning` that is actually a `nit`
  (minor, cosmetic, mirrors an existing untested/accepted pattern, or derivative of
  another finding), or a definite-sounding claim that is really a `question`. Lower
  the finding to `demote_to` and keep it — don't discard real signal because the
  severity was wrong.
- **`reject`** — not real, pre-existing, already handled elsewhere, or the premise
  is false. Drop it.

Record demotions and drops (with the validator's reason) for the Coverage line.
`nit`/`question` findings skip validation to save cost — fold them into the batch
only when the surviving set is small (≤ ~5 total).

## Stage 9: Render the final report

Print this and nothing else — it supersedes the interim report. Keep it short: a
reader should be able to act on **Actionable changes** alone, so every bullet must
stand on its own.

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
<Coverage caveat only if needed: validator drops and demotions, suppressed low-confidence findings, files skipped, or low reviewer confidence.>
```

Do not emit a per-finding severity table, do not restate Top issues inside
Actionable changes, and do not include time estimates.

## Stage 10: Clean up

If you created a worktree, remove it from the same clone:
`git -C "$REPO_DIR" worktree remove --force "$WT"`, then
`git -C "$REPO_DIR" worktree prune`. Confirm the PR's checkout was never moved
(HEAD unchanged) and no files were modified in it.

## Fallback

Keep the ≤3-agents-in-flight cap no matter what. If a spawn fails for capacity,
treat it as backpressure — wait and retry that one agent, don't widen the fan-out.
If the harness can't run parallel sub-agents at all, run each wave's reviewers
sequentially; the wave structure and the interim report still apply. Everything
else stays the same.

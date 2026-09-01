---
name: llvm-review
description: Review a change to an LLVM, Clang, or LLDB tree — a GitHub PR, a branch, or the working tree — by running the reusable review-* agents in parallel and merging their findings into one report. Applies LLVM/LLDB conventions and runs clang-format/clang-tidy. Read-only. Load when asked to review an LLVM PR, review a change before opening one, or get feedback on a diff.
argument-hint: "[blank = current branch, or a PR number / URL / branch name]"
---

# LLVM review

Run the `review-*` agents against an LLVM/Clang/LLDB change and merge what they
find into one report. You fetch the change, brief the reviewers, and write the
report; each agent owns its own axis.

**Read-only.** Never edit, commit, push, or move the user's HEAD. The deliverable is
a report.

## 1. Get the change

### A PR number or URL

Lay the PR head down in a throwaway worktree so cited lines match GitHub and
reviewers can build and run the tools. Never `gh pr checkout`, `git checkout`, or
`git switch` — they move the user's tree.

```bash
NUM=$ARGUMENTS                # bare number, or parse owner/repo + number from a URL
REPO_DIR=.                    # a clone of the PR's repo; find one if the cwd isn't
REPO=$(git -C "$REPO_DIR" remote get-url origin | sed -E 's#^(git@github.com:|https://github.com/)##; s#\.git$##')
WT=/tmp/llvm-review-$NUM

HEAD_SHA=$(gh pr view "$NUM" --repo "$REPO" --json headRefOid --jq .headRefOid)
BASE_SHA=$(gh pr view "$NUM" --repo "$REPO" --json baseRefOid --jq .baseRefOid)

git -C "$REPO_DIR" fetch --no-tags origin "pull/$NUM/head"
rm -rf "$WT"
git -C "$REPO_DIR" worktree add --detach "$WT" "$HEAD_SHA"

gh pr view "$NUM" --repo "$REPO" --json number,title,body,author,files > /tmp/llvm-review-$NUM.meta.json
gh pr diff "$NUM" --repo "$REPO" > /tmp/llvm-review-$NUM.diff
```

A bare branch name: try `gh pr view <branch> --json number` first and take this path
if it resolves; otherwise fall through.

### No argument — the current branch or working tree

```bash
BASE_REF=$(gh pr view --json baseRefName --jq .baseRefName 2>/dev/null)
BASE_REF=${BASE_REF:-$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's@^origin/@@')}
BASE_REF=${BASE_REF:-main}
git fetch --no-tags origin "$BASE_REF" 2>/dev/null || true
BASE_SHA=$(git merge-base HEAD "origin/$BASE_REF" 2>/dev/null || git merge-base HEAD "$BASE_REF")
git diff -U10 $BASE_SHA > /tmp/llvm-review-local.diff
```

Reviewers read the working tree in place. If no base resolves, stop and say so —
`git diff HEAD` would miss every committed change.

Then write two or three lines on what the change is trying to do, from the PR body
or `git log $BASE_SHA..HEAD`. Every reviewer gets it.

## 2. Pick the reviewers

Always: `review-correctness`, `review-design`, `review-tests`, `review-docs`,
`review-conventions`, `review-adversarial`.

Add when the diff genuinely touches the domain — judgment, not extension matching:

| agent | when |
|---|---|
| `review-api` | an SB API, a public header, a plugin interface, a serialized format, a protocol, a command or setting name |
| `review-security` | parsing untrusted input — DWARF, object files, debuggee memory, packets — or paths, subprocesses, raw pointer arithmetic |
| `review-performance` | a hot path: symbol or DIE lookup, index building, per-frame or per-instruction work, a container choice under load |
| `review-concurrency` | threads, locks, atomics, async callbacks, shared mutable state |

Drop `review-tests` and `review-docs` only for a genuinely mechanical diff.

Launch all of them in **one message** so they run concurrently. `review-adversarial`
is the slow one; start it in that same message and let it run while you read the
others.

## 3. Brief them

Sub-agents inherit nothing from your context. Every prompt states:

- **Where to read**: `$WT` for a PR, the working tree otherwise. Nothing else.
- **The diff**: the `/tmp/llvm-review-*.diff` path, and `$BASE_SHA` so they can run
  `git -C <tree> diff $BASE_SHA -- <path>` per file.
- **The intent** from step 1, plus the PR title and body when there is one.
- **The LLVM references to read first**, by absolute path, from the table below.
- **The build directory**, if one exists, so `clang-tidy -p` and the test suites are
  usable.

| agent | read first under `~/.claude/skills/llvm-development/references/` |
|---|---|
| `review-correctness` | `errors.md`, `lldb.md` |
| `review-design` | `adt.md`, `style.md` |
| `review-api` | `lldb.md`, `adt.md` |
| `review-tests` | `lldb.md` (Testing) |
| `review-docs` | `style.md` (Comments and Doxygen) |
| `review-conventions` | `naming.md`, `style.md` |

Also hand each one the red flags for its axis:

- **correctness** — `formatv` / `LLDB_LOG` / `LLVM_DEBUG` format indices must match
  the argument count; iterating a `DenseMap`/`DenseSet` into diagnostics, output, or
  a hash is non-deterministic (wants `MapVector`/`SetVector` or a sort); a
  `ConstString` compared against a fresh temporary leaks the string pool; every
  `Error` must be consumed; `report_fatal_error`/`abort` in LLDB kills the user's
  session.
- **design / api** — a heavy `#include` or non-trivial inline method added to a
  widely-used public header; `const char *` where `StringRef` fits, `std::vector`
  where `ArrayRef` or `SmallVectorImpl &` fits; a magic sentinel return
  (`UINT32_MAX`) where `Expected<T>` is clearer; a base-class virtual with one
  implementation; `lldb_private::` types leaked through an SB header; a new virtual
  on an SB class (vtable break); an SB name that diverges from the internal API for
  no reason.
- **tests** — a bug fix needs a test that fails without the fix; pick the cheapest
  tier that can catch it (unit, then shell, then API).
- **docs** — new public SB methods need Doxygen (`///`, `\param`, `\returns`).
- **conventions** — run `clang-format --dry-run --Werror` on the changed files, and
  `clang-tidy -p <build>` when a build directory exists; LLVM is `CamelCase` types
  and `camelBack` functions, LLDB is `UpperCamelCase` methods and `snake_case`
  variables with `m_`/`s_`/`g_` prefixes.

## 4. Report

Merge the returned findings: collapse duplicates (same line or same root cause,
noting that several reviewers hit it), drop anything the diff doesn't actually
introduce, and spot-check any finding that would block the merge by reading the
cited line. Then write this, and nothing else:

```
# Review: <title> (<#NUM or branch>)

<One sentence on what the change actually does, from the diff — not the description.>
<One sentence on whether the description matches it, if it doesn't.>

## Fix before merge
- **path:line** — <the problem, and the fix>.

## Worth considering
- **path:line** — <design, tests, docs>.

## Nits
- **path:line** — <mechanical, one line each; collapse repeats into one bullet>.

## Open questions
- <what nobody could settle, and what would settle it>.

<approve | request changes | comment> — one sentence.
```

Omit any section that is empty. Every bullet stands on its own: someone who reads
only that line knows what to change and why. If an agent came back empty-handed or
failed, say which axis went uncovered rather than dropping it silently.

## 5. Clean up

Once every reviewer has returned:

```bash
git -C "$REPO_DIR" worktree remove --force "$WT" && git -C "$REPO_DIR" worktree prune
```

Confirm the user's checkout never moved.

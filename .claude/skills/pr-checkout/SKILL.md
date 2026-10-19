---
name: pr-checkout
description: Check out a GitHub PR head in a throwaway worktree so line numbers match GitHub and tools can run, without moving the user's HEAD. Load before reviewing a PR (e.g. before /code-review <PR>) or when asked to look at a PR locally.
argument-hint: "<PR number or URL>"
---

# PR checkout

Lay a PR head down in a detached worktree. Cited lines then match the PR, and
builds, `clang-format`, and `clang-tidy` can run against it.

Never `gh pr checkout`, `git checkout`, or `git switch`: they move the user's tree.

## Setup

```bash
NUM=$ARGUMENTS     # bare number, or parse owner/repo + number from a URL
REPO_DIR=.         # a clone of the PR's repo; find one if the cwd isn't
REPO=$(git -C "$REPO_DIR" remote get-url origin | sed -E 's#^(git@github.com:|https://github.com/)##; s#\.git$##')
WT=/tmp/pr-$NUM

HEAD_SHA=$(gh pr view "$NUM" --repo "$REPO" --json headRefOid --jq .headRefOid)
BASE_SHA=$(gh pr view "$NUM" --repo "$REPO" --json baseRefOid --jq .baseRefOid)

git -C "$REPO_DIR" fetch --no-tags origin "pull/$NUM/head"
git -C "$REPO_DIR" worktree remove --force "$WT" 2>/dev/null
git -C "$REPO_DIR" worktree add --detach "$WT" "$HEAD_SHA"

gh pr view "$NUM" --repo "$REPO" --json number,title,body,author,files > "$WT.meta.json"
gh pr diff "$NUM" --repo "$REPO" > "$WT.diff"
```

A bare branch name: try `gh pr view <branch> --json number` first and use the
resulting number.

Review against `$WT`, with `$BASE_SHA` for per-file diffs:
`git -C "$WT" diff $BASE_SHA -- <path>`. Pass `$WT` and the PR title/body to any
sub-agent: they inherit nothing.

## Cleanup

```bash
git -C "$REPO_DIR" worktree remove --force "$WT" && git -C "$REPO_DIR" worktree prune
rm -f "$WT.meta.json" "$WT.diff"
```

Confirm the user's checkout never moved.

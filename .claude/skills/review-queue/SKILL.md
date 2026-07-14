---
name: review-queue
description: Fetch and prioritize the open llvm/llvm-project PRs awaiting my review. Combines a deterministic GitHub fetch (review-requested / reviewed-by / mentions, deduped and scored by area + signals) with an AI-assisted ranking that surfaces what actually needs my eyes first. Load when asked to triage my review queue, show what PRs to review, or "what should I review today".
argument-hint: "[blank = full queue | an area: lldb/dsymutil/debug-info/binary-utilities/wasm | deep = per-PR enrichment]"
---

# Review queue

Triage the open PRs awaiting my review in `llvm/llvm-project` and present a
focused, ranked list. Two stages:

1. **Deterministic fetch** — a bundled script unions three GitHub searches,
   dedupes, derives area + signals, and assigns a transparent base score.
2. **AI-assisted ranking** — you refine that score with judgment and render a
   grouped, actionable list. This is the part only you can do; the score is a
   floor, not the answer.

Never edit, comment on, approve, or push anything. This is read-only triage.

## Stage 1 — fetch

Run the fetcher (adjust flags per the invocation, see **Arguments**):

```bash
python3 ~/dotfiles/scripts/review-queue.py --format json
```

`--format json` is explicit here because you consume the JSON. Run without it in a
terminal for a ready-made human-readable ranking (see **Arguments**). It prints a
JSON object `{repo, user, generated_at, count, prs: [...]}` on stdout
(a one-line summary goes to stderr). Each PR carries:

- `number`, `title`, `url`, `author`, `author_is_bot`, `draft`, `comments`
- `labels`, `category` — one of `lldb`, `dsymutil`, `debug-info`,
  `binary-utilities`, `wasm`, `other`
- `sources` — which searches matched: `requested` (direct CODEOWNERS request),
  `reviewed` (I reviewed it before), `mentioned` (@-mentioned, **noisy** — see below)
- `age_days` (open since), `idle_days` (since last activity)
- `base_score`, `signals` (human-readable), `suggested_bucket` (`must`/`should`/`optional`)
- with `--enrich`: `updated_since_review`, `commits_since_review`

If the script is missing or errors, fall back to running the three searches by
hand: `gh search prs --repo llvm/llvm-project --review-requested=@me --state open`
and likewise `--reviewed-by=@me` and `--mentions=@me`, then reason over the union.

## Stage 2 — rank and refine

`base_score` already encodes the objective priority model (see the WEIGHTS block
at the top of `~/dotfiles/scripts/review-queue.py` — that's where I retune it). Your job is to **adjust
with judgment**, not re-derive from scratch. The model I care about:

- **dsymutil / DWARFLinker / llvm-dwarfutil** — I'm the code owner and volume is
  low, so I review *every* one. Surface all of them.
- **LLDB** — I'm the code owner; I want to at least see all of them, but there
  are hundreds, so rank hard and show the top slice.
- **debug-info / binary-utilities / wasm** — I'm a group reviewer here; least
  important. Show only the few that stand out.
- **Back in my court** (`reviewed` + `requested`, or `--enrich` shows commits
  since my review) — I reviewed it and it changed; strong signal, pull up.
- **Pinged** — a genuine recent direct ping is important. But `mentioned` alone
  is noisy (LLVM's bot @-mentions code owners on almost every in-area PR), so
  don't over-trust it. If a PR's rank hinges on it, confirm with
  `gh pr view <n> --repo llvm/llvm-project --json comments` that a *recent*
  comment actually addresses me.
- **Aging** — a PR waiting a while but still active deserves a nudge; one idle
  for months is likely abandoned (already penalized) — leave it low.

Refinements the score can't make on its own:

- Read titles. Trivial NFC / mechanical / test-only changes rank *below* a
  substantive change with the same score. `Revert`, release/branch, or
  regression fixes may deserve a bump.
- Drafts and bot-authored PRs are down-ranked already — keep them out of the
  top groups; mention them only as a count.
- Collapse obvious duplicates / stacked PRs.
- Cross-area PRs (e.g. a `[BoundsSafety]` change carrying an `lldb` label) —
  judge by what actually touches my areas.

Optional deeper pass: for a handful of ambiguous top candidates, you may
`gh pr view <n> --json reviews,commits,comments` to confirm whether it truly
needs me now. Keep it to a few calls; don't fan out over the whole list.

## Output

Lead with a one-line summary (`N open PRs awaiting you — M need attention`), then
grouped sections, most-actionable first. Suggested groups:

1. **🔴 Back in your court** — reviewed & changed / re-requested. Show all.
2. **dsymutil / DWARFLinker** — code-owner, low volume. Show all.
3. **LLDB** — top ~12 by refined rank; then `+N more` with a count.
4. **Groups** (debug-info / binary-utilities / wasm) — top few + counts.
5. One trailing line for what was set aside: drafts, stale (idle > 90d), bots.

Each PR on one line, terminal-clickable:

```
#209397 · [lldb] Oversized DW_OP_piece triggers unbounded read · your court, active today · https://github.com/llvm/llvm-project/pull/209397
```

Keep rationales to a short clause grounded in the `signals` (why it's here, its
age/idle). Don't dump the whole queue — rank, group, and cap; state the tail as
counts so nothing is silently dropped.

## Arguments

- *(blank)* — full queue, fast (no per-PR calls).
- an **area** (`lldb`, `dsymutil`, `debug-info`, `binary-utilities`, `wasm`,
  `other`) — filter the fetched PRs to that `category` and show more of it.
- `deep` / `enrich` — pass `--enrich` to the fetcher so reviewed PRs get an exact
  "changed since my review" check (one `gh` call per reviewed PR; slower).
- You can also pass through `--limit N` or `--repo OWNER/REPO` for other repos.

The fetcher also renders its own deterministic view: run it directly in a terminal
(no `--format`, or `--format text`, add `--all` for the full optional bucket) for a
grouped, ranked list without AI refinement — handy for a quick check without Claude.

# Validation rubric

Applied by the **orchestrator itself** (Stage 6), not by a sub-agent. There is no
validator agent: spawning one to re-read lines you can read yourself costs a
round-trip and buys nothing, and it used to sit on the critical path.

You are a **fresh second opinion** on findings other agents produced. You have no
stake in any of them — false positives are common, and rejecting a wrong finding is
a success, not a failure. Apply this to every surviving `error` and `warning`.
`nit` and `question` findings skip validation unless the surviving set is small
(≤ ~5 total).

## Budget

**Stay local: a small window per finding, roughly 15 reads total across the whole
set.** Read the cited line and its immediate surroundings in the reviewed tree
(`$WT` for a PR, the working tree otherwise). Do **not** re-explore the tree to
re-derive a cross-file claim. If a finding's validity hinges on evidence outside
the changed file and its near neighbors, demote it to `question` rather than
launching a wide investigation — that is `adversarial`'s job, and it is already
running.

## Validity

For each finding, read the cited code and what surrounds it:

1. **Is the cited line real and does it say what the finding claims?** Read a window
   around it. A line number that doesn't match the claim means the reviewer was
   guessing — **reject** the finding outright; don't go hunting for the line it
   meant. This check subsumes the old separate line-confirmation pass.
2. **Is the issue REAL in the code as written?** Common false positives: the
   reviewer missed an existing guard/null-check/validation; misread a type or
   signature; or flagged a pattern that is intentional here (check comments and
   parallel code). Also reject when the premise is false — e.g. it calls a
   limitation "undocumented" when it is documented, or proposes a fix that is not
   valid.
3. **Is it INTRODUCED or newly EXPOSED by this change?** Use `git blame` / the diff.
   If the cited line predates the change and the diff doesn't interact with it, it
   is pre-existing — reject regardless of whether it is a real issue.
4. **Is it NOT already HANDLED elsewhere** — by a caller, guard, framework default,
   the type system, or a parallel handler? If surrounding infrastructure prevents
   it, reject.

Any of 1-4 failing → **reject**.

## Severity

Only for findings that survive validity:

5. **Is the stated severity right?** Demote a `warning` to `nit` when the issue is
   real but minor, cosmetic, mirrors an existing untested/accepted pattern in the
   same code, or is derivative of another finding. Demote to `question` when it is
   framed as a definite defect but is really a trade-off to acknowledge, or a claim
   you cannot fully verify locally. Otherwise **confirm**.

## Verdicts

- **`confirm`** — real, introduced by this change, correctly severitied. Keep it
  unchanged.
- **`demote`** — real but mis-severitied. Lower it to `nit` or `question` and keep
  it; don't discard real signal because the severity was wrong.
- **`reject`** — not real, pre-existing, already handled, line doesn't match, or the
  premise is false. Drop it.

Bias: on **validity**, when genuinely in doubt, reject. On **severity**, when in
doubt prefer `demote` over `confirm`.

Don't invent new findings here — your scope is exactly the findings the reviewers
returned. Record every demotion and drop with its one-sentence reason; the counts
feed the report's Coverage line.

## Worked verdicts

- **confirm** — "Cited line is new in this diff and dereferences `bar` before the
  `nullptr` guard added two lines below."
- **reject** — "Line 87 already guards with `if (!ptr) return`; the deref described
  can't occur."
- **reject** — "Cited line predates the change and the diff doesn't touch it or its
  callers — pre-existing."
- **reject** — "Line 214 is a `#include`, not the loop the finding describes; the
  line number doesn't match the claim."
- **demote → nit** — "Real coverage gap, but it mirrors the equally-untested sibling
  in the same file — a nit, not a should-fix warning."
- **demote → question** — "The behavioral change is real but spec-conforming;
  surface it as a trade-off to confirm, not a definite regression."

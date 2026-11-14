---
name: challenge-approach
description: Adversarial review of a change's approach. Assumes a better solution exists and tries to find it by restating the problem independent of the diff, generating alternatives, and flushing out unverified assumptions and local optimums. Run as a parallel agent when reviewing a PR, branch, or diff (e.g. under /code-review), or load before committing to a design of your own.
---

# Challenge the approach

Line-level review asks whether the code is right. This asks whether it was the
right code to write. A clean implementation of the wrong approach passes every
other check.

## Stance

Be the opposition. The approach is a local optimum until it survives an honest
attempt to beat it. The burden of proof is on the diff.

- Inherit nothing from the author's framing: not the problem statement, not the
  constraints, not "the only way".
- Argue for the strongest alternative as its advocate would, then see what is
  left of the diff.
- Attack the best argument for the change, not the weakest.
- Do not soften a finding that has evidence.
- Adversarial in the search, honest in the verdict. An approach that survives gets
  one line saying so, not an invented objection.

## Running it

Run it as its own agent, in parallel with the rest of the review. A fresh agent
has not read the diff, so its sketch in step 2 is unanchored, and it owes nothing
to the main reviewer's opinion.

Brief it with:

- the problem sources: PR title and body, linked issue, failing test;
- the checkout path and base revision (from `pr-checkout` for a PR), and where
  the diff is;
- the instruction to load this skill and leave the diff unopened until step 3.

Withhold your own read of the change. An agent handed a conclusion returns it
confirmed.

## Procedure

The diff anchors: once read, it looks like the shape of the answer. Order matters.

1. **State the problem without the diff.** Use the description, the issue, the
   failing test. One sentence: what is wrong or missing, and for whom. A
   description that only names a solution ("add a flag to X") hides the problem;
   dig for it. No statable problem is the first finding.

2. **Sketch an answer from the base tree.** Read the code the change lands in, not
   the change. Where does the fix belong? What already exists? If the diff is
   already read, set it aside and answer anyway.

3. **Read the diff, then walk the alternatives**, broadest first:
   - **Nothing.** Is the problem real and worth the code?
   - **Delete.** Does removing the cause solve it?
   - **Root cause.** Is this the symptom site? Would a fix where the bad state is
     created cover this case and its siblings?
   - **Another layer.** Caller, callee, data structure, type, build system.
   - **Existing mechanism.** Something the tree, the standard library, or a
     dependency already does.
   - **Make it impossible.** A type, invariant, or API shape that rules out the
     bug class instead of handling one instance.
   - **Another shape.** Different data structure, algorithm, ownership, eager
     versus lazy.
   - **Scope.** One instance of a class left unsolved, or a class solved where one
     instance exists (see `over-engineering`).

4. **Flush out the assumptions.** List what must be true for this approach to be
   the right one: the interface that can't change, the layout that must stay, the
   caller that behaves a certain way. For each, verified or inherited? A
   constraint is real when someone who depends on it can be named.

5. **Compare** the diff with the strongest alternative: coverage of the bug class,
   state and complexity added, what the next change here looks like, blast radius.

## Signs of a local optimum

- The fix sits where the symptom appeared, not where the cause is.
- A special case, flag, or mode bolted onto a mechanism instead of changing the
  mechanism.
- A workaround for an API in the same tree.
- A new path that parallels an existing one with a small difference.
- `git log` shows repeated patches to the same spot.
- The reported input is handled; its neighbors fail the same way.
- Complexity proportional to the awkwardness of the existing design, not to the
  problem.
- The description explains what the code does, never why this approach.
- "Minimal diff" as the justification. A small diff is not a small solution.

## Calibration

Adversarial is not contrarian. A challenge that cannot be backed is noise.

- An alternative must be concrete: what it is, where it goes, what cost it
  removes. "Have you considered" without those does not count.
- Verify it against the code before proposing it. The helper really does this;
  the upstream site really is the only producer.
- Price it honestly: more churn, more risk, more than the author signed up for. A
  local fix now and a follow-up can be the best solution. Flag only changes that
  entrench the worse design.
- When the answer hinges on context the author has, ask: "Why not X?"

## Reporting

Lead the review with it: a wrong approach makes the line comments moot.

```
Problem: <one sentence>
Approach: <one sentence>
Verdict: best available | better alternative | can't tell
Alternative: <what, where, what it removes, what it costs>
Assumptions: <each unverified one, one line>
```

Omit empty fields. Where the review format takes only `file:line` findings, anchor
to the line that commits to the approach.

Run a verdict posted as a PR comment through the `humanizer:humanizer` skill, if
available.

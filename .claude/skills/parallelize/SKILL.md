---
name: parallelize
description: Guidance for offloading work to subagents and running independent work in parallel. Load when a task involves multiple independent investigations, heavy codebase exploration, or research that would bloat the main context. Covers when to delegate vs. do directly, how to dispatch agents concurrently in a single message, how to choose between Explore / Plan / general-purpose / specialist agents, and how to structure agent prompts for useful results.
---

# Parallelize with subagents

Subagents exist for two reasons:

1. **Concurrency** — independent pieces of work run at the same time instead of one after another.
2. **Context hygiene** — a subagent's tool output lives in its own window and returns to you as a summary, so the main conversation stays clean.

A subagent does **not** inherit this session's history. You brief it cold, with exactly the context needed — nothing more, nothing less. That discipline is what makes it effective.

## Decide: delegate, parallelize, or do directly

Walk this ladder top to bottom and stop at the first match:

1. **Target already known** (specific path, specific symbol, one-line change) → do it directly with `Read` / `grep` / `Edit`. Delegation overhead isn't worth it.
2. **One investigation, >3 searches across unfamiliar code** → dispatch a single `Explore` agent.
3. **Multiple independent investigations** (different subsystems, different files, different questions with no shared state) → dispatch one agent per domain, **in a single message**, concurrently.
4. **Work is sequential** (step 2 depends on step 1's result) → do it yourself, or dispatch one agent at a time. Don't fake parallelism on dependent work.

"Independent" means: fixing domain A does not affect domain B, and neither agent needs the other's output to start.

## Parallel dispatch: one message, multiple `Agent` calls

When multiple agents are independent, put **all `Agent` tool uses in the same assistant message**. They execute concurrently. Sending them in separate messages serializes them for no reason.

If the user says "in parallel", this is mandatory — not a suggestion.

Do **not** dispatch multiple agents in parallel if they might edit the same files. Edits from concurrent agents can conflict and silently overwrite each other.

## Choosing the agent

- **`Explore`** — read-only codebase search and orientation. Fastest for "where is X?", "how does Y work?", "find all callers of Z". Specify thoroughness: `quick` / `medium` / `very thorough`.
- **`Plan`** — design an implementation strategy for a non-trivial change. Returns step-by-step plans and flags architectural tradeoffs. Use before writing code for anything more than a localized fix.
- **`general-purpose`** — open-ended research or multi-step tasks that don't fit a specialist. Can also write code. The fallback.
- **Specialists** (e.g. `claude-code-guide`, repo-defined review agents) — use whenever the task matches the agent's description.

If torn between `Explore` and `general-purpose`: `Explore` is faster and read-only; `general-purpose` can edit files.

## Writing the prompt

An agent prompt is self-contained. Four pieces, always:

- **Scope** — exactly what to look at or touch. File paths, symbol names, directory.
- **Goal** — what you want to know or what you want changed, and *why* it matters (so the agent can make judgment calls at the edges).
- **Constraints** — what not to do. "Don't edit production code." "Don't refactor surrounding files." "Report only, don't fix."
- **Output shape** — "under 200 words", "bullet list of `file:line` findings", "yes/no with one-sentence justification", "list of commits ahead of main with a diff summary per commit".

Include what you've already tried or ruled out, so the agent doesn't repeat your steps.

**Do not delegate synthesis.** "Based on your findings, fix the bug" pushes the hard judgment onto the agent. The agent gathers; you decide. If a fix is needed, dispatch a separate agent with a concrete instruction grounded in what you learned.

Terse command-style prompts produce shallow, generic work. A paragraph of real context beats a one-liner.

## Common mistakes

- **Too broad** — "investigate the failures" → the agent wanders. Give it one domain.
- **No constraints** — the agent refactors half the repo. Say what's off-limits.
- **No output shape** — you get a wall of prose instead of the bullet list you wanted.
- **Leaking session history** — assuming the agent knows what you just discussed. It doesn't. Restate what it needs.
- **Over-delegating** — spawning an agent for a two-line `grep`. If the target is known, just do it.
- **Parallel edits to the same file** — two agents, one file, silent conflict. Serialize the writes, or scope each agent to a disjoint set of files.
- **Polling a background agent** — `run_in_background` notifies you on completion. Do not sleep or poll.

## Background vs foreground

- **Foreground** (default) — you need the result to continue your work.
- **Background** (`run_in_background: true`) — you have genuinely independent local work to do while it runs. You'll be notified on completion.

## Continuing an agent

To continue an agent with its prior context, use `SendMessage` with its ID or name. A new `Agent` call always starts fresh — prompts must be self-contained.

## After agents return

1. **Read each summary** — understand what the agent says it did.
2. **Check for conflicts** — if multiple agents edited files, confirm their diffs don't stomp each other.
3. **Verify code changes** — an agent's summary describes what it *intended* to do. Read the actual diff before reporting work done.
4. **Integrate** — run the build / tests / typecheck once, on the merged result, not on each agent's output separately.

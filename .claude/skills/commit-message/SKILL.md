---
name: commit-message
description: Conventions for drafting git commit messages. Load when asked to write a commit message, draft a commit, or run `git commit`. Covers subject-line bracket prefixes, NFC tagging, line-length and wrapping rules, imperative mood, body content focused on the why, and trailers like rdar:// references and `Assisted-by: Claude`.
---

# Commit messages

Draft commit messages in this format. Do not run `git commit` — output the message and let the user commit. Commit signing prompts a GPG pinentry that hangs Claude Code.

## Workflow

1. Run `git status` and `git diff --staged` (or `git diff` if nothing is staged) to see the actual change.
2. Run `git log -n 10 --oneline` in the same repo to match the local prefix conventions (component tags differ between repos — `[lldb]`, `[clang]`, `[DWARFLinker]`, etc.).
3. Draft subject + body following the rules below.
4. Present the message to the user. Do not commit.

If the staged diff spans multiple unrelated logical changes, say so and suggest splitting before drafting — one logical change per commit.

## Subject line

Format: `[component] Imperative summary`

- **Bracket prefix** identifies the subsystem. Match what `git log` in the current repo uses.
- **One thing per bracket pair.** Never `[lldb, CMake]`. Use separate pairs when nesting is genuinely needed: `[lldb][CMake]`. Prefer a single pair when one suffices.
- **Aim for 50 characters, hard cap ~72** including the bracket prefix. GitHub will append ` (#NNNNN)` on squash-merge — that does not count against the limit.
- **Imperative mood, present tense.** "Add", "Fix", "Support" — not "Added", "Fixes", "Adding".
- **Sentence case** for the first word after the bracket. Capitalize proper nouns and identifiers as written in code.
- **No trailing period.**
- **`(NFC)` suffix** for non-functional changes (refactors, renames, comment-only, formatting). Use `(NFCI)` when the change is intended to be non-functional but you can't fully prove it (e.g. threading a parameter that should not change behavior). The suffix goes at the end of the subject, before any PR number.

Examples (good):
- `[lldb] Assert that CommandObject::DoExecute sets a return status`
- `[lldb-dap] Make lldbDAP an OBJECT library (NFC)`
- `[DWARFLinker] Emit DW_IDX_parent in the accelerator table`
- `[lldb][CMake] Force OBJECT libraries to also be STATIC`

Anti-patterns:
- `[lldb, dap] Fixed bug` — comma-listed tags, past tense, vague.
- `Updates the linker to handle Swift modules.` — no bracket, third-person, trailing period.
- `[lldb] Refactor` — too vague; say what was refactored and how.

## Body

Optional but usually present. Separate from the subject by one blank line. Wrap at 72 characters.

What goes in the body:

- **Why the change is needed.** The diff shows what changed; the body explains motivation: the bug being fixed, the constraint being satisfied, the user-visible problem, the prior commit being undone.
- **Non-obvious context.** Spec references, the alternative approach considered and rejected, an interaction with another commit, a follow-up that's coming.
- **Concrete observable evidence** when it clarifies the problem — short transcripts of confusing output, an error message, a code snippet showing the bug. Use fenced blocks.

What stays out:

- Restating what the diff already shows line by line.
- Marketing language ("greatly improves", "robust", "comprehensive").
- TODOs that belong in tracker tickets.

Imperative mood and present tense apply in the body too: "Pass STATIC alongside OBJECT so..." not "Passed STATIC...".

## Trailers

Place at the end of the body, separated by one blank line. One trailer per line.

- `rdar://NNNNNNNNN` — Apple-internal Radar reference, only include when the change is explicitly tied to a Radar.
- `Assisted-by: Claude` — when Claude materially helped author the change (drafted code, designed the approach). Omit for purely mechanical assistance.
- `Fixes #NNNNN` / `Closes #NNNNN` — only when the change actually closes a public GitHub issue.

Do not add `Co-Authored-By: Claude` or any other Claude attribution beyond `Assisted-by:` unless the user asks.

## When the body should be empty

A bare subject is fine for changes whose subject is fully self-describing and whose motivation is obvious from the diff (mechanical fixes, test updates after a rename, reverting a clearly-named commit). When in doubt, write the body.

## Output format

Return the message in a fenced block so the user can copy-paste:

```
[component] Imperative summary

Body paragraph explaining why, wrapped at 72 columns. Reference
prior commits by short SHA when relevant (e.g. a5a13ca29186).

rdar://NNNNNNNNN
Assisted-by: Claude
```

Do not prepend "Here is the commit message:" or similar — just the block.

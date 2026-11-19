---
name: comments
description: Write, edit, or review source code comments and API documentation. Use when deciding whether a comment belongs.
---

# Comments

Default to no comment. Use clear names, explicit control flow, and enforceable invariants to make the code explain itself. Add a comment when a careful reader would otherwise miss a constraint, contract, or rationale that matters for using or changing the code safely. When code changes are in scope, consider whether a better name, a small helper, or an assertion can carry that information.

## Inline comments

Explain the intent and rationale. Skip mechanics the reader can infer from the code. Useful comments explain required ordering, a lock the caller must hold, an ABI constraint, or the reason for a surprising branch or value.

State the rule the code enforces. Check that the rationale applies wherever the code acts and is supported by the code, contract, or a reliable reference.

If a path grammar ignores repeated and boundary separators, the same rule explains why the parser skips empty segments throughout the path.

```cpp
// Repeated, leading, and trailing separators create no path components.
if (segment.empty())
  continue;
```

## Durable rationale

Omit references to prompts and conversations. Record change history in the commit message or PR description. A specific caller, input, or version earns a place when it defines the constraint or helps maintainers verify when it stops applying. Keep full reproductions in tests or issue trackers.

For a workaround, name the affected system and the failure the code prevents. Include a version boundary or an issue reference when it helps verify or retire the workaround. Cite a spec section, RFC, or paper when it saves the reader from reconstructing the rationale.

## Documentation comments

Follow the project's requirements for API docs and file headers. Where docs are optional, skip them if the name and signature already tell callers what they need. Document caller-visible details such as ownership, units, or error behavior where they matter. Put the contract at the public declaration and avoid duplicating it in the implementation.

## Tone and maintenance

Use the shortest comment that states the constraint accurately. Write in plain, declarative prose with proper capitalization and punctuation. Cut filler, vague hedging, and narration. Follow project conventions for forms such as argument labels and file headers.

Place comments next to the code or declaration they govern. When behavior changes, update or remove affected comments in the same edit, including API docs on a separate declaration. A stale comment is worse than none.

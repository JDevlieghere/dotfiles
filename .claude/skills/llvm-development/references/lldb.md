# LLDB specifics

LLDB follows LLVM conventions with a handful of notable deltas. These are the things that trip people up most often.

## Naming delta

See `references/naming.md` for the full rules. Quick summary:

- Functions / methods: `UpperCamelCase` (not `camelBack`).
- Variables and parameters: `snake_case`.
- Members: `m_` prefix.
- File-local statics and function-local statics: `s_` prefix.
- Globals: `g_` prefix.

## `ConstString`

`ConstString` is a uniqued string kept in a process-wide pool. It is cheap to compare and hash, expensive to construct.

**Pitfall:** comparing a `ConstString` against a freshly-constructed `ConstString` leaks a new entry into the pool on every call.

```cpp
// WRONG — leaks into the ConstString pool on every call.
if (name == ConstString("my_symbol"))
  ...

// Right — compare against an already-interned ConstString, or just a StringRef.
static ConstString g_my_symbol("my_symbol");
if (name == g_my_symbol)
  ...

// Also fine — StringRef comparison against the ConstString's string.
if (name.GetStringRef() == "my_symbol")
  ...
```

Only intern a `ConstString` when the string will participate in many comparisons or live in a long-lived data structure.

## `Status` vs `Error`

LLDB's older `lldb_private::Status` predates `llvm::Error`. Current guidance:

- New code: use `llvm::Error` / `llvm::Expected<T>`.
- Public SB API: `SBError` is fine; `Status` appears in internal code that straddles SB.
- Converting: `Status::ToError()` / `Status::FromError()` exist at the boundary.

Don't introduce new APIs that return `Status` if `Error`/`Expected` would work.

## Assertions

- Default: plain `assert(cond && "message")` (or `llvm_unreachable` for unreachable paths).
- `lldbassert(cond)` is a *soft* assert: behaves like `assert` when asserts are enabled; when disabled, prints a warning asking the user to file a bug and continues execution. Reserve it for recoverable bugs where the alternative would be aborting on a user. Use sparingly — prefer `Error`/`Expected` whenever real error handling is feasible.

## Fatal errors

Aborting LLDB's process must be avoided at all costs — it kills the user's debug session.

- Do **not** call `llvm::report_fatal_error()` or `abort()` in LLDB.
- `llvm_unreachable()` is fine only for genuinely unreachable code (e.g. the `default` of an exhaustive `switch`).
- For any failure that could plausibly happen at runtime, return an `Error` / `Expected<T>` instead.

## SB API stability

The `SB*` classes (`SBTarget`, `SBProcess`, `SBFrame`, ...) are the public Python-and-C++ API. They're considered ABI-stable.

Red flags on SB-surface changes:

- New public method without Doxygen.
- Leaking `lldb_private::` types through an SB header — SB must stay decoupled from internals.
- Adding a virtual to an SB base class (breaks the ABI).
- Magic integer sentinel returns (`return UINT32_MAX;`) where an `Expected<T>` or an out-parameter would be clearer.
- SB method name that diverges from the underlying internal API for no reason.

## Debug and logging

- `LLDB_LOG(log, "format {0} {1}", a, b)` — printf-style indices match `formatv`.
- `LLDB_LOGF(log, "format %s", s)` — printf-style, legacy.
- Check `log` for null (LLDB macros handle it, but don't bypass them).
- No side effects inside `LLDB_LOG` arguments — logs are compiled in but may not fire.

## `lldb_private` vs `lldb`

- `lldb` namespace: the SB API and public types. Stable.
- `lldb_private` namespace: everything else. Free to change.

Keep public headers (under `lldb/API/`) free of `lldb_private` types. Internal headers can freely include both.

## Target/Process/Thread/Frame hierarchy

These are the core internal classes. Key invariants:

- A `Target` is a debugger's view of an executable. It exists before/without a `Process`.
- A `Process` belongs to a `Target`. Attaching or launching produces one.
- `Thread` and `StackFrame` belong to a `Process`. Their lifetimes are tied to process state — holding a `ThreadSP` across a continue/stop may yield an unbacked thread.

Shared-pointer suffix convention: `ThreadSP`, `ProcessSP`, `TargetSP`, `StackFrameSP`. Weak pointers: `ThreadWP`, etc.

## Plugin boundaries

Many LLDB subsystems (ABI, ObjectFile, SymbolFile, Process, ExpressionParser) are plugin-based. Adding a feature that crosses a plugin boundary:

- Think about out-of-tree plugins. They implement the same interface and can break if you change a base class's virtual table or add a new pure virtual.
- Prefer adding a non-pure virtual with a sensible default over a pure virtual.

## Testing

- C++ unit tests live in `lldb/unittests/`. Use `gtest`.
- Integration / API tests live in `lldb/test/API/`. Python + `dotest.py`.
- Shell tests live in `lldb/test/Shell/`. `lit`-driven.
- A bug fix needs a test that fails without the fix.

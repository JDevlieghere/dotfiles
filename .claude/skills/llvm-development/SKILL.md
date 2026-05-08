---
name: llvm-development
description: Conventions for writing, refactoring, or reviewing C++ in LLVM, Clang, or LLDB trees. Covers the naming split between LLVM and LLDB, include ordering, ADT containers and string types (StringRef, SmallVector, DenseMap), Error/Expected handling, LLVM-style casts, formatting rules, and LLDB-specific hazards. Load when editing `.cpp`/`.h` files under an LLVM monorepo, opening a file that includes `llvm/ADT/`, or answering questions about LLVM/LLDB coding standards.
---

# LLVM / LLDB development

Reference distilled from the LLVM Coding Standards and LLDB's local conventions. LLVM and LLDB **disagree** on naming; get that right first.

## Quick rules (do these by default)

- **Run the tools first.** `clang-format` and `clang-tidy` (with the project's `.clang-format` and `.clang-tidy`) enforce most mechanical rules below. Use them to format diffs and catch naming / include-order / `auto` / `isa`+`cast` violations automatically. See `references/style.md` for invocations. Reserve manual review for semantic and design issues.
- **Match surrounding style.** Consistency within a file beats any rule below.
- **Naming:** LLVM uses `CamelCase` for types/variables and `camelBack` for functions; LLDB uses `UpperCamelCase` for functions/methods, `snake_case` for variables, with `m_`/`s_`/`g_` prefixes. See `references/naming.md`.
- **Strings:** `StringRef` for params, `const Twine &` for concatenable messages (never stored), `SmallString<N>` for scratch, `std::string` when you own it. Avoid `const char *`.
- **Containers:** `SmallVector<T, N>` by default, passed as `SmallVectorImpl<T> &`. `ArrayRef<T>` for read-only params. `DenseMap` / `DenseSet` over `std::unordered_*`. `StringMap<V>` for string keys. See `references/adt.md`.
- **Errors:** Return `Error` / `Expected<T>`. No exceptions. Every `Error` must be handled — `consumeError` to discard, `cantFail` only when infallible. See `references/errors.md`.
- **Casts:** `isa<T>`, `cast<T>`, `dyn_cast<T>`. Pattern: `if (auto *X = dyn_cast<T>(V))`. No `dynamic_cast`.
- **Formatting:** 80 cols, 2-space indent, no tabs. Early `return`/`continue`, no `else` after terminating branch. `auto *` for pointers, `auto &` for references. Braces omitted on simple single-statement bodies, but if any branch braces then all do. See `references/style.md`.
- **C++17.** No `<iostream>`, no `std::endl` (use `'\n'`), no exceptions, no `dynamic_cast`.
- **Assertions:** `assert(cond && "message")`. `llvm_unreachable("msg")` over `assert(false && ...)`.
- **Diagnostics:** error/warning messages are lowercase, no trailing period.

## References

Load the specific reference file for depth on each topic:

- `references/naming.md` — LLVM vs LLDB naming, prefixes, enumerators, header guards.
- `references/style.md` — formatting, includes, namespaces, control flow, C++ feature restrictions, comments.
- `references/adt.md` — strings and containers: when to pick which, parameter conventions.
- `references/errors.md` — `Error`, `Expected`, `cantFail`, `consumeError`, LLVM-style casts, fatal-error rules.
- `references/lldb.md` — LLDB-specific deltas: `ConstString` rules, `Status` vs `Error`, SB-API stability, debug macros.

## When working in LLDB specifically

LLDB inherits LLVM conventions except where noted in `references/lldb.md`. The most common mistakes:

- Using LLVM `camelBack` for LLDB functions (LLDB wants `UpperCamelCase`).
- Forgetting the `m_` / `s_` / `g_` prefix on members / file-local statics / globals.
- Comparing a `ConstString` against a freshly-built temporary `ConstString` (leaks the string pool).
- Reaching for `Status` in new code when `Error` / `Expected` is preferred.
- Using `lldbassert` in new code — it's a soft assert reserved for recoverable bugs where error handling isn't feasible; default to plain `assert` / `llvm_unreachable`, and prefer `Error`/`Expected` when real error handling is possible.
- Calling `report_fatal_error()` or `abort()` in LLDB — never. Aborts kill the user's debug session. `llvm_unreachable` is only for genuinely unreachable code (e.g. exhaustive `switch` defaults).
- Leaking `lldb_private::` types through public SB headers.

## Configuring the build

Prefer `llvm-cmake.py` (in `~/dotfiles/scripts/`) over invoking `cmake` directly. Run it from the build directory, which is assumed to live inside `llvm-project`.

- Default to `-r` (RelWithDebInfo + assertions) unless the user asks otherwise.
- Pass `--projects` and/or `--runtimes` for only the components the current work touches. For an LLDB PR, include `lldb`; for a Clang change, include `clang`; etc. Don't enable everything by default — it slows the build.
- Extra `-D...` flags can be appended; they're forwarded to cmake.

Example for an LLDB change: `llvm-cmake.py -r --projects clang lldb`.

## Debug and logging idioms

- `LDBG() << "msg"` or `LLVM_DEBUG(dbgs() << "msg\n")`. Define `DEBUG_TYPE` **after** all includes.
- Debug macro arguments must have **no side effects**.
- `formatv("{0} {1}", a, b)` preferred over printf-style. Indices must match argument count exactly.
- LLDB log: `LLDB_LOG(log, "...", args)` — same indexing rule.

## When reviewing vs writing

This skill describes the rules. Applying them to a diff (severity labels, one-line finding format, dedupe, ranking) is the job of the `/review-pr` command, which references this skill.

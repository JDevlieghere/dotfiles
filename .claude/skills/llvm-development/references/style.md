# Formatting and style

## Use the tools first

Most of the mechanical rules below are enforced by `clang-format` and `clang-tidy`. Run them instead of applying the rules by hand — they're faster, they won't miss cases, and their output is authoritative when it disagrees with memory.

### `clang-format`

Every LLVM repo ships a `.clang-format` at the root; it's the source of truth for whitespace, line length, brace placement, include ordering, `auto *` / `auto &` spacing, and namespace formatting.

```bash
# Format only the lines you changed (preferred — don't reflow untouched code).
git clang-format HEAD~1

# Format a single file in place.
clang-format -i path/to/file.cpp

# Dry-run: show a diff of what would change.
clang-format --dry-run --Werror path/to/file.cpp
```

When writing new code, format before you commit. When editing existing code, `git clang-format` against the branch point so you don't churn unrelated lines.

### `clang-tidy`

LLVM maintains a `.clang-tidy` at the repo root that enables the `llvm-*` and `readability-*` check families most relevant to the project. Run it to catch naming violations, `auto` misuse, missing `llvm::` qualifiers on sorted algorithms, inefficient string/container patterns, and more.

```bash
# Check a single file using the project's .clang-tidy.
clang-tidy path/to/file.cpp -- -I<build>/include

# Apply fixes the checks can auto-repair.
clang-tidy -fix path/to/file.cpp

# With a compilation database (preferred):
clang-tidy -p <build-dir> path/to/file.cpp
```

Useful check families to know about:

- `llvm-header-guard` — enforces the `LLVM_<COMPONENT>_<SUBDIR>_<FILE>_H` form.
- `llvm-include-order` — enforces the include-group ordering described below.
- `llvm-namespace-comment` — requires `} // end namespace X` trailers.
- `llvm-qualified-auto` — catches `auto` that should be `auto *`.
- `llvm-prefer-isa-or-dyn-cast-in-conditionals` — catches `isa` + `cast` pairs.
- `readability-identifier-naming` — enforces the naming split (configured per-repo; LLDB's `.clang-tidy` overrides for `snake_case` / `m_` prefixes).
- `readability-braces-around-statements`, `readability-else-after-return` — control-flow style.
- `performance-*` — unnecessary copies, inefficient string ops.
- `modernize-use-nullptr`, `modernize-use-override`, `modernize-use-equals-default`.

Flag a finding by hand only when the tools can't see it (semantic bugs, API-shape concerns, design-level issues). For anything on the list above, **run the tool** rather than manually reviewing.

### When to trust the tools vs. the written rules

- **Tools win on mechanics.** If `clang-format` and the written rule disagree on brace placement or include order, follow the tool — the `.clang-format` file is the canonical spec for that repo.
- **Written rules win on judgment.** "`auto` only when it improves readability" is not enforceable; that's still a review call.
- **When tools are silent**, fall back to these rules.

## Whitespace

- 80-column limit.
- 2-space indent, no tabs.
- No trailing whitespace.
- One statement per line.

## Includes

Four groups, in order, separated by one blank line, each group sorted lexicographically:

1. The main module header (the header for this `.cpp`).
2. Local/project headers (the same subproject).
3. LLVM-project headers (`llvm/...`, `clang/...`, `lldb/...`).
4. System headers (`<string>`, `<cstdio>`, platform headers).

Use `""` for project headers, `<>` for system headers. Don't include a heavy header into a widely-used public header if a forward declaration would do.

## Namespaces

- Top-level project namespace: `llvm`, `clang`, `lldb`, `lldb_private`.
- **No indentation** inside `namespace { ... }` or `namespace llvm { ... }`. Close with `} // end namespace llvm`.
- Anonymous namespaces: keep small, and only for file-local types. For file-local **functions**, prefer `static`. Never put an anonymous namespace in a header.
- Out-of-line definitions in `.cpp` files use qualified names (`void Foo::bar()`); do not reopen the namespace to write them.

## Control flow

- Prefer early `return` / `continue` to reduce nesting.
- No `else` after a branch that `return`s, `break`s, `continue`s, or `throw`s (we don't throw anyway).
- Cache `end()` outside the loop when iterating.
- Preincrement (`++I`) over postincrement for non-trivial iterators.
- Range-based `for` when you can.
- No `default:` label in a switch that covers every enumerator — it silences the compiler's "unhandled case" warning.

## `auto`

- Use `auto` when it materially improves readability (long type names, iterator types, lambda captures).
- Always qualify pointers and references: `auto *P = ...`, `auto &R = ...`. Never let `auto` silently drop a pointer or reference.
- Prefer spelled-out types for short names (`int`, `StringRef`) where `auto` adds no clarity.

## Braces

- Omit braces on simple single-statement bodies.
- But: if any branch of an `if` / `else if` / `else` uses braces, **all** do.
- Multi-line bodies always brace.

## Comments

- `//` for normal comments. Full sentences, initial capital, trailing period.
- `/* */` reserved for inline parameter docs. Use the leading `/*Name=*/value` form (`foo(/*Prefix=*/nullptr, /*Verbose=*/true);`), never a trailing `value /* Name */`. The leading form is what `clang-tidy` and `clang-format` understand.
- Disable code with `#if 0` / `#endif`, not by commenting it out with `//`.
- Don't restate what the code does — only *why*, when non-obvious.
- Doxygen on new public APIs: `///`, `\brief`, `\param`, `\returns`.

## Diagnostics

- Error and warning messages start lowercase, no trailing period: `"expected ';' before 'return'"`, not `"Expected ';'..."`.

## C++ feature restrictions

- C++17 only (unless the project has moved up — check `CMakeLists.txt`).
- No C++ exceptions.
- No `<iostream>` — use `raw_ostream` / `errs()` / `outs()`.
- No `std::endl` — use `'\n'`.
- No `dynamic_cast` — use LLVM-style casts (see `references/errors.md`).
- Prefer C++-style casts (`static_cast`, `reinterpret_cast`) over C casts.
- No braced init lists for calls to regular constructors (`Foo f(1, 2);`, not `Foo f{1, 2};`) — braced init carries `initializer_list` overload-resolution surprises.
- `struct` when all members are public and there are no member functions beyond trivial ones; otherwise `class`.
- No unnecessary `inline` keyword on methods defined inside a class body (already implicit).
- `llvm::sort` over `std::sort` — catches non-determinism in debug builds.
- `[[maybe_unused]]` for variables only used in asserts.
- Classes with virtual methods need an out-of-line virtual method (often the destructor) to anchor the vtable.

## Asserts

- `assert(condition && "human-readable message")`.
- `llvm_unreachable("reason")` for truly unreachable code — preferred over `assert(false && ...)`.
- Don't put side effects inside `assert()` — asserts compile out in release.

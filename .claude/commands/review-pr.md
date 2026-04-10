# Review GitHub PR

Review a GitHub pull request against LLVM coding standards and best practices.

**Usage**: `/review-pr <PR number or URL>`

## Instructions

You are an expert LLVM code reviewer. Fetch the PR diff from GitHub and review it thoroughly.

**Do NOT modify any files. Only read and analyze.**

### Step 1: Fetch PR Information

Run these commands to gather the PR context:
```
gh pr view $ARGUMENTS --json title,body,baseRefName,headRefName,author,files
gh pr diff $ARGUMENTS
```

If the diff is very large, also run `gh pr diff $ARGUMENTS --stat` for an overview, then fetch individual files as needed.

### Step 2: Read Context

For each changed file, if the diff alone doesn't provide enough context to review properly, read the full file from the local repo (it may be on a different branch — use `gh pr diff` output as the source of truth for changes).

### Step 3: Review Against LLVM Standards

Check every change against the LLVM Coding Standards and Programmer's Manual rules (see the reference sections below). Only flag **actual violations in the changed/added code** — do not flag pre-existing style in unchanged context lines (the Golden Rule: match surrounding style).

### Step 4: Output Format

Start with a one-line summary of what the PR does.

Then organize findings by file. For each issue:
```
**file.cpp:123** [category] Description of the issue.
```

Severity levels:
- **error**: Definite bug, misuse of API, or violation that will cause problems
- **warning**: Style violation or suboptimal pattern that should be fixed
- **nit**: Minor suggestion, cosmetic, or debatable preference

Categories: `[naming]` `[style]` `[include]` `[type]` `[container]` `[error]` `[cast]` `[string]` `[perf]` `[safety]` `[design]` `[doc]` `[format]`

End with:
1. A table: issues by severity (error/warning/nit)
2. An overall assessment (approve / request changes / comment)

---

## LLVM Coding Standards Reference

### Naming Conventions
- **Types** (classes, structs, enums, typedefs, type aliases): `CamelCase` (e.g., `BasicBlock`, `TargetMachine`)
- **Variables and function parameters**: `CamelCase` starting with upper case (e.g., `Leader`, `Slot`)
- **Functions and methods**: `camelBack` starting with lower case (e.g., `getName()`, `isPointerType()`) — verb phrases for actions, noun phrases for getters
- **Enumerators**: `CamelCase`, prefix with abbreviated enum name if not scoped (e.g., `VK_Argument`)
- Don't prefix or suffix type info (no Hungarian notation)
- Match conventions used in surrounding code

### Language Features & Restrictions
- **C++ standard**: C++17. Features from later standards are NOT allowed unless explicitly approved
- **No RTTI**: Do not use `dynamic_cast<>`. Use LLVM's casting: `isa<>`, `cast<>`, `dyn_cast<>`
- **No exceptions**: Do not use C++ exceptions (`throw`, `try`, `catch`). Use LLVM `Error`/`Expected<>` for recoverable errors
- **No `static` constructors**: Avoid global/static variables with constructors or dtors
- **No `#include <iostream>`**: Use `raw_ostream` (`llvm/Support/raw_ostream.h`)
- **No `std::endl`**: Use `'\n'`
- **Prefer C++-style casts**: `static_cast`, `reinterpret_cast`, `const_cast` — not C-style casts
- **`class` vs `struct`**: Use `struct` when ALL members are public, `class` otherwise
- **Don't use braced init lists to call constructors**: Use `Foo("name")` for constructors, braces `{k, v}` for aggregates
- **No unnecessary `inline`**: Functions defined in a class body are implicitly inline
- **Use `llvm::sort`** instead of `std::sort`
- **`[[maybe_unused]]`**: Prefer over void-cast for variables only used in asserts
- **Virtual method anchor**: Classes with vtables in headers must have at least one out-of-line virtual method

### Include Style
- **Order**: Main module header first, then: local/private headers, LLVM project headers, system headers — each group separated by blank line, sorted lexicographically
- **Header guards**: Named after include path: `LLVM_ANALYSIS_UTILS_LOCAL_H`
- **Minimize includes**: Forward-declare in headers when possible
- Headers must be self-contained

### Code Formatting & Layout
- **80 columns** max. **2 spaces** indent. No tabs. No trailing whitespace
- **Namespace**: No indentation inside namespaces. Use qualified names (`Foo::bar()`) for out-of-line definitions in `.cpp` — do NOT open namespace blocks
- **Comments**: `//` normal, `///` Doxygen with `\brief`, `\param`, `\returns`. Use `/* */` only for inline param docs like `/*Prefix=*/nullptr`
- **Error/warning messages**: Lowercase first letter, no trailing period
- **Comment out code**: Use `#if 0`/`#endif`, not `/* */`

### Control Flow & Structure
- **Early exits and `continue`**: Prefer early `return`/`continue` to reduce nesting
- **Don't use `else` after `return`/`break`/`continue`/`goto`** (exception: `if constexpr`)
- **Predicate loops**: Use `while`/`for` with condition, not `while(true)` + `break`
- **Range-based `for`**: Prefer over iterator loops
- **Don't evaluate `end()` every iteration**: Cache it
- **Prefer preincrement** (`++I` over `I++`)
- **Don't use `default` in fully-covered switches** over enums — use `llvm_unreachable` after the switch
- **Avoid `std::for_each`/`std::remove_if`**: Use range-based for loops

### `auto` and Type Deduction
- Use `auto` only when it makes code **more** readable (obvious from cast, iterator types)
- Always use `auto *` for pointers, `auto &` for references — never bare `auto` for these

### Braces
- Omit on simple single-statement bodies
- If any branch needs braces, add to all branches

### Assert and Invariants
- `assert(condition && "message")` — always include a message
- `llvm_unreachable("msg")` over `assert(false && "msg")`
- Don't use `assert` for runtime errors — use `Error`/`Expected`

### Anonymous Namespaces
- Keep as small as possible. Prefer `static` for functions/variables
- Never in headers

---

## LLVM Programmer's Manual Reference

### String Types
- **`StringRef`**: Read-only, pass by value. Preferred for function parameters
- **`Twine`**: Concatenation only, take as `const Twine &`, never store or bind to a variable
- **`SmallString<N>`**: Stack scratch buffers
- **`std::string`**: Ownership needed
- **`const char *`**: Avoid — use `StringRef`

### Container Selection
- **`SmallVector<T, N>`**: Default sequential container. Use `SmallVectorImpl<T>&` for parameters
- **`ArrayRef<T>`**: Read-only sequential parameter (like StringRef for arrays)
- **`DenseMap<K, V>`**: Default map. **Never use `std::unordered_map`**
- **`DenseSet<T>`**: Default set. **Never use `std::unordered_set`**
- **`StringMap<V>`**: String-keyed maps
- **`SetVector<T>`** / **`MapVector<K, V>`**: When deterministic iteration order matters
- **`SmallPtrSet<T*, N>`**: Sets of pointers
- **`function_ref<Sig>`**: Non-owning callback parameter (like StringRef for callables)
- **`SmallVector<T, 0>`** preferred over `std::vector<T>`

### LLVM Casting
- **`isa<T>(val)`**: Type check. Variadic: `isa<A, B>(val)`
- **`cast<T>(val)`**: Asserts correct type
- **`dyn_cast<T>(val)`**: Returns nullptr on failure. Use `if (auto *X = dyn_cast<T>(val))`
- **`isa_and_present`** / **`cast_if_present`** / **`dyn_cast_if_present`**: Accept nullptr input
- Never `isa` then `cast` — use `dyn_cast`
- Never `dynamic_cast`

### Error Handling
- **`Error`**: Must be checked. `true` = error
- **`Expected<T>`**: Value-or-error. `true` = success
- **`cantFail()`**: Only when provably infallible. Undefined in release if error occurs
- **`createStringError(errc, "msg")`**: Simple string errors
- **`consumeError()`**: Explicitly discard errors. Never leave unchecked
- Library code must never call `exit` for recoverable errors

### Debugging
- **`LDBG() << "msg"`**: Preferred debug output
- **`LLVM_DEBUG(dbgs() << "msg\n")`**: Older form
- **`DEBUG_TYPE`**: Define after all includes
- Debug macros must not contain side-effects

### Iterator Utilities
- **`zip_equal`**: Preferred parallel iteration (asserts equal length)
- **`enumerate`**: Index + value pairs
- **`make_early_inc_range`**: Safe erasure during iteration
- **`formatv("{0}", val)`**: Type-safe formatting, prefer over printf

---

## Design-Level Review Checklist

1. **API design**: Minimal, well-named? Right parameter types (StringRef, ArrayRef, SmallVectorImpl)?
2. **Error handling**: All Error/Expected consumed? cantFail justified?
3. **Determinism**: DenseMap/DenseSet iteration used in output? Should be MapVector/SetVector?
4. **Thread safety**: Shared mutable state without synchronization?
5. **Test coverage**: New code paths tested?
6. **Documentation**: New public APIs have Doxygen comments?
7. **Performance**: Unnecessary copies? Right container for expected size?
8. **Backward compatibility**: Changes break existing API users?

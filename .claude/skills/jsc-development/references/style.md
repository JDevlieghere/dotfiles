# WebKit / JSC C++ conventions

`Tools/Scripts/check-webkit-style` enforces the mechanical rules. This file
covers what it can't see. When a rule here conflicts with the surrounding file,
the file wins.

## Naming

- Types, classes, enums, namespaces: `UpperCamelCase`.
- Functions, methods, variables: `lowerCamelCase`. No `get` prefix on simple
  getters — `port()`, not `getPort()`.
- Members: `m_` prefix. File-scope statics and globals: `s_` and `g_`.
- Enumerators are `lowerCamelCase` inside an `enum class`, not `SHOUTY`.
- Prefer full words: `character`, not `ch`. `WebKit` never `Webkit`.
- Booleans read as predicates: `isValid()`, `hasBreakpoints()`, `shouldStop`.

## Headers

- `#pragma once`, never include guards.
- Feature guard immediately after, wrapping the whole file:
  `#if ENABLE(WEBASSEMBLY_DEBUGGER)`.
- In a `.cpp`, `#include "config.h"` first, then the matching header, then
  everything else — project headers in quotes, then system and `<wtf/…>` in
  angle brackets, each group alphabetized.
- Forward-declare in headers rather than including; push includes into the
  `.cpp`.

## Types

WTF, not `std`:

| Need | Use | Not |
| --- | --- | --- |
| Growable array | `Vector<T>`, `Vector<T, N>` for inline capacity | `std::vector` |
| Hash map / set | `HashMap<K, V>`, `HashSet<T>` | `std::unordered_*` |
| String | `String` | `std::string` |
| Non-owning string param | `StringView` | `const char *` |
| String literal | `"text"_s` | `"text"`, `ASCIILiteral` |
| Building strings | `makeString(a, b, c)` | `operator+` chains |
| Optional | `std::optional<T>` | sentinel values |
| Fixed-width ints | `uint8_t`, `uint32_t`, … | `unsigned long` |

- `enum class` with an explicit underlying type (`: uint8_t`) — plain `enum` is
  for legacy code only.
- `auto` only where the type is obvious from the initializer.

## Ownership

- Ref-counted objects: `Ref<T>` when it can't be null, `RefPtr<T>` when it can.
  `adoptRef(new T)` at construction; return `Ref<T>` from factories.
- Sole ownership: `std::unique_ptr<T>` / `UniqueRef<T>` (`makeUnique<T>()`,
  `makeUniqueRef<T>()`).
- Raw pointers only for non-owning references with a clearly shorter lifetime.
  Prefer `CheckedPtr`/`CheckedRef` for non-owning pointers to objects that can
  outlive nothing in particular.
- Heap-allocated classes declare their allocator:
  `WTF_MAKE_TZONE_ALLOCATED(ClassName);` in the header,
  `WTF_MAKE_TZONE_ALLOCATED_IMPL(ClassName);` in the `.cpp`.
- Never `new`/`delete` directly in new code.

## Assertions and errors

- `ASSERT(cond)` — debug-only. `ASSERT_UNUSED(var, cond)` when the only use of
  `var` is the assertion.
- `RELEASE_ASSERT(cond)` — kept in release builds. Use where failure means
  memory unsafety.
- `ASSERT_NOT_REACHED()`, `RELEASE_ASSERT_NOT_REACHED()`.
- `ASSERT_WITH_MESSAGE(cond, "fmt", …)` when the condition isn't self-explaining.
- No exceptions. Report failure with `std::optional`, `Expected<T, E>`, or a
  protocol-level error reply — never by aborting a user-visible operation.

## Logging

- `dataLogLn("…", value, …)` — variadic, no format string, appends a newline.
- `dataLogLnIf(Options::someVerboseOption(), "…")` — the standard gated form.
  Add the gate to `Source/JavaScriptCore/runtime/OptionsList.h`:
  `v(Bool, verboseWasmDebugger, false, Normal, nullptr) \`.
- `WTFLogAlways` only for output that must always appear.

## Concurrency

- `Lock` + `Locker locker { m_lock };`. Annotate with `WTF_GUARDED_BY_LOCK(m_lock)`
  on members and `WTF_REQUIRES_LOCK(m_lock)` on methods — Clang's thread-safety
  analysis is on and will catch mismatches at compile time.
- `Atomic<T>` / `std::atomic<T>` for lock-free state.
- `Ref`/`RefPtr` are not thread-safe unless the object is `ThreadSafeRefCounted`.

## Formatting

`check-webkit-style` covers this; the highlights:

- 4-space indent, no tabs. No hard column limit, but keep lines reasonable.
- Attached braces on functions and classes, `else` on the same line as the
  closing brace.
- Braces omitted for single-statement bodies; if one branch needs them, all do.
- One space around binary operators, none inside parentheses.
- Pointer/reference binds to the type: `Foo* foo`, `Foo& foo`.
- `nullptr`, never `0` or `NULL`.

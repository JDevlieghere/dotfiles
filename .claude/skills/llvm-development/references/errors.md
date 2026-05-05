# Errors and casts

LLVM does not use C++ exceptions. Errors are values.

## `Error` and `Expected<T>`

- `Error` — represents a possibly-failed operation with no successful value. Truthy (`if (Err)`) means **error**.
- `Expected<T>` — success value or error. Truthy (`if (Exp)`) means **success**.

Every `Error` **must** be consumed. An unchecked `Error` aborts the program in debug builds.

### Common patterns

```cpp
// Propagate on failure.
Error doThing() {
  if (Error E = openFile())
    return E;
  ...
  return Error::success();
}

// Expected usage.
Expected<int> parseSize(StringRef S);
if (auto Size = parseSize(Input))
  use(*Size);
else
  return Size.takeError();

// Chain with handleErrors / handleAllErrors when inspecting variants.
handleAllErrors(std::move(Err),
  [](const FileError &FE) { ... },
  [](const ErrorInfoBase &Other) { ... });
```

### `cantFail`

```cpp
auto V = cantFail(computeThing());  // infallible by construction
```

Only valid when the operation is **provably** infallible. In release builds the check is elided; an unexpected error becomes undefined behavior. Never use `cantFail` to "make the error go away" — handle it or propagate.

### `consumeError`

```cpp
consumeError(std::move(Err));
```

Explicitly discards an error. Use when you've intentionally decided the error doesn't matter (e.g., a best-effort cleanup). Don't use this to silence errors you haven't examined.

### `report_fatal_error` / `abort`

- Library code must not call `report_fatal_error` or `abort` for recoverable errors. Return `Error` instead.
- Tools' `main()` may call `report_fatal_error` at top level if the error is truly unrecoverable.

### `llvm::Error` vs `std::error_code`

Prefer `Error`. `std::error_code` appears in older code and at some platform boundaries; convert on the edge.

### LLDB note

LLDB has its own `lldb_private::Status` type. In new LLDB code, prefer LLVM's `Error` / `Expected<T>` over `Status`. `Status` remains where it crosses public SB-API boundaries. See `references/lldb.md`.

## LLVM-style RTTI

Replaces `dynamic_cast`. Works on types that opt in with a `classof` method (most LLVM class hierarchies do).

| Helper | Behavior |
|--------|----------|
| `isa<T>(V)` | `true` if `V` is a `T`. |
| `cast<T>(V)` | Downcast; asserts on failure. Use when you **know** the type. |
| `dyn_cast<T>(V)` | Downcast or `nullptr`. Use when you're testing. |
| `dyn_cast_if_present<T>(V)` | Like `dyn_cast` but accepts `nullptr` input. |
| `isa_and_nonnull<T>(V)` | Like `isa` but handles `nullptr`. |

Idiom:

```cpp
if (auto *I = dyn_cast<LoadInst>(V))
  use(I);
```

Anti-patterns:

- `isa<T>(V)` followed by `cast<T>(V)` — redundant; use `dyn_cast`.
- `dynamic_cast` — we don't use RTTI.
- `static_cast<T*>(V)` to downcast — use `cast<T>`.

## Lifetime hazards

Because `StringRef`, `ArrayRef`, `Twine`, and `function_ref` are non-owning:

- Never return one referring to a local.
- Never store a `Twine` — it can reference stack temporaries inside its concatenation tree.
- Be careful binding a `StringRef` to the result of `std::string + const char *` — `StringRef` on a temporary `std::string` dangles at the next sequence point.

## Thread safety

- Function-local `static` counters and caches need `std::atomic` or a mutex.
- Shared mutable state across threads needs a `std::mutex` or `llvm::sys::Mutex`.
- LLVM has `ManagedStatic<T>` for initialization-order-safe singletons.

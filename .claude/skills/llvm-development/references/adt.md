# ADT: strings and containers

LLVM provides its own string and container types. Prefer them over the `std::` equivalents in almost all cases.

## Strings

| Type | When to use | Notes |
|------|-------------|-------|
| `StringRef` | Function parameters for read-only string views. Pass **by value**. | Non-owning. Must not outlive the backing storage. |
| `Twine` | Parameter type for "concatenable" messages: `const Twine &Msg`. | **Never store.** Evaluate immediately with `.str()` or pass straight through. |
| `SmallString<N>` | Local scratch buffer when you need to own and mutate. `N` is the inline capacity. | Stack-allocated up to `N`, spills to heap beyond. |
| `std::string` | When you genuinely own the string and return or store it. | Fine at API boundaries that need it. |
| `const char *` | Avoid in new code. | Use `StringRef` or `std::string`. |

Rules of thumb:

- Returning a constructed string: `std::string`.
- Taking a string to read: `StringRef`.
- Taking a string to log, format, or concatenate: `const Twine &`.
- Need to mutate locally: `SmallString<N>`.

## Sequence containers

| Type | When to use | Notes |
|------|-------------|-------|
| `SmallVector<T, N>` | Default choice for local variables and members. | Inline `N` elements, spills to heap. Pick `N` based on expected size. |
| `SmallVectorImpl<T> &` | Function parameter type for a mutable vector. | Lets callers pass any `SmallVector<T, N>` without coupling to `N`. |
| `ArrayRef<T>` | Function parameter type for a read-only vector or array. | Non-owning view. Pass by value. |
| `MutableArrayRef<T>` | Read/write view over a caller's buffer. | Non-owning, fixed-length. |
| `std::vector<T>` | Only when an external API demands it. | Prefer `SmallVector` otherwise. |

## Associative containers

| Type | When to use | Notes |
|------|-------------|-------|
| `DenseMap<K, V>` | Default map. | Requires `DenseMapInfo<K>` — provided for integers, pointers, and several LLVM types. |
| `DenseSet<T>` | Default set. | Same traits requirement. |
| `SmallDenseMap<K, V, N>` | Small maps, avoids heap until `N` entries. | |
| `StringMap<V>` | Map keyed by string. | Owns the keys. |
| `SetVector` / `MapVector` | When insertion order must be preserved (deterministic iteration). | Slower than `DenseMap` but reproducible. |
| `SmallPtrSet<T*, N>` | Set of pointers. | Faster than `DenseSet<T*>` for small sets. |
| `std::unordered_map` / `std::unordered_set` | **Never** in new code. | Non-deterministic, bad cache behavior. |
| `std::map` / `std::set` | Only when you need ordered iteration and `MapVector` won't do. | |

Determinism matters: if the iteration order of a map feeds into diagnostics, file output, hashes, or anything user-visible, you need `MapVector`, `SetVector`, or a sort pass. Iterating over `DenseMap` and emitting results produces non-reproducible output.

## Function objects

- `function_ref<Sig>` for non-owning callbacks (like `std::function` but no heap allocation, cannot outlive the target).
- `unique_function<Sig>` when ownership is needed but copying isn't.
- `std::function` only when required by external API.

## ADT helpers worth knowing

- `llvm::zip` / `llvm::zip_equal` — parallel iteration.
- `llvm::enumerate` — index + value, like Python's `enumerate`.
- `llvm::make_early_inc_range` — iterate while erasing.
- `llvm::to_vector(Range)` — materialize a range into a `SmallVector`.
- `llvm::is_contained(Range, V)`, `llvm::find_if`, `llvm::all_of`, `llvm::any_of`, `llvm::none_of`.

If you're hand-rolling one of these, use the helper instead.

## Parameter conventions summary

- Read-only string → `StringRef` by value.
- Concat-able message → `const Twine &`.
- Read-only sequence → `ArrayRef<T>` by value.
- Read/write sequence → `SmallVectorImpl<T> &`.
- Read-only callback → `function_ref<Sig>`.

# Naming

LLVM and LLDB disagree. Pick the convention that matches the project the file lives in, and within a file always match what's already there.

## LLVM

- **Types** (classes, structs, typedefs, enums, type template params): `CamelCase`, upper-first. Example: `TextFileReader`, `ASTContext`.
- **Variables**, including parameters and data members: `CamelCase`, upper-first. Example: `Leader`, `Boats`. No Hungarian prefixes, no `m_` prefix.
- **Functions**: `camelBack`, lower-first. Example: `openFile`, `isFoo`, `runPass`.
- **Enumerators** (unscoped): `CamelCase` with an abbreviated-enum prefix so they read well at the use site. Example: `enum ValueKind { VK_Argument, VK_BasicBlock, VK_Function };`.
- **Enumerators** (scoped enum class): still `CamelCase`, prefix optional.
- **Header guards**: `LLVM_<COMPONENT>_<SUBDIR>_<FILE>_H`. Example: `LLVM_ANALYSIS_UTILS_LOCAL_H`.

## LLDB

- **Types**: `UpperCamelCase`. Same as LLVM.
- **Functions / methods**: `UpperCamelCase`. Example: `GetThread`, `IsAlive`.
- **Variables** (locals, parameters): `snake_case`. Example: `frame_count`, `thread_sp`.
- **Data members**: `m_` prefix + `snake_case`. Example: `m_process_sp`.
- **File-local statics (function-local statics too)**: `s_` prefix + `snake_case`. Example: `static uint32_t s_next_id;`. Use `s_`, not `g_`, for statics inside functions.
- **Globals**: `g_` prefix + `snake_case`. Example: `extern Log *g_log;`.

## Never

- No Hungarian notation (`pFoo`, `iCount`).
- No `m_` in LLVM code outside LLDB.
- No bare `camelBack` for LLDB methods.
- No trailing underscore for members (that's a Google-style pattern, not ours).

## Judgment calls

- A file that sits in `lldb/` but has no existing members and is clearly new LLVM-style infrastructure (e.g. a utility library shared with LLVM) can use LLVM naming. When in doubt, look at neighboring files.
- Acronyms stay fully capitalized in types (`ASTNode`, `URLParser`) but follow the normal function-name rule elsewhere (`parseURL` in LLVM, `ParseURL` in LLDB).

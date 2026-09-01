---
name: jsc-development
description: Building, running, and testing WebKit's JavaScriptCore, plus WebKit C++ conventions. Covers `build-jsc`, running the `jsc` shell, the Wasm debugger test framework (`test-wasm-debugger.py`), `run-javascriptcore-tests`, `check-webkit-style`, and WebKit commit-message format. Load when working in a WebKit checkout, editing files under `Source/JavaScriptCore` or `Source/WTF`, running JSC or Wasm debugger tests, or answering questions about WebKit coding style.
---

# JavaScriptCore development

All commands run from the WebKit checkout root (`~/WebKit/OpenSource`), which is
where `Tools/`, `Source/`, and `JSTests/` live.

## Building

```bash
Tools/Scripts/build-jsc --debug     # products land in WebKitBuild/Debug
Tools/Scripts/build-jsc --release   # WebKitBuild/Release
```

Debug is the default for debugger work — assertions on, and IPInt/LLInt state is
inspectable.

Builds take a long time. Kick one off **eagerly and in the background** with
`run_in_background: true` as soon as you know you'll need it, and keep editing
while it runs. Re-trigger after the last edit for a clean signal. The harness
notifies you when it finishes, so don't poll or sleep. Only block on it when you
need the result.

## Running jsc

The shell needs the framework path set:

```bash
DYLD_FRAMEWORK_PATH=WebKitBuild/Debug WebKitBuild/Debug/jsc foo.js
```

Or let the wrapper do it (defaults to Release; `--debugger` runs under LLDB):

```bash
Tools/Scripts/run-jsc foo.js
```

Useful `jsc` flags: `-d` (dump bytecode + disassembly), `-s` (synchronous
compilation), `-e '<code>'`, `-m` (module), `--useDollarVM=1` (enables `$vm`).
`jsc --options` lists every runtime option.

## Testing

### Wasm debugger tests

The primary suite for Wasm debugging work — drives a real `jsc` process and a
real LLDB against each other:

```bash
./JSTests/wasm/debugger/test-wasm-debugger.py -p --debug
```

- `-p` / `--parallel [N]` — one worker per test, each on its own port. Omit `N`
  to auto-detect. Sequential (no `-p`) is the mode to use when debugging a
  single failure; its output is not interleaved.
- `--debug` / `--release` — pick the build. Without one, it takes whichever of
  `WebKitBuild/Debug` or `WebKitBuild/Release` has a `jsc`, preferring Debug.
- `-t NAME` — run one test case (repeatable). `-l` lists them.
- `-v` — print all JSC and LLDB output. `--verbose-wasm-debugger` additionally
  passes `--verboseWasmDebugger=1` to JSC for server-side packet tracing.

LLDB comes from `xcrun --find lldb`. Wasm debugging needs a recent LLDB; if the
Xcode one is too old, put a locally built `llvm-project` LLDB earlier in the
`xcrun` path or fix `JSTests/wasm/debugger/lib/environment.py`.

Test cases live in `JSTests/wasm/debugger/tests/` and are auto-discovered — a
new class in that directory needs no registration. Each drives an LLDB session
and asserts on output substrings:

```python
self.session.cmd("b add")
self.session.cmd("c", patterns=["Process 1 stopped", "stop reason = breakpoint", "add.c:2"])
```

Note: `JSTests/wasm/debugger/README.md` is stale in places (it describes a
`lib/core/` layout and a hardcoded LLDB path that no longer exist). Trust the
code and `--help` over it.

### C++ debug-server unit tests

```bash
DYLD_FRAMEWORK_PATH=WebKitBuild/Debug WebKitBuild/Debug/testwasmdebugger
```

Sources in `Source/JavaScriptCore/wasm/debugger/tests/`. These exercise the
server in-process, without LLDB, so they're much faster than the Python suite —
run them first when the change is server-side.

### Full JSC suite

```bash
Tools/Scripts/run-javascriptcore-tests --debug
```

Very long. Narrow it with the `--[no-]` toggles per test family (`--testmasm`,
`--testb3`, `--testapi`, `--testwasmdebugger`, `--jsc-stress`, …), e.g.
`--no-jsc-stress --no-mozilla-tests`. For a single stress test, invoke
`Tools/Scripts/run-jsc-stress-tests` directly.

Cheapest first: `testwasmdebugger` → `test-wasm-debugger.py` → the relevant
`run-javascriptcore-tests` families. Stop and investigate at the first failure
rather than running everything and sorting through the output.

## Style

```bash
Tools/Scripts/check-webkit-style          # checks the working-tree diff
Tools/Scripts/check-webkit-style path/…   # checks specific files
```

Run it before handing work back. It catches most mechanical violations. See
`references/style.md` for the conventions it can't check — WTF types, smart
pointer discipline, assertion macros, `ENABLE()` guards.

WebKit style is **not** LLVM style. If the `llvm-development` skill is also
loaded, this one wins inside a WebKit tree.

## Commit messages

WebKit's format, which the pre-commit hooks and `git-webkit` expect:

```
[JSC] Short imperative summary
https://bugs.webkit.org/show_bug.cgi?id=NNNNNN
rdar://NNNNNNNNN

Reviewed by NOBODY (OOPS!).

Body explaining why, wrapped at ~72 columns.

* Source/JavaScriptCore/wasm/debugger/WasmQueryHandler.cpp:
(JSC::Wasm::QueryHandler::handleWasmGlobal):
* Source/JavaScriptCore/wasm/debugger/WasmQueryHandler.h:
```

- Subject gets a component prefix in brackets (`[JSC]`, `[WTF]`, `[css-sizing]`).
- Bug URL and `rdar://` go on their own lines directly under the subject.
- `Reviewed by NOBODY (OOPS!).` is literal — the merge queue rewrites it.
- The trailing file list names each touched file, with changed function names
  in parentheses beneath it. `git-webkit` generates it; keep it accurate if you
  edit by hand.

## References

- `references/style.md` — WebKit C++ conventions: naming, WTF containers and
  strings, `Ref`/`RefPtr`/`CheckedPtr`, assertions, logging, headers.
- `references/wasm-debugger.md` — map of the Wasm debug server: components,
  virtual addresses, the GDB remote packets it speaks, threading.

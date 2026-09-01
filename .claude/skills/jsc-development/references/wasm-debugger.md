# Wasm debug server

`Source/JavaScriptCore/wasm/debugger/` — a GDB Remote Serial Protocol server
that lets LLDB debug WebAssembly running in JSC's IPInt interpreter. Guarded by
`ENABLE(WEBASSEMBLY_DEBUGGER)`.

Longer docs live next to the code and are kept current by the people changing
it: `README.md`, `RWI_ARCHITECTURE.md`, `Debugger-Mutator-Protocol.md`.

## Components

| File | Role |
| --- | --- |
| `WasmDebugServer` | Singleton coordinator. Owns the socket, parses packets, routes to handlers. |
| `WasmExecutionHandler` | Breakpoints, continue, step, interrupt, stop replies. |
| `WasmMemoryHandler` | Memory read/write, memory region info. |
| `WasmQueryHandler` | `q…` packets: capability negotiation, locals, globals, call stack. |
| `WasmModuleManager` | Tracks live modules and instances; owns the virtual address space. |
| `WasmBreakpointManager` | Breakpoint storage. Patches module bytecode, which every instance of a module shares. |
| `WasmVirtualAddress` | The 64-bit address encoding LLDB sees. |
| `WasmGDBPacketParser` | Incremental packet framing off the socket. |

## Virtual addresses

LLDB needs flat 64-bit addresses; Wasm has none. `VirtualAddress` synthesizes
them:

```
bits 63-62  type: 0 = Memory (instance linear memory), 1 = Module (code), 2/3 = invalid
bits 61-32  id:   InstanceID for Memory, ModuleID for Module
bits 31-0   offset
```

So module code starts at `0x4000000000000000` and instance memory at
`0x0000000000000000`. A module id in bits 61:32 is how a code address names its
module — that's the id `qWasmGlobal:…;instance:<id>` carries.

One module can have several live instances, and they share code but not
globals or memory. Anything that maps an address back to an instance has to
handle that ambiguity explicitly rather than picking the first instance.

## Packets

Queries handled: `qSupported`, `qHostInfo`, `qProcessInfo`, `qRegisterInfo`,
`qThreadStopInfo`, `qMemoryRegionInfo:`, `qXfer:libraries:read::`,
`qWasmCallStack:`, `qWasmLocal:`, `qWasmGlobal:`, plus the `qWasmInstance+`
capability. Execution and memory packets (`c`, `s`, `Z`/`z`, `m`/`M`, `?`) go to
their respective handlers.

The Wasm extensions are specified at
<https://lldb.llvm.org/resources/lldbgdbremote.html#wasm-packets>. When adding a
packet form, gate it behind a `qSupported` capability so an older client keeps
the old behavior, and make the two forms distinguishable on the wire.

Never default an unparsable field to a plausible value — `parseDecimal()`
returning 0 for garbage turns a malformed packet into a confidently wrong
answer. Reply with a protocol error instead.

## Two modes

- **Standalone** — TCP server, default port 1234, for the `jsc` shell.
  `jsc --wasm-debugger --useConcurrentJIT=0 main.js`, then
  `lldb -o 'process connect --plugin wasm connect://localhost:1234'`.
- **RWI** — IPC through Remote Web Inspector, for debugging WebContent. See
  `RWI_ARCHITECTURE.md`.

## Debugging the debugger

Server-side packet trace:

```bash
VM=WebKitBuild/Debug
DYLD_FRAMEWORK_PATH=$VM $VM/jsc --verboseWasmDebugger=1 --wasm-debugger --useConcurrentJIT=0 main.js
```

Client-side packet trace: `lldb -o 'log enable gdb-remote packets' …`.

To run the whole thing under a debugger, launch `jsc` inside LLDB and connect a
second LLDB to the port.

## Tests

- `WebKitBuild/Debug/testwasmdebugger` — in-process C++ tests, sources in
  `wasm/debugger/tests/`. Fast; run these first for server-side changes.
- `JSTests/wasm/debugger/test-wasm-debugger.py` — end-to-end, drives a real
  LLDB against a real `jsc`. See the main SKILL.md for invocation.

Test fixtures under `JSTests/wasm/debugger/resources/` (`c-wasm/`,
`swift-wasm/`, `wasm/`) are prebuilt `.wasm` plus the `main.js` that loads them.

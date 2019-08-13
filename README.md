# subhook.nim
subhook wrapper for Nim https://github.com/Zeex/subhook

### Usage

```nim
import subhook, subhook/helpers


proc recv(s: SOCKET, buf: cstring, len: int32, flags: int32): int32 {.fptr.} = 0x123456

proc MY_recv(s: SOCKET, buf: cstring, len: int32, flags: int32): int32 {.stdcall.} =
  discard

let hook = initHook(recv, MY_recv)
if hook.install() != 0:
  quit "Unable to install revc hook"
```
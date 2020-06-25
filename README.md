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

Trampoline example:
```nim
import subhook

proc add2(a, b: int): int =
  result = a + b
  echo "add2 result = ", result

var addHook: Hook
proc double_add2(a, b: int): int =
  echo "add called"
  result = cast[typeof(add2)](addHook.getTrampoline())(a, b) * 2


addHook = initHook(add2, double_add2, true)

assert add2(1, 3) == 8
```
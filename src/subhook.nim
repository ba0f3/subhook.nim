import os

{.compile: "private/subhook/subhook.c".}
{.passC: "-DSUBHOOK_STATIC".}
{.pragma: subhook,
  cdecl,
  importc,
  header: parentDir(currentSourcePath()) & "/private/subhook/subhook.h"
  discardable
.}


type
  subhook_flags* {.pure.} = enum
    NONE
    SUBHOOK_64BIT_OFFSET = 1
  Hook* = ptr subhook_struct
  subhook_struct* {.bycopy.} = object
    installed*: int
    src*: pointer
    dst*: pointer
    flags*: subhook_flags
    code*: pointer
    trampoline*: pointer
    jmp_size*: csize
    trampoline_size*: csize
    trampoline_len*: csize
  subhook_t* = ptr subhook_struct

#[ C API ]#
proc subhook_new*(src, dst: pointer, flags: subhook_flags): subhook_t {.subhook.}
proc subhook_free*(hook: subhook_t) {.subhook.}
proc subhook_get_src*(hook: subhook_t): pointer {.subhook.}
proc subhook_get_dst*(hook: subhook_t): pointer {.subhook.}
proc subhook_get_trampoline*(hook: subhook_t): pointer {.subhook.}
proc subhook_install*(hook: subhook_t): cint {.subhook.}
proc subhook_is_installed*(hook: subhook_t): cint {.subhook.}
proc subhook_remove*(hook: subhook_t): cint {.subhook.}


#[ High level templates ]#
template initHook*(src, dest: pointer, flags: subhook_flags = NONE): Hook = subhook_new(src, dest, flags)
template initHook*(src, dest: int, flags = NONE): Hook = subhook_new(cast[pointer](src), cast[pointer](dest), flags)
template initHook*(src: pointer, dest: int, flags = NONE): Hook = initHook(src, cast[pointer](dest), flags)
template initHook*(src: int, dest: pointer, flags = NONE): Hook = initHook(cast[pointer](src), dest, flags)
template free*(hook: Hook) = subhook_free(hook)
template getSource*(hook: Hook): pointer = subhook_get_src(hook)
template getDest*(hook: Hook): pointer = subhook_get_dst(hook)
template getTrampoline*(hook: Hook): pointer = subhook_get_trampoline(hook)
template install*(hook: Hook): int = subhook_install(hook)
template isInstalled*(hook: Hook): bool = subhook_is_installed(hook) > 0
template remove*(hook: Hook): int = subhook_remove(hook)


when isMainModule:
  import strformat

  var hook: Hook

  proc foo(x: int): int =
    result = x * x
    echo &"foo({x}) = {result}"

  proc bar(x: int): int =
    echo &"bar({x}) called"
    hook.remove()
    result = foo(x)
    hook.install()

  proc foobar(x: int): int =
    result = x * 2
    echo &"foobar({x}) = {result}"

  hook = initHook(foo, bar)
  hook.install()

  assert foo(3) == 9

  hook.remove()
  hook.free()

  var foobar_hook = initHook(foo, foobar)
  foobar_hook.install()

  assert foo(3) == 6

  foobar_hook.remove()
  foobar_hook.free()
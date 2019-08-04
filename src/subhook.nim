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

proc subhook_new(src, dst: pointer, flags: subhook_flags): subhook_t {.subhook.}
proc subhook_free(hook: subhook_t) {.subhook.}
proc subhook_get_src(hook: subhook_t): pointer {.subhook.}
proc subhook_get_dst(hook: subhook_t): pointer {.subhook.}
proc subhook_get_trampoline(hook: subhook_t): pointer {.subhook.}
proc subhook_install(hook: subhook_t): cint {.subhook.}
proc subhook_is_installed(hook: subhook_t): cint {.subhook.}
proc subhook_remove(hook: subhook_t): cint {.subhook.}


type
  Hook* = ptr subhook_struct

proc initHook*(src, dest: pointer, flags: subhook_flags = NONE): Hook {.inline.} =
  result = subhook_new(src, dest, flags)

proc initHook*(src, dest: int, flags = NONE): Hook  {.inline.} =
  result = subhook_new(cast[pointer](src), cast[pointer](dest), flags)

proc initHook*(src: pointer, dest: int, flags = NONE): Hook {.inline.} =
  initHook(src, cast[pointer](dest), flags)

proc initHook*(src: int, dest: pointer, flags = NONE): Hook {.inline.} =
  initHook(cast[pointer](src), dest, flags)

proc free*(hook: Hook) {.inline.} =
  subhook_free(hook)

proc getSource*(hook: Hook): pointer {.inline.} =
  subhook_get_src(hook)

proc getDest*(hook: Hook): pointer {.inline.} =
  subhook_get_dst(hook)

proc getTrampoline*(hook: Hook): pointer {.inline.} =
  subhook_get_trampoline(hook)

proc install*(hook: Hook): int {.inline, discardable.} =
  subhook_install(hook)

proc isInstalled*(hook: Hook): int {.inline.} =
  subhook_is_installed(hook)

proc remove*(hook: Hook): int {.inline, discardable.} =
  subhook_remove(hook)


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



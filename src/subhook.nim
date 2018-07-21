{.compile: "private/subhook/subhook.c".}

{.pragma: subhook,
  cdecl,
  importc,
  discardable
.}


type
  subhook_t* {.final, pure.} = object

proc subhook_new(src, dst: pointer, options: int): ptr subhook_t {.subhook.}
proc subhook_free(hook: ptr subhook_t) {.subhook.}
proc subhook_get_src(hook: ptr subhook_t): pointer {.subhook.}
proc subhook_get_dst(hook: ptr subhook_t): pointer {.subhook.}
proc subhook_get_trampoline(hook: ptr subhook_t): pointer {.subhook.}
proc subhook_install(hook: ptr subhook_t): cint {.subhook.}
proc subhook_is_installed(hook: ptr subhook_t): cint {.subhook.}
proc subhook_remove(hook: ptr subhook_t): cint {.subhook.}


type
  Hook* = object
    impl: ptr subhook_t

proc initHook*(src, dest: pointer, options = 0): Hook {.inline.} =
  result.impl = subhook_new(src, dest, options)

proc initHook*(src, dest: int, options = 0): Hook {.inline.} =
  initHook(cast[pointer](src), cast[pointer](dest), options)

proc initHook*(src: pointer, dest: int, options = 0): Hook {.inline.} =
  initHook(src, cast[pointer](dest), options)

proc initHook*(src: int, dest: pointer, options = 0): Hook {.inline.} =
  initHook(cast[pointer](src), dest, options)

proc free*(hook: Hook) {.inline.} =
  subhook_free(hook.impl)

proc getSource*(hook: Hook): pointer {.inline.} =
  subhook_get_src(hook.impl)

proc getDest*(hook: Hook): pointer {.inline.} =
  subhook_get_dst(hook.impl)

proc getTrampoline*(hook: Hook): pointer {.inline.} =
  subhook_get_trampoline(hook.impl)

proc install*(hook: Hook): int {.inline, discardable.} =
  subhook_install(hook.impl)

proc isInstalled*(hook: Hook): int {.inline.} =
  subhook_is_installed(hook.impl)

proc remove*(hook: Hook): int {.inline, discardable.} =
  subhook_remove(hook.impl)


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



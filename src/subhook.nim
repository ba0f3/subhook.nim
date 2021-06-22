{.compile: "private/subhook/subhook.c".}
{.passC: "-DSUBHOOK_STATIC".}
{.pragma: subhook,
  cdecl,
  importc,
  discardable
.}


type
  subhook_flags* {.pure.} = enum
    NONE
    SUBHOOK_64BIT_OFFSET = 1
  Hook* = subhook_t
  subhook_t* {.bycopy, pure.} = ptr object
    installed*: int
    src*: pointer
    dst*: pointer
    flags*: subhook_flags
    code*: pointer
    trampoline*: pointer
    jmp_size*: csize_t
    trampoline_size*: csize_t
    trampoline_len*: csize_t

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
proc initHook*(src, dest: pointer, install = false, flags: subhook_flags = NONE): Hook =
  result = subhook_new(src, dest, flags)
  if install:
    subhook_install(result)

template free*(hook: Hook) =
  subhook_free(hook)
  hook = nil
template getSource*(hook: Hook): pointer = subhook_get_src(hook)
template getDest*(hook: Hook): pointer = subhook_get_dst(hook)
template getTrampoline*(hook: Hook): pointer = subhook_get_trampoline(hook)
template install*(hook: Hook): int = subhook_install(hook)
template isInstalled*(hook: Hook): bool = subhook_is_installed(hook) > 0
template remove*(hook: Hook): int = subhook_remove(hook)

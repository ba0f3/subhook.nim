import os

{.compile: "private/subhook/subhook.c".}
{.passC: "-DSUBHOOK_STATIC".}
{.pragma: subhook,
  cdecl,
  importc,
  header: parentDir(currentSourcePath()) & "/private/subhook/subhook.h",
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
template free*(hook: Hook) = subhook_free(hook)
template getSource*(hook: Hook): pointer = subhook_get_src(hook)
template getDest*(hook: Hook): pointer = subhook_get_dst(hook)
template getTrampoline*(hook: Hook): pointer = subhook_get_trampoline(hook)
template install*(hook: Hook): int = subhook_install(hook)
template isInstalled*(hook: Hook): bool = subhook_is_installed(hook) > 0
template remove*(hook: Hook): int = subhook_remove(hook)

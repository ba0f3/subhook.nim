import macros, random, tables

converter toPointer*(x: int): pointer = cast[pointer](x)

proc fnv32a*[T: string|openArray[char]|openArray[uint8]|openArray[int8]](data: T): int32 =
  result = -18652613'i32
  for b in items(data):
    result = result xor ord(b).int32
    result = result *% 16777619

var
  #nameToProc {.compileTime.} = initTable[string, string]()
  nameToPointer {.compileTime.} = initTable[string, string]()
  seed {.compileTime.} = fnv32a(CompileTime & CompileDate) and 0x7FFFFFFF
  r {.compileTime.} = initRand(seed)

macro faddr*(body: untyped): untyped =
  var name = ident(nameToPointer[$body.toStrLit])
  result = quote do:
    addr `name`

macro fptr*(body: untyped) : untyped =
  ## this marco will create a proc type based on input
  ## and then create a proc pointer to an address if specified
  if body.kind != nnkProcDef:
    return

  var
    name, ptrName, procName: string
    isExported = false
  if body[0].kind == nnkIdent:
    name = $body[0]
  else:
    #[
      #echo treeRepr body[0]
    if body[0].kind == nnkAccQuoted:
      name = $body[0][0]
    else:
      name = $body[0][1]
    ]#
    name = $body[0][1]
    isExported = true
  var suffix = "_" & $r.next()
  procName = "proc_" & name & suffix
  ptrName = "var_" & name & suffix
  #nameToProc[name] = procName
  if (nameToPointer.hasKey(name)):
    echo name & " is already defined, this may causes hooking to wrong address"
  else:
    nameToPointer[name] = ptrName
  var
    typeSection = newNimNode(nnkTypeSection)
    typeDef = newNimNode(nnkTypeDef)
    varSection = newNimNode(nnkVarSection)
    identDef = newNimNode(nnkIdentDefs)
    aliasProc = newProc(ident(name))
    pragma = newNimNode(nnkPragma)

  typeSection.add(typeDef)
  varSection.add(identDef)

  # pragma
  if body[4].kind == nnkPragma:
    pragma = body[4]
  else:
    pragma.add(ident("noconv"))

  if isExported:
    typeDef.add(postfix(ident(procName), "*"))
  else:
    typeDef.add(ident(procName))
  typeDef.add(newEmptyNode())
  typeDef.add(newNimNode(nnkProcTy)
    .add(body[3]) # FormalParams
    .add(pragma) # pragmas
  )
  result = newStmtList(typeSection)

  if body[6].kind == nnkStmtList and body[6][0].kind == nnkIntLit:
    if isExported:
      identDef.add(postfix(ident(ptrName), "*"))
      aliasProc.name = postfix(ident(name), "*")
    else:
      identDef.add(ident(ptrName))


    identDef.add(newEmptyNode())
    identDef.add(newNimNode(nnkCast)
      .add(ident(procName))
      .add(body[6][0])
    )

    var aliasProcBody = newCall(ident(ptrName))
    for param in body[3]:
      if param.kind == nnkIdentDefs:
        aliasProcBody.add(param[0])

    aliasProc.params = body[3]
    aliasProc.addPragma(ident("inline"))
    aliasProc.body = aliasProcBody

    result.add(varSection)
    result.add(aliasProc)
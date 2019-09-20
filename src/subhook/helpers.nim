import macros

converter toPointer*(x: int): pointer = cast[pointer](x)

macro fptr*(body: untyped) : untyped =
  ## this marco will create a proc type based on input
  ## and then create a proc pointer to an address if specified
  if body.kind != nnkProcDef:
    return

  var
    name, procName: string
    isExported = false
  if body[0].kind == nnkIdent:
    name = $body[0]
  else:
    name = $body[0][1]
    isExported = true
  procName = name & "Proc"
  var
    typeSection = newNimNode(nnkTypeSection)
    typeDef = newNimNode(nnkTypeDef)
    varSection = newNimNode(nnkVarSection)
    identDef = newNimNode(nnkIdentDefs)
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
      identDef.add(postfix(ident(name), "*"))
    else:
      identDef.add(ident(name))
    identDef.add(newEmptyNode())
    identDef.add(newNimNode(nnkCast)
      .add(ident(procName))
      .add(body[6][0])
    )
    result.add(varSection)
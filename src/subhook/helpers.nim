import macros

macro fptr*(body: untyped) : untyped =
  ## this marco will create a proc type based on input
  ## and then create a proc pointer to an address if specified
  if body.kind != nnkProcDef:
    return
  let
    name = $body[0]
    procName = name & "Proc"
  var
    typeSection = newNimNode(nnkTypeSection)
    typeDef = newNimNode(nnkTypeDef)
    letSection = newNimNode(nnkLetSection)
    identDef = newNimNode(nnkIdentDefs)

  typeSection.add(typeDef)
  letSection.add(identDef)

  typeDef.add(postfix(ident(procName), "*"))
  typeDef.add(newEmptyNode())
  typeDef.add(newNimNode(nnkProcTy)
    .add(body[3]) # FormalParams
    .add(newNimNode(nnkPragma).add(ident("noconv"))) # {.noconv.}
  )
  result = newStmtList(typeSection)

  if body[6].kind == nnkStmtList and body[6][0].kind == nnkIntLit:
    identDef.add(postfix(ident(name), "*"))
    identDef.add(newEmptyNode())
    identDef.add(newNimNode(nnkCast)
      .add(ident(procName))
      .add(body[6][0])
    )
    result.add(letSection)
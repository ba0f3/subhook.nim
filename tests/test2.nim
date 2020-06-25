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
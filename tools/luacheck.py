#!/usr/bin/env python3
"""Parse-check Lua files with a bundled Lua runtime.

    pip install lupa
    python tools/luacheck.py Mods/ZC_Endless/Scripts/*.lua

Exit code is non-zero if any file fails to compile. This checks syntax only, with
Lua 5.5 (lupa's bundled runtime); UE4SS runs LuaJIT/5.1, so avoid 5.2+-only syntax.
"""

import sys

try:
    import lupa
except ImportError:
    sys.exit("lupa not installed:  pip install lupa")

lua = lupa.LuaRuntime(unpack_returned_tuples=True)
check = lua.eval("""
    function(src, name)
        local f, e = load(src, name)
        if f then return 'OK', '' else return 'FAIL', tostring(e) end
    end
""")

bad = 0
for path in sys.argv[1:]:
    with open(path, encoding="utf-8") as fh:
        src = fh.read()
    status, err = check(src, "@" + path)
    if status == "OK":
        print("OK    " + path)
    else:
        bad += 1
        print("FAIL  " + path + "\n      " + err)

sys.exit(1 if bad else 0)

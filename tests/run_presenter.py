"""Presenter panel tests: the real panel file driven through a fake ReaImGui and a fake REAPER.

From the repo root:   python3 tests/run_presenter.py          (needs Python 3 and `pip install lupa`)
Each Lua test (tests/presenter_test.lua) runs in a fresh Lua runtime; the paste-kit tests are in Python."""
import os
import sys

import lupa.lua54 as lupa

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
PANEL = os.environ.get("PRESENTER_SRC") or os.path.join(ROOT, "Presenter", "Presenter panel.lua")

passed = failed = 0


def report(name, err):
    global passed, failed
    if err is None:
        passed += 1
        print("  ok    " + name)
    else:
        failed += 1
        print("  FAIL  %s\n        %s" % (name, str(err).replace("\n", "\n        ")))


def lua_tests():
    loader = "return assert(loadfile(HERE_ARG .. '/presenter_test.lua'))(HERE_ARG, PANEL_ARG)"
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    lua.globals().HERE_ARG, lua.globals().PANEL_ARG = HERE, PANEL
    tests = lua.execute(loader)
    names = [tests[i + 1].name for i in range(len(tests))]
    for i, name in enumerate(names):
        rt = lupa.LuaRuntime(unpack_returned_tuples=True)   # fresh runtime: every test starts from nothing
        rt.globals().HERE_ARG, rt.globals().PANEL_ARG = HERE, PANEL
        try:
            rt.execute(loader)[i + 1].fn()
            report(name, None)
        except lupa.LuaError as e:
            report(name, e)


def main():
    print("Presenter panel (%s)" % os.path.relpath(PANEL, ROOT))
    lua_tests()
    import test_paste_kit
    for name, err in test_paste_kit.run(ROOT):
        report(name, err)
    print("\n%d passed, %d failed" % (passed, failed))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.path.insert(0, HERE)
    sys.exit(main())

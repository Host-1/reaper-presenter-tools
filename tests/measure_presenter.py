"""Prints the vertical-space table: python3 tests/measure_presenter.py [panel.lua]   (default: the real panel)."""
import os
import sys
import lupa.lua54 as lupa

HERE = os.path.dirname(os.path.abspath(__file__))
PANEL = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(HERE), "Presenter", "Presenter panel.lua")


def main():
    print("panel: " + PANEL)
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    lua.globals().HERE_ARG, lua.globals().PANEL_ARG = HERE, PANEL
    specs = lua.execute("return assert(loadfile(HERE_ARG .. '/measure.lua'))(HERE_ARG, PANEL_ARG).sessions()")
    for i in range(len(specs)):
        rt = lupa.LuaRuntime(unpack_returned_tuples=True)
        rt.globals().HERE_ARG, rt.globals().PANEL_ARG, rt.globals().N = HERE, PANEL, i + 1
        tb, body = rt.execute("local M = assert(loadfile(HERE_ARG .. '/measure.lua'))(HERE_ARG, PANEL_ARG); return M.measure(M.sessions()[N])")
        name = specs[i + 1].name
        print("  %-42s toolbar %4d px   scrolling body %5d px" % (name, tb or -1, body or -1))


main()

"""Paste-kit tests: the parts are small enough, and the REAL launcher (run under a fake REAPER) puts them back
together byte for byte -- for the real file at the real limit and at a small limit that forces many parts --
and reports cut-off, missing and mixed-version parts."""
import os
import re
import shutil
import sys
import tempfile

import lupa.lua54 as lupa




def _load_kit(root):
    import importlib.util
    spec = importlib.util.spec_from_file_location("make_paste_kit", os.path.join(root, "extras", "make_paste_kit.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def run_launcher(root, folder):
    """Run the real launcher from `folder`. Returns (joined script or None, message boxes)."""
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    lua.globals().FOLDER = folder.replace("\\", "/") + "/"
    lua.globals().LAUNCHER = os.path.join(root, "extras", "paste-kit", "Presenter_panel_launcher.lua")
    lua.execute("""
        MSGS, CAPTURED = {}, nil
        reaper = {
          get_action_context = function() return true, FOLDER .. 'Presenter_panel_launcher.lua' end,
          EnumerateFiles = function(dir, i) return PYFILES[i + 1] end,
          MB = function(m) MSGS[#MSGS + 1] = m return 1 end,
        }
        load = function(s, name) CAPTURED = s return function() end end   -- capture the script instead of running it
    """)
    lua.globals().PYFILES = lua.table_from(sorted(f for f in os.listdir(folder) if f.endswith(".txt")))
    lua.execute("local f = assert(loadfile(LAUNCHER)); f()")
    msgs = [lua.eval("MSGS[%d]" % (i + 1)) for i in range(int(lua.eval("#MSGS")))]
    captured = lua.eval("CAPTURED")
    return captured, msgs


def kit_in(root, limit=None):
    kit = _load_kit(root)
    with open(os.path.join(root, "Presenter", "Presenter panel.lua"), encoding="utf-8", newline="") as f:
        src = f.read()
    version = re.search(r"-- @version (\S+)", src).group(1)
    texts = kit.split(src, limit) if limit else kit.split(src)
    files = kit.render(texts, version)
    folder = tempfile.mkdtemp(prefix="kit_")
    shutil.copy(os.path.join(root, "extras", "paste-kit", "Presenter_panel_launcher.lua"), folder)
    for name, text in files.items():
        with open(os.path.join(folder, name), "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
    return src, files, folder


def run(root):
    results = []

    def case(name, fn):
        try:
            fn()
            results.append((name, None))
        except Exception as e:  # noqa
            results.append((name, e))

    def t_sizes():
        _, files, folder = kit_in(root)
        shutil.rmtree(folder)
        assert files, "no parts"
        for n, t in files.items():
            assert len(t.encode()) < 95 * 1000, "%s is %d bytes (cap 95 KB)" % (n, len(t.encode()))

    def t_roundtrip():
        src, files, folder = kit_in(root)
        try:
            got, msgs = run_launcher(root, folder)
            assert not msgs, msgs
            assert got.encode("utf-8") == src.encode("utf-8"), "rebuilt script differs from the source"
        finally:
            shutil.rmtree(folder)

    def t_many_parts():
        src, files, folder = kit_in(root, limit=12 * 1024)
        try:
            assert len(files) >= 10, "expected many parts, got %d" % len(files)
            got, msgs = run_launcher(root, folder)
            assert not msgs, msgs
            assert got.encode("utf-8") == src.encode("utf-8"), "rebuilt script differs from the source (%d parts)" % len(files)
        finally:
            shutil.rmtree(folder)

    def t_cut_end():
        _, files, folder = kit_in(root, limit=40 * 1024)
        try:
            p = os.path.join(folder, "Presenter_panel_part_2.txt")
            t = open(p, encoding="utf-8", newline="").read()
            open(p, "w", encoding="utf-8", newline="").write(t[: len(t) - 300])
            got, msgs = run_launcher(root, folder)
            assert got is None and msgs and "Part 2" in msgs[0] and "last line" in msgs[0], msgs
        finally:
            shutil.rmtree(folder)

    def t_cut_start():
        _, files, folder = kit_in(root, limit=40 * 1024)
        try:
            p = os.path.join(folder, "Presenter_panel_part_3.txt")
            t = open(p, encoding="utf-8", newline="").read()
            open(p, "w", encoding="utf-8", newline="").write(t.split("\n", 1)[1])
            got, msgs = run_launcher(root, folder)
            assert got is None and msgs and "Part 3" in msgs[0] and "first line" in msgs[0], msgs
        finally:
            shutil.rmtree(folder)

    def t_missing():
        _, files, folder = kit_in(root, limit=40 * 1024)
        try:
            os.remove(os.path.join(folder, "Presenter_panel_part_2.txt"))
            got, msgs = run_launcher(root, folder)
            assert got is None and msgs and "part2" in msgs[0], msgs
        finally:
            shutil.rmtree(folder)

    def t_version_mix():
        _, files, folder = kit_in(root, limit=40 * 1024)
        try:
            p = os.path.join(folder, "Presenter_panel_part_2.txt")
            t = open(p, encoding="utf-8", newline="").read()
            open(p, "w", encoding="utf-8", newline="").write(re.sub(r"START (\S+) ", "START 0.0 ", t, count=1))
            got, msgs = run_launcher(root, folder)
            assert got is None and msgs and "different versions" in msgs[0], msgs
        finally:
            shutil.rmtree(folder)

    case("paste kit: every part is under 95 KB", t_sizes)
    case("paste kit: the real launcher rebuilds the panel byte for byte (real limit)", t_roundtrip)
    case("paste kit: byte for byte with 10+ parts (small limit)", t_many_parts)
    case("paste kit: a part cut off at the end is reported", t_cut_end)
    case("paste kit: a part cut off at the start is reported", t_cut_start)
    case("paste kit: a missing part is reported", t_missing)
    case("paste kit: parts from different versions are reported", t_version_mix)
    return results

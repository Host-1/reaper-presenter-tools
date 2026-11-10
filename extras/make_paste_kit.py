"""
Builds the "paste kit": the Presenter panel split into as many parts as it needs, each under
~95 KB, for machines (e.g. a VM) whose clipboard cuts off pastes longer than ~100 KB.

    python extras/make_paste_kit.py

Writes extras/paste-kit/Presenter_panel_part_1.txt ... _part_N.txt from
Presenter/Presenter panel.lua. Paste those files and Presenter_panel_launcher.lua into one
folder on the other machine and load the launcher as the REAPER action. Each part starts and
ends with a check line, so the launcher can tell if a paste was cut off at either end.
The first line of every part carries the version and the number of parts.
"""
import glob
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "..", "Presenter", "Presenter panel.lua")
OUT = os.path.join(HERE, "paste-kit")
LIMIT = 90 * 1024          # bytes of script per part; check lines add ~60 bytes; the hard cap is 95 KB


def split(src, limit=LIMIT):
    """Cut src into chunks of at most `limit` bytes, each cut at a blank line before a top-level block."""
    lines = src.split("\n")
    chunks, cur, size = [], [], 0
    for i, line in enumerate(lines):
        b = len(line.encode()) + 1
        if size + b > limit and cur:
            # back up to the last boundary inside cur so the cut is between blocks
            for j in range(len(cur) - 1, 0, -1):
                if cur[j] == "" and re.match(r"^(local function|function|local |--)", cur[j + 1] if j + 1 < len(cur) else line):
                    chunks.append(cur[:j + 1])
                    cur = cur[j + 1:]
                    size = sum(len(x.encode()) + 1 for x in cur)
                    break
            else:
                raise SystemExit("no block boundary found within %d bytes" % limit)
        cur.append(line)
        size += b
    chunks.append(cur)
    texts = ["\n".join(c) + "\n" for c in chunks[:-1]] + ["\n".join(chunks[-1])]
    assert "".join(texts) == src
    return texts


def render(texts, version):
    n = len(texts)
    files = {}
    for k, t in enumerate(texts, 1):
        assert t.endswith("\n"), "the script must end with a newline"
        files["Presenter_panel_part_%d.txt" % k] = (
            "-- @@PRESENTER-PART%d-START %s %d@@\n%s-- @@PRESENTER-PART%d-END@@\n" % (k, version, n, t, k))
    return files


def main():
    with open(SRC, encoding="utf-8", newline="") as f:
        src = f.read()
    version = re.search(r"-- @version (\S+)", src).group(1)
    files = render(split(src), version)
    os.makedirs(OUT, exist_ok=True)
    for old in glob.glob(os.path.join(OUT, "Presenter_panel_part_*.txt")):
        os.remove(old)
    for name, text in files.items():
        with open(os.path.join(OUT, name), "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
        print("  %s  %.1f KB" % (name, len(text.encode()) / 1024))
    print("Paste kit for v%s: %d part(s), written to %s" % (version, len(files), OUT))


if __name__ == "__main__":
    main()

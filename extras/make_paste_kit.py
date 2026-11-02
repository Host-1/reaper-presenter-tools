"""
Builds the "paste kit": the Presenter panel split into two halves, for
machines (e.g. a VM) whose clipboard cuts off pastes longer than ~100 KB.

    python extras/make_paste_kit.py

Writes extras/paste-kit/Presenter_panel_part_1.txt and _part_2.txt from
Presenter/Presenter panel.lua. Paste those two files and
Presenter_panel_launcher.lua into one folder on the other machine and load
the launcher as the REAPER action. Each part starts and ends with a check
line, so the launcher can tell if a paste was cut off at either end.
"""
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "..", "Presenter", "Presenter panel.lua")
OUT = os.path.join(HERE, "paste-kit")


def main():
    with open(SRC, encoding="utf-8", newline="") as f:
        src = f.read()
    version = re.search(r"-- @version (\S+)", src).group(1)
    lines = src.split("\n")

    # split near the middle, between two top-level blocks
    total, acc, mid = len(src.encode()), 0, 0
    for i, line in enumerate(lines):
        acc += len((line + "\n").encode())
        if acc >= total / 2:
            mid = i
            break
    cut = next(j + 1 for j in range(mid, len(lines) - 1)
               if lines[j] == "" and re.match(r"^(local function|function|local |--)", lines[j + 1]))
    p1 = "\n".join(lines[:cut]) + "\n"
    p2 = "\n".join(lines[cut:])
    assert p1 + p2 == src

    os.makedirs(OUT, exist_ok=True)
    parts = {
        "Presenter_panel_part_1.txt": f"-- @@PRESENTER-PART1-START {version}@@\n{p1}-- @@PRESENTER-PART1-END@@\n",
        "Presenter_panel_part_2.txt": f"-- @@PRESENTER-PART2-START {version}@@\n{p2}\n-- @@PRESENTER-PART2-END@@\n",
    }
    for name, text in parts.items():
        with open(os.path.join(OUT, name), "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
        print(f"  {name}  {len(text.encode()) // 1024} KB")
    print(f"Paste kit for v{version} written to {OUT}")


if __name__ == "__main__":
    main()

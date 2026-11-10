# Paste kit

For a machine where pasting the whole panel doesn't work (some VM / remote-desktop
clipboards cut text off at about 100 KB, and the panel is bigger than that).

1. From the repo folder, run `python extras/make_paste_kit.py`. It writes
   `Presenter_panel_part_1.txt` ... `_part_N.txt` here (as many as needed, each under 95 KB).
2. On the other machine, put the launcher and all the part files in one folder (REAPER's Scripts folder is best):
   `Presenter_panel_launcher.lua`, `Presenter_panel_part_1.txt`, `Presenter_panel_part_2.txt`, ...
   Paste each one in full.
3. Actions > Show action list > New action > Load ReaScript, and pick the **launcher**.

The part names only need to end in "part1", "part2", ... (spaces, underscores and hyphens don't
matter). If a paste was cut off, the launcher says which part and what to do.
To update, regenerate and replace all the part files.

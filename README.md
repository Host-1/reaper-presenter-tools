# REAPER presenter tools

A panel for presenting listening sessions (e.g. over Zoom) from REAPER: big text, tabs per region,
one-click exclusive playback, A/B switching at the same position, loop, waveform, marker jumps,
folders, takes and lanes, notes and images, adding notes and markers live, loudness matching, and a Presentation builder
that copies picked clips into their own section of the session.

Needs REAPER 7 and ReaImGui 0.10+.

- **New here?** Start with [INSTALL.md](INSTALL.md), then [HOW_TO_USE.md](HOW_TO_USE.md).

## Install (once per machine)

1. **ReaPack**: download from reapack.com, follow its install steps, restart REAPER. An *Extensions* menu appears.
2. **ReaImGui**: Extensions > ReaPack > Browse packages, filter "imgui", right-click
   *ReaImGui: ReaScript binding for Dear ImGui* > Install > Apply. Restart REAPER.
3. **The panel**: Extensions > ReaPack > Import repositories, paste:

   ```
   https://github.com/OWNER/REPO/raw/main/index.xml
   ```

   Then Extensions > ReaPack > Browse packages, filter "Presenter", right-click > Install > Apply.
   Run it from the Action list (Actions > Show action list, search "Presenter panel").
   Run the action again to close the panel.

## Updates

Extensions > ReaPack > Synchronize packages pulls the latest versions.

## Setting up a presenter session

- **Overview / Presentation** (top left): Overview is the whole session. Tick clips there and
  "Add to presentation…" copies them into a PRESENTATION folder after the end of the session,
  one region per section. Presentation has its own track/folder editor (drag to reorder,
  rename, colour, add, delete) and section controls.
- **Selecting and colour**: tick boxes on clips in both views (each view keeps its own ticks).
  The bar above the clips recolours the ticked clips, adds them to the presentation (Overview)
  or removes them (Presentation). Right-click a clip for the same on one clip.
- **Regions**: one region per test; the region name is the tab name. Regions can be nested
  (e.g. a "Round 1" region spanning several regions): each level gets its own row of tabs.
- **Text**: "+ Text" next to the region title adds the big text above the clips (an item on the
  topmost track, created if needed). Lines starting with `>` show as the smaller "listen for" cue.
- **Clips**: one per track, or several takes in one item. Track names are the button labels,
  so name tracks A/B/C to keep a session blind.
- **Folders**: folder tracks become collapsible groups in the panel.
- **Colours**: clips take REAPER's colours (item, else take, else track; grey if none). Green = playing,
  blue = A/B switch, amber state box = paused.
- **Markers**: take markers (per clip) and project markers (shared) become jump buttons. Take markers
  can also be added from the panel during a presentation ("+ Marker" or M), and removed with the
  little x next to each one.
- **Notes**: text items on other tracks, and a clip's own Item notes, show as collapsible notes
  on that track. Images set in the Item notes window show in the note; click one to enlarge it.
  (Stretching text or images to fill an item is built into REAPER's Item notes window.)
  Add notes with "+ Note" or N; remove a line with the little x next to it when the note is open.
- **A/B** (Off | Default | Smooth): Default switches at the same point with a tiny gap (standard, for different
  voices); Smooth has no gap, for clips that start at the same time (e.g. versions of one recording).
  For either, line up each region's clips at the same start time.
- **Levels** (Settings, top right): normalize this region or all clips in the view to a LUFS-I or peak target
  (default -23 LUFS-I) using REAPER's own loudness measurement; warns about clips that would go above -1 dBTP.

Panel keys: 1-9 play/pause row, Up/Down previous/next take or lane, Space play/pause the selected clip, Left/Right previous/next region, A A/B on/off, S switch A/B between Default and Smooth, L toggle loop, C compact view (just tabs, controls and small clip buttons; also top right), M add a take marker at the current moment of the playing/selected clip (also "+ Marker" at the start of each clip's marker row), N add a general note to the clip's Item notes (also "+ Note" at the start of each clip's notes line).

## What's in this repo

| Path | What it is |
|---|---|
| `Presenter/Presenter panel.lua` | The panel (the only file REAPER needs) |
| `INSTALL.md`, `HOW_TO_USE.md` | Setup and usage guides |
| `CHANGELOG.md` | What changed in each version |
| `make_index.py` | Builds `index.xml`, the file ReaPack reads |
| `extras/` | The paste kit, for VMs whose clipboard cuts off long pastes (see its README) |

## Maintaining this repo

1. Edit the panel and raise its `-- @version` number (e.g. 4.4 -> 4.5). ReaPack only offers an
   update when the version goes up. Add a line to `CHANGELOG.md`.
2. Regenerate the index from this folder:

   ```
   python make_index.py --owner OWNER --repo REPO
   ```

3. Commit and push the changed script and `index.xml`.
4. If anyone uses the paste kit: `python extras/make_paste_kit.py`, and send them the two new part files.

New scripts: put the `.lua` file in a subfolder (each subfolder is a category), give it
`-- @description` and `-- @version` lines at the top, and rerun `make_index.py`.

**ReaPack can only download from a repo that's readable without signing in (public).** With a
private repo, share the `.lua` file instead (see INSTALL.md, "If you were given the file").

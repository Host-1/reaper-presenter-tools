# Changelog

## Unreleased (4.6 work; folded into the single release entry by T-011)
- Pinned toolbar: the view tabs, region tabs and the play / A/B / Loop row stay at the top while the clips scroll underneath.
- Collapsing the window with its title-bar arrow and opening it again now brings it back to the size it had, instead of staying tiny.
- The window size is remembered between sessions (full view only; compact view still fits its own height).
- Keys (1-9, Space, A, S, L, C, M, N, arrows) only work while the panel has the keyboard focus and no popup is open.

## 4.5
- Rename a track right in the panel: hover a clip row and click the pencil. The name turns into a box (Enter or click away saves, Esc cancels). Undoable.

## 4.4
- Rename tracks, takes and folders from the panel (right-click a clip or a folder header).
- Folder colour from the folder header's right-click menu.

## 4.3
- Clips added to the presentation keep their session folders (Vendor A / Batch 2 / Turkish),
  or optionally go flat with the folder path in the track name.
- Markers added from the panel are red.

## 4.2
- Tick boxes and a selection bar in both views: recolour, add to presentation (Overview),
  remove (Presentation). Right-click menu on clips. Remove x shown on hover at the row's end.
- Track colour swatches in Tracks & folders.
- 4.2.1: fixed "Calling End() too many times" when the window is collapsed or docked out of view.

## 4.1
- Reads only the region on screen (plus its neighbours in the background) instead of the
  whole project: about 40x less work on large sessions; no more freeze on open or after edits.

## 4.0
- Overview and Presentation views. Presentation builder: copy ticked clips into sections
  after the session, tracks and folders editor (drag, rename, add, delete).
- + Text in both views; Settings moved to the top right; "trial" renamed "region".

## 3.x
- A/B (Default / Smooth), loop and loop sections, waveforms, take and project markers,
  folders, takes and lanes, notes and images, + Note / + Marker, loudness normalising,
  compact view, REAPER colours.

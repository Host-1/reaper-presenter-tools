# Fake ReaImGui (tests)

`imgui.lua` stands in for ReaImGui 0.10 when a script does `require "imgui" "0.10"`. It records what is drawn and lets a test script clicks, keys and window states. Its rules come from the ReaImGui 0.10.0.5 source (`api/window.cpp`, `api/table.cpp`, `api/popup.cpp`, `api/tabbar.cpp`, `shims/0.8.cpp`), read 2026-11-10.

Its own tests: `tests/fake_imgui_test.lua` (run first by `run_panel.py`).

## Using it

```lua
FAKE_IMGUI = {}                     -- before the script's first require
local FI = FAKE_IMGUI
function reaper.ImGui_GetBuiltinPath() return HERE .. "/fake_imgui" end
-- each frame:
FI.reset_frame()                    -- ends the last frame (balance check), starts the next
deferred_fn()                       -- the script's defer function
```

`FI.reset_frame()` is the frame boundary. Call `FI.end_frame()` after the last frame if you want the last one checked too.

## Balance checks (on by default)

Like real ReaImGui (Dear ImGui's error callback throws), an unbalanced call raises a Lua error. The message names the frame and the calls, for example:

```
fake ImGui, frame 273: End() called, but the innermost open block is BeginTable("##notes") from frame 273, call #11141: call EndTable() first
```

- **Blocks** must nest strictly: `Begin/End`, `BeginChild/EndChild`, `BeginTable/EndTable`, `BeginPopup*/EndPopup`, `BeginTabBar/EndTabBar`, `BeginTabItem/EndTabItem`, `TreeNode*/TreePush` + `TreePop`, `BeginCombo/EndCombo`, `BeginListBox`, `BeginMenuBar`, `BeginMenu`, `BeginGroup`, `BeginTooltip`, drag and drop.
- **The End call only follows a true.** `Begin` and `BeginChild` close themselves when they return false (ReaImGui calls `End`/`EndChild` for you), so `End`/`EndChild` after a false is an error. Same for tables, popups, tab bars, tab items, tree nodes, combos.
- **Stacks** are counted: `PushID/PopID`, `PushStyleVar/PopStyleVar(count)`, `PushStyleColor/PopStyleColor(count)`, `PushFont(ctx, font, size)/PopFont` (size is required in 0.10), `BeginDisabled/EndDisabled`, `PushItemWidth`, `PushTextWrapPos`, `PushItemFlag`, `Indent/Unindent` (same width). Popping with nothing pushed is an error. Closing a block while something pushed inside it is still pushed is an error. Pushing a style before `Begin` and popping it after `Begin` is allowed (real ImGui allows it). `PopID` may not pop an ID pushed outside the current window.
- **Drawing outside a window** (after `Begin` returned false, or after `End`) is an error.
- **Swallowed errors still count.** If a script's `pcall` catches a balance error, the next `FI.reset_frame()` raises it again.
- **At the end of a frame** nothing may be open.
- `FI.balance = false` (set before loading) turns all of this off. Use it only to bring up an old harness; never commit a test with it off.
- `FI.errors` lists every balance error so far. `FI.open_blocks()` lists what is open now.

## Window states

| Switch | Effect |
| --- | --- |
| `FI.windows["Title"] = { collapsed = true }` | `Begin` returns `visible = false` |
| `{ dock_hidden = true }` | docked in a tab that is not shown: `Begin` returns false |
| `{ docked = true }` | `Begin` true, `IsWindowDocked` true, `GetWindowDockID` -1 (or `dock_id = n`) |
| `{ focused = false }` | `IsWindowFocused` false, `Shortcut` does not fire. Default: `FI.focused` (true) |
| `FI.focus_child = "Title/##list"` | keyboard focus is inside that child: plain `IsWindowFocused` is true only there, `FocusedFlags_RootAndChildWindows` true anywhere in the window |
| `FI.hidden_children["##id"] = true` | `BeginChild` returns false (scrolled out). Also `FI.hidden_tables[id]`, `FI.hidden_tabbars[id]` |
| `FI.visible = false`, `FI.window_open = false` | the old switches: every window is not visible / the close button was clicked |

`IsWindowCollapsed` always returns false, as in ReaImGui 0.10 (a dead stub since 0.5). Don't build on it: after `Begin` returns false you are outside the window. Remember `IsWindowDocked` while visible instead.

## Widgets, keys and the rest

- `FI.clicks[label] = true` clicks a button, selectable, checkbox, radio, menu item or tab (a tab click selects it from the next frame). `FI.inputs[label] = "text"`, `FI.enter[label] = true`, `FI.opened["id"] = true` (combo open), `FI.closed_headers[label] = true`.
- Tabs: `FI.tabs["##bar"] = "Label"` selects a tab (default: the first one drawn). `FI.close_tabs[label] = true` clicks its close button (`p_open` comes back false).
- Popups: `OpenPopup` opens, `CloseCurrentPopup` closes; a test can set `FI.popups[id] = true`. `FI.context_popups[id or item label] = true` is a right-click. `FI.close_modal[name] = true` clicks a modal's close button.
- Tree nodes: closed unless `TreeNodeFlags_DefaultOpen` or `FI.trees[label] = true`.
- Keys: `FI.keys[FI.api.Key_S] = true` is a press this frame (used up by the first `IsKeyPressed` or `Shortcut` that reads it). `FI.held[key] = true` is a key held from earlier frames: `IsKeyPressed` repeats it unless called with `repeat = false`; `Shortcut` repeats it only with `InputFlags_Repeat`. `FI.mods = FI.api.Mod_Ctrl` holds modifiers for chords (`Mod_Ctrl | Key_S`).
- `Shortcut(ctx, chord, flags)` fires only when the current window has focus (the default route); `InputFlags_RouteGlobal` fires without focus. `IsKeyPressed` ignores focus, like the real one. `SetNextItemShortcut` presses the next widget when its shortcut fires (not when disabled). `FI.shortcuts` lists what was asked this frame.
- `ListClipper`: `FI.clip = { first, last }` (0-based, last exclusive) is what is on screen; otherwise `FI.clip_rows` rows from 0, or every row. Like ReaImGui, without a fixed row height the first step is row 0 only (measuring), then the rows on screen. `FI.clipper_log` lists the ranges handed out. Breaking out of the loop and calling `ListClipper_Begin` again is an error.
- Scrolling and cursor belong to the current window: `SetScrollY` inside a `BeginChild` scrolls the child, and lands on the next frame. `GetScrollY`, `GetScrollMaxY` (`FI.scroll_max[path]`, default 1000), `GetCursorPosY` (24 per widget, 18 per text line, undone by `SameLine`). `FI.scroll["Title/##child"]` is what a test reads.
- Flag constants are real bits per group (`TableFlags_*`, `InputFlags_*`, ...; `*_None` = 0), with `FocusedFlags_RootAndChildWindows` = `RootWindow | ChildWindows`. Any other call not listed is a no-op.

Records: `FI.texts`, `FI.buttons[label] = { disabled, input, combo }`, `FI.tooltips[label]`, `FI.selectables`, `FI.previews`, `FI.values[label]`, `FI.begin_calls`, `FI.ends`, `FI.overlaps`, `FI.draw`, `FI.next_size`, `FI.constraints`, `FI.frame`.

-- A fake ReaImGui 0.10 for tests. The panel does `require "imgui" "0.10"`; this returns a recording stand-in.
-- How to drive it and what it checks: tests/fake_imgui/README.md. Rules taken from the ReaImGui 0.10.0.5 source
-- (api/window.cpp, api/table.cpp, api/popup.cpp, api/tabbar.cpp, shims/0.8.cpp; coordination research §10).
--
-- Tests script it through the global FAKE_IMGUI (FI), set before the first require:
--   FI.clicks[label] = true     the button / selectable with that label is clicked (once)
--   FI.inputs[label] = "text"   the input box gets that text (once); FI.enter[label] = true presses Enter in it
--   FI.opened[id] = true        the combo "##id" is open this frame
--   FI.keys[FI.api.Key_Escape] = true   a key is pressed this frame (consumed by the first IsKeyPressed/Shortcut)
--   FI.windows[name] = { collapsed=, docked=, dock_hidden=, focused= }   window states (README)
-- It records what was drawn: FI.texts, FI.buttons[label] = {disabled=bool}, FI.tooltips[label], FI.selectables.
-- Unbalanced Begin/End, Push/Pop etc. raise a Lua error naming the frame and the call, as real ReaImGui does.
local FI = FAKE_IMGUI

-- ---------------------------------------------------------------------------
-- Constants. Flag groups get real bits (so `|` and `&` work); keys are small ints; Mod_* sit above the keys.
-- ---------------------------------------------------------------------------
local constants, next_id, group_bits, mod_bit = {}, 1, {}, 16
local COMPOSITE = {
  FocusedFlags_RootAndChildWindows = { "FocusedFlags_RootWindow", "FocusedFlags_ChildWindows" },
  HoveredFlags_RootAndChildWindows = { "HoveredFlags_RootWindow", "HoveredFlags_ChildWindows" },
  TreeNodeFlags_CollapsingHeader = { "TreeNodeFlags_Framed", "TreeNodeFlags_NoTreePushOnOpen", "TreeNodeFlags_NoAutoOpenOnLog" },
}
local constant
function constant(name)
  if constants[name] then return constants[name] end
  local group, rest = name:match("^([A-Za-z]*Flags)_(.+)$")
  if COMPOSITE[name] then
    local v = 0
    for _, part in ipairs(COMPOSITE[name]) do v = v | constant(part) end
    constants[name] = v
  elseif group then
    if rest == "None" then constants[name] = 0
    else
      group_bits[group] = (group_bits[group] or 0)
      constants[name] = 1 << group_bits[group]
      group_bits[group] = group_bits[group] + 1
    end
  elseif name:match("^Mod_") then
    constants[name] = 1 << mod_bit; mod_bit = mod_bit + 1
  else
    constants[name] = next_id; next_id = next_id + 1
  end
  return constants[name]
end
local KEY_MASK = (1 << 16) - 1
local function has(flags, name) return ((flags or 0) & constant(name)) ~= 0 end

-- ---------------------------------------------------------------------------
-- Recorded state and scripted inputs (the old fields keep their meaning)
-- ---------------------------------------------------------------------------
FI.texts, FI.buttons, FI.tooltips, FI.selectables, FI.previews = {}, {}, {}, {}, {}
FI.clicks, FI.inputs, FI.enter, FI.opened, FI.keys, FI.deactivated = {}, {}, {}, {}, {}, {}
FI.hover_all, FI.focused, FI.dbl = true, true, false
FI.disabled, FI.last, FI.queried_keys, FI.focus_calls, FI.begin_calls = 0, nil, {}, 0, {}
FI.checked, FI.ever = {}, {}
-- new in T-004
FI.windows = FI.windows or {}          -- [window name] = { collapsed, docked, dock_hidden, focused }
FI.hidden_children = FI.hidden_children or {} -- [child id] = true: BeginChild returns false (scrolled out / clipped)
FI.focus_child = FI.focus_child        -- "Window/##child": keyboard focus is inside that child
FI.popups = FI.popups or {}            -- [popup id] = true: open (OpenPopup sets it, CloseCurrentPopup clears it)
FI.context_popups = FI.context_popups or {} -- [id or last item label] = true: a right-click opened that context popup
FI.tabs = FI.tabs or {}                -- [tab bar id] = label of the selected tab (default: the first tab drawn)
FI.close_tabs = FI.close_tabs or {}    -- [tab label] = true: its close button is clicked (p_open comes back false)
FI.trees = FI.trees or {}              -- [tree label] = true/false: open or closed (default: TreeNodeFlags_DefaultOpen)
FI.held = FI.held or {}                -- [key] = true: held down from earlier frames (auto-repeat)
FI.mods = FI.mods or 0                 -- Mod_* bits held this frame (for Shortcut chords)
FI.clip = FI.clip                      -- { first, last }: rows on screen for every ListClipper (0-based, last exclusive)
FI.clip_rows = FI.clip_rows           -- ...or this many rows from 0 when FI.clip is nil (nil = every row)
FI.scroll_max = FI.scroll_max or {}    -- [window path] = GetScrollMaxY (default 1000)
if FI.balance == nil then FI.balance = true end -- false turns every balance check off (bring-up only)
FI.frame = FI.frame or 0
FI.errors = FI.errors or {}            -- every balance error so far, also the ones a pcall swallowed
FI.scroll, FI.cursor_y = {}, {}        -- [window path] = scroll y / cursor y
FI.clipper_log = {}                    -- { n=, first=, last= } per drawn range, this frame
FI.shortcuts = {}                      -- chords asked for this frame: { chord=, fired=, route= }

-- ---------------------------------------------------------------------------
-- Balance checking
-- ---------------------------------------------------------------------------
-- Blocks (strict nesting): window, child, table, popup, tabbar, tabitem, tree, combo, listbox, menubar, menu, group,
-- tooltip, dragsource, dragtarget. Stacks (counted, may cross a Begin like real ImGui's style stacks): ID, StyleVar,
-- StyleColor, Font, Disabled, ItemWidth, TextWrapPos, ItemFlag, Indent.
local STACKS = { "ID", "StyleVar", "StyleColor", "Font", "Disabled", "ItemWidth", "TextWrapPos", "ItemFlag", "Indent" }
local POP_NAME = { ID = "PopID", StyleVar = "PopStyleVar", StyleColor = "PopStyleColor", Font = "PopFont", Disabled = "EndDisabled",
  ItemWidth = "PopItemWidth", TextWrapPos = "PopTextWrapPos", ItemFlag = "PopItemFlag", Indent = "Unindent" }
local END_NAME = { window = "End", child = "EndChild", table = "EndTable", popup = "EndPopup", tabbar = "EndTabBar",
  tabitem = "EndTabItem", tree = "TreePop", combo = "EndCombo", listbox = "EndListBox", menubar = "EndMenuBar", menu = "EndMenu",
  group = "EndGroup", tooltip = "EndTooltip", dragsource = "EndDragDropSource", dragtarget = "EndDragDropTarget" }
local blocks, stacks, ncall = {}, {}, 0
for _, k in ipairs(STACKS) do stacks[k] = {} end

local function where(b) return string.format('%s("%s") from frame %d, call #%d', b.call, tostring(b.name), b.frame, b.n) end

local function fail(msg)
  msg = string.format("fake ImGui, frame %d: %s", FI.frame, msg)
  FI.errors[#FI.errors + 1] = msg
  FI.unreported = (FI.unreported or 0) + 1
  error(msg, 3)
end

local function sizes() local s = {} for _, k in ipairs(STACKS) do s[k] = #stacks[k] end return s end

local function push_block(kind, call, name)
  ncall = ncall + 1
  local b = { kind = kind, call = call, name = name, frame = FI.frame, n = ncall, sizes = sizes() }
  blocks[#blocks + 1] = b
  return b
end

local function innermost(kind, stop_at_window)
  for i = #blocks, 1, -1 do
    local b = blocks[i]
    if b.kind == kind then return b end
    if stop_at_window and (b.kind == "window" or b.kind == "child" or b.kind == "popup") then return nil end
  end
end

-- Closing a block: it must be the innermost one, and nothing pushed inside it may still be on a stack.
local function pop_block(kind, call)
  if not FI.balance then
    for i = #blocks, 1, -1 do if blocks[i].kind == kind then return table.remove(blocks, i) end end
    return nil
  end
  local top = blocks[#blocks]
  if not top then
    local hint = (kind == "window" or kind == "child") and " (Begin/BeginChild returned false? ReaImGui already closed it)" or ""
    fail(string.format("%s() called, but no block is open%s", call, hint))
  end
  if top.kind ~= kind and not innermost(kind) then
    local hint = (kind == "window" or kind == "child") and " (Begin/BeginChild returned false? ReaImGui already closed it)" or ""
    fail(string.format("%s() called, but no %s is open%s; innermost open block is %s", call, kind, hint, where(top)))
  end
  if top.kind ~= kind then
    fail(string.format("%s() called, but the innermost open block is %s: call %s() first", call, where(top), END_NAME[top.kind]))
  end
  for _, k in ipairs(STACKS) do
    local extra = #stacks[k] - top.sizes[k]
    if extra > 0 then
      fail(string.format("%s() called with %d %s still pushed inside %s: missing %s()", call, extra, k, where(top), POP_NAME[k]))
    end
  end
  return table.remove(blocks)
end

local function current_window()
  for i = #blocks, 1, -1 do
    local k = blocks[i].kind
    if k == "window" or k == "child" or k == "popup" or k == "tooltip" then return blocks[i] end
  end
end

local function push_stack(kind, call, value)
  ncall = ncall + 1
  local s = stacks[kind]
  s[#s + 1] = { call = call, value = value, frame = FI.frame, n = ncall }
end

local function pop_stack(kind, call, count)
  for _ = 1, count or 1 do
    local s = stacks[kind]
    if #s == 0 then
      if FI.balance then fail(string.format("%s() called with nothing pushed", call)) end
      return
    end
    -- the ID stack belongs to a window: it can't be popped below what the window started with
    local w = current_window()
    if FI.balance and kind == "ID" and w and #s <= w.sizes.ID then
      fail(string.format("%s() pops an ID pushed outside %s", call, where(w)))
    end
    local e = table.remove(s)
    if kind == "Indent" and FI.balance and FI._unindent_w ~= nil and e.value ~= nil and math.abs(FI._unindent_w - e.value) > 1e-6 then
      fail(string.format("Unindent(%s) does not match Indent(%s) from frame %d, call #%d", tostring(FI._unindent_w), tostring(e.value), e.frame, e.n))
    end
  end
end

-- Everything must be closed when a frame ends. Called by FI.reset_frame (start of the next frame) and FI.end_frame.
function FI.end_frame()
  local unreported = FI.unreported or 0
  FI.unreported = 0
  if not FI.balance then blocks = {} for _, k in ipairs(STACKS) do stacks[k] = {} end return end
  if unreported > 0 then
    local msg = FI.errors[#FI.errors]
    blocks = {} for _, k in ipairs(STACKS) do stacks[k] = {} end
    error("fake ImGui: a balance error was raised and swallowed (pcall?) during frame " .. FI.frame .. ": " .. msg, 2)
  end
  local open = {}
  for _, b in ipairs(blocks) do open[#open + 1] = where(b) .. " needs " .. END_NAME[b.kind] .. "()" end
  for _, k in ipairs(STACKS) do
    for _, e in ipairs(stacks[k]) do open[#open + 1] = string.format("%s from frame %d, call #%d needs %s()", e.call, e.frame, e.n, POP_NAME[k]) end
  end
  if #open > 0 then
    blocks = {} for _, k in ipairs(STACKS) do stacks[k] = {} end
    local msg = string.format("fake ImGui, frame %d: the frame ended with open blocks: %s", FI.frame, table.concat(open, "; "))
    FI.errors[#FI.errors + 1] = msg
    error(msg, 2)
  end
end

-- ---------------------------------------------------------------------------
-- Frames
-- ---------------------------------------------------------------------------
function FI.reset_frame()
  FI.end_frame()
  FI.frame = FI.frame + 1
  FI.texts, FI.buttons, FI.selectables, FI.previews = {}, {}, {}, {}
  FI.clipper_log, FI.shortcuts, FI.cursor_y = {}, {}, {}
  for path, y in pairs(FI.pending_scroll or {}) do FI.scroll[path] = y end -- SetScrollY lands on the next frame
  FI.pending_scroll = {}
end
function FI.text_has(pat)
  for _, t in ipairs(FI.texts) do if t:find(pat) then return true end end
  return false
end
function FI.find_selectable(pat)
  for _, l in ipairs(FI.selectables) do if l:find(pat) then return l end end
end
function FI.open_blocks() local o = {} for _, b in ipairs(blocks) do o[#o + 1] = b.kind .. ":" .. tostring(b.name) end return o end
FI.constant = constant

local api = {}
FI.api = api

local function window_path()
  local parts = {}
  for _, b in ipairs(blocks) do
    if b.kind == "window" or b.kind == "child" or b.kind == "popup" then
      if b.kind == "window" then parts = {} end
      parts[#parts + 1] = tostring(b.name)
    end
  end
  return table.concat(parts, "/")
end

-- Widgets need a window. Drawing after Begin returned false lands in ImGui's hidden "Debug" window: a bug.
local function need_window(call)
  if FI.balance and not current_window() then
    fail(call .. "() called outside any window (drawing after Begin returned false, or after End?)")
  end
end
local function advance(h)
  local p = window_path()
  FI.prev_y = FI.cursor_y[p] or 0
  FI.cursor_y[p] = (FI.cursor_y[p] or 0) + (h or 24)
end

local function note_item(label, call) need_window(call or "item"); advance(); FI.last = label; FI.prev_full = false end

local function shortcut_fires(chord, flags, consume)
  local key, mods = chord & KEY_MASK, chord & ~KEY_MASK
  if mods ~= (FI.mods or 0) then return false end
  local pressed = FI.keys[key] or (FI.held[key] and has(flags, "InputFlags_Repeat"))
  if not pressed then return false end
  local global = has(flags, "InputFlags_RouteGlobal") or has(flags, "InputFlags_RouteAlways")
  if not global then
    -- default route = focused: only when the current window (or a child of it, or a parent of the focused child) has focus
    local w = current_window()
    if not w then return false end
    local st = FI.windows[blocks[1] and blocks[1].name or ""] or {}
    local root_focused = st.focused; if root_focused == nil then root_focused = FI.focused end
    if not root_focused then return false end
    if FI.focus_child then
      local p = window_path()
      if FI.focus_child:sub(1, #p) ~= p then return false end -- focus is in a sibling child
    end
  end
  if consume and FI.keys[key] then FI.keys[key] = nil end
  return true
end

local function widget_click(label)
  local sc = FI.next_shortcut
  FI.next_shortcut = nil
  if sc and FI.disabled == 0 and shortcut_fires(sc.chord, sc.flags, true) then return true end
  if FI.clicks[label] then FI.clicks[label] = nil return true end
  return false
end

-- ---------------------------------------------------------------------------
-- Windows and child windows
-- ---------------------------------------------------------------------------
function api.Begin(ctx, name, open, flags)
  FI.begin_calls[#FI.begin_calls + 1] = name
  local st = FI.windows[name] or {}
  local visible = FI.visible ~= false and not st.collapsed and not st.dock_hidden
  local p_open = FI.window_open ~= false
  if open == nil then p_open = nil end
  if visible then
    local b = push_block("window", "Begin", name)
    b.state = st
    for path, _ in pairs(FI.pending_scroll or {}) do if path == name then FI.scroll[path] = FI.pending_scroll[path] FI.pending_scroll[path] = nil end end
  end
  -- ReaImGui calls End itself when Begin returns false (api/window.cpp:83): the caller must not.
  if open == nil then return visible end
  return visible, p_open
end
function api.End(ctx)
  pop_block("window", "End")
  FI.ends = (FI.ends or 0) + 1
end

function api.BeginChild(ctx, id, w, h, child_flags, window_flags)
  need_window("BeginChild")
  advance(h and h > 0 and h or 0)
  if FI.hidden_children[id] then return false end -- ReaImGui already called EndChild (api/window.cpp:123)
  push_block("child", "BeginChild", id)
  return true
end
function api.EndChild(ctx) pop_block("child", "EndChild") end

-- IsWindowCollapsed is a dead stub in ReaImGui 0.10 (shims/0.8.cpp:83, "broken since v0.5"): always false.
function api.IsWindowCollapsed(ctx) return false end
function api.IsWindowDocked(ctx)
  need_window("IsWindowDocked")
  local root = blocks[1]
  local st = root and FI.windows[root.name] or {}
  return st.docked or st.dock_hidden or false
end
function api.GetWindowDockID(ctx)
  need_window("GetWindowDockID")
  local st = FI.windows[blocks[1].name] or {}
  return st.dock_id or ((st.docked or st.dock_hidden) and -1 or 0)
end
function api.IsWindowFocused(ctx, flags)
  if flags and has(flags, "FocusedFlags_AnyWindow") then
    if FI.focused then return true end
    for _, st in pairs(FI.windows) do if st.focused then return true end end
    return false
  end
  local w = current_window()
  if not w then return false end
  local root = blocks[1]
  local st = FI.windows[root.name] or {}
  local root_focused = st.focused
  if root_focused == nil then root_focused = FI.focused end
  if not root_focused then return false end
  local p = window_path()
  local child_ok = has(flags, "FocusedFlags_ChildWindows")
  if has(flags, "FocusedFlags_RootWindow") then
    return child_ok or FI.focus_child == nil
  end
  if FI.focus_child == nil then return w == root or false end
  if FI.focus_child == p then return true end
  return child_ok and FI.focus_child:sub(1, #p + 1) == p .. "/"
end

-- Scrolling and the cursor belong to the CURRENT window: inside a BeginChild they act on the child.
function api.SetScrollY(ctx, y) need_window("SetScrollY") FI.pending_scroll = FI.pending_scroll or {} FI.pending_scroll[window_path()] = y end
function api.GetScrollY(ctx) need_window("GetScrollY") return FI.scroll[window_path()] or 0 end
function api.GetScrollMaxY(ctx) need_window("GetScrollMaxY") return FI.scroll_max[window_path()] or 1000 end
function api.SetScrollHereY(ctx) need_window("SetScrollHereY") FI.pending_scroll = FI.pending_scroll or {} FI.pending_scroll[window_path()] = FI.cursor_y[window_path()] or 0 end
function api.GetCursorPosY(ctx) need_window("GetCursorPosY") return FI.cursor_y[window_path()] or 0 end

function api.CreateContext(label) FI.context_label = label return { ctx = true } end
function api.Attach() end
function api.SetNextWindowSize(ctx, w, h, cond) FI.next_size = { w, h, cond } end
function api.SetNextWindowSizeConstraints(ctx, a, b, c, d) FI.constraints = { a, b, c, d } end

-- ---------------------------------------------------------------------------
-- List clipper: real ranges. Without a fixed row height the first step measures row 0, then the rows on screen.
-- ---------------------------------------------------------------------------
function api.CreateListClipper() return { n = 0, steps = nil } end
function api.ListClipper_Begin(c, n, items_height)
  if FI.balance and c.steps and c.step_i <= #c.steps then
    fail("ListClipper_Begin() called while the clipper is still stepping (a loop broke out before Step returned false)")
  end
  local first, last
  if FI.clip then first, last = FI.clip[1], FI.clip[2] else first, last = 0, FI.clip_rows or n end
  first, last = math.max(0, math.min(first, n)), math.max(0, math.min(last, n))
  local steps = {}
  if n > 0 then
    if (items_height or -1) <= 0 then
      steps[#steps + 1] = { 0, 1 }
      if last > math.max(1, first) then steps[#steps + 1] = { math.max(1, first), last } end
    elseif last > first then
      steps[#steps + 1] = { first, last }
    end
  end
  c.n, c.steps, c.step_i, c.cur = n, steps, 1, nil
end
function api.ListClipper_Step(c)
  if not c.steps then
    if FI.balance then fail("ListClipper_Step() called before ListClipper_Begin()") end
    return false
  end
  local s = c.steps[c.step_i]
  c.step_i = c.step_i + 1
  c.cur = s
  if not s then c.steps = nil return false end -- the last Step ends the clipper by itself
  FI.clipper_log[#FI.clipper_log + 1] = { n = c.n, first = s[1], last = s[2] }
  return true
end
function api.ListClipper_GetDisplayRange(c)
  if FI.balance and not c.cur then fail("ListClipper_GetDisplayRange() called outside a Step") end
  if not c.cur then return 0, 0 end
  return c.cur[1], c.cur[2]
end
function api.ListClipper_End(c) c.steps, c.cur = nil, nil end

-- ---------------------------------------------------------------------------
-- Text and widgets
-- ---------------------------------------------------------------------------
local function text(ctx, t) need_window("Text"); advance(18); FI.texts[#FI.texts + 1] = tostring(t); FI.last = "text:" .. tostring(t); FI.prev_full = false end
api.Text, api.TextWrapped, api.TextDisabled, api.SeparatorText = text, text, text, text
function api.TextColored(ctx, col, t) text(ctx, t) end

local function button(ctx, label)
  FI.buttons[label] = { disabled = FI.disabled > 0 }
  FI.ever[label] = true
  note_item(label, "Button")
  if FI.disabled > 0 then FI.clicks[label] = nil FI.next_shortcut = nil return false end
  return widget_click(label)
end
api.Button, api.SmallButton = button, button
function api.InvisibleButton(ctx, id) return button(ctx, id) end
function api.GetCursorScreenPos() return 0, 0 end
function api.GetFrameHeight() return 20 end
function api.GetWindowDrawList() FI.draw = FI.draw or { tri = 0, line = 0 } return FI.draw end
function api.DrawList_AddTriangleFilled(dl) dl.tri = dl.tri + 1 end
function api.DrawList_AddLine(dl) dl.line = dl.line + 1 end
function api.ArrowButton(ctx, id, dir) return button(ctx, id) end
function api.RadioButton(ctx, label, active) note_item(label, "RadioButton") FI.buttons[label] = { disabled = FI.disabled > 0 } return widget_click(label) end
function api.Checkbox(ctx, label, v)
  note_item(label, "Checkbox")
  FI.buttons[label] = { disabled = FI.disabled > 0 }
  if widget_click(label) then return true, not v end
  return false, v
end
function api.Selectable(ctx, label, sel, flags)
  FI.selectables[#FI.selectables + 1] = label
  note_item(label, "Selectable")
  return widget_click(label)
end

-- Behaves like real ReaImGui: with EnterReturnsTrue the box only hands back what was typed when Enter is
-- pressed, otherwise the caller gets its own old text back (so the typing is lost).
local function input(ctx, label, buf, flags)
  note_item(label, "InputText")
  FI.next_shortcut = nil
  FI.buttons[label] = { disabled = FI.disabled > 0, input = true }
  FI.prev_full = (FI.width_set or 0) <= 0
  FI.width_set = nil
  if FI.disabled > 0 then return false, buf end
  local old = buf
  FI.values = FI.values or {}; FI.values[label] = buf -- what the panel passed in this frame
  if FI.inputs[label] ~= nil then buf = FI.inputs[label]; FI.inputs[label] = nil end
  local enter = FI.enter[label] or false
  FI.enter[label] = nil
  if enter then FI.deactivated[label] = true; FI.keys[FI.api.Key_Enter] = true end
  if (flags or 0) & FI.api.InputTextFlags_EnterReturnsTrue ~= 0 then
    if enter then return true, buf end
    return false, old
  end
  return buf ~= old, buf
end
function api.InputText(ctx, label, buf, flags) return input(ctx, label, buf, flags) end
function api.InputTextWithHint(ctx, label, hint, buf, flags) return input(ctx, label, buf, flags) end
function api.InputTextMultiline(ctx, label, buf, w, h, flags) return input(ctx, label, buf, flags) end
function api.SetNextItemWidth(ctx, w) FI.width_set = w end
-- A box drawn with SameLine(offset) right after a full-width item lands on top of it.
function api.SameLine(ctx, offset)
  if offset and FI.prev_full then FI.overlaps = (FI.overlaps or 0) + 1 end
  local p = window_path()
  if FI.prev_y and FI.cursor_y[p] then FI.cursor_y[p] = FI.prev_y end
end

-- ---------------------------------------------------------------------------
-- Combos, list boxes, menus, tooltips, drag and drop: End* only when Begin* returned true
-- ---------------------------------------------------------------------------
function api.BeginCombo(ctx, label, preview)
  note_item(label, "BeginCombo")
  FI.buttons[label] = { disabled = FI.disabled > 0, combo = true }
  FI.ever[label] = true
  FI.previews[label] = preview
  FI.prev_full = (FI.width_set or 0) <= 0
  FI.width_set = nil
  if FI.disabled > 0 then return false end
  local open = FI.opened[label:gsub("^##", "")] or FI.opened[label] or false
  if open then push_block("combo", "BeginCombo", label) end
  return open
end
function api.EndCombo(ctx) pop_block("combo", "EndCombo") end
function api.BeginListBox(ctx, label)
  note_item(label, "BeginListBox")
  if (FI.hidden_children or {})[label] then return false end
  push_block("listbox", "BeginListBox", label) return true
end
function api.EndListBox(ctx) pop_block("listbox", "EndListBox") end
function api.BeginMenuBar(ctx) need_window("BeginMenuBar") push_block("menubar", "BeginMenuBar", "menubar") return true end
function api.EndMenuBar(ctx) pop_block("menubar", "EndMenuBar") end
function api.BeginMenu(ctx, label)
  note_item(label, "BeginMenu")
  local open = (FI.menus or {})[label] or false
  if open then push_block("menu", "BeginMenu", label) end
  return open
end
function api.EndMenu(ctx) pop_block("menu", "EndMenu") end
function api.MenuItem(ctx, label) note_item(label, "MenuItem") FI.buttons[label] = { disabled = FI.disabled > 0 } return widget_click(label) end
function api.BeginTooltip(ctx) push_block("tooltip", "BeginTooltip", "tooltip") return true end
function api.BeginItemTooltip(ctx)
  if not FI.hover_all then return false end
  push_block("tooltip", "BeginItemTooltip", "tooltip") return true
end
function api.EndTooltip(ctx) pop_block("tooltip", "EndTooltip") end
function api.BeginDragDropSource(ctx) if FI.dragging then push_block("dragsource", "BeginDragDropSource", FI.last) return true end return false end
function api.EndDragDropSource(ctx) pop_block("dragsource", "EndDragDropSource") end
function api.BeginDragDropTarget(ctx) if FI.drop then push_block("dragtarget", "BeginDragDropTarget", FI.last) return true end return false end
function api.EndDragDropTarget(ctx) pop_block("dragtarget", "EndDragDropTarget") end

-- ---------------------------------------------------------------------------
-- Disabled, groups, collapsing headers, tree nodes
-- ---------------------------------------------------------------------------
function api.BeginDisabled(ctx, d)
  local on = (d == nil or d) and true or false
  if on then FI.disabled = FI.disabled + 1 end
  push_stack("Disabled", "BeginDisabled", on)
end
function api.EndDisabled(ctx)
  local s = stacks.Disabled
  local top = s[#s]
  pop_stack("Disabled", "EndDisabled")
  if top and top.value then FI.disabled = FI.disabled - 1 end
end
function api.BeginGroup(ctx) need_window("BeginGroup") push_block("group", "BeginGroup", "group") end
function api.EndGroup(ctx) pop_block("group", "EndGroup") end

-- Collapsing headers are open unless a test closes them (FI.closed_headers[label] = true).
function api.CollapsingHeader(ctx, label) note_item(label, "CollapsingHeader") FI.buttons[label] = { disabled = false } return not (FI.closed_headers or {})[label] end

local function tree_open(label, flags)
  if FI.trees[label] ~= nil then return FI.trees[label] end
  return has(flags, "TreeNodeFlags_DefaultOpen")
end
function api.TreeNode(ctx, label, flags)
  note_item(label, "TreeNode")
  local open = tree_open(label, flags)
  if open and not has(flags, "TreeNodeFlags_NoTreePushOnOpen") then push_block("tree", "TreeNode", label) end
  return open
end
function api.TreeNodeEx(ctx, id, label, flags)
  note_item(id, "TreeNodeEx")
  local open = tree_open(id, flags)
  if open and not has(flags, "TreeNodeFlags_NoTreePushOnOpen") then push_block("tree", "TreeNodeEx", id) end
  return open
end
function api.TreePush(ctx, id) push_block("tree", "TreePush", id) end
function api.TreePop(ctx) pop_block("tree", "TreePop") end

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------
function api.BeginTable(ctx, id, cols, flags)
  need_window("BeginTable")
  FI.table_open = true
  if (FI.hidden_tables or {})[id] then return false end
  local b = push_block("table", "BeginTable", id)
  b.cols, b.col, b.row = cols, -1, -1
  return true
end
function api.EndTable(ctx) pop_block("table", "EndTable") end
local function need_table(call)
  local t = innermost("table", true)
  if FI.balance and not t then fail(call .. "() called with no table open (BeginTable returned false, or after EndTable?)") end
  return t
end
function api.TableSetupColumn(ctx, label) need_table("TableSetupColumn") end
function api.TableSetupScrollFreeze(ctx) need_table("TableSetupScrollFreeze") end
function api.TableHeadersRow(ctx) local t = need_table("TableHeadersRow") if t then t.row, t.col = t.row + 1, -1 end end
function api.TableNextRow(ctx) local t = need_table("TableNextRow") if t then t.row, t.col = t.row + 1, -1 end end
function api.TableNextColumn(ctx)
  local t = need_table("TableNextColumn")
  if not t then return false end
  t.col = t.col + 1
  if t.col >= t.cols then t.col, t.row = 0, t.row + 1 end
  return true
end
function api.TableSetColumnIndex(ctx, i)
  local t = need_table("TableSetColumnIndex")
  if t then
    if FI.balance and (i < 0 or i >= t.cols) then fail(string.format("TableSetColumnIndex(%d) outside 0..%d", i, t.cols - 1)) end
    t.col = i
  end
  return true
end
function api.TableGetColumnIndex(ctx) local t = need_table("TableGetColumnIndex") return t and t.col or 0 end
function api.TableGetRowIndex(ctx) local t = need_table("TableGetRowIndex") return t and t.row or 0 end
function api.TableNeedSort(ctx) need_table("TableNeedSort") return false, false end

-- ---------------------------------------------------------------------------
-- Tab bars
-- ---------------------------------------------------------------------------
function api.BeginTabBar(ctx, id)
  need_window("BeginTabBar")
  if (FI.hidden_tabbars or {})[id] then return false end
  push_block("tabbar", "BeginTabBar", id)
  return true
end
function api.EndTabBar(ctx) pop_block("tabbar", "EndTabBar") end
function api.BeginTabItem(ctx, label, p_open, flags)
  local bar = blocks[#blocks]
  if FI.balance and (not bar or bar.kind ~= "tabbar") then fail('BeginTabItem("' .. tostring(label) .. '") called outside a tab bar') end
  note_item(label, "BeginTabItem")
  local bar_id = bar and bar.name or "?"
  if has(flags, "TabItemFlags_SetSelected") then FI.tabs[bar_id] = label end
  if FI.tabs[bar_id] == nil then FI.tabs[bar_id] = label end -- the first tab drawn is selected
  local selected = FI.tabs[bar_id] == label
  if FI.clicks[label] then FI.clicks[label] = nil FI.tabs[bar_id] = label end -- a click selects it from the next frame
  local still_open = p_open
  if p_open ~= nil and FI.close_tabs[label] then FI.close_tabs[label] = nil still_open = false end
  if selected then push_block("tabitem", "BeginTabItem", label) end
  if p_open == nil then return selected end
  return selected, still_open
end
function api.EndTabItem(ctx) pop_block("tabitem", "EndTabItem") end
function api.TabItemButton(ctx, label) note_item(label, "TabItemButton") return widget_click(label) end

-- ---------------------------------------------------------------------------
-- Popups and modals: EndPopup only when BeginPopup* returned true
-- ---------------------------------------------------------------------------
function api.OpenPopup(ctx, id) FI.popups[id] = true end
function api.IsPopupOpen(ctx, id) return FI.popups[id] or false end
function api.CloseCurrentPopup(ctx)
  local p = innermost("popup")
  if FI.balance and not p then fail("CloseCurrentPopup() called outside a popup") end
  if p then FI.popups[p.name] = nil end
end
function api.BeginPopup(ctx, id)
  if not FI.popups[id] then return false end
  push_block("popup", "BeginPopup", id)
  return true
end
function api.BeginPopupModal(ctx, name, p_open)
  if not FI.popups[name] then if p_open == nil then return false end return false, p_open end
  local still = p_open
  if p_open ~= nil and (FI.close_modal or {})[name] then FI.close_modal[name] = nil still = false FI.popups[name] = nil end
  if still == false then if p_open == nil then return false end return false, false end
  push_block("popup", "BeginPopupModal", name)
  if p_open == nil then return true end
  return true, still
end
function api.BeginPopupContextItem(ctx, id)
  local key = id or FI.last
  if FI.context_popups[key] then FI.popups[key] = true end
  if not FI.popups[key] then return false end
  push_block("popup", "BeginPopupContextItem", key)
  return true
end
function api.BeginPopupContextWindow(ctx, id)
  local key = id or "window_context"
  if FI.context_popups[key] then FI.popups[key] = true end
  if not FI.popups[key] then return false end
  push_block("popup", "BeginPopupContextWindow", key)
  return true
end
function api.EndPopup(ctx) pop_block("popup", "EndPopup") end

-- ---------------------------------------------------------------------------
-- Push/Pop stacks
-- ---------------------------------------------------------------------------
function api.PushID(ctx, id) push_stack("ID", "PushID", id) end
function api.PopID(ctx) pop_stack("ID", "PopID") end
function api.PushStyleVar(ctx, var) push_stack("StyleVar", "PushStyleVar", var) end
function api.PushStyleVarX(ctx, var) push_stack("StyleVar", "PushStyleVarX", var) end
function api.PushStyleVarY(ctx, var) push_stack("StyleVar", "PushStyleVarY", var) end
function api.PopStyleVar(ctx, count) pop_stack("StyleVar", "PopStyleVar", count) end
function api.PushStyleColor(ctx, col) push_stack("StyleColor", "PushStyleColor", col) end
function api.PopStyleColor(ctx, count) pop_stack("StyleColor", "PopStyleColor", count) end
function api.PushFont(ctx, font, size)
  if FI.balance and size == nil then fail("PushFont() needs a size in 0.10: PushFont(ctx, font_or_nil, size)") end
  push_stack("Font", "PushFont", font)
end
function api.PopFont(ctx) pop_stack("Font", "PopFont") end
function api.PushItemWidth(ctx, w) push_stack("ItemWidth", "PushItemWidth", w) end
function api.PopItemWidth(ctx) pop_stack("ItemWidth", "PopItemWidth") end
function api.PushTextWrapPos(ctx, x) push_stack("TextWrapPos", "PushTextWrapPos", x) end
function api.PopTextWrapPos(ctx) pop_stack("TextWrapPos", "PopTextWrapPos") end
function api.PushItemFlag(ctx, f, on) push_stack("ItemFlag", "PushItemFlag", f) end
function api.PopItemFlag(ctx) pop_stack("ItemFlag", "PopItemFlag") end
-- Indent is not a stack in ImGui, but an Indent left over moves every later line: each Unindent must undo an
-- Indent of the same width inside the same window.
function api.Indent(ctx, w) push_stack("Indent", "Indent", w) end
function api.Unindent(ctx, w) FI._unindent_w = w pop_stack("Indent", "Unindent") FI._unindent_w = nil end

-- ---------------------------------------------------------------------------
-- Keyboard: IsKeyPressed (no focus check, repeats by default) and Shortcut (focused window by default)
-- ---------------------------------------------------------------------------
function api.IsItemHovered() return FI.hover_all end
function api.SetTooltip(ctx, t) if FI.last then FI.tooltips[FI.last] = t end end
function api.IsKeyPressed(ctx, key, rep)
  FI.queried_keys[key] = true
  if FI.keys[key] then FI.keys[key] = nil return true end
  if FI.held[key] and rep ~= false then return true end -- held keys repeat unless repeat=false
  return false
end
function api.IsKeyDown(ctx, key) return (FI.keys[key] or FI.held[key]) and true or false end
function api.Shortcut(ctx, chord, flags)
  need_window("Shortcut")
  local fired = shortcut_fires(chord, flags, true)
  FI.shortcuts[#FI.shortcuts + 1] = { chord = chord, fired = fired, flags = flags or 0 }
  return fired
end
function api.SetNextItemShortcut(ctx, chord, flags) FI.next_shortcut = { chord = chord, flags = flags or 0 } end

function api.IsAnyItemActive() return FI.any_active or false end
function api.IsItemDeactivated() return FI.deactivated[FI.last] or false end
function api.IsMouseDoubleClicked() return FI.dbl end
function api.SetKeyboardFocusHere() FI.focus_calls = FI.focus_calls + 1 end
function api.SetClipboardText(ctx, t) FI.clipboard = t end
function api.GetContentRegionAvail() return 440, 360 end
function api.CalcTextSize(ctx, t) return #tostring(t) * 7, 16 end
function api.GetTextLineHeightWithSpacing() return 18 end
function api.GetFrameHeightWithSpacing() return 24 end
function api.GetFontSize() return 13 end

setmetatable(api, { __index = function (t, name)
  if name:match("^[A-Z][A-Za-z]*_[A-Za-z]") and not name:match("^ListClipper_") and not name:match("^DrawList_") then return constant(name) end
  return function () end -- any other call (layout, styles) is a no-op
end })

return function (version) FI.version = version return api end

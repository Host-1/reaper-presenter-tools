-- A fake ReaImGui 0.10 for the Presenter tests, stricter than a no-op stub.
-- The panel does `require 'imgui' '0.10'`; this file is what it gets.
--
-- Scripted through the global FAKE_IMGUI (FI):
--   FI.clicks[label] = true        the button / selectable with that label is clicked (once)
--   FI.keys[FI.api.Key_Space] = true   a key is pressed this frame (consumed by the first IsKeyPressed)
--   FI.focused = false             the panel window does not have keyboard focus
--   FI.win.collapsed / FI.win.docked / FI.win.dock_hidden   the window's state (see below)
--   FI.child_clipped[id] = true    BeginChild(id) returns false (child scrolled out of view)
--   FI.rclick[id] = true           right-click on the item that has context popup `id`
-- What it checks (an error is raised on the spot, with the offending call):
--   * Begin/End and BeginChild/EndChild balance. Like ReaImGui 0.10, Begin and BeginChild call End/EndChild
--     themselves when they return false, so End/EndChild after a false return is an error.
--   * Popups, groups, trees, combos, tables, drag-drop, disabled blocks: every Begin* that returned true must
--     be closed with its matching End*, in order.
--   * Push/Pop of styles, colours, fonts, IDs: counts must match.
--   FI.check_frame_end() (called by the test driver after every frame) fails if anything is left open.
-- It records: FI.texts, FI.buttons[label] = {disabled}, FI.scroll_calls (which window each SetScrollY hit),
-- FI.size_calls (SetNextWindowSize), FI.begin_flags.
local FI = FAKE_IMGUI
local constants, nextval, flagbit = {}, 1, 0
local function constant(name)
  if constants[name] == nil then
    if name:match("Flags_") or name:match("^Mod_") then
      constants[name] = 1 << flagbit; flagbit = flagbit + 1          -- real bit flags so `|` works
    else
      constants[name] = nextval; nextval = nextval + 1
    end
  end
  return constants[name]
end
-- popup flag combos used by the panel: AnyPopup = AnyPopupId | AnyPopupLevel
local PF_ID, PF_LEVEL = constant("PopupFlags_AnyPopupId"), constant("PopupFlags_AnyPopupLevel")
constants["PopupFlags_AnyPopup"] = PF_ID | PF_LEVEL
local FF_ROOT, FF_CHILD = constant("FocusedFlags_RootWindow"), constant("FocusedFlags_ChildWindows")
constants["FocusedFlags_RootAndChildWindows"] = FF_ROOT | FF_CHILD

function FI.reset()
  FI.texts, FI.buttons, FI.selectables = {}, {}, {}
  FI.clicks, FI.keys, FI.child_clipped, FI.rclick = {}, {}, {}, {}
  FI.focused, FI.hover_all = true, false
  FI.stack = {}                       -- open Begin*/ Push* scopes
  FI.counts = { style = 0, color = 0, font = 0, id = 0 }
  FI.popups = {}                      -- ids of open popups (OpenPopup) in order
  FI.scroll = {}                      -- window/child name -> scroll y
  FI.scroll_calls, FI.size_calls, FI.begin_flags = {}, {}, {}
  FI.next_size = nil
  FI.windows = {}                     -- name -> state (size, seen)
  FI.win = FI.win or {}
  FI.frames = 0
  FI.queried_keys = {}
  FI.begin_log, FI.child_log = {}, {}
  FI.disabled = 0
  FI.items = 0
  FI.seq = {}                         -- widget labels and 'child:<id>' markers in draw order
  FI.cursor_y, FI.row_shift = 0, 0
end
FI.win = { collapsed = false, docked = false, dock_hidden = false, shrink_on_collapse = false }
FI.reset()

-- how a user collapses / expands / resizes the window (the fake keeps the window's own state)
function FI.user_collapse() local w = FI.win; w.collapsed = true; if w.shrink_on_collapse then w.size_full = { 160, 26 } end end
function FI.user_expand() FI.win.collapsed = false end
function FI.user_resize(w, h) FI.win.size_full = { w, h } end
function FI.dock(hidden) FI.win.docked, FI.win.dock_hidden = true, hidden or false end
function FI.undock() FI.win.docked, FI.win.dock_hidden = false, false end

local function fail(msg) error("fake imgui: " .. msg, 3) end
local function top() return FI.stack[#FI.stack] end
local function push(kind, name) FI.stack[#FI.stack + 1] = { kind = kind, name = name } end
local function pop(kind, fname)
  local t = top()
  if not t then fail(fname .. " with nothing open") end
  if t.kind ~= kind then fail(fname .. " but the innermost open scope is " .. t.kind .. " '" .. tostring(t.name) .. "'") end
  FI.stack[#FI.stack] = nil
  return t
end
local function cur_window()   -- innermost window or child (what SetScrollY acts on)
  for i = #FI.stack, 1, -1 do
    local k = FI.stack[i].kind
    if k == "window" or k == "child" then return FI.stack[i].name, k end
  end
  fail("no current window (call outside Begin)")
end

function FI.check_frame_end()
  if #FI.stack > 0 then
    local t = top()
    fail("frame ended with " .. #FI.stack .. " scope(s) still open; innermost: " .. t.kind .. " '" .. tostring(t.name) .. "'")
  end
  for k, v in pairs(FI.counts) do
    if v ~= 0 then fail("frame ended with unbalanced Push/Pop of " .. k .. " (" .. v .. " left)") end
  end
  if FI.disabled ~= 0 then fail("frame ended inside BeginDisabled") end
end
function FI.text_has(pat) for _, t in ipairs(FI.texts) do if t:find(pat) then return true end end return false end

local api = {}
FI.api = api
local MAIN = "Presenter"

---------------------------------------------------------------- windows --
function api.CreateContext(label) return { ctx = true } end
function api.CreateFont() return { font = true } end
function api.CreateImage() return { img = true } end
function api.Image_GetSize() return 100, 100 end
function api.Attach() end
function api.SetNextWindowSize(ctx, w, h, cond)
  cond = cond or constant("Cond_Always")
  FI.next_size = { w, h, cond }
  local call = { w = w, h = h, cond = cond, frame = FI.frames }   -- .target = the window that took it
  FI.size_calls[#FI.size_calls + 1] = call
  FI.next_call = call
end

function api.Begin(ctx, name, open, flags)
  FI.begin_log[#FI.begin_log + 1] = name
  FI.begin_flags[name] = flags or 0
  local w = FI.windows[name]
  local first = not w
  if first then w = { seen = true, size_full = { 400, 300 } }; FI.windows[name] = w end
  local main = (name == MAIN)
  local ws = main and FI.win or w
  if main and not ws.size_full then ws.size_full = w.size_full end
  -- pending SetNextWindowSize
  local ns, call = FI.next_size, FI.next_call
  FI.next_size, FI.next_call = nil, nil
  if call then call.target = name end
  if ns then
    local cond = ns[3]
    local apply = (cond == constant("Cond_Always")) or (cond == constant("Cond_FirstUseEver") and first)
      or (cond == constant("Cond_Appearing") and first) or (cond == constant("Cond_Once") and first)
    if apply then ws.size_full = { ns[1], ns[2] } end
  end
  local visible = true
  if main then
    if ws.collapsed then visible = false end
    if ws.docked and ws.dock_hidden then visible = false end
  end
  if not visible then return false, true end    -- ReaImGui has already ended the window itself
  push("window", name)
  FI.in_main = main
  return true, FI.win.close ~= true
end
function api.End() pop("window", "End") end
function api.GetWindowSize() local w = (FI.in_main and FI.win or FI.windows[cur_window()]); return w.size_full[1], w.size_full[2] end
function api.IsWindowDocked() return FI.win.docked end
function api.IsWindowFocused(ctx, flags)
  cur_window()
  return FI.focused
end
-- (ReaImGui has no IsWindowCollapsed / IsWindowHovered-collapsed query; calling one here is an error on purpose)
function api.IsWindowCollapsed() fail("IsWindowCollapsed does not exist in ReaImGui 0.10") end
function api.SetNextWindowSizeConstraints() end

function api.BeginChild(ctx, id, w, h, cflags, wflags)
  cur_window()
  FI.child_log[#FI.child_log + 1] = { id = id, w = w, h = h, frame = FI.frames }
  if FI.child_clipped[id] then return false end
  push("child", id)
  FI.seq[#FI.seq + 1] = "child:" .. id
  FI.scroll[id] = FI.scroll[id] or 0
  return true
end
function api.EndChild() pop("child", "EndChild") end

function api.SetScrollY(ctx, y)
  local name, kind = cur_window()
  FI.scroll[name] = y
  FI.scroll_calls[#FI.scroll_calls + 1] = { window = name, kind = kind, y = y }
end
function api.GetScrollY() return FI.scroll[(cur_window())] or 0 end

---------------------------------------------------------------- popups --
local function popup_is_open(id) for _, p in ipairs(FI.popups) do if p == id then return true end end return false end
function api.OpenPopup(ctx, id) if not popup_is_open(id) then FI.popups[#FI.popups + 1] = id end end
function api.IsPopupOpen(ctx, id, flags)
  flags = flags or 0
  if flags & PF_ID ~= 0 then return #FI.popups > 0 end
  return popup_is_open(id)
end
local function begin_popup(id)
  if not popup_is_open(id) then return false end
  push("popup", id)
  return true
end
function api.BeginPopup(ctx, id) return begin_popup(id) end
function api.BeginPopupModal(ctx, id) return begin_popup(id) end
function api.BeginPopupContextItem(ctx, id)
  if FI.rclick[id] then FI.rclick[id] = nil; api.OpenPopup(ctx, id) end
  return begin_popup(id)
end
function api.EndPopup() pop("popup", "EndPopup") end
function api.CloseCurrentPopup()
  local t
  for i = #FI.stack, 1, -1 do if FI.stack[i].kind == "popup" then t = FI.stack[i] break end end
  if not t then fail("CloseCurrentPopup outside a popup") end
  for i, p in ipairs(FI.popups) do if p == t.name then table.remove(FI.popups, i) break end end
end

------------------------------------------------------------ scoped blocks --
function api.BeginGroup() push("group") end
function api.EndGroup() pop("group", "EndGroup") end
function api.BeginDisabled(ctx, d) local on = (d == nil) or d; push("disabled", on); if on then FI.disabled = FI.disabled + 1 end end
function api.EndDisabled() local t = pop("disabled", "EndDisabled"); if t.name then FI.disabled = FI.disabled - 1 end end
function api.BeginCombo(ctx, label) return false end
function api.EndCombo() pop("combo", "EndCombo") end
function api.BeginTable() push("table") return true end
function api.EndTable() pop("table", "EndTable") end
function api.BeginDragDropSource() return false end
function api.BeginDragDropTarget() return false end
function api.EndDragDropSource() pop("dragsource", "EndDragDropSource") end
function api.EndDragDropTarget() pop("dragtarget", "EndDragDropTarget") end
function api.AcceptDragDropPayload() return false end
function api.SetDragDropPayload() end
function api.TreeNodeEx(ctx, id, label, flags)       -- ReaImGui: (ctx, str_id, label, flags); label may be omitted
  if type(label) == "number" or label == nil then flags, label = label, id end
  FI.selectables[#FI.selectables + 1] = label
  local open = not (FI.closed_nodes or {})[id]
  if open and (flags or 0) & constant("TreeNodeFlags_NoTreePushOnOpen") == 0 then push("tree", label) end
  return open
end
function api.TreePop() pop("tree", "TreePop") end
function api.SetNextItemOpen() end

local function counter(kind, pushname, popname)
  api[pushname] = function() FI.counts[kind] = FI.counts[kind] + 1 end
  api[popname] = function(ctx, n)
    n = n or 1
    FI.counts[kind] = FI.counts[kind] - n
    if FI.counts[kind] < 0 then fail(popname .. " without a matching " .. pushname) end
  end
end
counter("style", "PushStyleVar", "PopStyleVar")
counter("color", "PushStyleColor", "PopStyleColor")
counter("font", "PushFont", "PopFont")
counter("id", "PushID", "PopID")

----------------------------------------------------------------- widgets --
local function note(label) FI.last = label; FI.items = FI.items + 1; FI.seq[#FI.seq + 1] = label end
local function clicked(label)
  if FI.clicks[label] then FI.clicks[label] = nil return true end
  return false
end
local function text(ctx, t) FI.texts[#FI.texts + 1] = tostring(t); FI.last = "text:" .. tostring(t) end
api.Text, api.TextWrapped, api.TextDisabled, api.SeparatorText = text, text, text, text
function api.TextColored(ctx, col, t) text(ctx, t) end
local function button(ctx, label)
  FI.buttons[label] = { disabled = FI.disabled > 0 }
  note(label)
  if FI.disabled > 0 then FI.clicks[label] = nil return false end
  return clicked(label)
end
api.Button, api.SmallButton, api.InvisibleButton, api.ColorButton = button, button, button, button
function api.ArrowButton(ctx, id) return button(ctx, id) end
function api.RadioButton(ctx, label) FI.buttons[label] = {} note(label) return clicked(label) end
function api.Checkbox(ctx, label, v) FI.buttons[label] = {} note(label) if clicked(label) then return true, not v end return false, v end
function api.Selectable(ctx, label) FI.selectables[#FI.selectables + 1] = label note(label) return clicked(label) end
function api.MenuItem(ctx, label) FI.selectables[#FI.selectables + 1] = label note(label) return clicked(label) end
function api.InputText(ctx, label, buf) note(label) return false, buf end
api.InputTextMultiline, api.InputTextWithHint = api.InputText, api.InputText
function api.SliderInt(ctx, label, v) note(label) return false, v end
api.SliderDouble = api.SliderInt
function api.ColorPicker3(ctx, label, v) return false, v end

function api.IsItemHovered() return FI.hover_all end
function api.IsItemClicked() return false end
function api.IsItemActive() return false end
function api.IsItemActivated() return false end
function api.IsItemDeactivated() return false end
function api.IsAnyItemActive() return FI.any_active or false end
function api.IsMouseDoubleClicked() return false end
function api.IsMouseHoveringRect() return false end
function api.SetTooltip(ctx, t) if FI.last then (FI.tooltips or {})[FI.last] = t end end
FI.tooltips = {}
function api.IsKeyPressed(ctx, key)
  FI.queried_keys[key] = true
  if FI.keys[key] then FI.keys[key] = nil return true end   -- NB: real ReaImGui ignores window focus here too
  return false
end
function api.GetKeyMods() return 0 end
function api.GetMousePos() return 0, 0 end

------------------------------------------------------------ layout values --
function api.GetCursorPos() return 0, 0 end
function api.GetCursorPosX() return 0 end
function api.GetCursorPosY() return 0 end
function api.GetCursorScreenPos() FI.cursor_y = FI.cursor_y + 40 return 0, FI.cursor_y + FI.row_shift end
function api.GetItemRectMin() return 0, 0 end
function api.GetItemRectMax() return 10, 10 end
function api.GetContentRegionAvail()
  local w = (FI.in_main and FI.win.size_full) or { 440, 360 }
  return FI.avail_w or (w[1] - 36), FI.avail_h or (w[2] - 120)
end
function api.CalcTextSize(ctx, t) return #tostring(t) * 7, 16 end
function api.GetFrameHeight() return 30 end
function api.GetFrameHeightWithSpacing() return 38 end
function api.GetTextLineHeight() return 16 end
function api.GetTextLineHeightWithSpacing() return 24 end
function api.GetFontSize() return 18 end
function api.GetWindowDrawList() FI.draw = FI.draw or { n = 0 } return FI.draw end
for _, n in ipairs({ "AddLine", "AddRectFilled", "AddRect", "AddText", "AddTriangleFilled", "AddCircleFilled" }) do
  api["DrawList_" .. n] = function(dl) dl.n = dl.n + 1 end
end
function api.SetClipboardText() end

setmetatable(api, { __index = function (t, name)
  if constants[name] ~= nil then return constants[name] end
  if name:match("^[A-Z][A-Za-z0-9]*_[A-Za-z0-9]") and not name:match("^DrawList_") then return constant(name) end
  return function () end    -- layout / style calls with no effect on these tests
end })

return function (version) FI.version = version return api end

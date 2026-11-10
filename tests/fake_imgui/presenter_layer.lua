-- Presenter-specific recording on top of the hardened fake (imgui.lua, byte for byte the Verifier's t004 file).
-- Loaded by tests/harness.lua right after imgui.lua, so the same `FAKE_IMGUI` table gets:
--   FI.win                      = FI.windows.Presenter ({collapsed, docked, dock_hidden, size_full, shrink_on_collapse})
--   FI.user_collapse/user_expand/user_resize(w,h)/dock(hidden)/undock   what a user does to the window
--   FI.size_calls               every SetNextWindowSize: { w, h, cond, frame, target }; applied per ImGui's Cond_* rules
--   FI.begin_flags[name]        flags passed to Begin;  FI.begin_log  window names Begin was called with (this frame)
--   FI.child_log                { id, w, h, frame } per BeginChild (this frame)
--   FI.seq                      widget labels in draw order, with "child:<id>" markers (this frame)
--   FI.scroll_calls             { window = name, kind = "window"|"child", y }: which window each SetScrollY hit
--   FI.avail_w / FI.avail_h     override GetContentRegionAvail;  FI.row_shift moves GetCursorScreenPos (a row that moved)
--   FI.sizes[label]             height recorded for a widget (see FI.height_of): used by the vertical-space measurements
-- Also fixes two things the panel needs: PopupFlags_AnyPopup = AnyPopupId | AnyPopupLevel, and IsPopupOpen honouring
-- AnyPopupId (the hardened fake compares the id only, so "any popup open" was always false).
local FI = FAKE_IMGUI
local api = FI.api
local C = FI.constant

-- value widgets hand back "unchanged, same value" (the hardened fake has no slider/drag/input-number)
for _, name in ipairs({ "SliderInt", "SliderDouble", "DragInt", "DragDouble", "InputInt", "InputDouble" }) do
  api[name] = function(ctx, label, v) FI.last = label; return false, v end
end

FI.windows.Presenter = FI.windows.Presenter or {}
FI.win = FI.windows.Presenter
FI.size_calls, FI.begin_flags, FI.begin_log, FI.child_log, FI.seq, FI.scroll_calls = {}, {}, {}, {}, {}, {}
FI.row_shift, FI.sy = 0, 0
FI.hover_all = false
FI.sizes = {}

function FI.user_collapse() local w = FI.win; w.collapsed = true; if w.shrink_on_collapse then w.size_full = { 160, 26 } end end
function FI.user_expand() FI.win.collapsed = false end
function FI.user_resize(w, h) FI.win.size_full = { w, h } end
function FI.dock(hidden) FI.win.docked, FI.win.dock_hidden = true, hidden or false end
function FI.undock() FI.win.docked, FI.win.dock_hidden = false, false end

local reset_frame = FI.reset_frame
function FI.reset_frame()
  reset_frame()
  FI.seq, FI.begin_log, FI.child_log, FI.sy = {}, {}, {}, 0
end

-- window / child stack of this layer (names and kinds), for GetWindowSize / GetContentRegionAvail / SetScrollY
local stack = {}
local function top() return stack[#stack] end
local pending, pending_call = nil, nil

local o_next = api.SetNextWindowSize
function api.SetNextWindowSize(ctx, w, h, cond)
  cond = cond or C("Cond_Always")
  pending = { w, h, cond }
  pending_call = { w = w, h = h, cond = cond, frame = FI.frame }
  FI.size_calls[#FI.size_calls + 1] = pending_call
  return o_next(ctx, w, h, cond)
end

local o_begin, o_end = api.Begin, api.End
function api.Begin(ctx, name, open, flags)
  FI.begin_log[#FI.begin_log + 1] = name
  FI.begin_flags[name] = flags or 0
  local st = FI.windows[name]
  if not st then st = {}; FI.windows[name] = st end
  local first = not st.seen
  if first then st.seen = true; st.size_full = st.size_full or { 400, 300 } end
  if pending_call then pending_call.target = name end
  if pending then
    local cond = pending[3]
    local apply = cond == C("Cond_Always") or ((cond == C("Cond_FirstUseEver") or cond == C("Cond_Appearing") or cond == C("Cond_Once")) and first)
    if apply then st.size_full = { pending[1], pending[2] } end
  end
  pending, pending_call = nil, nil
  local prev_open = FI.window_open
  if name == "Presenter" and FI.win.close then FI.window_open = false end
  local visible, p_open = o_begin(ctx, name, open, flags)
  FI.window_open = prev_open
  if visible then stack[#stack + 1] = { name = name, kind = "window" } end
  return visible, p_open
end
function api.End(ctx) o_end(ctx); stack[#stack] = nil end

local o_child, o_endchild = api.BeginChild, api.EndChild
function api.BeginChild(ctx, id, w, h, cf, wf)
  FI.child_log[#FI.child_log + 1] = { id = id, w = w, h = h, frame = FI.frame }
  local ok = o_child(ctx, id, w, h, cf, wf)
  if ok then stack[#stack + 1] = { name = id, kind = "child" }; FI.seq[#FI.seq + 1] = "child:" .. id end
  return ok
end
function api.EndChild(ctx) o_endchild(ctx); stack[#stack] = nil end

local o_scroll = api.SetScrollY
function api.SetScrollY(ctx, y)
  o_scroll(ctx, y)
  local t = top()
  FI.scroll_calls[#FI.scroll_calls + 1] = { window = t.name, kind = t.kind, y = y }
end

function api.GetWindowSize(ctx)
  for i = #stack, 1, -1 do
    if stack[i].kind == "window" then local s = FI.windows[stack[i].name].size_full; return s[1], s[2] end
  end
  return 400, 300
end
function api.GetContentRegionAvail(ctx)
  local t = top()
  local w = (t and t.kind == "window" and t.name == "Presenter") and FI.win.size_full or { 440, 360 }
  return FI.avail_w or (w[1] - 36), FI.avail_h or (w[2] - 120)
end
function api.GetCursorScreenPos() FI.sy = FI.sy + 40; return 0, FI.sy + FI.row_shift end

-- widget labels in draw order
for _, name in ipairs({ "Button", "SmallButton", "InvisibleButton", "ArrowButton", "Selectable", "Checkbox", "RadioButton",
    "MenuItem", "TreeNodeEx", "SliderDouble", "SliderInt", "InputText" }) do
  local f = api[name]
  api[name] = function(ctx, label, ...)
    FI.seq[#FI.seq + 1] = label
    return f(ctx, label, ...)
  end
end

-- popups: AnyPopup = AnyPopupId | AnyPopupLevel; IsPopupOpen(ctx, '', AnyPopupId) = "is any popup open"
rawset(api, "PopupFlags_AnyPopup", C("PopupFlags_AnyPopupId") | C("PopupFlags_AnyPopupLevel"))
local o_ispop = api.IsPopupOpen
function api.IsPopupOpen(ctx, id, flags)
  if flags and flags & C("PopupFlags_AnyPopupId") ~= 0 then return next(FI.popups) ~= nil end
  return o_ispop(ctx, id, flags)
end

-- numeric getters the panel does arithmetic on (the hardened fake's catch-all returns nothing)
function api.GetCursorPos(ctx) return 0, api.GetCursorPosY(ctx) end
function api.GetCursorPosX() return 0 end
function api.GetItemRectMin() return 0, 0 end
function api.GetItemRectMax() return 10, 10 end
function api.GetMousePos() return 0, 0 end
function api.GetKeyMods() return FI.mods or 0 end
function api.GetTextLineHeight() return 16 end
function api.GetFrameHeight() return 30 end

-- The hardened fake's catch-all only makes constants for names like Key_A: Key_1..Key_9 (digit after the underscore)
-- come back as functions, so a test could never press a number key. Define them here (reported to the Verifier).
for d = 0, 9 do rawset(api, "Key_" .. d, C("Key_" .. d)) end

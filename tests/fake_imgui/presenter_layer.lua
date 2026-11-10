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

local fonts, vars, lay = {}, {}, {}
local reset_frame = FI.reset_frame
function FI.reset_frame()
  reset_frame()
  FI.seq, FI.begin_log, FI.child_log, FI.sy = {}, {}, {}, 0
  FI.toolbar_h, FI.body_h = nil, nil
  FI.draw_texts, FI.bcol, FI.tooltips = {}, {}, {}   -- per-frame records (the hardened fake keeps tooltips forever)
  for k in pairs(lay) do lay[k] = nil end
end

-- window / child stack of this layer (names and kinds), for GetWindowSize / GetContentRegionAvail / SetScrollY
local stack = {}
local function top() return stack[#stack] end
-- A small layout model, to MEASURE vertical space (not pixel-exact: ImGui's rules for the heights that matter here).
-- Frame widgets are font size + 2 * FramePadding.y tall, text is font size, explicit heights win, a new line adds
-- ItemSpacing.y, SameLine keeps the line (taller item wins). The body child's content height ends up in FI.body_h and
-- everything above the child in FI.toolbar_h.
local VAR_PAD, VAR_SP = C("StyleVar_FramePadding"), C("StyleVar_ItemSpacing")
local function eff(var, dx, dy)
  for i = #vars, 1, -1 do if vars[i].var == var then return vars[i].x, vars[i].y or vars[i].x end end
  return dx, dy
end
local function fsz() return fonts[#fonts] or 13 end
local function frame_h() local _, py = eff(VAR_PAD, 4, 3); return fsz() + 2 * py end
local function spacing_y() local _, sy = eff(VAR_SP, 8, 4); return sy end
local function path_key() local k = {} for _, e in ipairs(stack) do k[#k + 1] = e.name end return table.concat(k, "/") end
local function L() local k = path_key(); lay[k] = lay[k] or { y = 0, lineH = 0, started = false, same = false }; return lay[k] end
local function item(h)
  local l = L()
  if l.same then l.lineH = math.max(l.lineH, h); l.same = false
  else
    if l.started then l.y = l.y + l.lineH + spacing_y() end
    l.lineH, l.started = h, true
  end
end
local function extent(k) local l = lay[k]; return l and (l.y + l.lineH) or 0 end
FI.layout_extent = extent

local o_pushvar, o_popvar = api.PushStyleVar, api.PopStyleVar
function api.PushStyleVar(ctx, var, x, y) vars[#vars + 1] = { var = var, x = x, y = y }; return o_pushvar(ctx, var, x, y) end
function api.PopStyleVar(ctx, n) for _ = 1, (n or 1) do vars[#vars] = nil end return o_popvar(ctx, n) end
local o_pushfont, o_popfont = api.PushFont, api.PopFont
function api.PushFont(ctx, f, size) fonts[#fonts + 1] = size; return o_pushfont(ctx, f, size) end
function api.PopFont(ctx) fonts[#fonts] = nil; return o_popfont(ctx) end
local o_same = api.SameLine
function api.SameLine(ctx, ...) L().same = true; return o_same(ctx, ...) end
function api.Spacing(ctx) item(0) end
function api.Separator(ctx) item(1) end
function api.Dummy(ctx, w, h) item(h or 0) end

local HEIGHT = {
  Button = function(w, h) return (h and h > 0) and h or frame_h() end,
  InvisibleButton = function(w, h) return h or 0 end,
}
HEIGHT.SmallButton = function() return fsz() + 2 * 0 + 2 end
HEIGHT.ArrowButton = frame_h
HEIGHT.Checkbox, HEIGHT.RadioButton, HEIGHT.SliderDouble, HEIGHT.SliderInt, HEIGHT.InputText = frame_h, frame_h, frame_h, frame_h, frame_h
HEIGHT.Selectable = function() return fsz() end
HEIGHT.MenuItem = frame_h
HEIGHT.TreeNodeEx = frame_h
local ARGS = { Button = 3, InvisibleButton = 3 }   -- widgets whose 3rd/4th args are w, h (after ctx, label)
-- colours: FI.bcol[label] = the Col_Button colour in force when that button was drawn; FI.draw_texts = DrawList_AddText strings
local colstack = {}
local o_psc, o_ppc = api.PushStyleColor, api.PopStyleColor
function api.PushStyleColor(ctx, col, val) colstack[#colstack + 1] = { col, val }; return o_psc(ctx, col, val) end
function api.PopStyleColor(ctx, n) for _ = 1, (n or 1) do colstack[#colstack] = nil end return o_ppc(ctx, n) end
local function cur_col(col) for i = #colstack, 1, -1 do if colstack[i][1] == col then return colstack[i][2] end end end
FI.bcol, FI.draw_texts = {}, {}
function api.DrawList_AddText(dl, x, y, col, text) FI.draw_texts[#FI.draw_texts + 1] = tostring(text) end
-- widget labels in draw order
for _, name in ipairs({ "Button", "SmallButton", "InvisibleButton", "ArrowButton", "Selectable", "Checkbox", "RadioButton",
    "MenuItem", "TreeNodeEx", "SliderDouble", "SliderInt", "InputText" }) do
  local f = api[name]
  api[name] = function(ctx, label, a, b, ...)
    FI.seq[#FI.seq + 1] = label
    FI.bcol[label] = cur_col(C("Col_Button"))
    if HEIGHT[name] then
      local h = HEIGHT[name]
      if name == "Button" or name == "InvisibleButton" then item(h(a, b)) else item(h()) end
    end
    return f(ctx, label, a, b, ...)
  end
end
local o_text = api.Text
for _, name in ipairs({ "Text", "TextWrapped", "TextDisabled", "TextColored", "SeparatorText" }) do
  local f = api[name]
  api[name] = function(...) item(fsz()); return f(...) end
end

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
  if ok then
    FI.toolbar_h = FI.toolbar_h or extent(path_key())
    stack[#stack + 1] = { name = id, kind = "child" }; FI.seq[#FI.seq + 1] = "child:" .. id
    lay[path_key()] = nil
  end
  return ok
end
function api.EndChild(ctx)
  FI.body_h = extent(path_key())
  o_endchild(ctx); stack[#stack] = nil
end

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

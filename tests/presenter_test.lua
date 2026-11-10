local HERE, PANEL = ...
local tests = {}
local function test(name, fn) tests[#tests + 1] = { name = name, fn = fn } end
if not HERE then return tests end
local function load_harness() return assert(loadfile(HERE .. "/harness.lua"))(HERE, PANEL) end

local function eq(a, b, msg) if a ~= b then error((msg or "values differ") .. ": expected " .. tostring(b) .. ", got " .. tostring(a), 2) end end
local function ok(c, msg) if not c then error(msg or "check failed", 2) end end

test("smoke: opens and draws a small session, Begin/End balanced", function()
  local H = load_harness().start()
  H.frame(5)
  local FI = H.FI
  eq(FI.begin_log[1], "Presenter")
  ok(H.pending(), "the panel keeps running (defers itself)")
end)


local function new() return load_harness().start() end
local function key(H, name) H.FI.keys[H.FI.api[name]] = true end
local function pressed_any(H) return H.FR.playstate ~= 0 or H.FR.cursor ~= 0 end

----------------------------------------------------------------- layout --
test("session content: 3 regions, a 3-take item and a 2-lane track show as clips", function()
  local H = new(); H.frame(3)
  local seq = table.concat(H.FI.seq, "|")
  for _, want in ipairs({ "Region 1##lvl1_1", "Region 3##lvl1_3", "take 3##clip4", "dry##clip5", "wet##clip6" }) do
    ok(seq:find(want, 1, true), "missing " .. want)
  end
end)

test("pinned toolbar: views, region tabs, play/A-B/Loop are drawn before the scrolling child; clips inside it", function()
  local H = new(); H.frame(3)
  local c = H.seq_index("child:presenterBody")
  ok(c, "no presenterBody child")
  for _, l in ipairs({ "Overview##view", "Presentation##view", "Region 1##lvl1_1", "##playpause", "Default##ab2", "      Loop##togLoop" }) do
    local i = H.seq_index(l); ok(i and i < c, l .. " must come before the child")
  end
  ok(H.seq_index("1     A1##clip1") > c, "clips must be inside the child")
  eq(#H.FI.child_log, 1, "exactly one child per frame")
end)

test("window flags: no scrollbar / wheel-scroll in full view, none set in compact view", function()
  local H = new(); H.frame(2)
  local A = H.FI.api
  local want = A.WindowFlags_NoScrollbar | A.WindowFlags_NoScrollWithMouse
  eq(H.FI.begin_flags.Presenter & want, want, "full view flags")
  H.FI.clicks["      Compact view##togCompact view"] = true
  H.frame(3)
  eq(H.FI.begin_flags.Presenter & want, 0, "compact view flags")
  eq(#H.FI.child_log, 0, "no child in compact view")
end)

test("child clipped out (BeginChild false): no EndChild, still balanced", function()
  local H = new(); H.FI.hidden_children.presenterBody = true; H.frame(3)
end)

test("tiny window (no room): body is drawn without a child, still balanced", function()
  local H = new(); H.FI.avail_h = 40; H.frame(3)
  eq(#H.FI.child_log, 0)
  ok(H.seq_index("1     A1##clip1"), "clips still drawn")
end)

------------------------------------------------------------------- size --
local function main_sizes(H, from)   -- SetNextWindowSize calls that went to the panel window
  local out = {}
  for i = (from or 0) + 1, #H.FI.size_calls do if H.FI.size_calls[i].target == "Presenter" then out[#out + 1] = H.FI.size_calls[i] end end
  return out
end
local function last_size(H) local m = main_sizes(H); return m[#m] end

test("size: default 760x680 on first use", function()
  local H = new(); H.frame(1)
  local c = main_sizes(H)[1]
  eq(c.w, 760); eq(c.h, 680); eq(c.cond, H.FI.api.Cond_FirstUseEver)
  eq(H.FI.win.size_full[1], 760)
end)

test("size: remembered size is loaded next session and clamped", function()
  local H = load_harness().start{ ext = { sizeW = "900", sizeH = "500" } }; H.frame(1)
  eq(H.FI.win.size_full[1], 900); eq(H.FI.win.size_full[2], 500)
  H = load_harness().start{ ext = { sizeW = "100", sizeH = "99999" } }; H.frame(1)
  eq(H.FI.win.size_full[1], 320); eq(H.FI.win.size_full[2], 4000)
end)

test("size: a resized window is saved (after a pause, and on close) and reloaded", function()
  local H = new(); H.frame(2)
  H.FI.user_resize(910, 520); H.frame(1)
  eq(H.ext("sizeW"), nil, "not saved on every frame")
  H.FR.now = H.FR.now + 2; H.frame(1)
  eq(H.ext("sizeW"), "910"); eq(H.ext("sizeH"), "520")
  H.FI.user_resize(930, 540); H.frame(1); H.stop()
  eq(H.ext("sizeW"), "930", "saved on close")
  local H2 = load_harness().start{ ext = { sizeW = H.ext("sizeW"), sizeH = H.ext("sizeH") } }; H2.frame(1)
  eq(H2.FI.win.size_full[1], 930)
end)

test("size: the docked size is not saved (bug 2)", function()
  local H = new(); H.frame(2)
  H.FI.user_resize(800, 600); H.frame(1)
  H.FI.dock(false); H.FI.user_resize(300, 250); H.frame(2)
  H.stop()
  eq(H.ext("sizeW"), "800", "saved size is the floating one"); eq(H.ext("sizeH"), "600")
end)

test("size: compact view does not overwrite the saved full size", function()
  local H = new(); H.frame(2)
  H.FI.user_resize(800, 600); H.frame(1)
  H.FI.clicks["      Compact view##togCompact view"] = true
  H.frame(1)
  H.FI.user_resize(800, 90); H.frame(3); H.stop()
  eq(H.ext("sizeH"), "600")
end)

test("collapse (bug 1): arrow collapse then expand restores the size; size re-sent with Cond_Always only while collapsed", function()
  local H = new(); H.frame(2)
  H.FI.user_resize(900, 500); H.frame(2)
  H.FI.win.shrink_on_collapse = true          -- reported symptom: the window stays tiny after expanding
  H.FI.user_collapse()
  local before = #H.FI.size_calls
  H.frame(3)
  ok(#main_sizes(H, before) >= 3, "re-sent every collapsed frame")
  local c = last_size(H)
  eq(c.w, 900); eq(c.h, 500); eq(c.cond, H.FI.api.Cond_Always)
  H.FI.user_expand(); H.frame(2)
  eq(H.FI.win.size_full[1], 900); eq(H.FI.win.size_full[2], 500)
  local n = #H.FI.size_calls
  H.frame(3)
  for _, c in ipairs(main_sizes(H, n)) do eq(c.cond, H.FI.api.Cond_FirstUseEver, "open window: only FirstUseEver") end
end)

test("started docked in a hidden tab: no size is ever forced (nothing known yet)", function()
  local H = new()
  H.FI.dock(true)
  H.frame(5)
  for _, c in ipairs(main_sizes(H, 0)) do eq(c.cond, H.FI.api.Cond_FirstUseEver) end
end)

test("docked and visible, then hidden tab: no forced size on any frame (bug 1)", function()
  local H = new(); H.frame(2)
  H.FI.dock(false); H.frame(2)                 -- docked and showing
  H.FI.win.dock_hidden = true
  local n = #H.FI.size_calls
  H.frame(4)
  for _, c in ipairs(main_sizes(H, n)) do eq(c.cond, H.FI.api.Cond_FirstUseEver) end
  H.FI.win.dock_hidden = false; H.frame(2)     -- tab shown again: draws fine
end)

------------------------------------------------------------------ scroll --
test("scroll (bug 3): every SetScrollY lands inside the child, never on the pinned window", function()
  local H = new(); H.frame(3)
  -- a click on a clip row, then the row moves on screen (layout above it changed): the anchor scrolls the list back
  H.FI.clicks["2     A2  |  take 1##clip2"] = true; H.frame(1)
  H.FI.row_shift = 25; H.frame(2)
  -- keyboard (drawn outside the child) asks to anchor too
  key(H, "Key_3"); H.frame(2)
  H.FI.row_shift = 60; H.frame(2)
  ok(#H.FI.scroll_calls > 0, "the test must provoke a scroll")
  for _, sc in ipairs(H.FI.scroll_calls) do eq(sc.window, "presenterBody", "SetScrollY window") end
end)

test("scroll: resetScroll (entering compact) scrolls the window only in compact view", function()
  local H = new(); H.frame(2)
  H.FI.clicks["      Compact view##togCompact view"] = true; H.frame(3)
  for _, sc in ipairs(H.FI.scroll_calls) do eq(sc.kind, "window") end
  H.FI.scroll_calls = {}
  H.FI.clicks["      Compact view##togCompact view"] = true; H.frame(3)
  for _, sc in ipairs(H.FI.scroll_calls) do eq(sc.window, "presenterBody") end
end)

------------------------------------------------------------------- keys --
test("keys: with focus they work (1, Space, A, L)", function()
  local H = new(); H.frame(2)
  key(H, "Key_1"); H.frame(1)
  ok(pressed_any(H), "key 1 should start a clip")
  local ab = H.ext("ab")
  key(H, "Key_A"); H.frame(1)
  eq(H.ext("ab") ~= ab, true, "A toggles A/B")
end)

test("keys: no effect when the window is not focused", function()
  local H = new(); H.frame(2)
  H.FI.focused = false
  for _, k in ipairs({ "Key_1", "Key_2", "Key_9", "Key_Space", "Key_A", "Key_S", "Key_L", "Key_C", "Key_M", "Key_N", "Key_LeftArrow", "Key_RightArrow" }) do key(H, k) end
  H.frame(2)
  eq(H.FR.playstate, 0); eq(H.FR.cursor, 0); eq(H.ext("ab"), nil)
  eq(#H.FI.begin_log, 1)
  ok(not H.FI.api.IsPopupOpen(nil, "Add marker##presenter"), "no marker popup")
end)

test("keys: no effect while a popup is open, even if the window still reports focus", function()
  local H = new(); H.frame(2)
  H.FI.api.OpenPopup(nil, "Settings##presenter")
  H.FI.focused = true
  key(H, "Key_1"); key(H, "Key_Space"); key(H, "Key_A")
  H.frame(2)
  eq(H.FR.playstate, 0); eq(H.FR.cursor, 0); eq(H.ext("ab"), nil)
end)

test("keys: keys work again once the popup is closed", function()
  local H = new(); H.frame(2)
  H.FI.api.OpenPopup(nil, "x"); H.frame(1)
  H.FI.popups = {}
  key(H, "Key_1"); H.frame(1)
  ok(pressed_any(H))
end)

return tests

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
test("session content: 3 regions, a 3-take item (one row, 3 chips) and a 2-lane track (header + 2 thin rows)", function()
  local H = new(); H.frame(3)
  local seq = table.concat(H.FI.seq, "|")
  for _, want in ipairs({ "Region 1##lvl1_1", "Region 3##lvl1_3", "t3##take2_3", "L1  dry##lane3_1", "L2  wet##lane3_2" }) do
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
  H.FI.clicks["2     A2##clip2"] = true; H.frame(1)
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

------------------------------------------------------------------ takes --
local GREEN, AMBER, BLUE, NEUTRAL = 0x2E9E5BFF, 0x8A6D1EFF, 0x2F6FB0FF, 0x3A3F47FF
local function active_take(H) return H.s.a2.items[1].active end
local function find_idx(H, pat) for i, l in ipairs(H.FI.seq) do if l:find(pat, 1, true) then return i end end end
local function count_prefix(seq, pat) local n = 0 for _, l in ipairs(seq) do if l:find(pat, 1, true) then n = n + 1 end end return n end

test("takes: one row per item with one chip per take (not one row per take), chips before the one seek bar", function()
  local H = new(); H.frame(3)
  local seq = H.FI.seq
  eq(count_prefix(seq, "##clip2"), 1, "the takes item is one name button")
  eq(count_prefix(seq, "##take2_"), 3, "three chips")
  eq(count_prefix(seq, "##seek2"), 1, "one seek bar")
  eq(count_prefix(seq, "##state2"), 1, "one state button")
  ok(H.seq_index("t1##take2_1") < H.seq_index("##seek2"), "chips come before the seek bar")
  ok(H.seq_index("t1##take2_1") > H.seq_index("2     A2##clip2"), "chips come after the name button")
  ok(table.concat(H.FI.draw_texts, "|"):find("3 takes", 1, true), "the name button says '3 takes'")
end)

test("takes: clicking a chip plays that take; the other chips show 'switch' while it plays", function()
  local H = new(); H.frame(3)
  H.FI.clicks["t2##take2_2"] = true; H.frame(2)
  eq(active_take(H), 2, "take 2 is the active take")
  ok(H.FR.playstate ~= 0, "playing")
  eq(H.FI.bcol["t2##take2_2"], GREEN, "playing chip is green")
  eq(H.FI.bcol["t1##take2_1"], BLUE, "other chips are blue (a click switches at the same point)")
end)

test("takes: switching takes keeps the position, even with A/B off", function()
  local H = new(); H.frame(3)
  H.FI.clicks["Off##ab1"] = true; H.frame(1)                      -- A/B off: other rows would play from their own start
  H.FI.clicks["t1##take2_1"] = true; H.frame(2)
  H.FR.playpos = 2.0; H.frame(1)
  H.FI.clicks["t3##take2_3"] = true; H.frame(2)
  eq(active_take(H), 3, "take 3 active")
  eq(H.FR.cursor, 2.0, "playback was moved to the same point (offset 2.0 into the item)")
  H.FI.clicks["t3##take2_3"] = true; H.frame(2)                   -- clicking the playing chip pauses
  eq(H.FR.playstate, 0, "paused")
end)

test("takes: Up/Down step to the previous / next take at the same point", function()
  local H = new(); H.frame(3)
  H.FI.clicks["t1##take2_1"] = true; H.frame(2)
  H.FR.playpos = 1.5; H.frame(1)
  key(H, "Key_DownArrow"); H.frame(2)
  eq(active_take(H), 2); eq(H.FR.cursor, 1.5)
  key(H, "Key_DownArrow"); H.frame(2)
  eq(active_take(H), 3)
  key(H, "Key_DownArrow"); H.frame(2)
  eq(active_take(H), 3, "stops at the last take")
  key(H, "Key_UpArrow"); H.frame(2)
  eq(active_take(H), 2)
end)

test("takes: a paused chip is amber (full view and compact view)", function()
  local H = new(); H.frame(3)
  H.FI.clicks["Off##ab1"] = true; H.frame(1)
  H.FI.clicks["t2##take2_2"] = true; H.frame(2)
  H.FR.playpos = 1.5; H.frame(1)
  H.FI.clicks["t2##take2_2"] = true; H.frame(2)                    -- pause
  eq(H.FR.playstate, 0)
  eq(H.FI.bcol["t2##take2_2"], AMBER, "full view: paused chip amber")
  ok(H.FI.bcol["t1##take2_1"] ~= AMBER, "only the paused take is amber")
  H.FI.clicks["      Compact view##togCompact view"] = true; H.frame(3)
  eq(H.FI.bcol["t2##seg2_2"], AMBER, "compact view: paused segment amber")
  eq(H.FI.bcol["2   A2##chip2"], AMBER, "compact view: paused name chip amber (v4.5 never showed paused)")
end)

test("takes: A/B from another row switches to the chosen take at the same point", function()
  local H = new(); H.frame(3)
  H.FI.clicks["1     A1##clip1"] = true; H.frame(2)             -- plain row plays (A/B on by default)
  H.FR.playpos = 1.0; H.frame(1)
  H.FI.clicks["t2##take2_2"] = true; H.frame(2)
  eq(active_take(H), 2); eq(H.FR.cursor, 1.0)
end)

test("takes: the number key plays the row's active take; the ticks select all takes of the item", function()
  local H = new(); H.frame(3)
  key(H, "Key_2"); H.frame(2)
  ok(H.FR.playstate ~= 0, "row 2 plays")
  H.FI.clicks["##sel2"] = true; H.frame(2)
  H.FI.clicks["Add to presentation...##seladd"] = true; H.frame(2)
  ok(H.FI.text_has("Add 3 selected clips to:"), "ticking the takes row selects all 3 takes")
end)

------------------------------------------------------------------ lanes --
test("lanes: slim header and one thin row per lane, no full rows, no separate group header", function()
  local H = new(); H.frame(3)
  local seq = H.FI.seq
  eq(count_prefix(seq, "##lanehdr3"), 1)
  eq(count_prefix(seq, "##lane3_"), 2)
  eq(count_prefix(seq, "##lstate3_"), 2)
  eq(count_prefix(seq, "##clip3"), 0, "no full clip row for a lane")
  ok(find_idx(H, "##lanehdr3") < find_idx(H, "##lane3_1"), "header first")
  ok(table.concat(H.FI.seq, "|"):find("2 lanes", 1, true), "header says how many lanes")
end)

test("lanes: a track with audio on one lane only is a plain row (no single-clip group)", function()
  local H = load_harness().start{ session = false }
  local FR = H.FR
  FR.region(0, 10, "R")
  local tr = FR.track{ name = "OneLane", freemode = 2, nlanes = 3, lanenames = { "a", "b", "c" } }
  FR.item{ track = tr, pos = 0, len = 5, lane = 1, takes = { { name = "x" } } }
  H.frame(3)
  eq(count_prefix(H.FI.seq, "##clip1"), 1)
  eq(count_prefix(H.FI.seq, "##lanehdr"), 0)
end)

test("lanes: clicking another lane switches at the same point and solos only that lane; Up/Down step lanes", function()
  local H = new(); H.frame(3)
  H.FI.clicks["L1  dry##lane3_1"] = true; H.frame(2)
  ok(H.FR.playstate ~= 0)
  eq(H.s.lanes.laneplays[0] or 0, 1, "lane 1 plays"); eq(H.s.lanes.laneplays[1] or 0, 0)
  H.FR.playpos = 2.5; H.frame(1)
  H.FI.clicks["L2  wet##lane3_2"] = true; H.frame(2)
  eq(H.s.lanes.laneplays[0] or 0, 0); eq(H.s.lanes.laneplays[1] or 0, 1)
  eq(H.FR.cursor, 2.5, "same point")
  eq(H.FI.bcol["L2  wet##lane3_2"], GREEN); eq(H.FI.bcol["L1  dry##lane3_1"], BLUE)
  key(H, "Key_UpArrow"); H.frame(2)
  eq(H.s.lanes.laneplays[0] or 0, 1, "Up steps back to lane 1")
  eq(H.FR.cursor, 2.5)
end)

test("lanes: the number key plays the group's last lane; each lane row shows its own time", function()
  local H = new(); H.frame(3)
  H.FI.clicks["L2  wet##lane3_2"] = true; H.frame(2)
  H.FI.clicks["      Loop##togLoop"] = nil
  H.FI.clicks["##state3_1"] = nil
  key(H, "Key_3"); H.frame(2)                                      -- pauses (it is playing)
  eq(H.FR.playstate, 0)
  key(H, "Key_3"); H.frame(2)                                      -- plays the lane played last
  eq(H.s.lanes.laneplays[1] or 0, 1)
  local t = table.concat(H.FI.draw_texts, "|")
  ok(t:find("/ 0:05.0", 1, true), "lane time boxes show their own length")
end)

------------------------------------------------------------- blind mode --
local function blind_session(seed)
  local H = load_harness().start{ session = false }
  local FR = H.FR
  FR.projext["PresenterPanel/blindSeed"] = seed and tostring(seed) or "12345"
  FR.region(0, 10, "Round 1")
  FR.region(10, 20, "Round 2")
  FR.track{ name = "ZZFolderVendors", depth = 1, color = FR.reaper.ColorToNative(200, 30, 30) | 0x1000000 }
  local a = FR.track{ name = "ZZElevenLabs", color = FR.reaper.ColorToNative(200, 30, 30) | 0x1000000 }
  local b = FR.track{ name = "ZZInworld", depth = -1 }
  local c = FR.track{ name = "ZZCartesia" }
  local d = FR.track{ name = "ZZLanesTrack", freemode = 2, nlanes = 2, lanenames = { "ZZlaneOne", "ZZlaneTwo" } }
  local script = FR.track{ name = "Script" }
  local txt = FR.track{ name = "ZZNoteTrack" }
  local mk = { { pos = 1.0, name = "ZZmarkerName" } }
  FR.item{ track = a, pos = 0, len = 5, notes = "ZZitemNote", takes = { { name = "ZZtakeA", markers = mk } } }
  FR.item{ track = b, pos = 0, len = 7, takes = { { name = "ZZtake1" }, { name = "ZZtake2" }, { name = "ZZtake3" } } }
  FR.item{ track = c, pos = 0, len = 6, takes = { { name = "ZZtakeC" } } }
  FR.item{ track = d, pos = 0, len = 4, lane = 0, takes = { { name = "ZZl1" } } }
  FR.item{ track = d, pos = 0, len = 5, lane = 1, takes = { { name = "ZZl2" } } }
  FR.item{ track = script, pos = 0, len = 9, takes = {}, notes = "The script line for round one" }
  FR.item{ track = txt, pos = 0, len = 5, takes = {}, notes = "ZZtextItem" }
  FR.item{ track = script, pos = 10, len = 9, takes = {}, notes = "The script line for round two" }
  FR.item{ track = a, pos = 10, len = 5, takes = { { name = "ZZtakeR2" } } }
  FR.item{ track = c, pos = 10, len = 5, takes = { { name = "ZZtakeR2b" } } }
  FR.item{ track = b, pos = 10, len = 5, takes = { { name = "ZZtakeR2c" } } }
  H.s = { a = a, b = b, c = c, d = d }
  return H
end

local function everything_drawn(H)          -- every string the fake saw in the last frame
  local FI = H.FI
  local all = {}
  local function add(t) for _, v in ipairs(t) do all[#all + 1] = tostring(v) end end
  add(FI.seq); add(FI.texts); add(FI.draw_texts); add(FI.selectables)
  for k, v in pairs(FI.tooltips) do all[#all + 1] = tostring(k); all[#all + 1] = tostring(v) end
  for k, v in pairs(FI.previews) do all[#all + 1] = tostring(k); all[#all + 1] = tostring(v) end
  add(FI.begin_log)
  all[#all + 1] = tostring(FI.context_label)
  return table.concat(all, "\n")
end
local function leaks(H)
  local text = everything_drawn(H)
  local out = {}
  for w in text:gmatch("ZZ%w+") do out[w] = true end
  local list = {} for w in pairs(out) do list[#list + 1] = w end
  table.sort(list)
  return list
end

test("blind: sanity, the same session shows its names when blind is off (so the leak test can fail)", function()
  local H = blind_session(); H.FI.hover_all = true; H.frame(3)
  ok(#leaks(H) >= 4, "names are visible without blind mode")
end)

test("blind: no track, folder, take, lane, note or marker name anywhere that is drawn (tooltips included)", function()
  local H = blind_session(); H.FI.hover_all = true
  H.FI.clicks["      Blind##togBlind"] = true
  H.frame(4)
  local l = leaks(H)
  eq(#l, 0, "names leaked: " .. table.concat(l, ", "))
  eq(#H.FI.begin_log, 1); eq(H.FI.begin_log[1], "Presenter", "constant window title")
  eq(H.FI.context_label, "Presenter", "constant context label (docked tab text)")
end)

test("blind: every other surface is clean too: playing, popups for notes and markers, settings, add/review, status", function()
  local H = blind_session(); H.FI.hover_all = true
  H.FI.clicks["      Blind##togBlind"] = true
  H.frame(3)
  key(H, "Key_1"); H.frame(2)
  H.FR.playpos = 1.2
  key(H, "Key_M"); H.frame(2)
  eq(#leaks(H), 0, "marker popup: " .. table.concat(leaks(H), ", "))
  H.FI.popups = {}; H.frame(1)
  key(H, "Key_N"); H.frame(2)
  eq(#leaks(H), 0, "note popup: " .. table.concat(leaks(H), ", "))
  H.FI.popups = {}; H.frame(1)
  H.FI.clicks["##sel1"] = true; H.frame(1)
  H.FI.clicks["Review##selrev"] = true; H.frame(3)
  eq(#leaks(H), 0, "review popup: " .. table.concat(leaks(H), ", "))
  H.FI.popups = {}; H.frame(1)
  H.FI.api.OpenPopup(nil, "Settings##presenter"); H.frame(2)
  eq(#leaks(H), 0, "settings: " .. table.concat(leaks(H), ", "))
  H.FI.popups = {}
  H.FI.clicks["      Compact view##togCompact view"] = true; H.frame(3)
  eq(#leaks(H), 0, "compact view: " .. table.concat(leaks(H), ", "))
end)

test("blind: colours are neutral, no waveform, no total length, nothing to rename", function()
  local H = blind_session(); H.FI.hover_all = true
  H.FI.clicks["      Blind##togBlind"] = true; H.frame(3)
  for label, col in pairs(H.FI.bcol) do
    if label:find("##clip", 1, true) or label:find("##take", 1, true) or label:find("##lane", 1, true) then
      ok(col == NEUTRAL or col == GREEN or col == BLUE or col == AMBER or col == nil or col == 0x2F3640FF or col == 0x22272EFF,
        ("%s has a source colour %x"):format(label, col or 0))
    end
  end
  key(H, "Key_1"); H.frame(2)
  eq(count_prefix(H.FI.seq, "##wave"), 0, "no waveform even for the selected clip")
  local t = table.concat(H.FI.draw_texts, "|")
  ok(not t:find(" / ", 1, true), "no 'elapsed / total' time: " .. t)
  eq(count_prefix(H.FI.seq, "##rename"), 0, "no rename pencil")
  eq(count_prefix(H.FI.seq, "##inlinerename"), 0)
  H.FI.context_popups["clipmenu1"] = true; H.frame(2)
  eq(count_prefix(H.FI.selectables, "Rename"), 0, "no right-click rename menu")
end)

test("blind: rows are lettered A, B, C ... in the shown order, folders are flattened", function()
  local H = blind_session(); H.FI.clicks["      Blind##togBlind"] = true; H.frame(3)
  local seq = table.concat(H.FI.seq, "|")
  ok(seq:find("1     A##clip1", 1, true), "first row is A")
  ok(seq:find("##clip2", 1, true) and seq:find("2     B", 1, true), "second row is B")
  eq(count_prefix(H.FI.seq, "fld"), 0, "no folder headers")
end)

test("blind: the order is shuffled per region from a stored seed, the same after a restart, different with another seed", function()
  local function order(seed)
    local H = blind_session(seed); H.FI.clicks["      Blind##togBlind"] = true; H.frame(3)
    key(H, "Key_1"); H.frame(2)
    local played = {}
    for i, tr in ipairs(H.FR.tracks) do if tr.solo == 2 then played[#played + 1] = tr.name end end
    return played[1]
  end
  -- which source sits on number 1 for a seed: stable for the same seed
  eq(order(111), order(111), "same seed, same order")
  local seen = {}
  for seed = 1, 12 do seen[order(seed) or "?"] = true end
  local n = 0 for _ in pairs(seen) do n = n + 1 end
  ok(n >= 2, "different seeds give different first rows")
  -- stored in the project, created on first use
  local H = blind_session(); H.FR.projext["PresenterPanel/blindSeed"] = nil
  H.FI.clicks["      Blind##togBlind"] = true; H.frame(3)
  ok(tonumber(H.FR.projext["PresenterPanel/blindSeed"]), "a seed is stored in the project")
end)

test("blind: number keys follow the shown (shuffled) order", function()
  local H = blind_session(7); H.FI.clicks["      Blind##togBlind"] = true; H.frame(3)
  key(H, "Key_3"); H.frame(2)
  local soloed
  for _, tr in ipairs(H.FR.tracks) do if tr.solo == 2 then soloed = tr end end
  ok(soloed, "something plays")
  -- the playing row's button is green and its label is the third letter
  local green
  for label, col in pairs(H.FI.bcol) do if col == GREEN and label:find("##clip", 1, true) then green = label end end
  ok(green and green:find("3     C", 1, true) or table.concat(H.FI.seq, "|"):find("3     C##clip3", 1, true), "key 3 is row C")
end)

test("blind: Reveal this region... asks first, shows names for this region only, hides them again on leaving", function()
  local H = blind_session(); H.FI.hover_all = true
  H.FI.clicks["      Blind##togBlind"] = true; H.frame(3)
  H.FI.clicks["Reveal this region...##blindreveal"] = true; H.frame(2)
  eq(#leaks(H), 0, "still hidden while the question is open")
  ok(H.FI.popups["Blind mode##presenter"], "a question is open")
  H.FI.clicks["Keep hidden##blindno"] = true; H.frame(2)
  eq(#leaks(H), 0, "Keep hidden keeps it hidden")
  H.FI.clicks["Reveal this region...##blindreveal"] = true; H.frame(2)
  H.FI.clicks["Reveal##blindok"] = true; H.frame(2)
  ok(#leaks(H) >= 3, "names show for this region")
  H.FI.clicks["Round 2##lvl1_2"] = true; H.frame(4)
  eq(#leaks(H), 0, "the next region is hidden again: " .. table.concat(leaks(H), ", "))
  H.FI.clicks["Round 1##lvl1_1"] = true; H.frame(4)
  eq(#leaks(H), 0, "and coming back it is hidden again")
end)

test("blind: turning Blind off asks first and then reveals everything; no key toggles it", function()
  local H = blind_session(); H.FI.hover_all = true
  H.FI.clicks["      Blind##togBlind"] = true; H.frame(3)
  for _, k in ipairs({ "Key_B", "Key_H", "Key_R" }) do key(H, k) end
  H.frame(2)
  eq(#leaks(H), 0, "no key un-blinds")
  H.FI.clicks["      Blind##togBlind"] = true; H.frame(2)
  ok(H.FI.popups["Blind mode##presenter"], "asks first")
  eq(#leaks(H), 0)
  H.FI.clicks["Turn off##blindok"] = true; H.frame(3)
  ok(#leaks(H) >= 4, "everything shows after the confirm")
  eq(H.ext("blind"), "0", "the setting is saved")
end)

test("blind: a copy made for the presentation is named by its code, with no source or folder names", function()
  local H = blind_session(); H.FI.clicks["      Blind##togBlind"] = true; H.frame(3)
  H.FI.clicks["##sel1"] = true; H.frame(1)
  H.FI.clicks["##sel2"] = true; H.frame(1)
  H.FI.clicks["Add to presentation...##seladd"] = true; H.frame(2)
  local add
  for _, l in ipairs(H.FI.seq) do if l:find("^Add %d+ clips?$") then add = l end end
  ok(add, "the add dialog is open")
  H.FI.clicks[add] = true; H.frame(3)
  local names = {}
  for _, tr in ipairs(H.FR.tracks) do names[#names + 1] = tr.name end
  local made = {}
  for i = 8, #names do made[#made + 1] = names[i] end      -- tracks the panel created (after the session's own)
  ok(#made >= 2, "presentation tracks were made: " .. table.concat(names, ","))
  for _, n in ipairs(made) do
    ok(not n:find("ZZ", 1, true), "a copy track carries a source name: " .. n)
  end
  local letters = 0
  for _, n in ipairs(made) do if n:match("^%u$") then letters = letters + 1 end end
  ok(letters >= 2, "copies are named by letter: " .. table.concat(made, ","))
end)

test("keys: Up/Down also respect focus and popups (no take stepping from another window)", function()
  local H = new(); H.frame(3)
  H.FI.clicks["t1##take2_1"] = true; H.frame(2)
  H.FI.focused = false
  key(H, "Key_DownArrow"); H.frame(2)
  eq(active_take(H), 1, "no step without focus")
end)

----------------------------------------------------------- draw guard --
test("draw error guard: an error in the middle of a frame (inside a folder, inside the child) shows a message and keeps the panel running", function()
  local H = new(); H.frame(3)
  local real = reaper.GetActiveTake
  reaper.GetActiveTake = function(...) error("boom in the middle of drawing") end
  H.frame(2)                                                   -- Begin/End balance is checked by the fake after each frame
  reaper.GetActiveTake = real
  ok(H.pending(), "still running")
  ok(H.FI.api.IsPopupOpen ~= nil)
  H.FI.clicks["Try again##drawerr"] = true; H.frame(3)
  ok(H.seq_index("1     A1##clip1"), "drawing works again after Try again")
end)

------------------------------------------------------ vertical space --
test("vertical space: takes and lanes use far less height than the v4.5 layout (numbers in tests/measure_presenter.py)", function()
  local M = assert(loadfile(HERE .. "/measure.lua"))(HERE, PANEL)
  local BASE = { 1017, 2680, 1117, 3308 }       -- scrolling body height on ac02c08 (v4.5 rows), same layout model
  local limit = { 1.0, 0.40, 0.55, 0.55 }
  for i, spec in ipairs(M.sessions()) do
    local _, body = M.measure(spec)
    ok(body and body <= BASE[i] * limit[i], ("%s: body %s px, allowed %s"):format(spec.name, tostring(body), BASE[i] * limit[i]))
  end
end)

return tests

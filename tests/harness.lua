-- Test harness: builds the fake session, loads the real panel file and drives frames.
-- Used by presenter_test.lua. `...` = tests dir, panel path.
local HERE, PANEL = ...
local H = {}

function H.session()
  local FR = H.FR
  -- folder "Vendor A" { A1 (plain clip), A2 (item with 3 takes) }, a fixed-lane track, 3 regions
  FR.track{ name = "Vendor A", depth = 1 }
  local a1 = FR.track{ name = "A1" }
  local a2 = FR.track{ name = "A2", depth = -1 }
  local lanes = FR.track{ name = "Lanes", freemode = 2, nlanes = 2, lanenames = { "dry", "wet" } }
  for r = 0, 2 do
    FR.region(r * 10, r * 10 + 10, "Region " .. (r + 1))
    FR.item{ track = a1, pos = r * 10, len = 5, takes = { { name = "A1 r" .. (r + 1) } } }
  end
  FR.item{ track = a2, pos = 0, len = 5, takes = { { name = "t1" }, { name = "t2" }, { name = "t3" } } }
  FR.item{ track = lanes, pos = 0, len = 5, lane = 0, takes = { { name = "dry" } } }
  FR.item{ track = lanes, pos = 0, len = 5, lane = 1, takes = { { name = "wet" } } }
  return { a1 = a1, a2 = a2, lanes = lanes }
end

-- opts.ext = { key = value } presets Presenter ExtState; opts.session = false for an empty project
function H.start(opts)
  opts = opts or {}
  FAKE_IMGUI = {}
  package.loaded.imgui = nil                     -- the panel's `require 'imgui'` must get THIS fake
  dofile(HERE .. "/fake_imgui/imgui.lua")        -- defines the fake and registers FAKE_IMGUI.api
  H.FI = FAKE_IMGUI
  H.FR = dofile(HERE .. "/fake_reaper.lua")
  H.FR.reset()
  H.FR.imgui_dir = HERE .. "/fake_imgui"
  reaper = H.FR.reaper
  for k, v in pairs(opts.ext or {}) do H.FR.ext["PresenterPanel/" .. k] = v end
  H.s = (opts.session ~= false) and H.session() or {}
  local chunk = assert(loadfile(PANEL))
  chunk()
  return H
end

-- one frame: run the deferred loop, then check balance
function H.frame(n)
  for _ = 1, n or 1 do
    local FI = H.FI
    FI.seq, FI.cursor_y, FI.frames = {}, 0, FI.frames + 1
    FI.begin_log, FI.child_log, FI.texts, FI.buttons, FI.selectables = {}, {}, {}, {}, {}
    H.FR.now = (H.FR.now or 100) + 0.05
    H.FR.run_frame()
    FI.check_frame_end()
  end
end
function H.pending() return #H.FR.defers > 0 end
function H.seq_index(label) for i, l in ipairs(H.FI.seq) do if l == label then return i end end end
function H.ext(k) return H.FR.ext["PresenterPanel/" .. k] end
function H.stop()   -- user closes the window
  H.FI.win.close = true
  H.frame(1)
  H.FI.win.close = nil
end
return H

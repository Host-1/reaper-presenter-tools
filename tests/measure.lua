-- Vertical space: how tall the scrolling body is for a region with N plain tracks / takes items / lane tracks.
-- Used by presenter_test.lua (assertions) and tests/measure_presenter.py (a table for the report).
local HERE, PANEL = ...
local M = {}

-- kinds: { plain = n, takes = {n items, k takes each}, lanes = {n tracks, k lanes each} }
function M.sessions()
  return {
    { name = "6 plain tracks",            plain = 6 },
    { name = "5 items x 3 takes",         takes = { 5, 3 } },
    { name = "2 tracks x 3 lanes",        lanes = { 2, 3 } },
    { name = "mixed: 4 plain + 3x3 takes + 2x3 lanes", plain = 4, takes = { 3, 3 }, lanes = { 2, 3 } },
  }
end

function M.build(H, spec)
  local FR = H.FR
  FR.region(0, 10, "R1")
  for n = 1, spec.plain or 0 do
    local tr = FR.track{ name = "P" .. n }
    FR.item{ track = tr, pos = 0, len = 5, takes = { { name = "p" .. n } } }
  end
  if spec.takes then
    for n = 1, spec.takes[1] do
      local tr = FR.track{ name = "T" .. n }
      local tk = {}
      for k = 1, spec.takes[2] do tk[k] = { name = ("t%d_%d"):format(n, k) } end
      FR.item{ track = tr, pos = 0, len = 5, takes = tk }
    end
  end
  if spec.lanes then
    for n = 1, spec.lanes[1] do
      local names = {}
      for k = 1, spec.lanes[2] do names[k] = ("L%d_%d"):format(n, k) end
      local tr = FR.track{ name = "Lane" .. n, freemode = 2, nlanes = spec.lanes[2], lanenames = names }
      for k = 1, spec.lanes[2] do FR.item{ track = tr, pos = 0, len = 5, lane = k - 1, takes = { { name = names[k] } } } end
    end
  end
end

-- returns toolbar height, body content height (what scrolls), number of body widgets drawn
function M.measure(spec, opts)
  opts = opts or {}
  local H = assert(loadfile(HERE .. "/harness.lua"))(HERE, PANEL).start{ session = false, ext = opts.ext }
  M.build(H, spec)
  H.frame(3)
  local FI = H.FI
  return FI.toolbar_h, FI.body_h
end
return M

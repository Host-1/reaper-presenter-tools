-- A fake REAPER for the Presenter tests: a small project model (tracks with folder depth, items, takes,
-- fixed lanes, regions, markers), ExtState, transport, and a defer queue.
--   local FR = dofile("fake_reaper.lua")        -- FR.reaper is the table to install as the global `reaper`
--   FR.reset(); FR.track{...}; FR.item{...}; FR.region(...)
-- Any reaper function the fake does not define raises an error naming it, so a new API call in the panel
-- shows up as a failing test instead of silently doing nothing.
local FR = {}
local R = {}
FR.reaper = R

function FR.reset()
  FR.tracks, FR.items, FR.regions, FR.markers = {}, {}, {}, {}
  FR.ext, FR.projext = {}, {}
  FR.defers, FR.exits = {}, {}
  FR.changes = 1
  FR.playstate, FR.playpos, FR.cursor, FR.repeat_on = 0, 0, 0, 0
  FR.messages, FR.log = {}, {}
  FR.guid_n = 0
end

local function guid() FR.guid_n = FR.guid_n + 1 return ("{GUID-%04d}"):format(FR.guid_n) end

-- t = { name, depth (I_FOLDERDEPTH change), color, freemode (2 = fixed lanes), nlanes, lanenames }
function FR.track(t)
  t = t or {}
  t.name, t.depth = t.name or "", t.depth or 0
  t.items, t.ext, t.guid = {}, {}, guid()
  t.laneplays = t.laneplays or {}
  t.freemode, t.nlanes, t.lanenames = t.freemode or 0, t.nlanes or 0, t.lanenames or {}
  FR.tracks[#FR.tracks + 1] = t
  t.idx = #FR.tracks - 1
  FR.changes = FR.changes + 1
  return t
end
-- t = { track, pos, len, notes, lane, takes = { {name=, srclen=}, ... } or text-only when takes == {} }
function FR.item(t)
  t.len, t.notes, t.lane, t.active = t.len or 5, t.notes or "", t.lane or 0, 1
  t.guid = guid()
  t.takes = t.takes or { { name = "take" } }
  for _, k in ipairs(t.takes) do k.item, k.srclen, k.offs, k.rate = t, k.srclen or t.len, k.offs or 0, k.rate or 1 end
  local its = t.track.items
  its[#its + 1] = t
  table.sort(its, function(a, b) return a.pos < b.pos end)
  FR.items[#FR.items + 1] = t
  FR.changes = FR.changes + 1
  return t
end
function FR.region(s, e, name) FR.regions[#FR.regions + 1] = { s = s, e = e, name = name or "" } FR.changes = FR.changes + 1 end

local function nope(name) return function() error("fake reaper: " .. name .. " is not implemented", 2) end end
setmetatable(R, { __index = function(_, name) return nope(name) end })

------------------------------------------------------------------ misc --
function R.ImGui_GetBuiltinPath() return FR.imgui_dir end
function R.set_action_options() end
function R.defer(fn) FR.defers[#FR.defers + 1] = fn end
function R.atexit(fn) FR.exits[#FR.exits + 1] = fn end
function R.MB(msg) FR.messages[#FR.messages + 1] = msg return 1 end
function R.time_precise() return FR.now or os.clock() end
function R.GetExtState(sec, key) return (FR.ext[sec .. "/" .. key]) or "" end
function R.SetExtState(sec, key, v, persist) FR.ext[sec .. "/" .. key] = v end
function R.GetProjExtState(_, sec, key) local v = FR.projext[sec .. "/" .. key] return v and 1 or 0, v or "" end
function R.SetProjExtState(_, sec, key, v) FR.projext[sec .. "/" .. key] = v return 0 end
function R.EnumProjects() return 0xBEEF, "/tmp/session/test.rpp" end
function R.GetProjectStateChangeCount() return FR.changes end
function R.Undo_BeginBlock() end
function R.Undo_EndBlock() end
function R.PreventUIRefresh() end
function R.UpdateArrange() end
function R.TrackList_AdjustWindows() end
function R.ValidatePtr2() return true end
function R.ColorFromNative(c) return c & 255, (c >> 8) & 255, (c >> 16) & 255 end
function R.ColorToNative(r, g, b) return r | (g << 8) | (b << 16) end
function R.GetProjectLength() local m = 0 for _, it in ipairs(FR.items) do m = math.max(m, it.pos + it.len) end return m end

----------------------------------------------------------------- tracks --
function R.CountTracks() return #FR.tracks end
function R.GetTrack(_, i) return FR.tracks[i + 1] end
function R.GetTrackName(tr) return true, tr.name end
function R.GetTrackGUID(tr) return tr.guid end
function R.GetTrackColor(tr) return tr.color or 0 end
function R.GetParentTrack(tr)
  local depth = 0
  for i = tr.idx, 1, -1 do   -- walk back to the nearest open folder
    local p = FR.tracks[i]
    depth = depth + p.depth
    if depth > 0 then return p end
  end
  return nil
end
function R.GetMediaTrackInfo_Value(tr, k)
  if k == "IP_TRACKNUMBER" then return tr.idx + 1
  elseif k == "B_SHOWINTCP" then return tr.hidden and 0 or 1
  elseif k == "I_FOLDERDEPTH" then return tr.depth
  elseif k == "I_FREEMODE" then return tr.freemode
  elseif k == "I_NUMFIXEDLANES" then return tr.nlanes
  elseif k == "I_SOLO" then return tr.solo or 0
  elseif k:match("^C_LANEPLAYS:") then return tr.laneplays[tonumber(k:match(":(%d+)"))] or 0
  end
  return 0
end
function R.SetMediaTrackInfo_Value(tr, k, v)
  if k == "I_FOLDERDEPTH" then tr.depth = v
  elseif k == "I_SOLO" then tr.solo = v
  elseif k:match("^C_LANEPLAYS:") then tr.laneplays[tonumber(k:match(":(%d+)"))] = v
  else tr[k] = v end
  FR.changes = FR.changes + 1
  return true
end
function R.GetSetMediaTrackInfo_String(tr, k, v, set)
  if k:match("^P_LANENAME:") then local n = tonumber(k:match(":(%d+)")) return true, tr.lanenames[n + 1] or "" end
  if k == "P_NAME" then if set then tr.name = v end return true, tr.name end
  if k:match("^P_EXT:") then if set then tr.ext[k] = v end return true, tr.ext[k] or "" end
  return false, ""
end
function R.SetTrackSelected() end

------------------------------------------------------------- items/takes --
function R.CountTrackMediaItems(tr) return #tr.items end
function R.GetTrackMediaItem(tr, i) return tr.items[i + 1] end
function R.GetMediaItemInfo_Value(it, k)
  if k == "D_POSITION" then return it.pos elseif k == "D_LENGTH" then return it.len
  elseif k == "I_FIXEDLANE" then return it.lane elseif k == "I_CUSTOMCOLOR" then return it.color or 0
  elseif k == "D_VOL" then return 1 end
  return 0
end
function R.SetMediaItemInfo_Value(it, k, v)
  if k == "D_POSITION" then it.pos = v elseif k == "D_LENGTH" then it.len = v elseif k == "I_FIXEDLANE" then it.lane = v
  elseif k == "I_CUSTOMCOLOR" then it.color = v end
  FR.changes = FR.changes + 1
  return true
end
function R.GetSetMediaItemInfo_String(it, k, v, set)
  if k == "P_NOTES" then if set then it.notes = v end return true, it.notes end
  if k == "GUID" then return true, it.guid end
  return false, ""
end
function R.GetItemStateChunk() return true, "<ITEM\n>" end
function R.GetActiveTake(it) if #it.takes == 0 then return nil end return it.takes[it.active] end
function R.CountTakes(it) return #it.takes end
function R.GetTake(it, i) return it.takes[i + 1] end
function R.SetActiveTake(tk) tk.item.active = nil for i, k in ipairs(tk.item.takes) do if k == tk then tk.item.active = i end end end
function R.TakeIsMIDI() return false end
function R.GetTakeName(tk) return tk.name end
function R.GetMediaItemTake_Source(tk) return tk end
function R.GetMediaSourceType() return "WAVE" end
function R.GetMediaSourceLength(src) return src.srclen, false end
function R.GetMediaSourceNumChannels() return 1 end
function R.GetMediaItemTakeInfo_Value(tk, k)
  if k == "D_STARTOFFS" then return tk.offs elseif k == "D_PLAYRATE" then return tk.rate end
  return 0
end
function R.GetMediaItemTake_Peaks() return 0 end   -- 0 peaks: the panel shows 'still building' and retries
function R.new_array() return { clear = function() end, table = function() return {} end } end
function R.GetNumTakeMarkers(tk) return #(tk.markers or {}) end
function R.GetTakeMarker(tk, k) local m = tk.markers[k + 1] return m.pos, m.name, m.color or 0 end
function R.GetMediaItem_Track(it) return it.track end
function R.SelectAllMediaItems() end
function R.SetMediaItemSelected() end

-- presentation building (copies of clips go onto new tracks)
function R.InsertTrackAtIndex(idx)
  local t = { name = "", depth = 0, items = {}, ext = {}, laneplays = {}, freemode = 0, nlanes = 0, lanenames = {}, guid = guid() }
  table.insert(FR.tracks, idx + 1, t)
  for i, tr in ipairs(FR.tracks) do tr.idx = i - 1 end
  FR.changes = FR.changes + 1
end
function R.DeleteTrack(tr)
  table.remove(FR.tracks, tr.idx + 1)
  for i, t in ipairs(FR.tracks) do t.idx = i - 1 end
end
function R.AddMediaItemToTrack(tr)
  local it = { track = tr, pos = 0, len = 1, notes = "", lane = 0, active = 1, takes = {}, guid = guid() }
  tr.items[#tr.items + 1] = it
  FR.items[#FR.items + 1] = it
  return it
end
function R.SetItemStateChunk(it, chunk) it.chunk = chunk return true end
function R.DeleteTrackMediaItem(tr, it)
  for i, x in ipairs(tr.items) do if x == it then table.remove(tr.items, i) break end end
  for i, x in ipairs(FR.items) do if x == it then table.remove(FR.items, i) break end end
  FR.changes = FR.changes + 1
  return true
end
function R.AddProjectMarker2(_, isrgn, s, e, name)
  if isrgn then FR.regions[#FR.regions + 1] = { s = s, e = e, name = name } end
  FR.changes = FR.changes + 1
  return #FR.regions
end
function R.SetProjectMarker(idx, isrgn, s, e, name)
  local r = FR.regions[idx]
  if r then r.s, r.e, r.name = s, e, name end
  return true
end

-------------------------------------------------------- regions, markers --
function R.EnumProjectMarkers3(_, i)
  local r = FR.regions[i + 1]
  if r then return 1, true, r.s, r.e, r.name, i + 1, 0 end
  local m = FR.markers[i - #FR.regions + 1]
  if m then return 1, false, m.pos, m.pos, m.name, i + 1, 0 end
  return 0
end

-------------------------------------------------------------- transport --
function R.GetPlayState() return FR.playstate end
function R.GetPlayPosition() return FR.playpos end
function R.SetEditCurPos(p) FR.cursor = p end
function R.GetCursorPosition() return FR.cursor end
function R.OnPlayButton() FR.playstate = 1 end
function R.OnStopButton() FR.playstate = 0 end
function R.GetSetRepeat(v) if v >= 0 then FR.repeat_on = v end return FR.repeat_on end
function R.GetSet_LoopTimeRange() return 0, 0 end
function R.Main_OnCommand(cmd) FR.log[#FR.log + 1] = "cmd " .. tostring(cmd) end
function R.CalculateNormalization() return 0 end

-- run one deferred callback (one "frame" of the panel)
function FR.run_frame()
  local fns = FR.defers
  FR.defers = {}
  for _, fn in ipairs(fns) do fn() end
  return #FR.defers > 0
end

FR.reset()
return FR

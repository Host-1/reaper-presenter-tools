-- @description Presenter panel: big-text region view with one-click exclusive clip playback
-- @version 4.5
-- @about
--   A dockable ReaImGui window for presenting listening tests (e.g. over Zoom).
--
--   OVERVIEW AND PRESENTATION (top left)
--     Overview is the whole session. Presentation is a separate section the
--     panel builds after the end of the session: a "PRESENTATION" folder of
--     tracks, with one region per section. Both views work the same way
--     (tabs, playback, A/B, notes); each remembers where you were.
--     Ticking: every clip has a gold tick box; each view keeps its own ticks,
--     kept across tabs. The bar above the clips shows the count and works on
--     the ticked clips: Colour... (both views), Add to presentation... and
--     Review (Overview), Remove (Presentation), Clear. Adding COPIES the clips
--     into a new or existing section, lined up at the section's start, each
--     on a presentation track named after its source ("B | take 2"), inside
--     copies of the source's folders (or, if chosen, with the folder path in
--     the track name instead). The
--     source stays as it is. In Presentation, hovering a clip shows an x at
--     the end of its row that removes that copy.
--     Right-click a clip: colour, rename track / take, select, add to
--     presentation / remove. Right-click a folder header: rename, colour.
--     Colour sets the item's colour (all its takes); "Track colour" clears it.
--     "Tracks & folders" (Presentation) lists the presentation's tracks:
--     drag the :: handle to reorder or drop onto a folder, double-click to
--     rename, swatch to colour, + Track / + Folder (+ Subfolder inside), x to delete
--     an empty track.
--     + Section / Rename section manage the sections (regions).
--
--   + TEXT (next to the region title, both views)
--     Adds or edits the big text for the region: a text item on the topmost
--     track ("Text"; created if there isn't one). The presentation has its
--     own Text track, so overview text isn't copied. Item notes on clips and
--     comment items on other tracks are shown but not edited here.
--
--   SETTINGS (top right, next to Compact view)
--     Sizes, waveform, notes, pre-roll, restore-on-close and Levels.
--
--   FOLDERS
--     Clips are grouped under their REAPER folder tracks as collapsible
--     headers (nested folders nest here too), coloured with the folder's
--     track colour. A collapsed header shows its clip count and [playing] if
--     one of its clips is playing. Open/closed state carries across tabs.
--     Expand all / Collapse all buttons sit in the top row. Turn grouping
--     off in Settings to get the flat list back.
--     Tracks inside folders that are collapsed in REAPER are still included;
--     only tracks you've hidden from the track panel are left out.
--
--   TAKES
--     Every take in an item is its own clip ("Jo | take 2"). An item with
--     several takes gets its own collapsible group named after the track.
--     Playing a take makes it the item's active take, so the arrange view
--     shows the one you're hearing (this does change the project's active
--     take, as clicking it in REAPER would). A/B between takes of the same
--     item keeps position, like A/B between tracks.
--     Each take plays only as long as its own audio: takes share the item's
--     length, so a shorter take would otherwise loop to fill it.
--
--   LANES (REAPER 7 fixed item lanes)
--     Items on every lane are picked up, not just the lane that's playing.
--     A track with audio on several lanes gets its own group named after the
--     track; buttons show the lane name ("Jo | lane 2", or your lane names).
--     Playing a clip makes its lane the only one that plays on that track.
--     A/B between lanes keeps position.
--
--   PUTTING THINGS BACK
--     Playing changes which take is active and which lane plays. By default
--     the panel restores both when it closes (setting in Settings).
--
--   TABS
--     Every region (or header item if there are no regions) gets a tab
--     at the top. Click a tab to jump straight to it. Tabs take the region's
--     colour, so sections coloured in REAPER show up colour-grouped here too.
--     Nested regions (e.g. "Round 1" spanning three regions) give one
--     row of tabs per level: top-level regions, then the regions inside the
--     selected one. The innermost region is what's shown; clicking a group tab
--     jumps to its first region. Arrow keys step through innermost regions.
--
--   TEXT
--     Text items are empty items with notes. In each region:
--       - the one on the TOPMOST track is the region's text: shown in large type
--         above the clips. Lines starting with ">" are the smaller cue.
--       - any others are notes, shown where they sit: under the clip on the
--         same track (the one it overlaps), or, if that track has no clip
--         here (e.g. "not available"), as a row in that track's place,
--         labelled with the track name.
--     Without regions, tabs come from the text items on the topmost track
--     that has any; text items on other tracks are notes.
--     A clip's own item notes (right-click > Item notes) show as its note too.
--     Notes are collapsible: closed they show a one-line preview; click to
--     open. "Notes open by default" in Settings.
--
--   IMAGES
--     An image set on an item in REAPER's Item notes window is shown in that
--     item's note, or under the region's text. Click any image
--     to open it large in its own window (resize or dock it; click the image
--     to close). No extensions needed beyond ReaImGui.
--
--   CLIPS (only one is ever audible)
--     Each row: [restart] [state box] [name] [time box]. The name never
--     changes; state is shown by colour and symbol:
--       green + pause symbol    playing (click to pause)
--       blue + swap symbol      A/B: click to switch to it at the same point
--       amber state box + play  paused, resumes from the time shown
--       clip colour + play      idle
--     The clip colour is REAPER's: the item's own colour, else the take's,
--     else the track's; grey if none is set.
--     Big button   Play / Pause / Resume
--     |<           Restart that clip from the beginning
--     Waveform     Appears for the clip you're playing (or all clips, see
--                  Settings). Click or drag-and-release to play from a point.
--                  SHIFT + drag on it to set a loop range; shift-click to clear.
--     Seek bar     Shown instead of the waveform for the other clips.
--
--   A/B (the "A/B  Off | Default | Smooth" control in the playback row)
--     While something plays, clicking another clip switches to it at the SAME
--     point in the clip, like soloing between tracks in a normal DAW session.
--     The switch re-seeks playback to the same point, so REAPER drops audio
--     it had already buffered for the old clip: a very short gap instead of
--     the old clip running on into the new one.
--     SMOOTH (third A/B setting, or S; back to Default each time the panel opens): for
--     clips that start at exactly the same time, e.g. versions of the same
--     recording, only the solo/lane/take is swapped, so there's no gap at
--     all. The change is heard a moment after you click. Clips that don't
--     line up still get the Default switch.
--
--   LOOP (toggle in the top row)
--     Loops the current clip natively, or just the shift-dragged range.
--     The range is stored as an offset into the clip, so it carries over when
--     you A/B switch between clips.
--
--   MARKERS
--     - Take markers on a clip are drawn on its waveform and listed as jump
--       buttons under it.
--     - Project markers inside the region are listed as a shared row above the
--       clips and drawn on every waveform; clicking one plays the current clip
--       at that point.
--     Jumps start a little early (pre-roll, set in Settings) so you hear the lead-in.
--
--   COMPACT VIEW (top right, or C)
--     Shrinks the panel to the tabs, the control row and one row of small
--     clip buttons (same colours, gold outline on the selected clip), so the
--     controls stay on screen while you show something else. Turn it off to
--     get your full layout and window size back. When docked, the panel can't
--     change size, so compact just hides the rest.
--
--   ADDING NOTES ("+ Note" at the start of a clip's notes line, or N)
--     A general comment on the clip, with no particular moment: added as a
--     new line to the clip's Item notes (what the panel shows under the
--     clip). The box shows the existing notes with the cursor on a new line
--     underneath; "Edit existing notes" to change them. Enter saves, Esc
--     cancels. Saved with the project and undoable.
--
--   REMOVING
--     Open a note: each line has a little x to remove that line. Each take
--     marker button has a little x next to it. Both are normal REAPER edits
--     (Ctrl+Z undoes them); a confirmation shows in the top row. Shared
--     project markers (blue) can't be removed from the panel.
--
--   ADDING MARKERS ("+ Marker" at the start of a clip's marker row, or M)
--     Takes the moment you press it on that clip (M: the playing/selected
--     clip); the clip keeps playing while you type. Enter adds a take marker
--     there with your text, in red: the same as adding one in REAPER, so
--     it shows on the waveform and as a jump button straight away, is saved
--     with the project and can be undone. The box lists the clip's existing
--     markers. A confirmation shows at the end of the top row.
--
--   LEVELS (in Settings)
--     Normalize this region / all clips in the view to a LUFS-I or peak target (default
--     -23 LUFS-I), using REAPER's own loudness measurement. Sets each take's
--     volume, one undo step, and warns how many clips would go above -1 dBTP.
--
--   KEYS (while the panel has focus)
--     1-9 play/pause clip     Space play/pause selected clip     Left/Right previous/next tab
--     A   toggle A/B mode     L     toggle loop     C   compact     M   add marker     N   add note     S   smooth A/B
--
--   Run the action again to close the panel. Requires ReaImGui 0.10+.

local SCRIPT_NAME = 'Presenter'
local EPS = 0.001

----------------------------------------------------------------- startup --
if not reaper.ImGui_GetBuiltinPath then
  reaper.MB('This script needs ReaImGui.\nInstall it via Extensions > ReaPack > Browse packages (search "imgui").',
    SCRIPT_NAME, 0)
  return
end
package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local okImGui, ImGui = pcall(function() return require 'imgui' '0.10' end)
if not okImGui then
  reaper.MB('This script needs ReaImGui 0.10 or newer.\nUpdate via Extensions > ReaPack > Synchronize packages.',
    SCRIPT_NAME, 0)
  return
end

-- Running the action again closes the panel (REAPER 7.03+)
if reaper.set_action_options then reaper.set_action_options(1) end

---------------------------------------------------------------- settings --
local EXT = 'PresenterPanel'
local function loadNum(key, default)
  return tonumber(reaper.GetExtState(EXT, key)) or default
end
local function loadBool(key, default)
  local v = reaper.GetExtState(EXT, key)
  if v == '' then return default end
  return v == '1'
end
local cfg = {
  textSize     = loadNum('textSize', 34),
  buttonSize   = loadNum('buttonSize', 28),
  tabSize      = loadNum('tabSize', 18),
  waveHeight   = loadNum('waveHeight', 90),
  preroll      = loadNum('preroll', 1.0),
  noteImgHeight = loadNum('noteImgHeight', 200),
  normMode     = loadNum('normMode', 1),
  normTarget   = loadNum('normTarget', -23),
  sizeW        = loadNum('sizeW', 760),    -- window size, remembered (full view, floating only)
  sizeH        = loadNum('sizeH', 680),
  notesOpen    = loadBool('notesOpen', false),
  showFiles    = loadBool('showFiles', false),
  showAllWaves = loadBool('showAllWaves', false),
  ab           = loadBool('ab', true),
  folders      = loadBool('folders', true),
  restoreOnClose = loadBool('restoreOnClose', true),
  loop         = false,   -- per session, not remembered
}
local function saveCfg()
  for _, k in ipairs({ 'textSize', 'buttonSize', 'tabSize', 'waveHeight', 'preroll', 'noteImgHeight', 'normMode', 'normTarget', 'sizeW', 'sizeH' }) do
    reaper.SetExtState(EXT, k, tostring(cfg[k]), true)
  end
  for _, k in ipairs({ 'showFiles', 'showAllWaves', 'ab', 'folders', 'restoreOnClose', 'notesOpen' }) do
    reaper.SetExtState(EXT, k, cfg[k] and '1' or '0', true)
  end
end

-- Colours are 0xRRGGBBAA
local COL = {
  accent       = 0xF0B429FF,
  dim          = 0x9AA0A6FF,
  btn          = 0x2F3640FF,
  btnHover     = 0x3C4552FF,
  btnActive    = 0x4A5563FF,
  play         = 0x2E9E5BFF,
  playHover    = 0x36B36AFF,
  playActive   = 0x2A8A50FF,
  paused       = 0x8A6D1EFF,
  pausedHov    = 0xA0801FFF,
  pausedAct    = 0x7A5F18FF,
  switch       = 0x2F6FB0FF,
  switchHov    = 0x3A80C8FF,
  switchAct    = 0x285E96FF,
  icon         = 0xFFFFFFFF,
  iconDim      = 0xC8CDD3FF,
  ledOff       = 0x5A626EFF,
  noteText     = 0xDDE1E6FF,
  liveNote     = 0xFF6B6BFF,   -- markers added from the panel (red)
  seekBg       = 0x22272EFF,
  seekBgHov    = 0x2B313AFF,
  waveOn       = 0x7FD3A0FF,
  waveOff      = 0x8C95A3FF,
  playhead     = 0xFFFFFFFF,
  takeMarker   = 0xFF6B6BFF,
  sharedMarker = 0x6BB8FFFF,
  loopShade    = 0xF0B42940,
  loopShadeOff = 0xF0B42918,
}

local ctx  = ImGui.CreateContext(SCRIPT_NAME)
local font = ImGui.CreateFont('sans-serif')
ImGui.Attach(ctx, font)

------------------------------------------------------------ project scan --
local IGNORE_SOURCE = { VIDEO = true, VIDEOEFFECT = true, PNG = true, JPG = true, JPEG = true }

local cache = { state = -1, proj = nil, regions = {}, markers = {}, headers = {}, clips = {}, nav = {} }

local function itemBounds(it)
  local s = reaper.GetMediaItemInfo_Value(it, 'D_POSITION')
  return s, s + reaper.GetMediaItemInfo_Value(it, 'D_LENGTH')
end

local function itemNotes(it)
  local _, n = reaper.GetSetMediaItemInfo_String(it, 'P_NOTES', '', false)
  return n or ''
end

-- The image attached to an item (set in REAPER's Item notes window).
-- REAPER has no direct scripting function for this, so it's read from the
-- item's saved state (the RESOURCEFN line, as in the .rpp file).
-- Cached for a few seconds because reading item state is relatively slow.
local imgPathCache = {}
local function projectDir()
  local _, fn = reaper.EnumProjects(-1)
  return (fn or ''):match('^(.*)[\\/]')
end
local function itemImage(it)
  local key, now = tostring(it), reaper.time_precise()
  local hit = imgPathCache[key]
  if hit and now - hit.t < 3 then return hit.path end

  local path
  local ok, chunk = reaper.GetItemStateChunk(it, '', false)
  if ok and chunk then
    path = chunk:match('\nRESOURCEFN%s+"([^"]+)"') or chunk:match('\nRESOURCEFN%s+(%S+)')
  end
  if path == '' then path = nil end
  -- relative paths are relative to the project folder
  if path and not path:match('^%a:[\\/]') and not path:match('^[\\/]') then
    local dir = projectDir()
    if dir then path = dir .. '/' .. path end
  end
  imgPathCache[key] = { path = path, t = now }
  return path
end

-- Where a take's own audio ends. All takes share the item's length, so a
-- take shorter than the item would otherwise loop (REAPER's "Loop source")
-- or run into silence. The clip is cut at the end of its audio instead.
local function takeEnd(take, s, e)
  local src = reaper.GetMediaItemTake_Source(take)
  local srcLen, isQN = reaper.GetMediaSourceLength(src)
  if not srcLen or srcLen <= 0 or isQN then return e end
  local offs = reaper.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
  local rate = reaper.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
  if rate <= 0 then rate = 1 end
  local len = (srcLen - offs) / rate
  if len <= 0.01 then return e end
  return math.min(e, s + len)
end

-- Take markers converted to offsets (seconds from the clip's start)
local function takeMarkers(take, s, e)
  local out = {}
  local n = reaper.GetNumTakeMarkers(take)
  if n == 0 then return out end
  local offs = reaper.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
  local rate = reaper.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
  if rate <= 0 then rate = 1 end
  for k = 0, n - 1 do
    local srcpos, name, color = reaper.GetTakeMarker(take, k)
    local pos = s + (srcpos - offs) / rate
    if pos >= s and pos < e then
      local col
      if color and (color & 0x1000000) ~= 0 then
        local r, g, b = reaper.ColorFromNative(color & 0xFFFFFF)
        col = (r << 24) | (g << 16) | (b << 8) | 0xFF
      end
      out[#out + 1] = { off = pos - s, name = (name ~= '' and name) or ('marker ' .. (k + 1)), col = col, idx = k }
    end
  end
  table.sort(out, function(a, b) return a.off < b.off end)
  return out
end

-- A clip's colour as REAPER shows it: the item's own colour, else the
-- take's, else the track's; nil if none is set (then the panel uses grey)
local function nativeToRGB(c)
  c = math.floor(c or 0)
  if c ~= 0 and (c & 0x1000000) ~= 0 then
    local r, g, b = reaper.ColorFromNative(c & 0xFFFFFF)
    return { r, g, b }
  end
end
local function clipRGB(it, take, tr)
  return nativeToRGB(reaper.GetMediaItemInfo_Value(it, 'I_CUSTOMCOLOR'))
      or (take and nativeToRGB(reaper.GetMediaItemTakeInfo_Value(take, 'I_CUSTOMCOLOR')))
      or nativeToRGB(reaper.GetTrackColor(tr))
end

local function trackRGB(tr)
  local c = reaper.GetTrackColor(tr)
  if c and c ~= 0 then
    local r, g, b = reaper.ColorFromNative(c & 0xFFFFFF)
    return { r, g, b }
  end
end

local applyView      -- defined with buildView below

-------------------------------------------------- presentation section --
-- The presentation is its own part of the project: a folder track named
-- PRESENTATION (tagged so the panel recognises it even if renamed) holding
-- the presentation's tracks, and regions placed in time after the session.
-- The time where it starts is saved in the project.
local EXT_SEC = 'PresenterPanel'

local function trackTag(tr)
  local _, v = reaper.GetSetMediaTrackInfo_String(tr, 'P_EXT:presenter', '', false)
  return v or ''
end
local function isPresRoot(tr) return tr and trackTag(tr) == 'root' end

local function presStartTime()
  local _, v = reaper.GetProjExtState(0, EXT_SEC, 'presStart')
  return tonumber(v)
end

-- Index of the PRESENTATION folder track, and of its last descendant
local function presRootIndex()
  for i = 0, reaper.CountTracks(0) - 1 do
    if isPresRoot(reaper.GetTrack(0, i)) then return i end
  end
end
local function presLastIndex(r)
  local depth, i, n = 1, r, reaper.CountTracks(0)
  if reaper.GetMediaTrackInfo_Value(reaper.GetTrack(0, r), 'I_FOLDERDEPTH') ~= 1 then return r end
  while i + 1 < n do
    i = i + 1
    depth = depth + reaper.GetMediaTrackInfo_Value(reaper.GetTrack(0, i), 'I_FOLDERDEPTH')
    if depth <= 0 then return i end
  end
  return i
end

-- Folder ancestry of a track, outermost first (the PRESENTATION folder
-- itself is left out, so presentation tracks group by their own folders)
local function folderPath(tr)
  local path = {}
  local p = reaper.GetParentTrack(tr)
  while p and not isPresRoot(p) do
    local _, name = reaper.GetTrackName(p)
    table.insert(path, 1, { key = reaper.GetTrackGUID(p), name = name, rgb = trackRGB(p), track = p })
    p = reaper.GetParentTrack(p)
  end
  return path
end

-- How the project is read
--   The panel shows one region at a time, so it only reads the clips and
--   text of the region on screen, the first time that region is shown, and
--   remembers them until the project changes. The next and previous regions
--   are read in the background while the panel is idle, so stepping through
--   regions stays instant. Any edit to the project clears what's remembered.
--   What's read for the whole project on each change is small: regions,
--   markers and the track list. (Sessions without regions also get a quick
--   pass over all text items, since their tabs come from those.)

-- Tracks the panel shows, with what's needed to read their items
local function scanTracks(presTracks)
  local list = {}
  for ti = 0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, ti)
    -- B_SHOWINTCP: hidden tracks are skipped, but children of collapsed
    -- folders are kept (IsTrackVisible can report those as not visible)
    if reaper.GetMediaTrackInfo_Value(tr, 'B_SHOWINTCP') ~= 0 then
      local _, tname = reaper.GetTrackName(tr)
      list[#list + 1] = {
        tr = tr, ti = ti, inPres = presTracks[tr] == true,
        name = (tname ~= '' and tname) or ('Track ' .. (ti + 1)),
        path = folderPath(tr),
        laneMode = reaper.GetMediaTrackInfo_Value(tr, 'I_FREEMODE') == 2,
      }
    end
  end
  return list
end

-- Indexes of the items on a track that overlap [ws, we). Items are kept in
-- time order, so the first one is found by halving instead of reading them
-- all; the 4 items before it are checked too, for long items that start
-- before the window but run into it.
local function itemsIn(tr, ws, we)
  local n = reaper.CountTrackMediaItems(tr)
  local lo, hi = 0, n
  while lo < hi do
    local mid = (lo + hi) // 2
    if reaper.GetMediaItemInfo_Value(reaper.GetTrackMediaItem(tr, mid), 'D_POSITION') < ws then lo = mid + 1 else hi = mid end
  end
  local out = {}
  for j = math.max(0, lo - 4), lo - 1 do
    local it = reaper.GetTrackMediaItem(tr, j)
    local s, e = itemBounds(it)
    if e > ws + EPS then out[#out + 1] = j end
  end
  for j = lo, n - 1 do
    local it = reaper.GetTrackMediaItem(tr, j)
    if reaper.GetMediaItemInfo_Value(it, 'D_POSITION') >= we then break end
    out[#out + 1] = j
  end
  return out
end

-- Read the text items and/or clips of one view in [ws, we)
local function scanItems(isPres, ws, we, wantHeaders, wantClips)
  local presStart = cache.presStart or math.huge
  local function inTime(t) if isPres then return t >= presStart - EPS else return t < presStart - EPS end end
  local headers, clips = {}, {}
  for _, T in ipairs(cache.tracks or {}) do
    if T.inPres == isPres then
      local tr, ti, trackName, path = T.tr, T.ti, T.name, T.path
      local idxs = itemsIn(tr, ws, we)

      -- REAPER 7 fixed item lanes: every lane's items become clips. If audio
      -- here sits on more than one lane, group them under a node named after the track.
      local lanePath = path
      if T.laneMode and wantClips then
        local used, nUsed = {}, 0
        for _, ii in ipairs(idxs) do
          local it = reaper.GetTrackMediaItem(tr, ii)
          if reaper.GetActiveTake(it) then
            local lane = reaper.GetMediaItemInfo_Value(it, 'I_FIXEDLANE')
            if not used[lane] then used[lane], nUsed = true, nUsed + 1 end
          end
        end
        if nUsed > 1 then
          lanePath = {}
          for _, f in ipairs(path) do lanePath[#lanePath + 1] = f end
          lanePath[#lanePath + 1] = {
            key = 'lanes' .. reaper.GetTrackGUID(tr), name = trackName, rgb = trackRGB(tr), isLanes = true, track = tr,
          }
        end
      end

      for _, ii in ipairs(idxs) do
        local it = reaper.GetTrackMediaItem(tr, ii)
        local take = reaper.GetActiveTake(it)
        if not take then
          if wantHeaders then
            local s, e = itemBounds(it)
            local notes = itemNotes(it)
            local hasText = notes:match('%S') ~= nil
            -- Reading an item's image means reading its whole saved state, which
            -- is slow, so it's only done here for text items with no text (to
            -- know if they hold an image). Everything else is looked up only
            -- when its note is actually on screen.
            local image = (not hasText) and itemImage(it) or nil
            if (hasText or image) and inTime(s) then
              -- Text (or image) item. Which one is the region's text and which
              -- are notes is decided later from the track it sits on.
              headers[#headers + 1] = {
                s = s, e = e, notes = notes, image = image, key = tostring(it), item = it, inPres = isPres,
                hasText = hasText,
                track = tr, ti = ti, trackName = trackName, path = path,
              }
            end
          end
        elseif wantClips then
          local s, e = itemBounds(it)
          if inTime(s) then
            -- Which lane this item is on (fixed-lane tracks only)
            local lane, laneLabel
            if T.laneMode then
              lane = math.floor(reaper.GetMediaItemInfo_Value(it, 'I_FIXEDLANE'))
              if lanePath ~= path then
                local _, lname = reaper.GetSetMediaTrackInfo_String(tr, 'P_LANENAME:' .. lane, '', false)
                laneLabel = (lname and lname ~= '') and lname or ('lane ' .. (lane + 1))
              end
            end

            -- Every audio take in the item becomes its own clip
            local audio = {}
            for k = 0, reaper.CountTakes(it) - 1 do
              local tk = reaper.GetTake(it, k)
              if tk and not reaper.TakeIsMIDI(tk) then
                local srcType = reaper.GetMediaSourceType(reaper.GetMediaItemTake_Source(tk), '')
                if not IGNORE_SOURCE[(srcType or ''):upper()] then audio[#audio + 1] = { tk = tk, k = k } end
              end
            end

            -- Several takes: group them under a node named after the track
            local takePath = lanePath
            if #audio > 1 then
              local _, iguid = reaper.GetSetMediaItemInfo_String(it, 'GUID', '', false)
              takePath = {}
              for _, f in ipairs(lanePath) do takePath[#takePath + 1] = f end
              takePath[#takePath + 1] = {
                key = 'takes' .. (iguid ~= '' and iguid or tostring(it)),
                name = trackName, rgb = trackRGB(tr), isTakes = true, track = tr,
              }
            end

            local note = (#audio > 0) and itemNotes(it) or ''
            for n, a in ipairs(audio) do
              local parts = {}
              if laneLabel then parts[#parts + 1] = laneLabel end
              if #audio > 1 then parts[#parts + 1] = 'take ' .. n end
              local te = takeEnd(a.tk, s, e)
              clips[#clips + 1] = {
                item = it, take = a.tk, k = a.k, key = tostring(it) .. ':' .. a.k,
                track = tr, ti = ti, s = s, e = te, lane = lane, inPres = isPres,
                rgb = clipRGB(it, a.tk, tr),
                trackName = trackName,
                takeLabel = (#parts > 0) and table.concat(parts, '  |  ') or nil,
                takeName = reaper.GetTakeName(a.tk),
                markers = takeMarkers(a.tk, s, te),
                itemNote = note,
                path = takePath,
              }
            end
          end
        end
      end
    end
  end
  table.sort(headers, function(a, b)
    if a.s ~= b.s then return a.s < b.s end
    return a.ti < b.ti
  end)
  table.sort(clips, function(a, b)
    if a.ti ~= b.ti then return a.ti < b.ti end
    if (a.lane or 0) ~= (b.lane or 0) then return (a.lane or 0) < (b.lane or 0) end
    if a.s ~= b.s then return a.s < b.s end
    return a.k < b.k
  end)
  return headers, clips
end

-- One view's share of the project. Overview: everything except the
-- presentation's tracks, before the presentation's start time.
-- Presentation: the PRESENTATION folder's tracks and regions after its start.
local function buildView(isPres, presStart, allRegions, allMarkers)
  local function inTime(t) if isPres then return t >= presStart - EPS else return t < presStart - EPS end end
  local regions, markers = {}, {}
  for _, r in ipairs(allRegions) do
    if inTime(r.s) then
      regions[#regions + 1] = { s = r.s, e = r.e, name = r.name, rgb = r.rgb, idx = r.idx }
    end
  end
  for _, m in ipairs(allMarkers) do if inTime(m.pos) then markers[#markers + 1] = m end end

  -- Without regions, tabs come from the text items on the topmost track
  -- that has any text items; text items on other tracks are notes. That
  -- needs every text item, so they're read now (clips still wait).
  local headers, mainHeaders = {}, {}
  if #regions == 0 then
    headers = scanItems(isPres, -math.huge, math.huge, true, false)
    local scriptTi
    for _, h in ipairs(headers) do
      if h.hasText and (not scriptTi or h.ti < scriptTi) then scriptTi = h.ti end
    end
    for _, h in ipairs(headers) do
      if h.hasText and h.ti == scriptTi then mainHeaders[#mainHeaders + 1] = h end
    end
  end

  -- Nested regions: a region inside a longer region is its child. The
  -- innermost region at the cursor is the one shown; outer ones are groups
  -- (e.g. "Round 1" around three regions), shown as their own row of tabs.
  for n, r in ipairs(regions) do
    r.children = {}
    r.label = (r.name ~= '' and r.name) or ((isPres and 'Section ' or 'Region ') .. n)
  end
  for _, r in ipairs(regions) do
    local best
    for _, q in ipairs(regions) do
      if q ~= r and q.s <= r.s + EPS and r.e <= q.e + EPS and (q.e - q.s) > (r.e - r.s) + EPS then
        if not best or (q.e - q.s) < (best.e - best.s) then best = q end
      end
    end
    r.parent = best
    if best then table.insert(best.children, r) end
  end
  local roots = {}
  for _, r in ipairs(regions) do if not r.parent then roots[#roots + 1] = r end end

  -- Regions for the arrow keys and the counter: innermost only, or one per
  -- text item if there are no regions
  local nav = {}
  if #regions > 0 then
    for _, r in ipairs(regions) do
      if #r.children == 0 then nav[#nav + 1] = { s = r.s, e = r.e, label = r.label, rgb = r.rgb, region = r } end
    end
  else
    for n, h in ipairs(mainHeaders) do
      local first = h.notes:match('^%s*([^\r\n]*)') or ''
      if #first > 22 then first = first:sub(1, 20) .. '..' end
      nav[#nav + 1] = { s = h.s, e = h.e, label = n .. '  ' .. first }
    end
  end
  return { isPres = isPres, regions = regions, markers = markers, headers = headers, clips = {},
           mainHeaders = mainHeaders, roots = roots, nav = nav, spans = {} }
end

local currentView = 'overview'   -- 'overview' or 'presentation'

-- Point the panel at the current view's lists
applyView = function()
  local v = cache.views and cache.views[currentView]
  if not v then return end
  for k, val in pairs(v) do cache[k] = val end
end

-- The clips (and, with regions, the text items) of the span s..e in the
-- current view: read once, then remembered until the project changes
local function spanData(s, e)
  local v = cache.views and cache.views[currentView]
  if not v then return { headers = {}, clips = {} } end
  local key = ('%.4f:%.4f'):format(s, e)
  local d = v.spans[key]
  if not d then
    local withHeaders = #v.regions > 0
    local h, c = scanItems(v.isPres, s, e, withHeaders, true)
    d = { headers = withHeaders and h or v.headers, clips = c }
    v.spans[key] = d
  end
  return d
end
local function loadSpan(s, e)
  local d = spanData(s, e)
  cache.headers, cache.clips = d.headers, d.clips
end
local function loadPoint(t)
  local v = cache.views and cache.views[currentView]
  if not v then return end
  if not (v.point and v.point.t == t) then
    local h, c = scanItems(v.isPres, t, t + EPS, #v.regions > 0, true)
    v.point = { t = t, headers = (#v.regions > 0) and h or v.headers, clips = c }
  end
  cache.headers, cache.clips = v.point.headers, v.point.clips
end
local function spanLoaded(s, e)
  local v = cache.views and cache.views[currentView]
  return v and v.spans[('%.4f:%.4f'):format(s, e)] ~= nil
end

local function refresh()
  local proj = reaper.EnumProjects(-1)
  local st = reaper.GetProjectStateChangeCount(0)
  if st == cache.state and proj == cache.proj then return end
  -- The panel's own playback changes (solo, selection, active take, lane,
  -- edit cursor) don't change what's in the project, so they don't need a
  -- rescan. A forced rescan (cache.state = -1) always happens.
  if st == cache.ownState and proj == cache.proj and cache.state ~= -1 then
    cache.state = st
    return
  end
  cache.state, cache.proj = st, proj

  -- Regions and project markers
  local regions, markers, i = {}, {}, 0
  while true do
    local rv, isrgn, pos, rgnend, name, idxnum, color = reaper.EnumProjectMarkers3(0, i)
    if rv == 0 then break end
    if isrgn then
      local rgb
      if color and (color & 0x1000000) ~= 0 then
        local r, g, b = reaper.ColorFromNative(color & 0xFFFFFF)
        rgb = { r, g, b }
      end
      regions[#regions + 1] = { s = pos, e = rgnend, name = name, rgb = rgb, idx = idxnum }
    else
      markers[#markers + 1] = { pos = pos, name = (name ~= '' and name) or ('M' .. idxnum) }
    end
    i = i + 1
  end
  table.sort(regions, function(a, b) return a.s < b.s end)
  table.sort(markers, function(a, b) return a.pos < b.pos end)

  -- Which tracks belong to the presentation (the PRESENTATION folder and
  -- everything inside it)
  local presTracks = {}
  local pr = presRootIndex()
  if pr then
    for ti = pr, presLastIndex(pr) do presTracks[reaper.GetTrack(0, ti)] = true end
  end
  local presStart = presStartTime() or math.huge

  cache.presStart = presStart
  cache.hasPres = pr ~= nil
  cache.tracks = scanTracks(presTracks)
  cache.views = {
    overview     = buildView(false, presStart, regions, markers),
    presentation = buildView(true, presStart, regions, markers),
  }
  applyView()
end

-- Every clip in the current view (for "Normalize all clips in this view")
local function allClipsInView()
  local v = cache.views and cache.views[currentView]
  if not v then return {} end
  local _, c = scanItems(v.isPres, -math.huge, math.huge, false, true)
  return c
end

-- Read the regions next to the one on screen, one per frame, while idle
local function prefetch(cur)
  if not cur or not cache.nav then return end
  for i, n in ipairs(cache.nav) do
    if math.abs(n.s - cur) < EPS then
      for _, j in ipairs({ i + 1, i - 1 }) do
        local m = cache.nav[j]
        if m and m.e and not spanLoaded(m.s, m.e) then spanData(m.s, m.e) return end
      end
      return
    end
  end
end

-------------------------------------------------------------- trial logic --

-- Is time x inside one of this region's child regions? Used so a group
-- region (one with regions inside it) only claims what isn't in a child.
local function inChild(region, x)
  if not region then return false end
  for _, ch in ipairs(region.children) do
    if x >= ch.s - EPS and x < ch.e - EPS then return true end
  end
  return false
end

-- Returns span start, span end, title, script header, region (any may be nil).
-- The trial is the innermost region at time t. Its script is the text item
-- on the topmost track within it; other text items are notes (see notesIn).
local function currentTrial(t, probe)
  local r
  for _, x in ipairs(cache.regions) do
    if t >= x.s and t < x.e then
      if not r or (x.e - x.s) < (r.e - r.s) - EPS then r = x end
    end
  end
  if r then
    if probe then return r.s, r.e, r.name, nil, r end
    loadSpan(r.s, r.e)
    local hdr
    for _, h in ipairs(cache.headers) do
      if h.hasText and h.s < r.e - EPS and h.e > r.s + EPS and not inChild(r, h.s) then
        if not hdr or h.ti < hdr.ti or (h.ti == hdr.ti and h.s < hdr.s) then hdr = h end
      end
    end
    return r.s, r.e, r.name, hdr, r
  end
  for _, h in ipairs(cache.mainHeaders or {}) do
    if t >= h.s and t < h.e then
      if not probe then loadSpan(h.s, h.e) end
      return h.s, h.e, nil, h
    end
  end
  -- Between regions: just what's under t (one slot, not remembered)
  if not probe then loadPoint(t) end
  return nil
end

-- Text items in the trial other than the script: shown where they sit
local function notesIn(s, e, t, hdr, region)
  local out = {}
  for _, h in ipairs(cache.headers) do
    if h ~= hdr then
      local inside
      if s then inside = h.s < e - EPS and h.e > s + EPS and not inChild(region, h.s)
      else inside = t >= h.s and t < h.e end
      if inside then out[#out + 1] = h end
    end
  end
  return out
end

local function clipsIn(s, e, t, region)
  local out = {}
  for _, c in ipairs(cache.clips) do
    local inside
    if s then inside = c.s >= s - EPS and c.s < e - EPS and not inChild(region, c.s)
    else inside = t >= c.s and t < c.e end
    if inside then out[#out + 1] = c end
  end
  return out
end

-- Project markers inside the trial, as offsets into the clip they fall in
local function sharedMarkersIn(s, e, clips)
  local out = {}
  if not s then return out end
  for _, m in ipairs(cache.markers) do
    if m.pos >= s and m.pos < e then
      local ref = clips[1] and clips[1].s or s
      for _, c in ipairs(clips) do
        if m.pos >= c.s and m.pos < c.e then ref = c.s break end
      end
      out[#out + 1] = { off = m.pos - ref, name = m.name }
    end
  end
  return out
end

local function navPoints()
  local pts = {}
  for _, n in ipairs(cache.nav) do pts[#pts + 1] = n.s end
  return pts
end

---------------------------------------------------------------- playback --
local viewT      = nil  -- a time inside the trial that's on screen
local seenCursor = nil  -- edit cursor position last time we looked
local lastAction = 0    -- when the panel last started, stopped or moved playback
local function markAction() lastAction = reaper.time_precise() end

local scrollAnchor = nil -- { key, y }: keep this clip's row where it was on screen
local rowYs = {}         -- clip key -> row's screen y (from the last frame)
local rowSeen = {}       -- clip key -> frame number it was last drawn in
local frameNo = 0
local blockH = {}        -- measured heights: blockH.wave (waveform), blockH.seek (seek bar)

local playing   = nil   -- { clip = c, started = time, lastPos = project time }
local activeKey = nil   -- last clip played (its waveform stays shown)
local resume    = {}    -- clip key -> offset where it was paused (normal mode)
local abOff     = nil   -- shared paused offset (A/B mode)
local seekDrag  = {}    -- clip key -> offset while seek bar / waveform is dragged
local loopDrag  = nil   -- { key, a, b } while shift-dragging a loop range
local loopRange = nil   -- { lo, hi } offsets, or nil = whole clip

local origRepeat, repeatWeSet = nil, false

local function clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end

-- Only tracks whose solo actually changes are touched
local function soloOnly(track)
  for i = 0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)
    local want = (tr == track) and 2 or 0
    if reaper.GetMediaTrackInfo_Value(tr, 'I_SOLO') ~= want then
      reaper.SetMediaTrackInfo_Value(tr, 'I_SOLO', want)
    end
  end
end

local function unsoloAll()
  for i = 0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)
    if reaper.GetMediaTrackInfo_Value(tr, 'I_SOLO') ~= 0 then
      reaper.SetMediaTrackInfo_Value(tr, 'I_SOLO', 0)
    end
  end
end

-- Call after the panel's own playback changes: marks the project's current
-- change count as "ours", so refresh() doesn't rescan because of it
local function absorbOwnChanges()
  cache.ownState = reaper.GetProjectStateChangeCount(0)
end

-- What the panel changed, so the project can be put back when it closes
local origTakes = {}   -- item key -> { item, take }
local origLanes = {}   -- track GUID -> { track, vals = { [lane] = C_LANEPLAYS value } }

-- Make only `lane` play on a fixed-lane track
local function playOnlyLane(tr, lane)
  local n = math.floor(reaper.GetMediaTrackInfo_Value(tr, 'I_NUMFIXEDLANES'))
  local g = reaper.GetTrackGUID(tr)
  if not origLanes[g] then
    local vals = {}
    for l = 0, n - 1 do vals[l] = reaper.GetMediaTrackInfo_Value(tr, 'C_LANEPLAYS:' .. l) end
    origLanes[g] = { track = tr, vals = vals }
  end
  for l = 0, n - 1 do
    if l ~= lane and reaper.GetMediaTrackInfo_Value(tr, 'C_LANEPLAYS:' .. l) ~= 0 then
      reaper.SetMediaTrackInfo_Value(tr, 'C_LANEPLAYS:' .. l, 0)
    end
  end
  if reaper.GetMediaTrackInfo_Value(tr, 'C_LANEPLAYS:' .. lane) ~= 1 then
    reaper.SetMediaTrackInfo_Value(tr, 'C_LANEPLAYS:' .. lane, 1)
  end
end

-- Select only this clip's item and make it the one that sounds:
-- its take becomes the active take, and on lane tracks its lane plays alone
local function selectClip(c)
  reaper.SelectAllMediaItems(0, false)
  reaper.SetMediaItemSelected(c.item, true)
  if c.take and reaper.GetActiveTake(c.item) ~= c.take then
    local ik = tostring(c.item)
    if not origTakes[ik] then origTakes[ik] = { item = c.item, take = reaper.GetActiveTake(c.item) } end
    reaper.SetActiveTake(c.take)
  end
  if c.lane then playOnlyLane(c.track, c.lane) end
end

-- Put active takes and lane play states back the way they were
local function restoreTakesAndLanes()
  for _, o in pairs(origTakes) do
    if o.take and reaper.ValidatePtr2(0, o.take, 'MediaItem_Take*') then reaper.SetActiveTake(o.take) end
  end
  for _, o in pairs(origLanes) do
    if reaper.ValidatePtr2(0, o.track, 'MediaTrack*') then
      for l, v in pairs(o.vals) do reaper.SetMediaTrackInfo_Value(o.track, 'C_LANEPLAYS:' .. l, v) end
    end
  end
  origTakes, origLanes = {}, {}
  reaper.UpdateArrange()
end

local function loopBounds(c)
  local len = c.e - c.s
  if loopRange then
    local lo, hi = clamp(loopRange.lo, 0, len), clamp(loopRange.hi, 0, len)
    if hi - lo >= 0.05 then return lo, hi end
  end
  return 0, len
end

local function applyLoop(c)
  local lo, hi = loopBounds(c)
  reaper.GetSet_LoopTimeRange(true, true, c.s + lo, c.s + hi, false)
  if not repeatWeSet then
    origRepeat = reaper.GetSetRepeat(-1)
    repeatWeSet = true
  end
  reaper.GetSetRepeat(1)
end

local function restoreRepeat()
  if repeatWeSet then
    reaper.GetSetRepeat(origRepeat or 0)
    repeatWeSet = false
  end
end

local function currentOffset()
  if not playing then return nil end
  local pos = (reaper.GetPlayState() & 1 == 1) and reaper.GetPlayPosition() or playing.lastPos
  return (pos or playing.clip.s) - playing.clip.s
end

-- Remember where the playing clip is, so it can resume from there
local function rememberPosition()
  if not playing then return end
  local c = playing.clip
  local off = currentOffset()
  if off > 0.05 and off < (c.e - c.s) - 0.05 then
    resume[c.key] = off
    abOff = off
  else
    resume[c.key] = nil
    abOff = nil
  end
end

local function pauseClip()
  markAction()
  rememberPosition()
  reaper.OnStopButton()
  restoreRepeat()
  if playing then unsoloAll() end
  playing = nil
  absorbOwnChanges()
end

local function playClip(c, from)
  markAction()
  if playing and playing.clip.key ~= c.key then rememberPosition() end
  from = clamp(from or c.s, c.s, c.e - 0.01)
  if cfg.loop then
    local lo, hi = loopBounds(c)
    if from < c.s + lo or from >= c.s + hi then from = c.s + lo end
  end

  reaper.PreventUIRefresh(1)
  reaper.OnStopButton()
  soloOnly(c.track)
  selectClip(c)
  if cfg.loop then applyLoop(c) else restoreRepeat() end
  reaper.SetEditCurPos(from, true, false)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.OnPlayButton()

  resume[c.key] = nil
  playing = { clip = c, started = reaper.time_precise(), lastPos = from }
  activeKey = c.key
  absorbOwnChanges()
end

-- A/B switch while playing: keep the same offset into the clip.
-- off = nil means "wherever the current clip is right now".
--
-- Clean switch: after changing the solo/lane/take, always seek playback to
-- the same point. Seeking makes REAPER throw away audio it had already read
-- and processed ahead, so B starts straight away instead of A running on for
-- the length of REAPER's buffers. Costs a very short gap instead of overlap.
--
-- Smooth (optional, the "Smooth" toggle): for clips that start at exactly the
-- same time, e.g. two versions of the same recording, only the solo/lane/take
-- is swapped and playback isn't touched, so the sound carries on with no gap.
-- The switch is heard a moment late (REAPER plays out what it had already
-- prepared), which is inaudible when the material is the same. Clips that
-- don't line up always get the reset switch.
local smoothAB = false     -- off every time the panel opens

local function switchTo(c, off)
  markAction()
  local p = playing.clip
  local smooth = smoothAB and off == nil and math.abs(c.s - p.s) <= EPS
  if smooth and currentOffset() >= (c.e - c.s) - 0.01 then smooth = false end  -- past B's end

  reaper.PreventUIRefresh(1)
  soloOnly(c.track)
  selectClip(c)
  if cfg.loop then applyLoop(c) end
  if not smooth then
    -- read the position as late as possible so the jump lands where you are
    if off == nil then off = currentOffset() end
    if off >= (c.e - c.s) - 0.01 then off = 0 end
    reaper.SetEditCurPos(c.s + off, false, true)
  end
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()

  playing.clip = c
  activeKey = c.key
  absorbOwnChanges()
end

-- Play clip c from offset `off`, seeking smoothly if it's already playing
local function seekTo(c, off)
  markAction()
  off = clamp(off, 0, (c.e - c.s) - 0.01)
  if playing and playing.clip.key == c.key then
    reaper.SetEditCurPos(c.s + off, false, true)
    absorbOwnChanges()
  elseif playing and cfg.ab then
    switchTo(c, off)
  else
    playClip(c, c.s + off)
  end
end

local function jumpToMarker(c, off)
  seekTo(c, math.max(0, off - cfg.preroll))
end

-- Big button
local function toggleClip(c)
  if playing and playing.clip.key == c.key then
    pauseClip()
  elseif playing and cfg.ab then
    switchTo(c)
  elseif cfg.ab and abOff then
    playClip(c, c.s + abOff)
  elseif resume[c.key] then
    playClip(c, c.s + resume[c.key])
  else
    playClip(c, c.s)
  end
end

local function restartClip(c)
  resume[c.key] = nil
  abOff = nil
  playClip(c, c.s)
end

local function setLoop(on)
  cfg.loop = on
  if playing then
    if on then applyLoop(playing.clip) else restoreRepeat() end
  end
  absorbOwnChanges()
end

local function watchPlayback()
  if not playing then return end
  local c = playing.clip
  local isPlaying = reaper.GetPlayState() & 1 == 1
  if isPlaying then
    local pos = reaper.GetPlayPosition()
    playing.lastPos = pos
    -- With loop on, REAPER wraps by itself; the margin is just a safety net
    local stopAt = cfg.loop and (c.e + 0.25) or c.e
    if pos >= stopAt then
      reaper.OnStopButton()
      restoreRepeat()
      unsoloAll()
      resume[c.key], abOff = nil, nil
      playing = nil
      absorbOwnChanges()
    end
  elseif reaper.time_precise() - playing.started > 0.3 then
    -- stopped from REAPER's own transport: keep the position like a pause
    rememberPosition()
    restoreRepeat()
    unsoloAll()
    playing = nil
    absorbOwnChanges()
  end
end

local function jumpTo(pos)
  pauseClip()
  reaper.SetEditCurPos(pos, true, false)
  viewT, seenCursor = pos, pos
  absorbOwnChanges()
end

-- Which time decides the trial on screen. Deliberately sticky:
--   - while the panel plays a clip, stay on that clip's trial, even if the
--     clip runs past the end of its region or header item
--   - just after a panel action, ignore the playhead/edit cursor (they can
--     briefly report other positions while REAPER starts or stops)
--   - otherwise only change when you move the edit cursor in REAPER, or when
--     REAPER's own transport is playing (then follow it, like before)
-- If the time falls between trials, keep showing the last one.
local function resolveViewTime()
  if playing then
    local c = playing.clip
    viewT = c.s + math.min(0.01, (c.e - c.s) / 2)
    seenCursor = reaper.GetCursorPosition()
    return viewT
  end
  local cur = reaper.GetCursorPosition()
  if viewT and reaper.time_precise() - lastAction < 0.6 then
    seenCursor = cur
    return viewT
  end
  if reaper.GetPlayState() & 1 == 1 then
    local t = reaper.GetPlayPosition()
    if currentTrial(t, true) then viewT = t end
  elseif cur ~= seenCursor then
    seenCursor = cur
    if currentTrial(cur, true) then viewT = cur end
  end
  if not viewT then viewT = cur end
  return viewT
end

-- Remember where a clip's row is on screen, so the list can be scrolled back
-- if the layout above it changes (e.g. the waveform moving to another clip)
-- Scrolling acts on the CURRENT window, and the clips live in the 'presenterBody'
-- child. inBody is true only while the clip list is being drawn; a call from
-- anywhere else (toolbar, keyboard section) is queued and applied inside the child
-- next frame, so it can never scroll the pinned toolbar.
local inBody = false
local pendingScrollDy = 0
local function scrollBodyBy(dy)
  if inBody then
    ImGui.SetScrollY(ctx, math.max(0, ImGui.GetScrollY(ctx) + dy))
  else
    pendingScrollDy = pendingScrollDy + dy
  end
end

local function anchorRow(c)
  if not (c and rowYs[c.key]) then return end
  scrollAnchor = { key = c.key, y = rowYs[c.key] }

  -- The waveform is about to move to this clip. If it's currently on a clip
  -- ABOVE this one (and on screen), everything below shrinks up by the
  -- difference between a waveform and a seek bar. Scroll by that amount now,
  -- so the change and the scroll land in the same frame: no visible jump.
  -- (The anchor above still corrects anything this doesn't catch.)
  local old = activeKey
  if old and old ~= c.key and not cfg.showAllWaves and rowSeen[old] == frameNo
      and rowYs[old] and rowYs[old] < rowYs[c.key] and blockH.wave and blockH.seek then
    local dy = blockH.wave - blockH.seek
    if dy > 0 then scrollBodyBy(-dy) end
  end
end

-------------------------------------------------------------------- peaks --
local WAVE_COLS = 1200
local peakCache = {}   -- clip key -> { s, e, n, maxs, mins } or { retryAt }

local function getPeaks(c)
  local pk = peakCache[c.key]
  if pk and pk.maxs and pk.s == c.s and pk.e == c.e then return pk end
  if pk and pk.retryAt and reaper.time_precise() < pk.retryAt then return nil end

  local len = c.e - c.s
  if len <= 0 then return nil end
  local src = reaper.GetMediaItemTake_Source(c.take)
  local nch = clamp(math.floor(reaper.GetMediaSourceNumChannels(src)), 1, 2)
  local n = WAVE_COLS
  local buf = reaper.new_array(n * nch * 2)
  buf.clear()
  local rv = reaper.GetMediaItemTake_Peaks(c.take, n / len, c.s, nch, n, 0, buf)
  local got = math.floor(rv) & 0xFFFFF
  if got == 0 then
    -- peaks still being built; try again shortly
    peakCache[c.key] = { retryAt = reaper.time_precise() + 0.5 }
    return nil
  end

  local t = buf.table()
  local maxs, mins = {}, {}
  for i = 1, got do
    local mx, mn = 0, 0
    for ch = 1, nch do
      local a = t[(i - 1) * nch + ch] or 0
      local b = t[n * nch + (i - 1) * nch + ch] or 0
      if a > mx then mx = a end
      if b < mn then mn = b end
    end
    maxs[i], mins[i] = mx, mn
  end
  pk = { s = c.s, e = c.e, n = got, maxs = maxs, mins = mins }
  peakCache[c.key] = pk
  return pk
end

-------------------------------------------------------------------- draw --
-- Project colours ({r, g, b}) as ImGui colours, plus readable text on them
local function rgba(rgb, a) return (rgb[1] << 24) | (rgb[2] << 16) | (rgb[3] << 8) | (a or 0xFF) end
local function shade(rgb, f)   -- f > 0 lightens, f < 0 darkens
  local out = {}
  for k = 1, 3 do
    local v = rgb[k]
    v = (f >= 0) and (v + (255 - v) * f) or (v * (1 + f))
    out[k] = math.floor(math.max(0, math.min(255, v)))
  end
  return out
end
local function textOn(rgb)
  local lum = 0.299 * rgb[1] + 0.587 * rgb[2] + 0.114 * rgb[3]
  return lum > 150 and 0x111111FF or 0xFFFFFFFF
end

-- style: 'play' (green), 'paused' (amber), 'switch' (blue), a project
-- colour {r, g, b}, or nil (grey)
local function coloredButton(label, w, h, style)
  if type(style) == 'table' then
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, rgba(style))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, rgba(shade(style, 0.15)))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, rgba(shade(style, -0.15)))
    ImGui.PushStyleColor(ctx, ImGui.Col_Text, textOn(style))
    local pressed = ImGui.Button(ctx, label, w, h)
    ImGui.PopStyleColor(ctx, 4)
    return pressed
  end
  if style == 'play' then
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, COL.play)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, COL.playHover)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, COL.playActive)
  elseif style == 'paused' then
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, COL.paused)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, COL.pausedHov)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, COL.pausedAct)
  elseif style == 'selected' then
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, COL.btnActive)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, COL.btnActive)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, COL.btnActive)
  elseif style == 'switch' then
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, COL.switch)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, COL.switchHov)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, COL.switchAct)
  else
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, COL.btn)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, COL.btnHover)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, COL.btnActive)
  end
  local pressed = ImGui.Button(ctx, label, w, h)
  ImGui.PopStyleColor(ctx, 3)
  return pressed
end

local function fmtTime(sec)
  sec = math.max(0, sec)
  return ('%d:%04.1f'):format(math.floor(sec / 60), sec % 60)
end

-- Draw a transport symbol centred in the last item's box.
-- Drawn as shapes, so it doesn't depend on the font having the glyphs.
local function drawIcon(kind, col)
  local x0, y0 = ImGui.GetItemRectMin(ctx)
  local x1, y1 = ImGui.GetItemRectMax(ctx)
  local dl = ImGui.GetWindowDrawList(ctx)
  local s = math.min(x1 - x0, y1 - y0) * 0.26
  local cx, cy = (x0 + x1) / 2, (y0 + y1) / 2

  if kind == 'play' then
    ImGui.DrawList_AddTriangleFilled(dl, cx - s * 0.75, cy - s, cx - s * 0.75, cy + s, cx + s, cy, col)
  elseif kind == 'pause' then
    local bw = s * 0.6
    ImGui.DrawList_AddRectFilled(dl, cx - s * 0.85, cy - s, cx - s * 0.85 + bw, cy + s, col, 1)
    ImGui.DrawList_AddRectFilled(dl, cx + s * 0.85 - bw, cy - s, cx + s * 0.85, cy + s, col, 1)
  elseif kind == 'restart' then
    ImGui.DrawList_AddRectFilled(dl, cx - s, cy - s, cx - s + s * 0.35, cy + s, col, 1)
    ImGui.DrawList_AddTriangleFilled(dl, cx + s, cy - s, cx + s, cy + s, cx - s * 0.55, cy, col)
  elseif kind == 'switch' then
    -- two arrows: right on top, left underneath (A/B swap)
    local t, hd = s * 0.22, s * 0.42
    local yt, yb = cy - s * 0.48, cy + s * 0.48
    ImGui.DrawList_AddLine(dl, cx - s, yt, cx + s * 0.35, yt, col, t)
    ImGui.DrawList_AddTriangleFilled(dl, cx + s * 0.3, yt - hd, cx + s * 0.3, yt + hd, cx + s, yt, col)
    ImGui.DrawList_AddLine(dl, cx + s, yb, cx - s * 0.35, yb, col, t)
    ImGui.DrawList_AddTriangleFilled(dl, cx - s * 0.3, yb - hd, cx - s * 0.3, yb + hd, cx - s, yb, col)
  elseif kind == 'edit' then
    -- pencil: slanted body, point at the bottom left, line underneath
    local t = s * 0.5
    ImGui.DrawList_AddLine(dl, cx + s * 0.85, cy - s * 0.85, cx - s * 0.35, cy + s * 0.35, col, t)
    ImGui.DrawList_AddTriangleFilled(dl, cx - s * 0.75, cy + s * 0.75, cx - s * 0.7, cy + s * 0.05, cx - s * 0.05, cy + s * 0.7, col)
    ImGui.DrawList_AddLine(dl, cx - s * 0.2, cy + s * 0.95, cx + s, cy + s * 0.95, col, s * 0.2)
  end
end

local function iconButton(id, kind, size, style, iconCol)
  local pressed = coloredButton('##' .. id, size, size, style)
  if type(style) == 'table' and not iconCol then iconCol = textOn(style) end
  drawIcon(kind, iconCol or COL.icon)
  return pressed
end

local function shiftHeld()
  return (ImGui.GetKeyMods(ctx) & ImGui.Mod_Shift) ~= 0
end

local KEYS = {
  ImGui.Key_1, ImGui.Key_2, ImGui.Key_3, ImGui.Key_4, ImGui.Key_5,
  ImGui.Key_6, ImGui.Key_7, ImGui.Key_8, ImGui.Key_9,
}

-- Colours for one tab: background, hover background, text
local function tabColours(n, isCurrent)
  if isCurrent then return COL.accent, COL.accent, 0x111111FF end
  if n.rgb then
    local rgb = (n.rgb[1] << 24) | (n.rgb[2] << 16) | (n.rgb[3] << 8)
    return rgb | 0x90, rgb | 0xE0, 0xFFFFFFFF
  end
  return COL.btn, COL.btnHover, 0xFFFFFFFF
end

-- One wrapping row of tabs. items: { label, rgb, s }. isCurrent(item) marks
-- the selected tab; onClick(item) runs when another tab is clicked.
local function drawTabRow(items, rowId, isCurrent, onClick, reserveRight)
  if #items == 0 then return end
  reserveRight = reserveRight or 0
  local padX, spacing = 12, 6
  ImGui.PushFont(ctx, font, cfg.tabSize)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, padX, 6)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, spacing, spacing)

  local avail = ImGui.GetContentRegionAvail(ctx)
  local lineW, firstLine = 0, true
  for i, n in ipairs(items) do
    local w = ImGui.CalcTextSize(ctx, n.label) + padX * 2
    local room = firstLine and (avail - reserveRight) or avail
    if i > 1 and lineW + spacing + w <= room then
      ImGui.SameLine(ctx)
      lineW = lineW + spacing + w
    else
      if i > 1 then firstLine = false end
      lineW = w
    end

    local cur = isCurrent(n)
    local bg, hov, txt = tabColours(n, cur)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, bg)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, hov)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, hov)
    ImGui.PushStyleColor(ctx, ImGui.Col_Text, txt)
    if ImGui.Button(ctx, n.label .. '##' .. rowId .. '_' .. i) and not cur then onClick(n) end
    ImGui.PopStyleColor(ctx, 4)
  end

  ImGui.PopStyleVar(ctx, 2)
  ImGui.PopFont(ctx)
end

-- Tabs when there are no regions: one per script item
local function drawTabs(currentStart, reserveRight)
  drawTabRow(cache.nav, 'tab',
    function(n) return currentStart and math.abs(n.s - currentStart) < EPS end,
    function(n) jumpTo(n.s) end, reserveRight)
end

-- Where clicking a group tab goes: the start of its first trial
local function firstTrialStart(r)
  while #r.children > 0 do r = r.children[1] end
  return r.s
end

-- Tabs for regions, one row per nesting level along the current trial's
-- path: top-level regions, then the regions inside the selected one, and so
-- on down to the trials. Regions with nothing inside are just trial tabs.
local function drawRegionTabs(cur, reserveRight)
  local path = {}
  local r = cur
  while r do table.insert(path, 1, r); r = r.parent end

  local list, level = cache.roots, 1
  while list and #list > 0 do
    local selected = path[level]
    drawTabRow(list, 'lvl' .. level,
      function(n) return n == selected end,
      function(n) jumpTo(firstTrialStart(n)) end, level == 1 and reserveRight or 0)
    if not selected or #selected.children == 0 then break end
    list = selected.children
    level = level + 1
  end
end

------------------------------------------------- confirmations + removing --
local status = nil            -- { text, col, untilT }: short line in the top row

local function setStatus(text, col)
  status = { text = text, col = col or COL.dim, untilT = reaper.time_precise() + 4 }
end

-- Remove one line from an item's notes (the little x on an open note line)
local function removeNoteLine(item, lineText)
  if not reaper.ValidatePtr2(0, item, 'MediaItem*') then return end
  local lines = {}
  for line in (itemNotes(item) .. '\n'):gmatch('(.-)\r?\n') do lines[#lines + 1] = line end
  for k, l in ipairs(lines) do
    if (l:gsub('%s+$', '')) == lineText then
      table.remove(lines, k)
      reaper.Undo_BeginBlock()
      reaper.GetSetMediaItemInfo_String(item, 'P_NOTES', (table.concat(lines, '\n'):gsub('%s+$', '')), true)
      reaper.Undo_EndBlock('Presenter: remove note line', -1)
      reaper.UpdateArrange()
      cache.state = -1
      setStatus('Note removed  (Ctrl+Z to undo)', COL.accent)
      return
    end
  end
end

-- Remove a take marker (the little x next to a marker button)
local function removeMarker(c, m)
  if not (c.take and m.idx and reaper.ValidatePtr2(0, c.take, 'MediaItem_Take*')) then return end
  reaper.Undo_BeginBlock()
  local ok = reaper.DeleteTakeMarker(c.take, m.idx)
  reaper.Undo_EndBlock('Presenter: remove take marker', -1)
  reaper.UpdateArrange()
  cache.state = -1
  if ok then
    setStatus('Marker removed: ' .. m.name .. '  (Ctrl+Z to undo)', COL.liveNote)
  else
    setStatus('Could not remove the marker', 0xFF6B6BFF)
  end
end

-- Small wrapping row of marker jump buttons. With onAdd, the row starts
-- with a "+ Marker" button (adds a take marker at the current moment).
local function drawMarkerButtons(list, idPrefix, color, onClick, onAdd, onRemove)
  if #list == 0 and not onAdd then return end
  local padX, spacing = 8, 6
  ImGui.PushFont(ctx, font, 15)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, padX, 3)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, spacing, spacing)
  local avail = ImGui.GetContentRegionAvail(ctx)
  local lineW = 0
  if onAdd then
    ImGui.PushStyleColor(ctx, ImGui.Col_Text, COL.liveNote)
    if coloredButton('+ Marker  [M]##add' .. idPrefix, 0, 0) then onAdd() end
    if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, 'Add a take marker here at the current moment (M)') end
    ImGui.PopStyleColor(ctx)
    lineW = ImGui.CalcTextSize(ctx, '+ Marker  [M]') + padX * 2
  end
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, color)
  local xW = onRemove and (ImGui.CalcTextSize(ctx, 'x') + 10 + 2) or 0   -- the little x
  for k, m in ipairs(list) do
    local label = ('%s  %s'):format(fmtTime(m.off), m.name)
    local w = ImGui.CalcTextSize(ctx, label) + padX * 2 + xW
    if (k > 1 or onAdd) and lineW + spacing + w <= avail then
      ImGui.SameLine(ctx)
      lineW = lineW + spacing + w
    else
      lineW = w
    end
    if m.col then ImGui.PushStyleColor(ctx, ImGui.Col_Text, m.col) end
    if coloredButton(label .. '##' .. idPrefix .. k, 0, 0) then onClick(m) end
    if m.col then ImGui.PopStyleColor(ctx) end
    if onRemove then
      -- little x, tucked against the marker's button
      ImGui.SameLine(ctx, 0, 2)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 5, 3)
      ImGui.PushStyleColor(ctx, ImGui.Col_Text, COL.dim)
      if coloredButton('x##rm' .. idPrefix .. k, 0, 0) then onRemove(m) end
      if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, 'Remove this marker') end
      ImGui.PopStyleColor(ctx)
      ImGui.PopStyleVar(ctx)
    end
  end
  ImGui.PopStyleColor(ctx)
  ImGui.PopStyleVar(ctx, 2)
  ImGui.PopFont(ctx)
end

local function displayOffset(c, isThis)
  if seekDrag[c.key] then return seekDrag[c.key] end
  if isThis then return reaper.GetPlayPosition() - c.s end
  if cfg.ab and abOff then return abOff end
  return resume[c.key] or 0
end

local function drawSeekBar(c, i, isThis)
  local len = c.e - c.s
  local cur = clamp(displayOffset(c, isThis), 0, len)
  local label = ''   -- the time is shown in the clip's time box above

  ImGui.PushFont(ctx, font, 16)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 8, 4)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabMinSize, 14)
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, COL.seekBg)
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, COL.seekBgHov)
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive, COL.seekBgHov)
  ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab, isThis and COL.play or COL.accent)
  ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive, COL.accent)

  ImGui.SetNextItemWidth(ctx, -1)
  local _, v = ImGui.SliderDouble(ctx, '##seek' .. i, cur, 0, len, label)
  if ImGui.IsItemActive(ctx) then seekDrag[c.key] = v end
  if ImGui.IsItemDeactivated(ctx) then
    local target = seekDrag[c.key] or v
    seekDrag[c.key] = nil
    seekTo(c, target)
  end

  ImGui.PopStyleColor(ctx, 5)
  ImGui.PopStyleVar(ctx, 2)
  ImGui.PopFont(ctx)
end

local function drawWaveform(c, i, isThis, shared)
  local len = c.e - c.s
  if len <= 0 then return end
  local w = math.max(50, ImGui.GetContentRegionAvail(ctx))
  local h = cfg.waveHeight
  local x0, y0 = ImGui.GetCursorScreenPos(ctx)

  ImGui.InvisibleButton(ctx, '##wave' .. i, w, h)
  local mx = ImGui.GetMousePos(ctx)
  local mouseOff = clamp((mx - x0) / w, 0, 1) * len

  -- Interaction: click/drag = seek on release; shift+drag = loop range
  if ImGui.IsItemActivated(ctx) and shiftHeld() then
    loopDrag = { key = c.key, a = mouseOff, b = mouseOff }
  end
  if ImGui.IsItemActive(ctx) then
    if loopDrag and loopDrag.key == c.key then
      loopDrag.b = mouseOff
    else
      seekDrag[c.key] = mouseOff
    end
  end
  if ImGui.IsItemDeactivated(ctx) then
    if loopDrag and loopDrag.key == c.key then
      local lo, hi = math.min(loopDrag.a, loopDrag.b), math.max(loopDrag.a, loopDrag.b)
      loopDrag = nil
      if hi - lo < 0.05 then
        loopRange = nil                        -- shift-click clears the range
      else
        loopRange = { lo = lo, hi = hi }
        cfg.loop = true
      end
      if playing and cfg.loop then applyLoop(playing.clip) end
    else
      local target = seekDrag[c.key] or mouseOff
      seekDrag[c.key] = nil
      seekTo(c, target)
    end
  end

  local dl = ImGui.GetWindowDrawList(ctx)
  local function xOf(off) return x0 + clamp(off / len, 0, 1) * w end

  -- Background
  ImGui.DrawList_AddRectFilled(dl, x0, y0, x0 + w, y0 + h, COL.seekBg, 6)

  -- Loop range
  local lo, hi
  if loopDrag and loopDrag.key == c.key then
    lo, hi = math.min(loopDrag.a, loopDrag.b), math.max(loopDrag.a, loopDrag.b)
  elseif loopRange then
    lo, hi = loopBounds(c)
  end
  if lo and hi and hi > lo then
    ImGui.DrawList_AddRectFilled(dl, xOf(lo), y0, xOf(hi), y0 + h,
      cfg.loop and COL.loopShade or COL.loopShadeOff)
  end

  -- Waveform
  local pk = getPeaks(c)
  local mid = y0 + h / 2
  if pk then
    local col = isThis and COL.waveOn or (c.rgb and rgba(shade(c.rgb, 0.35))) or COL.waveOff
    local cols = math.floor(w)
    for px = 0, cols - 1 do
      local idx = math.floor(px / cols * pk.n) + 1
      local top = (pk.maxs[idx] or 0) * (h / 2 - 2)
      local bot = (pk.mins[idx] or 0) * (h / 2 - 2)
      ImGui.DrawList_AddLine(dl, x0 + px, mid - top, x0 + px, mid - bot + 1, col, 1)
    end
  else
    ImGui.DrawList_AddText(dl, x0 + 10, mid - 8, COL.dim, 'building waveform...')
  end

  -- Markers (shared = project markers, own = take markers)
  ImGui.PushFont(ctx, font, 14)
  for _, m in ipairs(shared) do
    local x = xOf(m.off)
    ImGui.DrawList_AddLine(dl, x, y0, x, y0 + h, COL.sharedMarker, 2)
    ImGui.DrawList_AddText(dl, x + 4, y0 + h - 18, COL.sharedMarker, m.name)
  end
  for _, m in ipairs(c.markers) do
    local x = xOf(m.off)
    ImGui.DrawList_AddLine(dl, x, y0, x, y0 + h, m.col or COL.takeMarker, 2)
    ImGui.DrawList_AddText(dl, x + 4, y0 + 2, m.col or COL.takeMarker, m.name)
  end

  -- Playhead and time
  local cur = clamp(displayOffset(c, isThis), 0, len)
  local px = xOf(cur)
  ImGui.DrawList_AddLine(dl, px, y0, px, y0 + h, COL.playhead, 2)
  local timeTxt = fmtTime(cur) .. ' / ' .. fmtTime(len)
  local tw = ImGui.CalcTextSize(ctx, timeTxt)
  ImGui.DrawList_AddText(dl, x0 + w - tw - 8, y0 + 4, COL.dim, timeTxt)
  ImGui.PopFont(ctx)
end

-- One clip: restart button, main button, waveform or seek bar, marker buttons
----------------------------------------------------------------- notes --
local clipNotes = {}   -- clip key -> list of { text, image }, rebuilt every frame
local noteGen   = 0    -- bumped when "notes open by default" changes, to re-apply it
local bigImage  = nil  -- image path shown in the large viewer window

-- Images are loaded once per file and kept attached to the panel
local imgCache = {}    -- path -> image, or false if it couldn't be loaded
local function getImage(path)
  if not path then return nil end
  local img = imgCache[path]
  if img == nil then
    local ok, res = pcall(ImGui.CreateImage, path)
    if ok and res then
      ImGui.Attach(ctx, res)
      img = res
    else
      img = false
    end
    imgCache[path] = img
  end
  return img or nil
end

-- Draw an image scaled to fit maxW x maxH (never enlarged). Click opens it
-- in the large viewer.
local function drawImage(path, maxW, maxH)
  local img = getImage(path)
  if not img then
    ImGui.TextColored(ctx, COL.dim, '(image not found: ' .. (path:match('[^\\/]+$') or path) .. ')')
    return
  end
  local iw, ih = ImGui.Image_GetSize(img)
  if not iw or iw <= 0 or ih <= 0 then return end
  local sc = math.min(maxW / iw, maxH / ih, 1)
  ImGui.Image(ctx, img, iw * sc, ih * sc)
  if ImGui.IsItemHovered(ctx) then ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_Hand) end
  if ImGui.IsItemClicked(ctx) then bigImage = path end
end

-- Decide where each note goes: under the clips on its track (those that
-- overlap it in time, else the track's first clip), or as its own row if
-- its track has no clip in this trial. Returns the notes that need rows.
local function assignNotes(notes, clips)
  clipNotes = {}
  local rows = {}
  for _, n in ipairs(notes) do
    local onTrack, overlapping = {}, {}
    for _, c in ipairs(clips) do
      if c.track == n.track then
        onTrack[#onTrack + 1] = c
        if c.s < n.e - EPS and c.e > n.s + EPS then overlapping[#overlapping + 1] = c end
      end
    end
    local targets = (#overlapping > 0) and overlapping or { onTrack[1] }
    if #onTrack == 0 then
      rows[#rows + 1] = n
    else
      for _, c in ipairs(targets) do
        clipNotes[c.key] = clipNotes[c.key] or {}
        table.insert(clipNotes[c.key], { text = n.notes, image = n.image or itemImage(n.item), item = n.item })
      end
    end
  end
  return rows
end

local function noteSize() return math.max(14, math.floor(cfg.buttonSize * 0.6)) end

-- The full note: texts and images, with a gold bar down the left side
local function drawNoteBody(entries)
  ImGui.Indent(ctx, 16)
  ImGui.BeginGroup(ctx)
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, COL.noteText)
  for _, en in ipairs(entries) do
    local text = (en.text or ''):gsub('%s+$', '')
    if text:match('%S') then
      if en.item then
        -- one line at a time, each with a little x to remove it
        local n = 0
        for line in (text .. '\n'):gmatch('(.-)\r?\n') do
          n = n + 1
          local l = line:gsub('%s+$', '')
          if l:match('%S') then
            ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 4, 0)
            ImGui.PushStyleColor(ctx, ImGui.Col_Text, COL.dim)
            if ImGui.SmallButton(ctx, 'x##dl' .. tostring(en.item) .. '_' .. n) then
              removeNoteLine(en.item, l)
            end
            if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, 'Remove this line') end
            ImGui.PopStyleColor(ctx)
            ImGui.PopStyleVar(ctx)
            ImGui.SameLine(ctx)
            ImGui.TextWrapped(ctx, l)
          end
        end
      else
        ImGui.TextWrapped(ctx, text)
      end
    end
    if en.image then
      drawImage(en.image, math.max(50, ImGui.GetContentRegionAvail(ctx)), cfg.noteImgHeight)
    end
  end
  ImGui.PopStyleColor(ctx)
  ImGui.EndGroup(ctx)
  local x0, y0 = ImGui.GetItemRectMin(ctx)
  local _, y1 = ImGui.GetItemRectMax(ctx)
  ImGui.DrawList_AddRectFilled(ImGui.GetWindowDrawList(ctx), x0 - 12, y0, x0 - 8, y1, COL.accent, 2)
  ImGui.Unindent(ctx, 16)
end

-- A collapsible note. Closed, it shows one line: the title (or "Note") and a
-- preview of the first line of text, plus "[+ image]" if there's an image.
-- Click to open. Whether notes start open is set in Settings.
local function drawNotes(id, entries, title)
  if #entries == 0 then return end
  local preview, hasImg = nil, false
  for _, en in ipairs(entries) do
    if en.image then hasImg = true end
    if not preview then
      local first = (en.text or ''):match('[^\r\n]*%S[^\r\n]*')
      if first then preview = first:gsub('^%s+', ''):gsub('%s+$', '') end
    end
  end
  if preview and #preview > 60 then preview = preview:sub(1, 58) .. '..' end
  local label = (title or 'Note') .. ':   ' .. (preview or (hasImg and 'image' or ''))
  if hasImg and preview then label = label .. '   [+ image]' end

  ImGui.PushFont(ctx, font, noteSize())
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, COL.accent)
  ImGui.SetNextItemOpen(ctx, cfg.notesOpen, ImGui.Cond_Once)
  local open = ImGui.TreeNodeEx(ctx, 'note' .. id .. 'g' .. noteGen, label, ImGui.TreeNodeFlags_SpanAvailWidth)
  ImGui.PopStyleColor(ctx)
  if open then
    drawNoteBody(entries)
    ImGui.TreePop(ctx)
  end
  ImGui.PopFont(ctx)
end

local PB = {}   -- the presentation builder (see "presentation" below)
local startMarker   -- defined in "add a marker" below
local startNote     -- defined in "add a note" below

local function drawClip(c, i, activeClip, shared)
  local btnH = math.floor(cfg.buttonSize * 1.9)
  local isThis = playing and playing.clip.key == c.key
  local isPaused = (not isThis) and (not cfg.ab) and resume[c.key] ~= nil

  -- State of this clip, shown by colour + symbol (the text never changes):
  --   playing  green,  pause symbol   (click pauses)
  --   paused   amber,  play symbol    (click resumes from the time shown)
  --   switch   blue,   swap symbol    (A/B: click switches to it at the same point)
  --   idle     grey,   play symbol
  local state
  if isThis then state = 'playing'
  elseif playing and cfg.ab then state = 'switch'
  elseif isPaused or (cfg.ab and abOff) then state = 'paused'
  else state = 'idle' end
  -- Name button: green playing, blue A/B, otherwise the clip's own colour.
  -- State box: same, except amber when paused (so paused still shows).
  local style = ({ playing = 'play', switch = 'switch' })[state] or c.rgb
  local stateStyle = (state == 'paused') and 'paused' or style
  local icon  = ({ playing = 'pause', paused = 'play', switch = 'switch', idle = 'play' })[state]

  -- Restart and state boxes
  local rowX, rowY = ImGui.GetCursorScreenPos(ctx)

  -- If this row was clicked last frame and has since moved on screen (because
  -- something above it changed height), scroll so it's back where it was
  if scrollAnchor and scrollAnchor.key == c.key then
    local dy = rowY - scrollAnchor.y
    if math.abs(dy) > 1 then scrollBodyBy(dy) end
    scrollAnchor = nil
  end
  rowYs[c.key] = rowY
  rowSeen[c.key] = frameNo

  -- Tick box (both views): select for recolouring / adding / removing
  if PB.selectBox('sel' .. i, PB.isSelected(c), btnH) then PB.setSelected(c, not PB.isSelected(c)) end
  ImGui.SameLine(ctx)
  if iconButton('restart' .. i, 'restart', btnH, nil, COL.iconDim) then anchorRow(c); restartClip(c) end
  ImGui.SameLine(ctx)
  if iconButton('state' .. i, icon, btnH, stateStyle) then anchorRow(c); toggleClip(c) end
  ImGui.SameLine(ctx)

  -- Time box: fixed width, shows where the clip is (or will play from)
  local timeSize = math.max(13, math.floor(cfg.buttonSize * 0.6))
  ImGui.PushFont(ctx, font, timeSize)
  local timeW = ImGui.CalcTextSize(ctx, '00:00.0 / 00:00.0') + 24
  ImGui.PopFont(ctx)

  -- Name: number, track, lane/take. Fixed text, left-aligned.
  local name = (i <= 9 and (i .. '     ') or '') .. c.trackName
  if c.takeLabel then name = name .. '  |  ' .. c.takeLabel end
  if cfg.showFiles then name = name .. '   (' .. c.takeName .. ')' end
  -- Presentation: room for the remove x at the end of the row
  local xW = c.inPres and math.floor(btnH * 0.75) or 0
  local editW = math.floor(btnH * 0.75)       -- room for the rename pencil
  local nameW = math.max(80, ImGui.GetContentRegionAvail(ctx) - timeW - 10 - (editW + 10) - (xW > 0 and xW + 10 or 0))
  local editing = PB.inlineRename and PB.inlineRename.key == c.key
  ImGui.PushFont(ctx, font, cfg.buttonSize)
  if editing then
    -- Track name edited in place. Enter or clicking away saves, Esc cancels.
    local d = PB.inlineRename
    if d.focus then ImGui.SetKeyboardFocusHere(ctx); d.focus = false end
    ImGui.SetNextItemWidth(ctx, nameW)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 8, math.max(2, (btnH - ImGui.GetTextLineHeight(ctx)) / 2))
    local _
    _, d.text = ImGui.InputText(ctx, '##inlinerename' .. i, d.text)
    ImGui.PopStyleVar(ctx)
    if ImGui.IsKeyPressed(ctx, ImGui.Key_Escape, false) then
      PB.inlineRename = nil
    elseif ImGui.IsItemDeactivated(ctx) then
      local t = d.text:gsub('^%s+', ''):gsub('%s+$', '')
      if t ~= '' and t ~= c.trackName then PB.saveRename({ kind = 'track', obj = c.track, text = t }) end
      PB.inlineRename = nil
    end
  else
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign, 0, 0.5)
    if coloredButton(name .. '##clip' .. i, nameW, btnH, style) then anchorRow(c); toggleClip(c) end
    ImGui.PopStyleVar(ctx)
  end
  ImGui.PopFont(ctx)
  PB.clipMenu(c, i)
  ImGui.SameLine(ctx)

  local len = c.e - c.s
  local cur = clamp(displayOffset(c, isThis), 0, len)
  local tx, ty = ImGui.GetCursorScreenPos(ctx)
  ImGui.Dummy(ctx, timeW, btnH)
  local dl = ImGui.GetWindowDrawList(ctx)
  ImGui.DrawList_AddRectFilled(dl, tx, ty, tx + timeW, ty + btnH, COL.seekBg, 6)
  local tcol = (state == 'playing' and COL.waveOn) or (state == 'paused' and COL.accent) or COL.dim
  ImGui.PushFont(ctx, font, timeSize)
  local txt = fmtTime(cur) .. ' / ' .. fmtTime(len)
  local tw, th = ImGui.CalcTextSize(ctx, txt)
  ImGui.DrawList_AddText(dl, tx + (timeW - tw) / 2, ty + (btnH - th) / 2, tcol, txt)
  ImGui.PopFont(ctx)

  -- Rename pencil: shown while the mouse is over the row (space is kept so
  -- nothing shifts). Renames the track, i.e. the clip's button label.
  ImGui.SameLine(ctx, 0, 10)
  local rowRight = tx + timeW + editW + 12 + (xW > 0 and xW + 10 or 0)
  if not editing and ImGui.IsMouseHoveringRect(ctx, rowX, rowY, rowRight, rowY + btnH) then
    if iconButton('rename' .. i, 'edit', editW, nil, COL.iconDim) then
      PB.inlineRename = { key = c.key, text = c.trackName, focus = true }
    end
    if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, 'Rename this track (the button label)') end
  else
    ImGui.Dummy(ctx, editW, btnH)
  end

  -- Presentation: remove x at the end of the row, shown while the mouse is
  -- over the row (the space is kept so nothing shifts)
  if xW > 0 then
    ImGui.SameLine(ctx, 0, 10)
    if ImGui.IsMouseHoveringRect(ctx, rowX, rowY, rowRight, rowY + btnH) then
      if coloredButton('x##rmclip' .. i, xW, btnH) then PB.removeClips({ c }) end
      if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, 'Remove from the presentation (Ctrl+Z to undo)') end
    else
      ImGui.Dummy(ctx, xW, btnH)
    end
  end

  -- Selected clip (playing, or the one Space will resume): gold outline
  if activeClip and activeClip.key == c.key then
    ImGui.DrawList_AddRect(dl, rowX - 4, rowY - 4, tx + timeW + 4, ty + btnH + 4, COL.accent, 8, 0, 2)
  end

  local by0 = ImGui.GetCursorPosY(ctx)
  if cfg.showAllWaves or (activeClip and activeClip.key == c.key) then
    drawWaveform(c, i, isThis, shared)
    blockH.wave = ImGui.GetCursorPosY(ctx) - by0
  else
    drawSeekBar(c, i, isThis)
    blockH.seek = ImGui.GetCursorPosY(ctx) - by0
  end

  -- Notes: the clip's own item notes/image, then text items on its track
  local entries = {}
  local clipImage = itemImage(c.item)       -- cached; only clips on screen are looked up
  if (c.itemNote or ''):match('%S') or clipImage then
    entries[1] = { text = c.itemNote, image = clipImage, item = c.item }
  end
  for _, en in ipairs(clipNotes[c.key] or {}) do entries[#entries + 1] = en end
  -- Notes line: "+ Note" first, then the collapsible note (if any)
  ImGui.PushFont(ctx, font, 15)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 8, 3)
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, COL.accent)
  if coloredButton('+ Note  [N]##addnote' .. i, 0, 0) then startNote(c) end
  if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, 'Add a note to this clip (N)') end
  ImGui.PopStyleColor(ctx)
  ImGui.PopStyleVar(ctx)
  ImGui.PopFont(ctx)
  if #entries > 0 then ImGui.SameLine(ctx) end
  drawNotes(c.key, entries)

  -- Take markers: "+ Marker" first, then a jump button per marker
  drawMarkerButtons(c.markers, 'tm' .. i .. '_', COL.takeMarker,
    function(m) jumpToMarker(c, m.off) end,
    function() startMarker(c) end,
    function(m) removeMarker(c, m) end)
  ImGui.Spacing(ctx)
end

-- A note row for a track that has text but no clip in this trial
-- (e.g. a "not available" comment where a clip would be)
local function drawNoteRow(n)
  drawNotes(n.key, { { text = n.notes, image = n.image or itemImage(n.item), item = n.item } }, n.trackName)
  ImGui.Spacing(ctx)
end

-------------------------------------------------------------- folder tree --
-- Clips and note rows in track order (note rows go after any clips on
-- earlier tracks, so they appear where their track is in REAPER)
local function mergeRows(clips, noteRows)
  local rows = {}
  for i, c in ipairs(clips) do rows[#rows + 1] = { clip = c, i = i, ti = c.ti, ord = i } end
  for j, n in ipairs(noteRows) do rows[#rows + 1] = { note = n, ti = n.ti, ord = #clips + j } end
  table.sort(rows, function(a, b)
    if a.ti ~= b.ti then return a.ti < b.ti end
    return a.ord < b.ord
  end)
  return rows
end

-- Build a tree from the trial's rows using each row's folder path.
-- Entries keep track order, so folders and loose clips interleave as in REAPER.
local function buildTree(rows)
  local root = { entries = {}, byKey = {} }
  for _, row in ipairs(rows) do
    local c = row.clip or row.note
    local i = row.i
    local node = root
    for _, f in ipairs(c.path or {}) do
      local child = node.byKey[f.key]
      if not child then
        child = { folder = f, entries = {}, byKey = {} }
        node.byKey[f.key] = child
        node.entries[#node.entries + 1] = { node = child }
      end
      node = child
    end
    if row.clip then
      node.entries[#node.entries + 1] = { clip = c, i = i }
    else
      node.entries[#node.entries + 1] = { note = c }
    end
  end
  return root
end

local function subtreeInfo(node)
  local count, live = 0, false
  for _, ent in ipairs(node.entries) do
    if ent.clip then
      count = count + 1
      if playing and playing.clip.key == ent.clip.key then live = true end
    elseif ent.node then
      local n, l = subtreeInfo(ent.node)
      count, live = count + n, live or l
    end
  end
  return count, live
end

local forceOpen = nil   -- true/false for one frame after Expand all / Collapse all

local TREE_FLAGS = ImGui.TreeNodeFlags_DefaultOpen | ImGui.TreeNodeFlags_Framed
  | ImGui.TreeNodeFlags_SpanAvailWidth

local drawNode   -- forward declaration (folders contain nodes)

local function drawFolder(n, activeClip, shared)
  local f = n.folder
  local count, live = subtreeInfo(n)

  local bg, hov = COL.btn, COL.btnHover
  if f.rgb then
    local rgb = (f.rgb[1] << 24) | (f.rgb[2] << 16) | (f.rgb[3] << 8)
    bg, hov = rgb | 0x90, rgb | 0xC8
  end
  ImGui.PushStyleColor(ctx, ImGui.Col_Header, bg)
  ImGui.PushStyleColor(ctx, ImGui.Col_HeaderHovered, hov)
  ImGui.PushStyleColor(ctx, ImGui.Col_HeaderActive, hov)
  ImGui.PushFont(ctx, font, cfg.tabSize)

  if forceOpen ~= nil then ImGui.SetNextItemOpen(ctx, forceOpen) end
  -- ReaImGui's TreeNodeEx is (ctx, id, label, flags). The id is fixed per
  -- folder so the open/closed state survives the label changing (count,
  -- [playing]) and carries across tabs.
  local unit
  if f.isTakes then unit = count == 1 and 'take' or 'takes'
  elseif f.isLanes then unit = count == 1 and 'clip on lanes' or 'clips on lanes'
  else unit = count == 1 and 'clip' or 'clips' end
  local label = ('%s    (%d %s)'):format(f.name, count, unit)
  local open = ImGui.TreeNodeEx(ctx, 'fld' .. f.key, label, TREE_FLAGS)

  -- Something inside is playing: green box with a play symbol at the right
  -- end of the header (visible even when the folder is collapsed)
  if live then
    local x0, y0 = ImGui.GetItemRectMin(ctx)
    local x1, y1 = ImGui.GetItemRectMax(ctx)
    local dl = ImGui.GetWindowDrawList(ctx)
    local hh = y1 - y0
    local bx0, by0, bx1, by1 = x1 - hh * 1.6, y0 + 3, x1 - 4, y1 - 3
    ImGui.DrawList_AddRectFilled(dl, bx0, by0, bx1, by1, COL.play, 4)
    local s = (by1 - by0) * 0.28
    local cx, cy = (bx0 + bx1) / 2, (by0 + by1) / 2
    ImGui.DrawList_AddTriangleFilled(dl, cx - s * 0.75, cy - s, cx - s * 0.75, cy + s, cx + s, cy, COL.icon)
  end

  ImGui.PopFont(ctx)
  ImGui.PopStyleColor(ctx, 3)
  PB.folderMenu(f)

  if open then
    ImGui.Spacing(ctx)
    drawNode(n, activeClip, shared)
    ImGui.TreePop(ctx)
  end
end

drawNode = function(node, activeClip, shared)
  for _, ent in ipairs(node.entries) do
    if ent.clip then
      drawClip(ent.clip, ent.i, activeClip, shared)
    elseif ent.note then
      drawNoteRow(ent.note)
    else
      drawFolder(ent.node, activeClip, shared)
    end
  end
end

-- On/off toggle with a fixed label and an indicator light, so it never
-- changes width: green with a lit light when on, grey with a dark light when off
local function topToggle(label, on)
  local pressed = coloredButton('      ' .. label .. '##tog' .. label, 0, 0, on and 'play' or nil)
  local x0, y0 = ImGui.GetItemRectMin(ctx)
  local _, y1 = ImGui.GetItemRectMax(ctx)
  local r = (y1 - y0) * 0.17
  ImGui.DrawList_AddCircleFilled(ImGui.GetWindowDrawList(ctx), x0 + 16, (y0 + y1) / 2, r,
    on and COL.icon or COL.ledOff)
  return pressed
end

-- A/B as one control with three settings: Off | Default | Smooth.
-- Off: clicking another clip plays it from its own position.
-- Default: switches at the same point, with a tiny gap.
-- Smooth: switches at the same point with no gap, for clips that start at
-- the same time; goes back to Default each time the panel opens.
local function drawABControl()
  local current = (not cfg.ab) and 1 or (smoothAB and 3 or 2)
  local tips = {
    'A/B off: clicking another clip plays it from its own position.',
    'Default: switch to the other clip at the same point, with a tiny gap.\nBest for different voices/vendors.',
    'Smooth: switch at the same point with no gap.\nFor clips that start at the same time, e.g. versions of the same recording.',
  }
  ImGui.AlignTextToFramePadding(ctx)
  ImGui.TextColored(ctx, COL.dim, 'A/B')
  ImGui.SameLine(ctx, 0, 8)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 0)
  for k, opt in ipairs({ 'Off', 'Default', 'Smooth' }) do
    if k > 1 then ImGui.SameLine(ctx, 0, 1) end
    local sel = (k == current)
    local style = sel and ((k == 1) and 'selected' or 'switch') or nil
    if coloredButton(opt .. '##ab' .. k, 0, 0, style) and not sel then
      cfg.ab = (k ~= 1)
      if k == 2 then smoothAB = false elseif k == 3 then smoothAB = true end
      saveCfg()
    end
    if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, tips[k]) end
  end
  ImGui.PopStyleVar(ctx)
end

------------------------------------------------------------- compact mode --
-- Compact mode shrinks the panel to the tabs, the control row and one row of
-- small clip buttons; turning it off restores the size you had. (Separate
-- from the window's own collapse arrow, which is left as it is.)
local compact = false
local fullSize, restoreSize, compactH, winW, winH = nil, nil, nil, nil, nil
local resetScroll = false   -- compact: the window itself scrolls, reset it
local resetBody = false     -- full: reset the clip list's own scroll (inside the child)

local function toggleCompact()
  if not compact then
    fullSize = { winW or 760, winH or 680 }
    compact, compactH, resetScroll, resetBody = true, nil, true, true
  else
    compact = false
    restoreSize = fullSize
  end
end

-- One wrapping row of small clip buttons: same colours as the full rows
-- (green playing, amber paused, blue A/B switch), gold outline on the
-- selected clip, then the selected clip's time
local function drawClipChips(clips, activeClip)
  if #clips == 0 then
    ImGui.TextColored(ctx, COL.dim, 'No clips in this region.')
    return
  end
  local padX, spacing = 12, 6
  ImGui.PushFont(ctx, font, cfg.tabSize)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, padX, 6)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, spacing, spacing)
  local avail = ImGui.GetContentRegionAvail(ctx)
  local lineW = 0
  local dl = ImGui.GetWindowDrawList(ctx)
  for i, c in ipairs(clips) do
    local label = (i <= 9 and (i .. '   ') or '') .. c.trackName
    if c.takeLabel then label = label .. '  |  ' .. c.takeLabel end
    local w = ImGui.CalcTextSize(ctx, label) + padX * 2
    if i > 1 and lineW + spacing + w <= avail then
      ImGui.SameLine(ctx)
      lineW = lineW + spacing + w
    else
      lineW = w
    end
    local isThis = playing and playing.clip.key == c.key
    local style
    if isThis then style = 'play'
    elseif playing and cfg.ab then style = 'switch'
    else style = c.rgb end
    if coloredButton(label .. '##chip' .. i, 0, 0, style) then toggleClip(c) end
    if activeClip and activeClip.key == c.key then
      local x0, y0 = ImGui.GetItemRectMin(ctx)
      local x1, y1 = ImGui.GetItemRectMax(ctx)
      ImGui.DrawList_AddRect(dl, x0 - 3, y0 - 3, x1 + 3, y1 + 3, COL.accent, 7, 0, 2)
    end
  end
  ImGui.PopStyleVar(ctx, 2)
  ImGui.PopFont(ctx)

  if activeClip then
    local len = activeClip.e - activeClip.s
    local isThis = playing and playing.clip.key == activeClip.key
    local cur = clamp(displayOffset(activeClip, isThis), 0, len)
    ImGui.TextColored(ctx, isThis and COL.waveOn or COL.dim, fmtTime(cur) .. ' / ' .. fmtTime(len))
  end
end

------------------------------------------------------------ add a marker --
-- "+ Marker" at the start of a clip's marker row, or M for the playing or
-- selected clip. The moment is taken when you press it, so the clip keeps
-- playing while you type. Enter adds a take marker there with your text:
-- the same thing as adding one in REAPER, so it shows on the waveform and
-- as a jump button, is saved with the project and can be undone.
local markerDraft = nil       -- { clip, off, text, focus, err }
local openMarkerPopup = false

startMarker = function(c)
  if not c then return end
  local isThis = playing and playing.clip.key == c.key
  local off = clamp(displayOffset(c, isThis), 0, c.e - c.s)
  markerDraft = { clip = c, off = off, text = '', focus = true }
  openMarkerPopup = true
end

-- Returns true, or false and an error message
local function saveMarker(d)
  local c = d.clip
  local text = d.text:gsub('^%s+', ''):gsub('%s+$', '')
  if text == '' then return false, 'Type something first.' end
  if not (c.take and reaper.ValidatePtr2(0, c.take, 'MediaItem_Take*')) then
    return false, 'This clip no longer exists in the project.'
  end
  local offs = reaper.GetMediaItemTakeInfo_Value(c.take, 'D_STARTOFFS')
  local rate = reaper.GetMediaItemTakeInfo_Value(c.take, 'D_PLAYRATE')
  if rate <= 0 then rate = 1 end
  local col = reaper.ColorToNative(0xFF, 0x6B, 0x6B) | 0x1000000   -- red

  reaper.Undo_BeginBlock()
  local idx = reaper.SetTakeMarker(c.take, -1, text, offs + d.off * rate, col)
  reaper.Undo_EndBlock('Presenter: add take marker', -1)
  reaper.UpdateArrange()
  if idx == nil or idx < 0 then return false, 'REAPER did not accept the marker.' end

  cache.state = -1      -- rescan now, so the new marker shows straight away
  return true
end

local function drawMarkerPopup()
  if openMarkerPopup then
    ImGui.OpenPopup(ctx, 'Add marker##presenter')
    openMarkerPopup = false
  end
  ImGui.SetNextWindowSize(ctx, 560, 0, ImGui.Cond_Appearing)
  local visible = ImGui.BeginPopupModal(ctx, 'Add marker##presenter', true)
  if not visible then
    markerDraft = nil          -- closed (e.g. with its X)
    return
  end
  local d = markerDraft
  if not d then
    ImGui.CloseCurrentPopup(ctx)
    ImGui.EndPopup(ctx)
    return
  end

  local who = d.clip.trackName .. (d.clip.takeLabel and ('  |  ' .. d.clip.takeLabel) or '')
  ImGui.TextColored(ctx, COL.liveNote, 'Marker on ' .. who .. '  at  ' .. fmtTime(d.off))

  -- This clip's existing markers, for context
  if #d.clip.markers > 0 then
    ImGui.PushStyleColor(ctx, ImGui.Col_Text, COL.dim)
    for _, m in ipairs(d.clip.markers) do
      ImGui.Text(ctx, ('%s   %s'):format(fmtTime(m.off), m.name))
    end
    ImGui.PopStyleColor(ctx)
  end

  if d.focus then ImGui.SetKeyboardFocusHere(ctx); d.focus = false end
  ImGui.SetNextItemWidth(ctx, -1)
  local _
  _, d.text = ImGui.InputText(ctx, '##markertext', d.text)
  -- Enter is read directly (not via an input flag) so the typed text is
  -- always the latest
  local enter = ImGui.IsKeyPressed(ctx, ImGui.Key_Enter, false)
    or ImGui.IsKeyPressed(ctx, ImGui.Key_KeypadEnter, false)

  if d.err then ImGui.TextColored(ctx, 0xFF6B6BFF, d.err) end

  local clickedAdd = ImGui.Button(ctx, 'Add  [Enter]')
  ImGui.SameLine(ctx)
  local clickedCancel = ImGui.Button(ctx, 'Cancel  [Esc]')

  if enter or clickedAdd then
    local ok, res, msg = pcall(saveMarker, d)
    if ok and res then
      setStatus(('Marker added on %s at %s:  %s'):format(who, fmtTime(d.off), d.text), COL.liveNote)
      markerDraft = nil
      ImGui.CloseCurrentPopup(ctx)
    else
      -- keep the box open and say why
      d.err = (ok and msg) or tostring(res) or 'Could not add the marker.'
      d.focus = true
    end
  elseif clickedCancel or ImGui.IsKeyPressed(ctx, ImGui.Key_Escape, false) then
    markerDraft = nil
    ImGui.CloseCurrentPopup(ctx)
  end
  ImGui.EndPopup(ctx)
end

-------------------------------------------------------------- add a note --
-- "+ Note" at the start of a clip's notes line, or N for the playing or
-- selected clip. For a general comment on the clip (no particular moment):
-- added as a new line to the clip's Item notes, the same notes the panel
-- shows under the clip. The box shows the existing notes, with the cursor on
-- a new line underneath so typing can't overwrite them; "Edit existing
-- notes" lets you change what's there. Saved with the project, undoable.
local noteDraft = nil        -- { clip, existing, text, editAll, focus, err }
local openNotePopup = false

startNote = function(c)
  if not c then return end
  noteDraft = {
    clip = c, existing = (itemNotes(c.item):gsub('%s+$', '')),
    text = '', editAll = false, focus = true,
  }
  openNotePopup = true
end

-- Returns true, or false and an error message
local function saveNote(d)
  local c = d.clip
  if not reaper.ValidatePtr2(0, c.item, 'MediaItem*') then
    return false, 'This clip no longer exists in the project.'
  end
  local text = d.text:gsub('^%s+', ''):gsub('%s+$', '')
  local base = d.existing:gsub('%s+$', '')
  local current = itemNotes(c.item):gsub('%s+$', '')
  if text == '' and base == current then return false, 'Type something first.' end

  local notes = base
  if text ~= '' then notes = (base:match('%S') and (base .. '\n') or '') .. text end
  reaper.Undo_BeginBlock()
  reaper.GetSetMediaItemInfo_String(c.item, 'P_NOTES', notes, true)
  reaper.Undo_EndBlock('Presenter: add note', -1)
  reaper.UpdateArrange()
  cache.state = -1      -- rescan now, so the note shows straight away
  return true
end

local function drawNotePopup()
  if openNotePopup then
    ImGui.OpenPopup(ctx, 'Add note##presenter')
    openNotePopup = false
  end
  ImGui.SetNextWindowSize(ctx, 600, 0, ImGui.Cond_Appearing)
  local visible = ImGui.BeginPopupModal(ctx, 'Add note##presenter', true)
  if not visible then
    noteDraft = nil
    return
  end
  local d = noteDraft
  if not d then
    ImGui.CloseCurrentPopup(ctx)
    ImGui.EndPopup(ctx)
    return
  end

  local who = d.clip.trackName .. (d.clip.takeLabel and ('  |  ' .. d.clip.takeLabel) or '')
  ImGui.TextColored(ctx, COL.accent, 'Note on ' .. who)

  -- Existing notes: shown as text, or editable after "Edit existing notes"
  local multiActive = false
  if d.editAll then
    local _
    _, d.existing = ImGui.InputTextMultiline(ctx, '##existing', d.existing, -1, 140)
    multiActive = ImGui.IsItemActive(ctx)
  elseif d.existing:match('%S') then
    ImGui.PushStyleColor(ctx, ImGui.Col_Text, COL.noteText)
    ImGui.TextWrapped(ctx, d.existing)
    ImGui.PopStyleColor(ctx)
    if ImGui.SmallButton(ctx, 'Edit existing notes') then d.editAll = true end
  else
    ImGui.TextColored(ctx, COL.dim, '(no notes on this clip yet)')
  end

  ImGui.Separator(ctx)
  ImGui.TextColored(ctx, COL.dim, 'New line')
  if d.focus then ImGui.SetKeyboardFocusHere(ctx); d.focus = false end
  ImGui.SetNextItemWidth(ctx, -1)
  local _
  _, d.text = ImGui.InputText(ctx, '##notetext', d.text)
  -- Enter saves, except while editing the existing notes (there it's a new line)
  local enter = not multiActive and (ImGui.IsKeyPressed(ctx, ImGui.Key_Enter, false)
    or ImGui.IsKeyPressed(ctx, ImGui.Key_KeypadEnter, false))

  if d.err then ImGui.TextColored(ctx, 0xFF6B6BFF, d.err) end

  local clickedSave = ImGui.Button(ctx, 'Save  [Enter]')
  ImGui.SameLine(ctx)
  local clickedCancel = ImGui.Button(ctx, 'Cancel  [Esc]')

  if enter or clickedSave then
    local ok, res, msg = pcall(saveNote, d)
    if ok and res then
      setStatus('Note saved on ' .. who, COL.accent)
      noteDraft = nil
      ImGui.CloseCurrentPopup(ctx)
    else
      d.err = (ok and msg) or tostring(res) or 'Could not save the note.'
      d.focus = true
    end
  elseif clickedCancel or ImGui.IsKeyPressed(ctx, ImGui.Key_Escape, false) then
    noteDraft = nil
    ImGui.CloseCurrentPopup(ctx)
  end
  ImGui.EndPopup(ctx)
end

-------------------------------------------------------------- normalising --
-- Uses REAPER's own loudness measurement (the same as Item > Item processing
-- > Normalize), so no extensions are needed. Each take's volume is set so
-- the clip lands on the target, allowing for the item's own volume. One undo
-- step. Reports how many clips would go above -1 dBTP true peak (quiet clips
-- raised to the target can clip); it warns rather than limiting, because
-- limiting would break the loudness match.
local NORM_MODES = { { name = 'LUFS-I', id = 0, unit = 'LUFS' }, { name = 'Peak', id = 2, unit = 'dBFS' } }

local function normalizeClips(list, what)
  if not reaper.CalculateNormalization then
    setStatus('This REAPER version can\'t measure loudness from scripts. Update REAPER.', 0xFF6B6BFF)
    return
  end
  local mode = NORM_MODES[cfg.normMode] or NORM_MODES[1]
  local n, hot, failed = 0, 0, 0
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  for _, c in ipairs(list) do
    local ok = false
    if c.take and reaper.ValidatePtr2(0, c.take, 'MediaItem_Take*') then
      local src = reaper.GetMediaItemTake_Source(c.take)
      local offs = reaper.GetMediaItemTakeInfo_Value(c.take, 'D_STARTOFFS')
      local rate = reaper.GetMediaItemTakeInfo_Value(c.take, 'D_PLAYRATE')
      if rate <= 0 then rate = 1 end
      local s0, s1 = offs, offs + (c.e - c.s) * rate
      local g = reaper.CalculateNormalization(src, mode.id, cfg.normTarget, s0, s1)
      if g and g > 0 and g < 1e4 then
        local itemVol = reaper.GetMediaItemInfo_Value(c.item, 'D_VOL')
        if itemVol <= 0 then itemVol = 1 end
        reaper.SetMediaItemTakeInfo_Value(c.take, 'D_VOL', g / itemVol)
        n, ok = n + 1, true
        local gtp = reaper.CalculateNormalization(src, 3, -1, s0, s1)    -- true peak at -1 dBTP
        if gtp and gtp > 0 and g > gtp * 1.0001 then hot = hot + 1 end
      end
    end
    if not ok then failed = failed + 1 end
  end
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock('Presenter: normalize ' .. what, -1)
  reaper.UpdateArrange()
  cache.state = -1

  local msg = ('Normalized %d clip%s (%s) to %g %s'):format(n, n == 1 and '' or 's', what,
    cfg.normTarget, mode.unit)
  if hot > 0 then msg = msg .. ('  -  %d would go above -1 dBTP'):format(hot) end
  if failed > 0 then msg = msg .. ('  -  %d could not be measured'):format(failed) end
  setStatus(msg .. '  (Ctrl+Z to undo)', hot > 0 and COL.accent or COL.waveOn)
end

------------------------------------------------------------ presentation --
-- Two views: OVERVIEW (the session) and PRESENTATION (its own section of the
-- project: the PRESENTATION folder of tracks, regions after the session).
-- In Overview you tick clips ("select for presentation"); ticks stay as you
-- move between regions. "Add to presentation" copies them into a section of
-- the presentation, each on its own track, all starting together. Copies
-- point at the same audio files, so nothing is duplicated on disk and the
-- session itself isn't changed.

PB.selection, PB.selOrder = {}, {}   -- clip key -> { clip, region }; order ticked
PB.curRegionLabel = nil           -- region shown now (for the PB.selection list)
PB.viewTs = {}                    -- remembered position per view

-- Each view has its own ticks: PB.selection/PB.selOrder are Overview's
-- (clips to add to the presentation, recolour), PB.psel/PB.porder are
-- Presentation's (recolour, remove).
PB.psel, PB.porder = {}, {}
function PB.selFor(c)
  if c.inPres then return PB.psel, PB.porder end
  return PB.selection, PB.selOrder
end
PB.isSelected = function(c) return (PB.selFor(c))[c.key] ~= nil end
PB.setSelected = function(c, on)
  local map, order = PB.selFor(c)
  if on and not map[c.key] then
    map[c.key] = { clip = c, region = PB.curRegionLabel }
    order[#order + 1] = c.key
  elseif not on and map[c.key] then
    map[c.key] = nil
    for k, key in ipairs(order) do
      if key == c.key then table.remove(order, k) break end
    end
  end
end
function PB.clearSelection(view)
  if view == 'presentation' then PB.psel, PB.porder = {}, {}
  else PB.selection, PB.selOrder = {}, {} end
end
-- The ticked clips of a view whose items still exist (drops any that don't)
function PB.selectedClips(view)
  local map, order = PB.selection, PB.selOrder
  if view == 'presentation' then map, order = PB.psel, PB.porder end
  local out, keep = {}, {}
  for _, key in ipairs(order) do
    local c = map[key].clip
    if c.item and reaper.ValidatePtr2(0, c.item, 'MediaItem*') then
      out[#out + 1] = c; keep[#keep + 1] = key
    else
      map[key] = nil
    end
  end
  for k = #order, 1, -1 do order[k] = nil end
  for k, key in ipairs(keep) do order[k] = key end
  return out
end

------------------------------------------------------------------ colour --
-- Recolouring sets the item's colour (all its takes show it, as in REAPER's
-- arrange view) and clears take colours so nothing hides it. "Track colour"
-- clears both, so the clip shows its track's colour again.
PB.PALETTE = {
  { 0xE0, 0x4F, 0x4F }, { 0xF0, 0x8A, 0x3C }, { 0xF0, 0xC8, 0x3C }, { 0x8C, 0xC8, 0x4B },
  { 0x3C, 0xB4, 0x6E }, { 0x3C, 0xB4, 0xB4 }, { 0x46, 0x8C, 0xE6 }, { 0x6E, 0x64, 0xDC },
  { 0xAA, 0x5A, 0xD2 }, { 0xDC, 0x5A, 0xA0 }, { 0x9A, 0x9A, 0x9A }, { 0x5A, 0x60, 0x6E },
}
PB.customRGB = 0x468CE6
function PB.nativeOf(rgb)
  if not rgb then return 0 end
  return reaper.ColorToNative(rgb[1], rgb[2], rgb[3]) | 0x1000000
end
function PB.applyColour(clips, rgb)
  if #clips == 0 then return end
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  local done, n = {}, 0
  for _, c in ipairs(clips) do
    if c.item and not done[c.item] and reaper.ValidatePtr2(0, c.item, 'MediaItem*') then
      done[c.item] = true
      n = n + 1
      reaper.SetMediaItemInfo_Value(c.item, 'I_CUSTOMCOLOR', PB.nativeOf(rgb))
      for k = 0, reaper.CountTakes(c.item) - 1 do
        local tk = reaper.GetTake(c.item, k)
        if tk then reaper.SetMediaItemTakeInfo_Value(tk, 'I_CUSTOMCOLOR', 0) end
      end
    end
  end
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock('Presenter: recolour clips', -1)
  reaper.UpdateArrange()
  cache.state = -1
  setStatus(('%s %d clip%s  (Ctrl+Z to undo)'):format(rgb and 'Recoloured' or 'Track colour for',
    n, n == 1 and '' or 's'), COL.accent)
end
function PB.setTrackColour(tr, rgb)
  reaper.Undo_BeginBlock()
  reaper.SetMediaTrackInfo_Value(tr, 'I_CUSTOMCOLOR', PB.nativeOf(rgb))
  reaper.Undo_EndBlock('Presenter: track colour', -1)
  reaper.TrackList_AdjustWindows(false)
  reaper.UpdateArrange()
  cache.state = -1
end

-- Swatches (and optionally a custom colour picker). Calls apply(rgb), with
-- rgb = nil for "Track colour". Returns true once something was picked.
function PB.drawPalette(id, apply, withCustom, defaultLabel)
  local picked = false
  local sz = 26
  for k, rgb in ipairs(PB.PALETTE) do
    if (k - 1) % 6 ~= 0 then ImGui.SameLine(ctx, 0, 4) end
    local rgba = (rgb[1] << 24) | (rgb[2] << 16) | (rgb[3] << 8) | 0xFF
    if ImGui.ColorButton(ctx, '##' .. id .. 'sw' .. k, rgba, ImGui.ColorEditFlags_NoTooltip, sz, sz) then
      apply(rgb); picked = true
    end
  end
  if coloredButton((defaultLabel or 'Track colour') .. '##' .. id .. 'def', sz * 6 + 20, 0) then
    apply(nil); picked = true
  end
  if withCustom then
    ImGui.Spacing(ctx)
    ImGui.SetNextItemWidth(ctx, sz * 6 + 20)
    local _
    _, PB.customRGB = ImGui.ColorPicker3(ctx, '##' .. id .. 'pick', PB.customRGB,
      ImGui.ColorEditFlags_NoSidePreview | ImGui.ColorEditFlags_NoInputs)
    if coloredButton('Use this colour##' .. id .. 'use', sz * 6 + 20, 0) then
      local c = PB.customRGB
      apply({ (c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF }); picked = true
    end
  end
  return picked
end

------------------------------------------------------------------ rename --
-- Rename a track/folder (P_NAME) or a take (its name, as in REAPER's take
-- properties) from a small box. Normal REAPER edits, undoable.
PB.renameDraft = nil      -- { kind = 'track'|'take', obj, text, what, focus }
PB.openRenamePopup = false
function PB.startRename(kind, obj, current, what)
  PB.renameDraft = { kind = kind, obj = obj, text = current or '', what = what, focus = true }
  PB.openRenamePopup = true
end
function PB.saveRename(d)
  local t = (d.text or ''):gsub('^%s+', ''):gsub('%s+$', '')
  if t == '' then return false end
  reaper.Undo_BeginBlock()
  if d.kind == 'take' then
    if not reaper.ValidatePtr2(0, d.obj, 'MediaItem_Take*') then reaper.Undo_EndBlock('Presenter: rename', -1) return false end
    reaper.GetSetMediaItemTakeInfo_String(d.obj, 'P_NAME', t, true)
  else
    if not reaper.ValidatePtr2(0, d.obj, 'MediaTrack*') then reaper.Undo_EndBlock('Presenter: rename', -1) return false end
    reaper.GetSetMediaTrackInfo_String(d.obj, 'P_NAME', t, true)
  end
  reaper.Undo_EndBlock('Presenter: rename ' .. d.kind, -1)
  reaper.TrackList_AdjustWindows(false)
  reaper.UpdateArrange()
  cache.state = -1
  setStatus('Renamed to "' .. t .. '"  (Ctrl+Z to undo)', COL.accent)
  return true
end
function PB.drawRenamePopup()
  if PB.openRenamePopup then
    ImGui.OpenPopup(ctx, 'Rename##presenter')
    PB.openRenamePopup = false
  end
  ImGui.SetNextWindowSize(ctx, 460, 0, ImGui.Cond_Appearing)
  if not ImGui.BeginPopupModal(ctx, 'Rename##presenter', true) then PB.renameDraft = nil; return end
  local d = PB.renameDraft
  if not d then ImGui.CloseCurrentPopup(ctx); ImGui.EndPopup(ctx); return end
  ImGui.TextColored(ctx, COL.accent, 'Rename ' .. (d.what or d.kind))
  if d.focus then ImGui.SetKeyboardFocusHere(ctx); d.focus = false end
  ImGui.SetNextItemWidth(ctx, -1)
  local _
  _, d.text = ImGui.InputText(ctx, '##renametext', d.text)
  local ok = ImGui.Button(ctx, 'Rename  [Enter]') or ImGui.IsKeyPressed(ctx, ImGui.Key_Enter, false)
  ImGui.SameLine(ctx)
  local cancel = ImGui.Button(ctx, 'Cancel  [Esc]') or ImGui.IsKeyPressed(ctx, ImGui.Key_Escape, false)
  if ok then
    PB.saveRename(d)
    PB.renameDraft = nil
    ImGui.CloseCurrentPopup(ctx)
  elseif cancel then
    PB.renameDraft = nil
    ImGui.CloseCurrentPopup(ctx)
  end
  ImGui.EndPopup(ctx)
end

-- Right-click menu on a folder header
function PB.folderMenu(f)
  if not f.track then return end
  if not ImGui.BeginPopupContextItem(ctx, 'fldmenu' .. f.key) then return end
  local word = (f.isTakes or f.isLanes) and 'track' or 'folder'
  if ImGui.MenuItem(ctx, 'Rename ' .. word .. '...') then
    PB.startRename('track', f.track, f.name, word == 'folder' and 'Folder' or 'Track')
  end
  ImGui.Separator(ctx)
  ImGui.Text(ctx, (word == 'folder') and 'Folder colour' or 'Track colour')
  if PB.drawPalette('fm' .. f.key, function(rgb) PB.setTrackColour(f.track, rgb) end, false, 'No colour') then
    ImGui.CloseCurrentPopup(ctx)
  end
  ImGui.EndPopup(ctx)
end

-- Right-click menu on a clip
function PB.clipMenu(c, i)
  if not ImGui.BeginPopupContextItem(ctx, 'clipmenu' .. i) then return end
  ImGui.TextColored(ctx, COL.dim, c.trackName .. (c.takeLabel and ('  |  ' .. c.takeLabel) or ''))
  ImGui.Separator(ctx)
  ImGui.Text(ctx, 'Colour')
  if PB.drawPalette('cm' .. i, function(rgb) PB.applyColour({ c }, rgb) end) then
    ImGui.CloseCurrentPopup(ctx)
  end
  ImGui.Separator(ctx)
  if ImGui.MenuItem(ctx, 'Rename track...') then
    PB.startRename('track', c.track, c.trackName, 'Track (the clip\'s button label)')
  end
  if ImGui.MenuItem(ctx, 'Rename take...') then
    PB.startRename('take', c.take, c.takeName, 'Take name (the file name shown with "Show file names")')
  end
  ImGui.Separator(ctx)
  local sel = PB.isSelected(c)
  if ImGui.MenuItem(ctx, sel and 'Unselect' or 'Select') then PB.setSelected(c, not sel) end
  if c.inPres then
    if ImGui.MenuItem(ctx, 'Remove from presentation') then PB.removeClips({ c }) end
  else
    if ImGui.MenuItem(ctx, 'Add to presentation...') then PB.addOnly = c; PB.openAddPopup = true end
  end
  ImGui.EndPopup(ctx)
end

-- "Colour..." in the selection bar: the palette for the ticked clips
function PB.colourButton(view, n)
  if coloredButton('Colour...##selcol', 0, 0) then ImGui.OpenPopup(ctx, 'selcolour') end
  if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, 'Recolour the selected clips') end
  if ImGui.BeginPopup(ctx, 'selcolour') then
    ImGui.TextColored(ctx, COL.dim, ('Colour for %d selected clip%s'):format(n, n == 1 and '' or 's'))
    if PB.drawPalette('bar', function(rgb) PB.applyColour(PB.selectedClips(view), rgb) end, true) then
      ImGui.CloseCurrentPopup(ctx)
    end
    ImGui.EndPopup(ctx)
  end
end

function PB.setTrackName(tr, n) reaper.GetSetMediaTrackInfo_String(tr, 'P_NAME', n, true) end
function PB.setTrackTag(tr, v) reaper.GetSetMediaTrackInfo_String(tr, 'P_EXT:presenter', v, true) end
function PB.trackNameOf(tr)
  local _, n = reaper.GetTrackName(tr)
  return n
end

-- Create the PRESENTATION folder (with its Text track) if it isn't there yet,
-- and decide where in time the presentation starts. Returns its track index.
function PB.ensurePresentation()
  if not presStartTime() then
    local start = math.ceil(reaper.GetProjectLength(0)) + 10
    reaper.SetProjExtState(0, EXT_SEC, 'presStart', tostring(start))
  end
  local r = presRootIndex()
  if r then return r end
  local n = reaper.CountTracks(0)
  reaper.InsertTrackAtIndex(n, true)
  local root = reaper.GetTrack(0, n)
  PB.setTrackName(root, 'PRESENTATION')
  PB.setTrackTag(root, 'root')
  reaper.SetMediaTrackInfo_Value(root, 'I_FOLDERDEPTH', 1)
  reaper.InsertTrackAtIndex(n + 1, true)
  local tt = reaper.GetTrack(0, n + 1)
  PB.setTrackName(tt, 'Text')
  PB.setTrackTag(tt, 'text')
  reaper.SetMediaTrackInfo_Value(tt, 'I_FOLDERDEPTH', -1)
  return n
end

-- How many folders deep a track is inside `folder` (1 = direct child)
function PB.nestLevel(tr, folder)
  local L, p = 0, tr
  while p and p ~= folder do p = reaper.GetParentTrack(p); L = L + 1 end
  return L
end

-- Insert a new track as the last direct child of the track at folderIdx
-- (making it a folder if it wasn't). Returns the new track's index.
function PB.insertIntoFolder(folderIdx, name)
  local folder = reaper.GetTrack(0, folderIdx)
  local fd = reaper.GetMediaTrackInfo_Value(folder, 'I_FOLDERDEPTH')
  local last = (fd == 1) and presLastIndex(folderIdx) or folderIdx
  local idx = last + 1
  reaper.InsertTrackAtIndex(idx, true)
  local tr = reaper.GetTrack(0, idx)
  if last == folderIdx then
    -- no children yet: it opens, the new track closes it (and whatever it closed)
    reaper.SetMediaTrackInfo_Value(folder, 'I_FOLDERDEPTH', 1)
    reaper.SetMediaTrackInfo_Value(tr, 'I_FOLDERDEPTH', (fd > 0) and -1 or (fd - 1))
  else
    -- the old last track stops closing this folder; the new one closes it
    local prev = reaper.GetTrack(0, last)
    local d = reaper.GetMediaTrackInfo_Value(prev, 'I_FOLDERDEPTH')
    local L = PB.nestLevel(prev, folder)
    reaper.SetMediaTrackInfo_Value(prev, 'I_FOLDERDEPTH', -(L - 1))
    reaper.SetMediaTrackInfo_Value(tr, 'I_FOLDERDEPTH', d + L - 1)
  end
  PB.setTrackName(tr, name)
  return idx
end

function PB.trackHasItemIn(tr, s, e)
  for i = 0, reaper.CountTrackMediaItems(tr) - 1 do
    local it = reaper.GetTrackMediaItem(tr, i)
    local p = reaper.GetMediaItemInfo_Value(it, 'D_POSITION')
    local l = reaper.GetMediaItemInfo_Value(it, 'D_LENGTH')
    if p < e - EPS and p + l > s + EPS then return true end
  end
  return false
end

-- Index of a track (they move as tracks are inserted)
function PB.indexOf(tr)
  return math.floor(reaper.GetMediaTrackInfo_Value(tr, 'IP_TRACKNUMBER')) - 1
end

-- Direct children of the folder at index fi
function PB.childrenOf(fi)
  local folder, out = reaper.GetTrack(0, fi), {}
  if reaper.GetMediaTrackInfo_Value(folder, 'I_FOLDERDEPTH') ~= 1 then return out end
  for i = fi + 1, presLastIndex(fi) do
    local tr = reaper.GetTrack(0, i)
    if reaper.GetParentTrack(tr) == folder then out[#out + 1] = tr end
  end
  return out
end

-- The presentation folder standing for one of the session's folders
-- (tagged with the session folder's ID, so two folders that share a name,
-- e.g. "Batch 2" under two vendors, stay apart), made if needed
function PB.folderFor(parent, src)
  local pi = PB.indexOf(parent)
  local tag = 'src:' .. src.key
  for _, ch in ipairs(PB.childrenOf(pi)) do
    if trackTag(ch) == tag then return ch end
  end
  local idx = PB.insertIntoFolder(pi, src.name ~= '' and src.name or 'Folder')
  local tr = reaper.GetTrack(0, idx)
  PB.setTrackTag(tr, tag)
  if src.rgb then reaper.SetMediaTrackInfo_Value(tr, 'I_CUSTOMCOLOR', PB.nativeOf(src.rgb)) end
  return tr
end

-- A presentation track for a clip. With keepFolders, it goes inside copies
-- of the clip's session folders (Vendor A / Batch 2 / Turkish) and keeps its
-- track name; otherwise it goes straight under PRESENTATION and the folder
-- names go into the track name ("Vendor A / Batch 2 / Turkish"). An existing
-- track with the same name, free in this section, is reused.
function PB.trackForClip(rootIdx, c, s, e, keepFolders)
  local parent = reaper.GetTrack(0, rootIdx)
  local label = c.takeLabel and ('  |  ' .. c.takeLabel) or ''
  local name = c.trackName .. label
  local path = folderPath(c.track)
  if keepFolders then
    for _, f in ipairs(path) do parent = PB.folderFor(parent, f) end
  elseif #path > 0 then
    local names = {}
    for _, f in ipairs(path) do names[#names + 1] = f.name end
    name = table.concat(names, ' / ') .. ' / ' .. c.trackName .. label
  end
  local pi = PB.indexOf(parent)
  for _, tr in ipairs(PB.childrenOf(pi)) do
    if trackTag(tr) ~= 'text' and reaper.GetMediaTrackInfo_Value(tr, 'I_FOLDERDEPTH') ~= 1
        and PB.trackNameOf(tr) == name and not PB.trackHasItemIn(tr, s, e) then
      return tr
    end
  end
  local idx = PB.insertIntoFolder(pi, name)
  local tr = reaper.GetTrack(0, idx)
  local col = reaper.GetTrackColor(c.track)
  if col and col ~= 0 then reaper.SetMediaTrackInfo_Value(tr, 'I_CUSTOMCOLOR', col) end
  return tr
end

-- Copy one clip (one take of one item) onto a track at a position. The whole
-- item is copied as REAPER stores it (fades, volume, markers, notes, FX), then
-- trimmed to the chosen take.
function PB.copyClip(c, dst, pos)
  local ok, chunk = reaper.GetItemStateChunk(c.item, '', false)
  if not ok or not chunk then return false end
  chunk = chunk:gsub('\n%s*IGUID [^\n]*', ''):gsub('\n%s*GUID [^\n]*', '')   -- new IDs
  local item = reaper.AddMediaItemToTrack(dst)
  if not reaper.SetItemStateChunk(item, chunk, false) then
    reaper.DeleteTrackMediaItem(dst, item)
    return false
  end
  reaper.SetMediaItemInfo_Value(item, 'D_POSITION', pos)
  reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', c.e - c.s)
  reaper.SetMediaItemInfo_Value(item, 'I_FIXEDLANE', 0)
  if reaper.CountTakes(item) > 1 then
    local tk = reaper.GetTake(item, c.k)
    if tk then
      reaper.SelectAllMediaItems(0, false)
      reaper.SetMediaItemSelected(item, true)
      reaper.SetActiveTake(tk)
      reaper.Main_OnCommand(40131, 0)       -- Take: Crop to active take in items
    end
  end
  return true
end

-- Add the ticked clips to a section: target = { region = <existing section> }
-- or { newName = 'Section name' }
function PB.addSelectionToPresentation(target, only)
  local list = only and { only } or PB.selectedClips('overview')
  if #list == 0 then return end
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  local rootIdx = PB.ensurePresentation()
  local presStart = presStartTime()

  local maxLen = 0
  for _, c in ipairs(list) do maxLen = math.max(maxLen, c.e - c.s) end

  local s0, sectionName
  if target.region then
    local r = target.region
    s0, sectionName = r.s, r.label
    if r.s + maxLen + 0.5 > r.e then
      reaper.SetProjectMarker(r.idx, true, r.s, r.s + maxLen + 0.5, r.name)
    end
  else
    s0 = presStart
    for _, r in ipairs((cache.views and cache.views.presentation.regions) or {}) do
      s0 = math.max(s0, r.e + 2)
    end
    sectionName = target.newName
    reaper.AddProjectMarker2(0, true, s0, s0 + maxLen + 0.5, sectionName, -1, 0)
  end

  local n, failed = 0, 0
  for _, c in ipairs(list) do
    if c.item and reaper.ValidatePtr2(0, c.item, 'MediaItem*') then
      local dst = PB.trackForClip(rootIdx, c, s0, s0 + (c.e - c.s), PB.keepFolders)
      if PB.copyClip(c, dst, s0) then n = n + 1 else failed = failed + 1 end
    else
      failed = failed + 1
    end
  end
  reaper.SelectAllMediaItems(0, false)
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock('Presenter: add to presentation', -1)
  reaper.TrackList_AdjustWindows(false)
  reaper.UpdateArrange()
  cache.state = -1
  if not only then PB.clearSelection('overview') end
  local msg = ('Added %d clip%s to "%s"'):format(n, n == 1 and '' or 's', sectionName)
  if failed > 0 then msg = msg .. ('  -  %d could not be copied'):format(failed) end
  setStatus(msg .. '  (Ctrl+Z to undo)', failed > 0 and COL.accent or COL.waveOn)
end

-- An empty section after the last one
function PB.addSection(name)
  reaper.Undo_BeginBlock()
  PB.ensurePresentation()
  local s0 = presStartTime()
  for _, r in ipairs((cache.views and cache.views.presentation.regions) or {}) do
    s0 = math.max(s0, r.e + 2)
  end
  reaper.AddProjectMarker2(0, true, s0, s0 + 10, name, -1, 0)
  reaper.Undo_EndBlock('Presenter: add section', -1)
  reaper.TrackList_AdjustWindows(false)
  reaper.UpdateArrange()
  cache.state = -1
  return s0
end

function PB.removeClips(clips)
  local done, n = {}, 0
  reaper.Undo_BeginBlock()
  for _, c in ipairs(clips) do
    if c.item and not done[c.item] and reaper.ValidatePtr2(0, c.item, 'MediaItem*') then
      done[c.item] = true
      if playing and playing.clip.item == c.item then pauseClip() end
      reaper.DeleteTrackMediaItem(reaper.GetMediaItem_Track(c.item), c.item)
      n = n + 1
    end
    if PB.psel[c.key] then PB.setSelected(c, false) end
  end
  reaper.Undo_EndBlock('Presenter: remove from presentation', -1)
  reaper.UpdateArrange()
  cache.state = -1
  local what = (n == 1 and #clips == 1) and clips[1].trackName or (n .. ' clips')
  setStatus('Removed ' .. what .. ' from the presentation  (Ctrl+Z to undo)', COL.accent)
end

------------------------------------------------------------- view switch --
function PB.switchView(v)
  if v == currentView then return end
  if playing then pauseClip() end
  PB.viewTs[currentView] = viewT
  currentView = v
  applyView()
  local t = PB.viewTs[v] or (cache.nav[1] and cache.nav[1].s)
  if t then jumpTo(t) else viewT = nil end
end

----------------------------------------------------------- tick box (UI) --
PB.GOLD = { 0xF0, 0xB4, 0x29 }
PB.selectBox = function(id, on, h)
  local w = math.floor(h * 0.75)
  local pressed = coloredButton('##' .. id, w, h, on and PB.GOLD or nil)
  local x0, y0 = ImGui.GetItemRectMin(ctx)
  local x1, y1 = ImGui.GetItemRectMax(ctx)
  local dl = ImGui.GetWindowDrawList(ctx)
  local s = math.min(x1 - x0, y1 - y0) * 0.22
  local cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
  if on then
    ImGui.DrawList_AddLine(dl, cx - s, cy, cx - s * 0.3, cy + s * 0.8, 0x111111FF, 3)
    ImGui.DrawList_AddLine(dl, cx - s * 0.3, cy + s * 0.8, cx + s, cy - s * 0.8, 0x111111FF, 3)
  else
    ImGui.DrawList_AddRect(dl, cx - s, cy - s, cx + s, cy + s, COL.iconDim, 2, 0, 2)
  end
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx, on and 'Selected (click to unselect)'
      or (currentView == 'overview' and 'Select (to recolour or add to the presentation)' or 'Select (to recolour or remove)'))
  end
  return pressed
end

------------------------------------------------------------ text (popup) --
-- "+ Text" / "Edit text": the region's text (shown big above the clips).
-- It's an empty item with the text in its notes, on the top text track.
PB.textDraft = nil        -- { item, region, text, focus, err }
PB.openTextPopup = false

function PB.startText(hdr, region)
  PB.textDraft = {
    item = hdr and hdr.item, region = region,
    text = hdr and (hdr.notes or ''):gsub('%s+$', '') or '', focus = true,
  }
  PB.openTextPopup = true
end

-- The track new text goes on: in the presentation, its Text track; in the
-- overview, a "Text" track at the very top (made if there isn't one)
function PB.textTrack()
  if currentView == 'presentation' then
    local r = PB.ensurePresentation()
    for i = r + 1, presLastIndex(r) do
      local tr = reaper.GetTrack(0, i)
      if trackTag(tr) == 'text' then return tr end
    end
    return reaper.GetTrack(0, PB.insertIntoFolder(r, 'Text'))
  end
  local first = reaper.GetTrack(0, 0)
  if first and not isPresRoot(first) then
    local n = PB.trackNameOf(first):lower()
    if trackTag(first) == 'text' or n == 'text' or n == 'script' then return first end
  end
  reaper.InsertTrackAtIndex(0, true)
  local tr = reaper.GetTrack(0, 0)
  PB.setTrackName(tr, 'Text')
  PB.setTrackTag(tr, 'text')
  return tr
end

function PB.saveText(d)
  local text = d.text:gsub('%s+$', '')
  reaper.Undo_BeginBlock()
  if d.item and reaper.ValidatePtr2(0, d.item, 'MediaItem*') then
    if text:match('%S') then
      reaper.GetSetMediaItemInfo_String(d.item, 'P_NOTES', text, true)
    else
      reaper.DeleteTrackMediaItem(reaper.GetMediaItem_Track(d.item), d.item)
    end
  elseif text:match('%S') and d.region then
    local tr = PB.textTrack()
    local it = reaper.AddMediaItemToTrack(tr)
    reaper.SetMediaItemInfo_Value(it, 'D_POSITION', d.region.s)
    reaper.SetMediaItemInfo_Value(it, 'D_LENGTH', math.max(0.5, d.region.e - d.region.s))
    reaper.GetSetMediaItemInfo_String(it, 'P_NOTES', text, true)
  end
  reaper.Undo_EndBlock('Presenter: edit text', -1)
  reaper.TrackList_AdjustWindows(false)
  reaper.UpdateArrange()
  cache.state = -1
end

function PB.drawTextPopup()
  if PB.openTextPopup then
    ImGui.OpenPopup(ctx, 'Text##presenter')
    PB.openTextPopup = false
  end
  ImGui.SetNextWindowSize(ctx, 640, 0, ImGui.Cond_Appearing)
  if not ImGui.BeginPopupModal(ctx, 'Text##presenter', true) then
    PB.textDraft = nil
    return
  end
  local d = PB.textDraft
  if not d then
    ImGui.CloseCurrentPopup(ctx)
    ImGui.EndPopup(ctx)
    return
  end
  ImGui.TextColored(ctx, COL.accent, (d.item and 'Edit text' or 'Add text') ..
    (d.region and ('  -  ' .. (d.region.label or '')) or ''))
  ImGui.TextColored(ctx, COL.dim, 'Shown large above the clips. Start a line with > for the smaller "listen for" cue.')
  if d.focus then ImGui.SetKeyboardFocusHere(ctx); d.focus = false end
  local _
  _, d.text = ImGui.InputTextMultiline(ctx, '##regiontext', d.text, -1, 160)
  local save = ImGui.Button(ctx, 'Save')
  ImGui.SameLine(ctx)
  local cancel = ImGui.Button(ctx, 'Cancel  [Esc]')
  if d.item then
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Remove text') then d.text = ''; save = true end
  end
  if save then
    PB.saveText(d)
    setStatus(d.text:match('%S') and 'Text saved' or 'Text removed', COL.accent)
    PB.textDraft = nil
    ImGui.CloseCurrentPopup(ctx)
  elseif cancel or ImGui.IsKeyPressed(ctx, ImGui.Key_Escape, false) then
    PB.textDraft = nil
    ImGui.CloseCurrentPopup(ctx)
  end
  ImGui.EndPopup(ctx)
end

--------------------------------------------------- PB.selection + add dialogs --
PB.openAddPopup, PB.openReviewPopup = false, false
PB.addTarget = { new = true, name = '' }
PB.keepFolders = reaper.GetExtState(EXT, 'keepFolders') ~= '0'   -- default on

function PB.sectionList()
  local out = {}
  for _, r in ipairs((cache.views and cache.views.presentation.regions) or {}) do
    if #r.children == 0 then out[#out + 1] = r end
  end
  return out
end

function PB.drawAddPopup()
  local count = PB.addOnly and 1 or #PB.selOrder
  if PB.openAddPopup then
    local n = #PB.sectionList() + 1
    PB.addTarget = { new = true, name = PB.curRegionLabel or ('Section ' .. n), focus = true }
    ImGui.OpenPopup(ctx, 'Add to presentation##presenter')
    PB.openAddPopup = false
  end
  ImGui.SetNextWindowSize(ctx, 520, 0, ImGui.Cond_Appearing)
  if not ImGui.BeginPopupModal(ctx, 'Add to presentation##presenter', true) then PB.addOnly = nil; return end

  ImGui.TextColored(ctx, COL.accent, PB.addOnly
    and ('Add %s to:'):format(PB.addOnly.trackName .. (PB.addOnly.takeLabel and ('  |  ' .. PB.addOnly.takeLabel) or ''))
    or ('Add %d selected clip%s to:'):format(count, count == 1 and '' or 's'))
  if ImGui.RadioButton(ctx, 'A new section', PB.addTarget.new) then PB.addTarget.new, PB.addTarget.region = true, nil end
  if PB.addTarget.new then
    ImGui.Indent(ctx, 24)
    if PB.addTarget.focus then ImGui.SetKeyboardFocusHere(ctx); PB.addTarget.focus = false end
    ImGui.SetNextItemWidth(ctx, -1)
    local _
    _, PB.addTarget.name = ImGui.InputText(ctx, '##newsection', PB.addTarget.name)
    ImGui.Unindent(ctx, 24)
  end
  for k, r in ipairs(PB.sectionList()) do
    if ImGui.RadioButton(ctx, r.label .. '##sec' .. k, (not PB.addTarget.new) and PB.addTarget.region == r) then
      PB.addTarget.new, PB.addTarget.region = false, r
    end
  end
  ImGui.Spacing(ctx)
  ImGui.TextColored(ctx, COL.dim, 'Folders:')
  if ImGui.RadioButton(ctx, 'Keep the session\'s folders  (Vendor A / Batch 2 / Turkish)', PB.keepFolders) then
    PB.keepFolders = true; reaper.SetExtState(EXT, 'keepFolders', '1', true)
  end
  if ImGui.RadioButton(ctx, 'No folders, folder names in the track name', not PB.keepFolders) then
    PB.keepFolders = false; reaper.SetExtState(EXT, 'keepFolders', '0', true)
  end
  ImGui.Spacing(ctx)
  ImGui.TextColored(ctx, COL.dim, 'Each clip goes on its own track, all starting together. The session is not changed.')

  local add = ImGui.Button(ctx, ('Add %d clip%s'):format(count, count == 1 and '' or 's'))
    or ImGui.IsKeyPressed(ctx, ImGui.Key_Enter, false)
  ImGui.SameLine(ctx)
  local cancel = ImGui.Button(ctx, 'Cancel  [Esc]') or ImGui.IsKeyPressed(ctx, ImGui.Key_Escape, false)
  if add then
    local name = (PB.addTarget.name or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if PB.addTarget.new then
      PB.addSelectionToPresentation({ newName = (name ~= '' and name) or ('Section ' .. (#PB.sectionList() + 1)) }, PB.addOnly)
    elseif PB.addTarget.region then
      PB.addSelectionToPresentation({ region = PB.addTarget.region }, PB.addOnly)
    end
    PB.addOnly = nil
    ImGui.CloseCurrentPopup(ctx)
  elseif cancel then
    PB.addOnly = nil
    ImGui.CloseCurrentPopup(ctx)
  end
  ImGui.EndPopup(ctx)
end

function PB.drawReviewPopup()
  if PB.openReviewPopup then
    ImGui.OpenPopup(ctx, 'Selected clips##presenter')
    PB.openReviewPopup = false
  end
  ImGui.SetNextWindowSize(ctx, 520, 0, ImGui.Cond_Appearing)
  if not ImGui.BeginPopupModal(ctx, 'Selected clips##presenter', true) then return end
  ImGui.TextColored(ctx, COL.accent, ('%d selected'):format(#PB.selOrder))
  local removeKey
  for k, key in ipairs(PB.selOrder) do
    local e = PB.selection[key]
    local c = e.clip
    if ImGui.SmallButton(ctx, 'x##unsel' .. k) then removeKey = key end
    ImGui.SameLine(ctx)
    ImGui.Text(ctx, ('%s%s   (%s)'):format(c.trackName, c.takeLabel and ('  |  ' .. c.takeLabel) or '',
      e.region or 'no region'))
  end
  if removeKey then PB.setSelected(PB.selection[removeKey].clip, false) end
  ImGui.Spacing(ctx)
  if ImGui.Button(ctx, 'Close') or ImGui.IsKeyPressed(ctx, ImGui.Key_Escape, false) then
    ImGui.CloseCurrentPopup(ctx)
  end
  ImGui.EndPopup(ctx)
end

----------------------------------------------- tracks & folders (builder) --
PB.showTrackEditor = false
PB.renaming = nil          -- { guid, text, focus }
PB.pendingMove = nil       -- { src, tgt, mode }

function PB.trackByGUID(g)
  for i = 0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)
    if reaper.GetTrackGUID(tr) == g then return tr, i end
  end
end

function PB.moveTrack(m)
  local src, si = PB.trackByGUID(m.src)
  if not src or trackTag(src) == 'text' then return end
  local lastS = (reaper.GetMediaTrackInfo_Value(src, 'I_FOLDERDEPTH') == 1) and presLastIndex(si) or si
  local before, mode
  if m.mode == 'end' then
    local r = presRootIndex()
    if not r then return end
    before, mode = presLastIndex(r) + 1, 2
  else
    local _, ti = PB.trackByGUID(m.tgt)
    if not ti or (ti >= si and ti <= lastS) then return end     -- onto itself / its own children
    if m.mode == 'into' then before, mode = ti + 1, 1 else before, mode = ti, 0 end
  end
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  for i = 0, reaper.CountTracks(0) - 1 do reaper.SetTrackSelected(reaper.GetTrack(0, i), false) end
  for i = si, lastS do reaper.SetTrackSelected(reaper.GetTrack(0, i), true) end
  reaper.ReorderSelectedTracks(before, mode)
  for i = 0, reaper.CountTracks(0) - 1 do reaper.SetTrackSelected(reaper.GetTrack(0, i), false) end
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock('Presenter: move track', -1)
  reaper.TrackList_AdjustWindows(false)
  cache.state = -1
end

function PB.addTrackOrFolder(parentIdx, isFolder)
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  local name = isFolder and 'New folder' or 'New track'
  local idx = PB.insertIntoFolder(parentIdx, name)
  if isFolder then PB.insertIntoFolder(idx, 'New track') end
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock('Presenter: add ' .. (isFolder and 'folder' or 'track'), -1)
  reaper.TrackList_AdjustWindows(false)
  cache.state = -1
  local tr = reaper.GetTrack(0, idx)
  PB.renaming = { guid = reaper.GetTrackGUID(tr), text = name, focus = true }
end

function PB.deleteTrack(tr)
  reaper.Undo_BeginBlock()
  reaper.DeleteTrack(tr)
  reaper.Undo_EndBlock('Presenter: delete track', -1)
  reaper.TrackList_AdjustWindows(false)
  reaper.UpdateArrange()
  cache.state = -1
end

function PB.dropTarget(guid, mode)
  if ImGui.BeginDragDropTarget(ctx) then
    local ok, payload = ImGui.AcceptDragDropPayload(ctx, 'PRES_TRACK')
    if ok and payload then PB.pendingMove = { src = payload, tgt = guid, mode = mode } end
    ImGui.EndDragDropTarget(ctx)
  end
end

function PB.drawTrackEditor()
  local r = presRootIndex()
  if not r then return end
  local root = reaper.GetTrack(0, r)
  local last = presLastIndex(r)
  ImGui.PushFont(ctx, font, 15)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 8, 3)

  if coloredButton('+ Track##root', 0, 0) then PB.addTrackOrFolder(r, false) end
  ImGui.SameLine(ctx, 0, 6)
  if coloredButton('+ Folder##root', 0, 0) then PB.addTrackOrFolder(r, true) end
  ImGui.SameLine(ctx, 0, 12)
  ImGui.TextColored(ctx, COL.dim, 'Drag :: to reorder (drop on a folder to move into it). Click a swatch to colour. Double-click a name to rename.')

  local avail = ImGui.GetContentRegionAvail(ctx)
  for i = r + 1, last do
    local tr = reaper.GetTrack(0, i)
    local guid = reaper.GetTrackGUID(tr)
    local isText = trackTag(tr) == 'text'
    local isFolder = reaper.GetMediaTrackInfo_Value(tr, 'I_FOLDERDEPTH') == 1
    local level = PB.nestLevel(tr, root)
    local name = PB.trackNameOf(tr)
    ImGui.PushID(ctx, guid)

    -- thin drop zone above the row: "move before this track"
    if not isText then
      ImGui.InvisibleButton(ctx, '##gap', math.max(10, avail), 4)
      PB.dropTarget(guid, 'before')
    end

    ImGui.Indent(ctx, (level - 1) * 22 + 1)
    if isText then
      ImGui.TextColored(ctx, COL.dim, '  ' .. name .. '   (text - always first)')
    else
      coloredButton('::##drag', 0, 0)
      if ImGui.BeginDragDropSource(ctx) then
        ImGui.SetDragDropPayload(ctx, 'PRES_TRACK', guid)
        ImGui.Text(ctx, 'Move ' .. name)
        ImGui.EndDragDropSource(ctx)
      end
      PB.dropTarget(guid, isFolder and 'into' or 'before')
      ImGui.SameLine(ctx, 0, 6)

      -- Track colour: click the swatch for the palette
      local trgb = trackRGB(tr)
      local swatch = trgb and ((trgb[1] << 24) | (trgb[2] << 16) | (trgb[3] << 8) | 0xFF) or 0x3A3F47FF
      local fh = ImGui.GetFrameHeight(ctx)
      if ImGui.ColorButton(ctx, '##trkcolbtn', swatch, ImGui.ColorEditFlags_NoTooltip, fh, fh) then
        ImGui.OpenPopup(ctx, 'trkcol')
      end
      if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, 'Track colour (its clips use it unless they have their own)') end
      if ImGui.BeginPopup(ctx, 'trkcol') then
        ImGui.TextColored(ctx, COL.dim, 'Colour for ' .. name)
        if PB.drawPalette('trk', function(rgb) PB.setTrackColour(tr, rgb) end, true, 'No colour') then
          ImGui.CloseCurrentPopup(ctx)
        end
        ImGui.EndPopup(ctx)
      end
      ImGui.SameLine(ctx, 0, 6)

      if PB.renaming and PB.renaming.guid == guid then
        if PB.renaming.focus then ImGui.SetKeyboardFocusHere(ctx); PB.renaming.focus = false end
        ImGui.SetNextItemWidth(ctx, 260)
        local _
        _, PB.renaming.text = ImGui.InputText(ctx, '##rename', PB.renaming.text)
        local done = ImGui.IsKeyPressed(ctx, ImGui.Key_Enter, false) or ImGui.IsItemDeactivated(ctx)
        if ImGui.IsKeyPressed(ctx, ImGui.Key_Escape, false) then
          PB.renaming = nil
        elseif done then
          local t = PB.renaming.text:gsub('^%s+', ''):gsub('%s+$', '')
          if t ~= '' and t ~= name then
            reaper.Undo_BeginBlock()
            PB.setTrackName(tr, t)
            reaper.Undo_EndBlock('Presenter: rename track', -1)
            cache.state = -1
          end
          PB.renaming = nil
        end
      else
        ImGui.Text(ctx, (isFolder and '[folder]  ' or '') .. name)
        if ImGui.IsItemHovered(ctx) and ImGui.IsMouseDoubleClicked(ctx, 0) then
          PB.renaming = { guid = guid, text = name, focus = true }
        end
        PB.dropTarget(guid, isFolder and 'into' or 'before')
      end

      ImGui.SameLine(ctx, 0, 12)
      if isFolder then
        if coloredButton('+ Track##in', 0, 0) then PB.addTrackOrFolder(i, false) end
        ImGui.SameLine(ctx, 0, 4)
        if coloredButton('+ Subfolder##in', 0, 0) then PB.addTrackOrFolder(i, true) end
        ImGui.SameLine(ctx, 0, 4)
        ImGui.BeginDisabled(ctx)
        coloredButton('x##del', 0, 0)
        ImGui.EndDisabled(ctx)
        if ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_AllowWhenDisabled) then
          ImGui.SetTooltip(ctx, 'Move or delete the tracks inside first')
        end
      else
        if coloredButton('x##del', 0, 0) then PB.deleteTrack(tr) end
        if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, 'Delete this track and its clips (Ctrl+Z to undo)') end
      end
    end
    ImGui.Unindent(ctx, (level - 1) * 22 + 1)
    ImGui.PopID(ctx)
  end

  -- drop zone at the end: "move to the end of the presentation"
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, COL.dim)
  ImGui.Button(ctx, 'Drop here to move to the end##endzone', -1, 0)
  ImGui.PopStyleColor(ctx)
  PB.dropTarget('end', 'end')

  ImGui.PopStyleVar(ctx)
  ImGui.PopFont(ctx)

  if PB.pendingMove then
    local m = PB.pendingMove
    PB.pendingMove = nil
    PB.moveTrack(m)
  end
end

----------------------------------------------------- section rename popup --
PB.sectionDraft = nil      -- { region, text, focus } or { new = true, text, focus }
PB.openSectionPopup = false

function PB.drawSectionPopup()
  if PB.openSectionPopup then
    ImGui.OpenPopup(ctx, 'Section##presenter')
    PB.openSectionPopup = false
  end
  ImGui.SetNextWindowSize(ctx, 420, 0, ImGui.Cond_Appearing)
  if not ImGui.BeginPopupModal(ctx, 'Section##presenter', true) then
    PB.sectionDraft = nil
    return
  end
  local d = PB.sectionDraft
  if not d then ImGui.CloseCurrentPopup(ctx); ImGui.EndPopup(ctx); return end
  ImGui.TextColored(ctx, COL.accent, d.new and 'New section' or 'Rename section')
  if d.focus then ImGui.SetKeyboardFocusHere(ctx); d.focus = false end
  ImGui.SetNextItemWidth(ctx, -1)
  local _
  _, d.text = ImGui.InputText(ctx, '##secname', d.text)
  local ok = ImGui.Button(ctx, d.new and 'Add  [Enter]' or 'Rename  [Enter]') or ImGui.IsKeyPressed(ctx, ImGui.Key_Enter, false)
  ImGui.SameLine(ctx)
  local cancel = ImGui.Button(ctx, 'Cancel  [Esc]') or ImGui.IsKeyPressed(ctx, ImGui.Key_Escape, false)
  if ok then
    local t = d.text:gsub('^%s+', ''):gsub('%s+$', '')
    if d.new then
      local s0 = PB.addSection(t ~= '' and t or ('Section ' .. (#PB.sectionList() + 1)))
      reaper.SetEditCurPos(s0, true, false)
      viewT = s0
    elseif t ~= '' and d.region then
      reaper.Undo_BeginBlock()
      reaper.SetProjectMarker(d.region.idx, true, d.region.s, d.region.e, t)
      reaper.Undo_EndBlock('Presenter: rename section', -1)
      cache.state = -1
    end
    PB.sectionDraft = nil
    ImGui.CloseCurrentPopup(ctx)
  elseif cancel then
    PB.sectionDraft = nil
    ImGui.CloseCurrentPopup(ctx)
  end
  ImGui.EndPopup(ctx)
end

-------------------------------------------------------------- the bars --
-- Overview: PB.selection bar. Presentation: builder bar. Both sit just above
-- the clips, with Expand all / Collapse all on the right when there are folders.
-- Expand all / Collapse all, right-aligned on the current line
function PB.expandButtons()
  local w = ImGui.CalcTextSize(ctx, 'Expand all') + ImGui.CalcTextSize(ctx, 'Collapse all') + 16 * 2 + 6
  ImGui.SameLine(ctx, 0, 10)
  local x = ImGui.GetCursorPosX(ctx)
  ImGui.SetCursorPosX(ctx, x + math.max(0, ImGui.GetContentRegionAvail(ctx) - w))
  if coloredButton('Expand all', 0, 0) then forceOpen = true end
  ImGui.SameLine(ctx, 0, 6)
  if coloredButton('Collapse all', 0, 0) then forceOpen = false end
end

function PB.drawListBar(clips, region, hasFolders)
  ImGui.PushFont(ctx, font, 15)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 8, 3)

  -- Selection row, the same in both views:
  --   N selected | Select all in region | Colour... | [view's action] | Review | Clear
  local function selectionRow(view)
    local n = (view == 'presentation') and #PB.porder or #PB.selOrder
    ImGui.AlignTextToFramePadding(ctx)
    ImGui.TextColored(ctx, n > 0 and COL.accent or COL.dim, ('%d selected'):format(n))
    ImGui.SameLine(ctx, 0, 10)
    local allIn = #clips > 0
    for _, c in ipairs(clips) do if not PB.isSelected(c) then allIn = false break end end
    local word = (view == 'presentation') and 'section' or 'region'
    if coloredButton((allIn and ('Unselect ' .. word) or ('Select all in ' .. word)) .. '##selreg', 0, 0) then
      for _, c in ipairs(clips) do PB.setSelected(c, not allIn) end
    end
    ImGui.SameLine(ctx, 0, 4)
    ImGui.BeginDisabled(ctx, n == 0)
    PB.colourButton(view, n)
    ImGui.SameLine(ctx, 0, 4)
    if view == 'overview' then
      if coloredButton('Add to presentation...##seladd', 0, 0, n > 0 and 'switch' or nil) then
        PB.addOnly = nil; PB.openAddPopup = true
      end
      ImGui.SameLine(ctx, 0, 4)
      if coloredButton('Review##selrev', 0, 0) then PB.openReviewPopup = true end
    else
      if coloredButton('Remove##selrm', 0, 0) then PB.removeClips(PB.selectedClips('presentation')) end
      if ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_AllowWhenDisabled) then
        ImGui.SetTooltip(ctx, 'Remove the selected clips from the presentation (Ctrl+Z to undo)')
      end
    end
    ImGui.SameLine(ctx, 0, 4)
    if coloredButton('Clear##selclr', 0, 0) then PB.clearSelection(view) end
    ImGui.EndDisabled(ctx)
  end

  if currentView == 'overview' then
    selectionRow('overview')
  else
    if not presRootIndex() then
      ImGui.TextColored(ctx, COL.dim, 'No presentation yet.')
      ImGui.SameLine(ctx, 0, 8)
      if coloredButton('Create presentation', 0, 0, 'switch') then
        PB.sectionDraft = { new = true, text = 'Section 1', focus = true }
        PB.openSectionPopup = true
      end
    else
      -- Builder row
      if coloredButton('+ Section', 0, 0) then
        PB.sectionDraft = { new = true, text = 'Section ' .. (#PB.sectionList() + 1), focus = true }
        PB.openSectionPopup = true
      end
      if region then
        ImGui.SameLine(ctx, 0, 4)
        if coloredButton('Rename section', 0, 0) then
          PB.sectionDraft = { region = region, text = region.name or '', focus = true }
          PB.openSectionPopup = true
        end
      end
      ImGui.SameLine(ctx, 0, 4)
      if topToggle('Tracks & folders', PB.showTrackEditor) then PB.showTrackEditor = not PB.showTrackEditor end
      if #PB.selOrder > 0 and region then
        ImGui.SameLine(ctx, 0, 4)
        if coloredButton(('+ Add %d from Overview here'):format(#PB.selOrder), 0, 0, 'switch') then
          PB.addSelectionToPresentation({ region = region })
        end
      end
      if hasFolders then
        PB.expandButtons()
        hasFolders = false
      end
      selectionRow('presentation')
    end
  end

  if hasFolders then PB.expandButtons() end
  ImGui.PopStyleVar(ctx)
  ImGui.PopFont(ctx)

  if currentView == 'presentation' and PB.showTrackEditor and presRootIndex() then
    ImGui.Spacing(ctx)
    PB.drawTrackEditor()
    ImGui.Separator(ctx)
  end
end

------------------------------------------------------------ settings popup --
PB.openSettings = false
-- (PB.drawSettingsBody is defined below)      -- defined below (the settings controls)

function PB.drawSettingsPopup(clips)
  if PB.openSettings then
    ImGui.OpenPopup(ctx, 'Settings##presenter')
    PB.openSettings = false
  end
  ImGui.SetNextWindowSize(ctx, 540, 0, ImGui.Cond_Appearing)
  if ImGui.BeginPopup(ctx, 'Settings##presenter') then
    PB.drawSettingsBody(clips)
    ImGui.EndPopup(ctx)
  end
end

PB.drawSettingsBody = function(clips)
  local ch, any = false, false
  ch, cfg.textSize = ImGui.SliderInt(ctx, 'Text size', cfg.textSize, 14, 96); any = any or ch
  ch, cfg.buttonSize = ImGui.SliderInt(ctx, 'Button size', cfg.buttonSize, 14, 72); any = any or ch
  ch, cfg.tabSize = ImGui.SliderInt(ctx, 'Tab size', cfg.tabSize, 12, 48); any = any or ch
  ch, cfg.waveHeight = ImGui.SliderInt(ctx, 'Waveform height', cfg.waveHeight, 40, 300); any = any or ch
  ch, cfg.preroll = ImGui.SliderDouble(ctx, 'Marker pre-roll', cfg.preroll, 0, 3, '%.1f s'); any = any or ch
  ch, cfg.showAllWaves = ImGui.Checkbox(ctx, 'Show waveforms for all clips', cfg.showAllWaves); any = any or ch
  ch, cfg.folders = ImGui.Checkbox(ctx, 'Group clips by folder', cfg.folders); any = any or ch
  ch, cfg.restoreOnClose = ImGui.Checkbox(ctx, 'Put active takes and lanes back when the panel closes',
    cfg.restoreOnClose); any = any or ch
  ch, cfg.showFiles = ImGui.Checkbox(ctx, 'Show file names (breaks blinding)', cfg.showFiles); any = any or ch
  ch, cfg.notesOpen = ImGui.Checkbox(ctx, 'Notes open by default', cfg.notesOpen)
  if ch then noteGen = noteGen + 1; any = true end    -- re-apply to every note
  ch, cfg.noteImgHeight = ImGui.SliderInt(ctx, 'Note image height', cfg.noteImgHeight, 60, 600); any = any or ch
  if any then saveCfg() end
  if ImGui.Button(ctx, 'Clear all paused positions') then resume, abOff = {}, nil end

  -- Levels: normalise clips
  ImGui.Spacing(ctx)
  ImGui.Separator(ctx)
  ImGui.TextColored(ctx, COL.accent, 'Levels')
  ImGui.AlignTextToFramePadding(ctx)
  ImGui.Text(ctx, 'Normalize to')
  for k, m in ipairs(NORM_MODES) do
    ImGui.SameLine(ctx, 0, k == 1 and 8 or 1)
    local sel = cfg.normMode == k
    if coloredButton(m.name .. '##norm' .. k, 0, 0, sel and 'switch' or nil) and not sel then
      cfg.normMode = k
      cfg.normTarget = (k == 1) and -23 or -1      -- sensible starting point per mode
      saveCfg()
    end
  end
  local unit = (NORM_MODES[cfg.normMode] or NORM_MODES[1]).unit
  ch, cfg.normTarget = ImGui.SliderDouble(ctx, 'Target', cfg.normTarget, -40, 0, '%.1f ' .. unit)
  if ch then saveCfg() end
  if ImGui.Button(ctx, ('Normalize this region  (%d clips)'):format(#clips)) then
    normalizeClips(clips, 'this region')
  end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Normalize all clips in this view') then
    normalizeClips(allClipsInView(), 'all clips')
  end
  ImGui.TextColored(ctx, COL.dim,
    'Sets each take\'s volume. One undo step. Warns about clips that would go above -1 dBTP.')

end

local function draw()
  frameNo = frameNo + 1
  local t = resolveViewTime()
  local s, e, title, hdr, region = currentTrial(t)
  cache.curS = s
  local clips = clipsIn(s, e, t, region)
  local shared = sharedMarkersIn(s, e, clips)
  local noteRows = assignNotes(notesIn(s, e, t, hdr, region), clips)
  local pts = navPoints()

  -- Trial index and neighbours (arrow keys)
  local idx
  if s then
    for i, p in ipairs(pts) do if math.abs(p - s) < EPS then idx = i break end end
  end
  local prevPos, nextPos
  local ref = s or t
  for _, p in ipairs(pts) do
    if p < ref - EPS then prevPos = p end
    if p > ref + EPS and not nextPos then nextPos = p end
  end

  -- Which clip in this trial is "active" (playing, or last played)
  local activeClip
  for _, c in ipairs(clips) do
    if (playing and playing.clip.key == c.key) or c.key == activeKey then activeClip = c end
    if playing and playing.clip.key == c.key then break end
  end

  PB.curRegionLabel = (region and region.label) or title

  ------------------------------------------------ top line
  -- Overview | Presentation on the left; Settings and Compact view on the right
  ImGui.PushFont(ctx, font, cfg.tabSize)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 12, 6)
  local topX, topY = ImGui.GetCursorPos(ctx)
  local fullW = ImGui.GetContentRegionAvail(ctx)
  for k, v in ipairs({ { 'overview', 'Overview' }, { 'presentation', 'Presentation' } }) do
    if k > 1 then ImGui.SameLine(ctx, 0, 1) end
    local sel = currentView == v[1]
    if coloredButton(v[2] .. '##view', 0, 0, sel and PB.GOLD or nil) and not sel then PB.switchView(v[1]) end
  end
  local cvW = ImGui.CalcTextSize(ctx, '      Compact view') + 24
  local setW = ImGui.CalcTextSize(ctx, 'Settings') + 24
  ImGui.SameLine(ctx)
  ImGui.SetCursorPosX(ctx, topX + math.max(0, fullW - cvW - setW - 6))
  if coloredButton('Settings##open', 0, 0) then PB.openSettings = true end
  ImGui.SameLine(ctx, 0, 6)
  if topToggle('Compact view', compact) then toggleCompact() end
  ImGui.PopStyleVar(ctx)
  ImGui.PopFont(ctx)
  ImGui.Spacing(ctx)

  ------------------------------------------------ region tabs
  if cache.roots and #cache.roots > 0 then
    drawRegionTabs(region, 0)
  elseif #cache.nav > 0 then
    drawTabs(s, 0)
  end
  ImGui.Spacing(ctx)

  ------------------------------------------------ control row
  -- Play/pause for the selected clip (same as Space)
  local function playPauseSelected()
    if playing then
      pauseClip()
    else
      local c = activeClip or clips[1]
      if c then anchorRow(c); toggleClip(c) end      -- resumes from where it was paused
    end
  end
  if iconButton('playpause', playing and 'pause' or 'play', ImGui.GetFrameHeight(ctx),
      playing and 'play' or nil) then
    playPauseSelected()
  end
  ImGui.SameLine(ctx, 0, 16)
  drawABControl()
  ImGui.SameLine(ctx, 0, 16)
  if topToggle('Loop', cfg.loop) then setLoop(not cfg.loop) end
  if loopRange then
    ImGui.SameLine(ctx)
    if coloredButton('Clear loop range', 0, 0) then
      loopRange = nil
      if playing and cfg.loop then applyLoop(playing.clip) end
    end
  end
  -- Counter: within the top-level group when regions are nested
  -- ("trial 2 / 3 in Round 1"), otherwise across the whole project
  local root = region
  while root and root.parent do root = root.parent end
  if root and root ~= region then
    local leaves = {}
    local function collect(r)
      if #r.children == 0 then leaves[#leaves + 1] = r end
      for _, ch in ipairs(r.children) do collect(ch) end
    end
    collect(root)
    for k, lf in ipairs(leaves) do
      if lf == region then
        ImGui.SameLine(ctx)
        ImGui.TextColored(ctx, COL.dim, ('   region %d / %d in %s'):format(k, #leaves, root.label))
      end
    end
  elseif idx then
    ImGui.SameLine(ctx)
    ImGui.TextColored(ctx, COL.dim, ('   region %d / %d'):format(idx, #pts))
  end
  if status and reaper.time_precise() < status.untilT then
    ImGui.SameLine(ctx)
    ImGui.TextColored(ctx, status.col, '   ' .. status.text)
  end
  ImGui.Spacing(ctx)

  local bodyOpen = false
  if compact then
    ImGui.Separator(ctx)
    drawClipChips(clips, activeClip)
  else
  -- Everything above stays put; the region text and the clips scroll in a child
  -- window. (Skipped when there is almost no room, so the window itself is used.)
  ImGui.Separator(ctx)
  local _, availH = ImGui.GetContentRegionAvail(ctx)
  if availH > 60 then
    bodyOpen = ImGui.BeginChild(ctx, 'presenterBody', 0, 0)
  end
  inBody = true
  if bodyOpen then
    if pendingScrollDy ~= 0 then   -- scroll requested from outside the child
      ImGui.SetScrollY(ctx, math.max(0, ImGui.GetScrollY(ctx) + pendingScrollDy))
    end
    if resetBody then ImGui.SetScrollY(ctx, 0) end
  end
  pendingScrollDy, resetBody = 0, false
  ------------------------------------------------ title and text
  -- Where this trial sits, for nested regions: "Round 1 / Jo"
  if region and region.parent then
    local names, r = {}, region.parent
    while r do table.insert(names, 1, r.label); r = r.parent end
    ImGui.PushFont(ctx, font, math.max(13, math.floor(cfg.textSize * 0.42)))
    ImGui.TextColored(ctx, COL.dim, table.concat(names, '  /  '))
    ImGui.PopFont(ctx)
  end
  -- Region name, with "+ Text" / "Edit text" beside it
  local shownTitle = (title and title ~= '') and title or (region and region.label) or nil
  if shownTitle then
    ImGui.PushFont(ctx, font, math.floor(cfg.textSize * 0.6))
    ImGui.TextColored(ctx, COL.accent, shownTitle)
    ImGui.PopFont(ctx)
  end
  if region or hdr then
    if shownTitle then ImGui.SameLine(ctx, 0, 14) end
    ImGui.PushFont(ctx, font, 15)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 8, 3)
    if coloredButton((hdr and 'Edit text' or '+ Text') .. '##textbtn', 0, 0) then PB.startText(hdr, region) end
    if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, 'The large text shown above the clips for this region') end
    ImGui.PopStyleVar(ctx)
    ImGui.PopFont(ctx)
  end
  if hdr then
    for line in (hdr.notes .. '\n'):gmatch('(.-)\r?\n') do
      local cue = line:match('^%s*>%s*(.*)$')
      if cue then
        ImGui.PushFont(ctx, font, math.floor(cfg.textSize * 0.7))
        ImGui.PushStyleColor(ctx, ImGui.Col_Text, COL.accent)
        ImGui.TextWrapped(ctx, cue)
        ImGui.PopStyleColor(ctx)
        ImGui.PopFont(ctx)
      elseif line:match('%S') then
        ImGui.PushFont(ctx, font, cfg.textSize)
        ImGui.TextWrapped(ctx, line)
        ImGui.PopFont(ctx)
      end
    end
    -- An image on the script item is shown under the script (click to enlarge)
    local hdrImage = hdr.image or (hdr.item and itemImage(hdr.item))
    if hdrImage then
      drawImage(hdrImage, math.max(50, ImGui.GetContentRegionAvail(ctx)), cfg.noteImgHeight * 1.5)
    end
  end

  ImGui.Spacing(ctx)
  ImGui.Separator(ctx)
  ImGui.Spacing(ctx)

  ------------------------------------------------ shared markers
  if #shared > 0 then
    drawMarkerButtons(shared, 'shared', COL.sharedMarker, function(m)
      jumpToMarker(activeClip or clips[1], m.off)
    end)
    ImGui.Spacing(ctx)
  end

  ------------------------------------------------ clips
  if #clips == 0 then
    ImGui.TextColored(ctx, COL.dim,
      (currentView == 'presentation') and 'No clips in this section yet. Tick clips in Overview, then add them here.' or 'No clips in this region.')
  end

  -- Bar above the clips: PB.selection (Overview) or builder (Presentation),
  -- plus Expand all / Collapse all when there are folders
  local hasFolders = false
  if cfg.folders then
    for _, c in ipairs(clips) do if c.path and #c.path > 0 then hasFolders = true break end end
  end
  PB.drawListBar(clips, region, hasFolders)

  local rows = mergeRows(clips, noteRows)
  if cfg.folders then
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_IndentSpacing, 22)
    drawNode(buildTree(rows), activeClip, shared)
    ImGui.PopStyleVar(ctx)
    forceOpen = nil
  else
    for _, row in ipairs(rows) do
      if row.clip then drawClip(row.clip, row.i, activeClip, shared) else drawNoteRow(row.note) end
    end
  end

  inBody = false
  if bodyOpen then ImGui.EndChild(ctx) end   -- BeginChild closes itself when it returns false
  end -- compact / full

  ------------------------------------------------ keyboard
  -- Only while this panel has the keyboard focus and no popup is open (IsKeyPressed
  -- itself ignores focus, so without this the keys fire from other REAPER windows)
  local keysOn = ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_RootAndChildWindows)
    and not ImGui.IsPopupOpen(ctx, '', ImGui.PopupFlags_AnyPopup)
  if keysOn and not ImGui.IsAnyItemActive(ctx) then
    for i, key in ipairs(KEYS) do
      if clips[i] and ImGui.IsKeyPressed(ctx, key, false) then anchorRow(clips[i]); toggleClip(clips[i]) end
    end
    if ImGui.IsKeyPressed(ctx, ImGui.Key_Space, false) then playPauseSelected() end
    if ImGui.IsKeyPressed(ctx, ImGui.Key_A, false) then cfg.ab = not cfg.ab; saveCfg() end
    if ImGui.IsKeyPressed(ctx, ImGui.Key_S, false) then    -- Default <-> Smooth (turns A/B on)
      if not cfg.ab then cfg.ab, smoothAB = true, true else smoothAB = not smoothAB end
      saveCfg()
    end
    if ImGui.IsKeyPressed(ctx, ImGui.Key_L, false) then setLoop(not cfg.loop) end
    if ImGui.IsKeyPressed(ctx, ImGui.Key_C, false) then toggleCompact() end
    if ImGui.IsKeyPressed(ctx, ImGui.Key_M, false) then startMarker(activeClip or clips[1]) end
    if ImGui.IsKeyPressed(ctx, ImGui.Key_N, false) then startNote(activeClip or clips[1]) end
    if ImGui.IsKeyPressed(ctx, ImGui.Key_LeftArrow, false) and prevPos then jumpTo(prevPos) end
    if ImGui.IsKeyPressed(ctx, ImGui.Key_RightArrow, false) and nextPos then jumpTo(nextPos) end
  end

  ------------------------------------------------ settings
  drawMarkerPopup()
  drawNotePopup()

  PB.drawTextPopup()
  PB.drawAddPopup()
  PB.drawReviewPopup()
  PB.drawSectionPopup()
  PB.drawSettingsPopup(clips)
  PB.drawRenamePopup()
end

-------------------------------------------------------------------- loop --
local lastOpenSize = nil   -- the size the floating window had when last open
local function loop()
  refresh()
  -- save the size shortly after the user stops resizing (not on every frame)
  if PB.sizeDirtyAt and reaper.time_precise() - PB.sizeDirtyAt > 1 then PB.sizeDirtyAt = nil; saveCfg() end
  watchPlayback()

  -- First open: the remembered size (clamped). The window's own size is kept by
  -- ReaImGui after that.
  ImGui.SetNextWindowSize(ctx, clamp(cfg.sizeW, 320, 4000), clamp(cfg.sizeH, 200, 4000), ImGui.Cond_FirstUseEver)
  if compact and compactH then
    ImGui.SetNextWindowSize(ctx, winW or 760, compactH, ImGui.Cond_Always)
  elseif restoreSize then
    ImGui.SetNextWindowSize(ctx, restoreSize[1], restoreSize[2], ImGui.Cond_Always)
    restoreSize = nil
  elseif PB.collapsedLast and lastOpenSize then
    -- The window was collapsed with its title-bar arrow: keep re-sending the size it
    -- had when open, so expanding it brings that size back instead of a tiny window.
    ImGui.SetNextWindowSize(ctx, lastOpenSize[1], lastOpenSize[2], ImGui.Cond_Always)
  end
  ImGui.PushFont(ctx, font, 18)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, 18, 16)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 14, 8)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 10, 8)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 6)

  -- No window scrollbar in full view: the clips scroll in their own child
  local winFlags = compact and ImGui.WindowFlags_None
    or (ImGui.WindowFlags_NoScrollbar | ImGui.WindowFlags_NoScrollWithMouse)
  local visible, open = ImGui.Begin(ctx, SCRIPT_NAME, true, winFlags)
  -- Begin returns false both when collapsed and when docked in a tab that isn't showing
  -- (ReaImGui has no working IsWindowCollapsed). Floating last frame + not visible = collapsed;
  -- docked last frame = hidden dock tab, so the size is left alone.
  PB.collapsedLast = (not visible) and not PB.dockedLast
  if visible then
    PB.dockedLast = ImGui.IsWindowDocked(ctx)
    if resetScroll then ImGui.SetScrollY(ctx, 0); resetScroll = false end
    draw()
    prefetch(cache.curS)
    winW, winH = ImGui.GetWindowSize(ctx)
    if not PB.dockedLast then
      lastOpenSize = { winW, winH }
      if not compact and (cfg.sizeW ~= winW or cfg.sizeH ~= winH) then   -- full view, floating only
        cfg.sizeW, cfg.sizeH = winW, winH
        PB.sizeDirtyAt = reaper.time_precise()
      end
    end
    -- compact: fit the window's height to what was drawn (width stays yours)
    if compact then compactH = ImGui.GetCursorPosY(ctx) + 8 end
    ImGui.End(ctx)   -- only when visible: ReaImGui ends a hidden window itself
  end

  -- Large image viewer: opened by clicking an image; fits the image to the
  -- window (resize it, or dock it, for a big view). Click the image or the
  -- window's close button to close.
  if bigImage then
    ImGui.SetNextWindowSize(ctx, 900, 700, ImGui.Cond_FirstUseEver)
    local v, o = ImGui.Begin(ctx, 'Image##presenterImage', true)
    if v then
      local img = getImage(bigImage)
      if img then
        local aw, ah = ImGui.GetContentRegionAvail(ctx)
        local iw, ih = ImGui.Image_GetSize(img)
        if iw and iw > 0 and ih > 0 then
          local sc = math.min(aw / iw, ah / ih)
          ImGui.Image(ctx, img, iw * sc, ih * sc)
          if ImGui.IsItemClicked(ctx) then o = false end
        end
      end
      ImGui.End(ctx)
    end
    if not o then bigImage = nil end
  end

  ImGui.PopStyleVar(ctx, 4)
  ImGui.PopFont(ctx)

  if open then
    reaper.defer(loop)
  else
    if playing then pauseClip() end
    restoreRepeat()
    if cfg.restoreOnClose then restoreTakesAndLanes() end
    saveCfg()
  end
end

reaper.atexit(function()
  if playing then
    reaper.OnStopButton()
    unsoloAll()
  end
  restoreRepeat()
  if cfg.restoreOnClose then restoreTakesAndLanes() end
  saveCfg()
end)

reaper.defer(loop)

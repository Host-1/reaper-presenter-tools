-- @description Presenter panel (launcher for the 2-part copy)
-- Runs the Presenter panel from two text files next to this script, named
-- anything ending in part1 / part2, e.g. Presenter_panel_part_1.txt and
-- Presenter_panel_part_2.txt (spaces, underscores and hyphens don't matter).
-- Each part starts and ends with a check line, so a part that was cut off
-- at either end when pasting is caught here with a clear message.
local dir = ({ reaper.get_action_context() })[2]:match('^(.*[\\/])') or ''

local found = {}
local i = 0
while true do
  local name = reaper.EnumerateFiles(dir, i)
  if not name then break end
  local n = name:lower():gsub('[%s_%-]', ''):match('part([12])%.txt$')
  if n then found[tonumber(n)] = name end
  i = i + 1
end

local parts, problems, versions = {}, {}, {}
for n = 1, 2 do
  local f = found[n] and io.open(dir .. found[n], 'rb')
  if not f then
    problems[#problems + 1] = 'Missing: a .txt file ending in "part' .. n .. '" (e.g. Presenter_panel_part_' .. n .. '.txt)'
  else
    local text = f:read('a'); f:close()
    text = text:gsub('^\239\187\191', '')                 -- byte-order mark some editors add
    local ver, body = text:match('^%s*%-%- @@PRESENTER%-PART' .. n .. '%-START (%S-)@@\r?\n(.*)$')
    if not ver then
      problems[#problems + 1] = 'Part ' .. n .. ' (' .. found[n] .. ') is missing its first line: the start was cut off or not copied. Paste it again, from the very top.'
    else
      -- remove just the end check line (the newline before it belongs to the script)
      local stripped = body:gsub('%-%- @@PRESENTER%-PART' .. n .. '%-END@@%s*$', '')
      if stripped == body then
        problems[#problems + 1] = 'Part ' .. n .. ' (' .. found[n] .. ') is missing its last line: the end was cut off. Paste it again, in full.'
      else
        parts[n], versions[n] = stripped, ver
      end
    end
  end
end
if #problems == 0 and versions[1] ~= versions[2] then
  problems[#problems + 1] = ('The parts are from different versions (part 1: %s, part 2: %s). Use both from the same update.'):format(versions[1], versions[2])
end
if #problems > 0 then
  reaper.MB(table.concat(problems, '\n\n') .. '\n\nFolder: ' .. dir, 'Presenter', 0)
  return
end

-- the two parts join back into the full script, so line numbers in any
-- error message match the full script
local chunk, err = load(parts[1] .. parts[2], '@Presenter panel.lua')
if not chunk then reaper.MB('The panel could not load:\n' .. tostring(err), 'Presenter', 0) return end
chunk()

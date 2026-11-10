-- @description Presenter panel (launcher for the multi-part copy)
-- Runs the Presenter panel from text files next to this script, named anything
-- ending in part1, part2, ... (e.g. Presenter_panel_part_1.txt; spaces,
-- underscores and hyphens don't matter). Part 1 says how many parts there are.
-- Each part starts and ends with a check line, so a part that was cut off at
-- either end when pasting is caught here with a clear message.
local dir = ({ reaper.get_action_context() })[2]:match('^(.*[\\/])') or ''

local found = {}
local i = 0
while true do
  local name = reaper.EnumerateFiles(dir, i)
  if not name then break end
  local n = name:lower():gsub('[%s_%-]', ''):match('part(%d+)%.txt$')
  if n then found[tonumber(n)] = name end
  i = i + 1
end

local function readPart(n)
  local f = found[n] and io.open(dir .. found[n], 'rb')
  if not f then return nil end
  local text = f:read('a'); f:close()
  return (text:gsub('^\239\187\191', ''))                 -- byte-order mark some editors add
end

-- part 1's first line: "-- @@PRESENTER-PART1-START <version> <total>@@"
local first = readPart(1)
local total = first and tonumber(first:match('^%s*%-%- @@PRESENTER%-PART1%-START %S+ (%d+)@@'))
if not total then
  local why = first and 'Part 1 (' .. found[1] .. ') is missing its first line: the start was cut off or not copied. Paste it again, from the very top.'
    or 'Missing: a .txt file ending in "part1" (e.g. Presenter_panel_part_1.txt)'
  reaper.MB(why .. '\n\nFolder: ' .. dir, 'Presenter', 0)
  return
end

local parts, problems, versions = {}, {}, {}
for n = 1, total do
  local text = readPart(n)
  if not text then
    problems[#problems + 1] = 'Missing: a .txt file ending in "part' .. n .. '" (e.g. Presenter_panel_part_' .. n .. '.txt). There are ' .. total .. ' parts.'
  else
    local ver, body = text:match('^%s*%-%- @@PRESENTER%-PART' .. n .. '%-START (%S-) ' .. total .. '@@\r?\n(.*)$')
    if not ver then
      problems[#problems + 1] = 'Part ' .. n .. ' (' .. found[n] .. ') is missing its first line, or is from a kit with a different number of parts. Paste it again, from the very top.'
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
if #problems == 0 then
  for n = 2, total do
    if versions[n] ~= versions[1] then
      problems[#problems + 1] = ('The parts are from different versions (part 1: %s, part %d: %s). Use all parts from the same update.'):format(versions[1], n, versions[n])
      break
    end
  end
end
if #problems > 0 then
  reaper.MB(table.concat(problems, '\n\n') .. '\n\nFolder: ' .. dir, 'Presenter', 0)
  return
end

-- the parts join back into the full script, so line numbers in any
-- error message match the full script
local chunk, err = load(table.concat(parts), '@Presenter panel.lua')
if not chunk then reaper.MB('The panel could not load:\n' .. tostring(err), 'Presenter', 0) return end
chunk()

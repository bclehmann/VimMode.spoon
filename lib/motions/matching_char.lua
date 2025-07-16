local Motion = dofile(vimModeScriptPath .. "lib/motion.lua")

local stringUtils = dofile(vimModeScriptPath .. "lib/utils/string_utils.lua")
local BackwardSearch = dofile(vimModeScriptPath .. "lib/motions/backward_search.lua")
local ForwardSearch = dofile(vimModeScriptPath .. "lib/motions/forward_search.lua")

local MatchingChar = Motion:new{ name = 'matching_char' }

function forwardSearchGetRangeWithNesting(buffer, beginningChar, endingChar)
  local start = buffer:getCaretPosition()
  local stringStart = start + 1
  local endCharsRequired = 1
  local endIndex = nil

  -- In case we get in an infinite loop :)
  local count = 0
  while (endCharsRequired > 0 and count < 50) do
    local nextStartChar = stringUtils.findNextIndex(
      buffer:getValue(),
      beginningChar,
      stringStart + 1
    )

    local nextEndChar = stringUtils.findNextIndex(
      buffer:getValue(),
      endingChar,
      stringStart + 1
    )

    -- start not present or after first end char
    if (nextStartChar == nil and nextEndChar ~= nil) or (nextStartChar ~= nil and nextEndChar ~= nil and nextEndChar < nextStartChar) then
      endCharsRequired = endCharsRequired - 1
      endIndex = nextEndChar
    end
    

    -- no more end chars
    if nextEndChar == nil then return nil end
    stringStart = nextEndChar
    count = count + 1
  end

  if endIndex ~= nil then
    return {
      start = start,
      finish = endIndex - 1,
      mode = 'inclusive',
      direction = 'characterwise'
    }
  end

  return nil
end

function backwardSearchGetRangeWithNesting(buffer, beginningChar, endingChar)
  local start = buffer:getCaretPosition()
  local stringStart = start
  local endCharsRequired = 1
  local endIndex = nil

  -- In case we get in an infinite loop :)
  local count = 0
  while (endCharsRequired > 0 and count < 50) do
    local nextStartChar = stringUtils.findPrevIndex(
      buffer:getValue(),
      beginningChar,
      stringStart - 1
    )

    local nextEndChar = stringUtils.findPrevIndex(
      buffer:getValue(),
      endingChar,
      stringStart - 1
    )

    -- start not present or after first end char
    if (nextStartChar == nil and nextEndChar ~= nil) or (nextStartChar ~= nil and nextEndChar ~= nil and nextEndChar > nextStartChar) then
      endCharsRequired = endCharsRequired - 1
      endIndex = nextEndChar
    end

    -- no more end chars
    if nextEndChar == nil then return nil end
    stringStart = nextEndChar
    count = count + 1
  end

  if endIndex ~= nil then
    return {
      start = start,
      finish = endIndex - 1,
      mode = 'inclusive',
      direction = 'characterwise'
    }
  end

  return nil
end




charToMatchingChar = {
  ["("] = { ')', false },
  [")"] = { '(', true },
  ["{"] = { '}', false },
  ["}"] = { '{', true },
  ["["] = { ']', false },
  ["]"] = { '[', true },
}

function MatchingChar:getRange(buffer)
  local beginningChar = buffer:charAt(buffer:getCaretPosition())
  local endingChar = charToMatchingChar[beginningChar][1]
  local isBackwards = charToMatchingChar[beginningChar][2]

  if not beginningChar or not endingChar == nil then
    return nil
  end

  if isBackwards then
    local range = backwardSearchGetRangeWithNesting(buffer, beginningChar, endingChar)
    return range
  else
    local range = forwardSearchGetRangeWithNesting(buffer, beginningChar, endingChar)
    return range
  end
 
end

return MatchingChar

---@meta _
--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's API Utilities v1.0.0

Contains miscellaneous functions which are shared by my modules.

--]]

--#REGION ˚♡ Generic ♡˚

--#REGION assert()

---`FOXAPI` Raises an error if the value of its argument v is false (i.e., `nil` or `false`); otherwise, returns all its arguments. In case of error, `message` is the error object; when absent, it defaults to `"assertion failed!"`
---@generic T
---@param v? T
---@param message? any
---@param level? integer
---@return T v
function assert(v, message, level)
  if not v then
    error(
      message or "Assertion failed!", (level or 1) + 1)
  end
  return v
end

--#ENDREGION
--#REGION warn()

---`FOXAPI` Emits a warning with a message.
---@param message any
---@diagnostic disable-next-line: lowercase-global
function warn(message)
  local _, traceback = pcall(function() error(message, 4) end)
  printJson(toJson {
    { text = "[warn] ",              color = "yellow" },
    { text = avatar:getEntityName(), color = "white" },
    " : ", traceback:match("(.*)\n"), "\n",
  })
end

-- Modified from a snippet written by AuriaFoxGirl

--#ENDREGION

--#ENDREGION
--#REGION ˚♡ Client ♡˚

---@class ClientAPI
local _client = figuraMetatables.ClientAPI.__index

--#REGION getAvatarTime()

local initTime = client:getSystemTime()
---`FOXAPI` Gets the length in ticks your avatar has been loaded for.
function _client.getAvatarTime() return math.ceil((client:getSystemTime() - initTime) * 0.02) end

-- Written with help from soomuchlag

--#ENDREGION

--#ENDREGION
--#REGION ˚♡ Vectors ♡˚

---@class VectorsAPI
local _vectors = figuraMetatables.VectorsAPI.__index

--#REGION hexToRGBA()

---`FOXAPI` Parses a hexadecimal string and converts it into a color vector.<br>
---The `#` is optional and the hex color can have any length, though only the first 8 digits are read. If the hex string
---is 4 digits long, it is treated as a short hex string. (`#ABCD` == `#AABBCCDD`)<br>
---Returns `⟨0, 0, 0, 1⟩` if the hex string is invalid.<br>
---Some special strings are also accepted in place of a hex string.
---@param hex string
---@return Vector4
---@nodiscard
function _vectors.hexToRGBA(hex)
  local _type = type(hex)
  assert(_type == "string", "Expected string, got " .. _type, 2)
  return hex:find("#") and vectors.hexToRGB(hex):augmented(#hex > 5 and
    tonumber(hex:match("#?%x%x%x%x%x%x(%x%x)") or "ff", 16) / 255 or
    tonumber(hex:match("#?%x%x%x(%x)") or "f", 16) / 15
  ) or vectors.hexToRGB(hex):augmented(1)
end

-- Written by AuriaFoxGirl, modified slightly to allow for strings

--#ENDREGION
--#REGION intToRGBA()

---`FOXAPI` Converts the given integer into a color vector.<br>
---If `int` is `nil`, it will default to `0`.<br>
---@param int integer
function _vectors.intToRGBA(int)
  local _type = type(int)
  assert(_type == "number", "Expected integer, got " .. _type, 2)
  return vec(
    math.floor(int / 0x10000) % 0x100 / 255,
    math.floor(int / 0x100) % 0x100 / 255,
    int % 0x100 / 255,
    math.floor(int / 0x1000000) % 0x100 / 255
  )
end

--#ENDREGION
--#REGION hsvToRGBA()

---`FOXAPI` Converts the given HSV values to a color vector.<br>
---If `h`, `s`, `v`, or `a` are `nil`, they will default to `0`.
---@overload fun(hsva?: Vector4): Vector4
---@overload fun(h?: number, s?: number, v?: number, a?: number): Vector4
function _vectors.hsvToRGBA(...)
  local args = { ... }
  local _type = type(args[1])
  assert(_type == "Vector4" or _type == "number", "Expected Vector4 or number, got " .. _type, 2)
  return _type == "Vector4" and vectors.hsvToRGB(args[1].xyz):augmented(args[1].w) or
      vectors.hsvToRGB(args[1], args[2], args[3]):augmented(args[4])
end

--#ENDREGION

--#ENDREGION
--#REGION ˚♡ Config ♡˚

---@class ConfigAPI
local _config = figuraMetatables.ConfigAPI.__index

--#REGION saveTo()

---`FOXAPI` Saves the given key and value to the provided config file without changing the active config file.<br>
---If `value` is `nil`, the key is removed from the config.
---@param file string
---@param name string
---@param value any
function _config:saveTo(file, name, value)
  local prevConfig = config:getName()
  config:setName(file):save(name, value)
  config:setName(prevConfig)
end

--#ENDREGION
--#REGION loadFrom()

---`FOXAPI` Loads the given key from the provided config file without changing the active config file.
---@param file string
---@param name string
---@return any
---@nodiscard
function _config:loadFrom(file, name)
  local prevConfig = config:getName()
  local load = config:setName(file):load(name)
  config:setName(prevConfig)
  return load
end

--#ENDREGION

--#ENDREGION
--#REGION ˚♡ Table ♡˚

--#REGION contains()

---`FOXAPI` Determines whether a value is contained within a table. Returns `true` if the value is contained, else it returns `false`.
---@param list table
---@param value any
---@return boolean
---@nodiscard
function table.contains(list, value)
  return toJson(list):find(tostring(value)) and true or false
end

--#ENDREGION
--#REGION quickFind()

---`FOXAPI` Returns the key of the first value found in the table as a string. Generally uses less instructions than `find()`. Returns `nil` if not found.
---@param list table
---@param value any
---@return any key
---@nodiscard
function table.quickFind(list, value)
  local json = toJson(list)
  if json:find("%b[]") then
    return select(2, json:match("(.*)" .. tostring(value)):gsub(",", ",")) + 1
  else
    return json:match('"(.*)":"' .. tostring(value))
  end
end

--#ENDREGION
--#REGION match()

---`FOXAPI` Match the first value in the table. Returns an empty table if nothing was found.
---@param list table
---@param pattern string
---@return string match
---@nodiscard
function table.match(list, pattern)
  for match in toJson(list):gmatch(pattern) do
    return match
  end
  return nil
end

--#ENDREGION
--#REGION gmatch()

---`FOXAPI` Match all the values that match the given value in the table. Returns an empty table if nothing was found.
---@param list table
---@param pattern string
---@return table matches
---@nodiscard
function table.gmatch(list, pattern)
  local matches = {}
  for match in toJson(list):gmatch(pattern) do
    table.insert(matches, match)
  end
  return matches
end

--#ENDREGION
--#REGION find()

---`FOXAPI` Returns the raw key of the first value found in the table. Returns `nil` if not found.
---@param list table
---@param value any
---@return any key
---@nodiscard
function table.find(list, value)
  if not table.contains(list, value) then return nil end
  local key
  for k, v in pairs(list) do if value == v then key = k end end
  return key
end

--#ENDREGION
--#REGION invert()


---`FOXAPI` Returns an inverted table with all keys becoming values and values becoming keys.
---@nodiscard
function table.invert(table)
  local _table = {}
  for key, value in pairs(table) do
    _table[value] = key
  end
  return _table
end

--#ENDREGION

--#ENDREGION
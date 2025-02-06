--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's API v1.1.3

An API containing several modules, each with their own functionality.
Modules can be added or removed depending on what features you wish to use.

--]]

---FOX's API metatable with events and modules
---@class FOXAPI.metatable
FOXMetatable = {
  __events = {},
  __registeredEvents = {},
  __modules = {},
}
---FOX's API module functions and resources
---@class FOXAPI
FOXAPI = setmetatable({}, FOXMetatable)
local _ver = { "1.1.3", 8 }
---@diagnostic disable: param-type-mismatch

--#REGION ˚♡ Events ♡˚

--#REGION ˚♡ Custom event registration ♡˚

---@class EventsAPI
---@field new fun(self: EventsAPI, eventName: string)
---@field newRaw fun(self: EventsAPI, eventName: string, event: {[string]: function})
---@field call fun(self: EventsAPI, eventName: string, ...?: any): any[]
local _e, _Re = FOXMetatable.__events, FOXMetatable.__registeredEvents
local s_l, s_u = string.lower, string.upper

---`FOXAPI` Registers a custom event that can be called like a normal event
function _e:new(eN)
  local e = {
    clear = function()
      _Re[eN] = {}
    end,
    getRegisteredCount = function(_, name)
      return _Re[eN][name] and _Re[eN][name]._n or 0
    end,
    register = function(_, func, name)
      if name then
        _Re[eN][name] = _Re[eN][name] or { _n = 0 }
        _Re[eN][name][func] = func
      else
        _Re[eN][func] = func
      end
    end,
    remove = function(_, callback)
      local n = 0
      if _Re[eN][callback] then
        n = type(callback) == "string" and _Re[eN][callback].n or 1
        _Re[eN][callback] = nil
      end
      return n
    end,
  }
  _Re[eN] = {}
  _e[s_l(eN)] = e
  _e[s_u(eN)] = e
end

---`FOXAPI` Registers a custom event that can be called like a normal event. The passed table must have a `register` function
function _e:newRaw(eN, tbl)
  _Re[eN] = {}
  _e[s_l(eN)] = tbl
  _e[s_u(eN)] = tbl
end

---`FOXAPI` Calls a custom event and runs all their functions
function _e:call(eN, ...)
  local retTbl = {}
  local ret_index = 0
  for _, func in pairs(_Re[eN]) do
    local ret
    if type(func) == "function" then
      ret = func(...)
      ret_index = ret_index + 1
      retTbl[ret_index] = ret
    elseif type(func) == "table" then
      for _, _func in pairs(func) do
        if type(_func) == "function" then
          ret = _func(...)
          ret_index = ret_index + 1
          retTbl[ret_index] = ret
        end
      end
    end
  end
  return retTbl
end

--#ENDREGION
--#REGION ˚♡ Custom event handler ♡˚

local E = figuraMetatables.EventsAPI
local E_i_ = E.__index
local E_ni = E.__newindex

function E:__index(key)
  return _e[key] or E_i_(self, key)
end

function E:__newindex(key, value)
  if _e[key] then
    _e[key]:register(value)
  else
    E_ni(self, key, value)
  end
end

--#ENDREGION

--#ENDREGION
--#REGION ˚♡ Utilities ♡˚

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
    error(message or "Assertion failed!", (level or 1) + 1)
  end
  return v
end

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
---@param hex string?
---@return Vector4
---@nodiscard
function _vectors.hexToRGBA(hex)
  hex = hex or ""
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
---@param int integer?
---@return Vector4
---@nodiscard
function _vectors.intToRGBA(int)
  int = int or 0
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
---@nodiscard
function _vectors.hsvToRGBA(...)
  local args = { ... }
  local _type = type(args[1])
  return _type == "Vector4" and
      vectors.hsvToRGB(args[1].xyz or vec(0, 0, 0)):augmented(args[1].w or 1) or
      vectors.hsvToRGB(args[1] or 0, args[2] or 0, args[3] or 0):augmented(args[4] or 1)
end

--#ENDREGION
--#REGION random()

---`FOXAPI` Works the same as math.random, except you have to insert the length of the output vector as a number `l`, and can use vectors for `m` and `n`.
---* `vectors.random(l)`: Returns a vector of `l` length, of floats in the range [0,1).
---* `vectors.random(l, n)`: Returns a vector of `l` length, of integers in the range [1, n].
---* `vectors.random(l, m, n)`: Returns a vector of `l` lenght, of integers in the range [m, n].
---@param l? number
---@param m? number|Vector
---@param n? number|Vector
---@return Vector
---@nodiscard
function _vectors.random(l, m, n)
  l = math.clamp(l or 3, 2, 4)
  local vec = vectors["vec" .. l]()
  m = type(m):find("Vector") and m or (m and vec + m)
  n = type(n):find("Vector") and n or (n and vec + n)

  for i = 1, l do
    if m and n then
      vec[i] = math.random(m[i], n[i])
    elseif m then
      vec[i] = math.random(m[i])
    else
      vec[i] = math.random()
    end
  end
  return vec
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
---@param value? any
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

---`FOXAPI` Returns whether the pattern matches the table. Uses json.
---@param tbl table
---@param pattern string
---@return boolean
---@nodiscard
function table.contains(tbl, pattern)
  assert(type(pattern) == "string", "The value must be a string!", 2)
  return toJson(tbl):find(pattern) and true or false
end

--#ENDREGION
--#REGION match()

---`FOXAPI` Return the first match in the table. Uses json.
---@param tbl table
---@param pattern string
---@return string? match
---@nodiscard
function table.match(tbl, pattern)
  assert(type(pattern) == "string", "The pattern must be a string!", 2)
  return toJson(tbl):match(pattern)
end

--#ENDREGION
--#REGION gmatch()

---`FOXAPI` Match all the values that match the given value in the table. Uses json.
---@param tbl table
---@param pattern string
---@return table matches
---@nodiscard
function table.gmatch(tbl, pattern)
  assert(type(pattern) == "string", "The pattern must be a string!", 2)
  local matches = {}
  for match in toJson(tbl):gmatch(pattern) do
    table.insert(matches, match)
  end
  return matches
end

--#ENDREGION
--#REGION invert()

---`FOXAPI` Returns an inverted table with all keys becoming values and values becoming keys.
---@param tbl table
---@return table
---@nodiscard
function table.invert(tbl)
  local _table = {}
  for key, value in pairs(tbl) do
    _table[value] = key
  end
  return _table
end

--#ENDREGION

--#ENDREGION

--#ENDREGION
--#REGION ˚♡ Module Loading ♡˚

local lang = {
  invalidPath = "§4FOXAPI was not installed correctly!§c",
  modUnknown = '§4Unknown script "%s" found in FOXAPI modules folder!§c',
  modOutdated = "§4%s requires a newer version of FOXAPI! Expected v%s, installed version v%s§c",
  depMissing = '§4"%s" requires "%s" which wasn\'t found!§c',
  depOutdated = "§4%s is outdated! A version of v%s or newer is required by another module!§c",
  loadSuccess = "FOXAPI successfully loaded %i modules!",
}
local apiPath = ...

assert(apiPath:find("FOXAPI"), "\n" .. lang.invalidPath, 2)
local modulePaths = listFiles(apiPath .. ".modules", true)

local req = {}
local _m = FOXMetatable.__modules
local s_f = string.format

-- Search through API for modules

for i = 1, #modulePaths do
  local path = modulePaths[i]
  local m = (__race and path == __race[1]) and __race[2] or require(path)
  assert(m._api[1] == "FOXAPI", s_f("\n" .. lang.modUnknown, path:match("modules.%s*(.*)")), 2)
  assert(m._api[3] <= _ver[2], s_f("\n" .. lang.modOutdated, m._name, m._api[2], _ver[1]), 2)
  _m[m._name] = m
  if m._require then req[m._name] = m._require[1] end
end

-- Handle a module requiring another module

for name, rName in pairs(req) do
  assert(_m[rName], s_f("\n" .. lang.depMissing, name, rName), 2)
  assert(_m[rName]._ver[2] >= _m[name]._require[3],
    s_f("\n" .. lang.depOutdated, rName, _m[name]._require[2]), 2)
end

--#ENDREGION

avatar:store("FOXAPI", { _ver = _ver, _mod = _m })
return FOXAPI

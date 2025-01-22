--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's API v1.0.0

An API containing several modules, each with their own functionality.
Modules can be added or removed depending on what features you wish to use.

--]]

local debug = false -- Set this to true to enable logging the amount of modules that have been loaded

---FOX's API
---@class FOXAPI
FOXAPI = setmetatable({}, { __race = {}, __events = {}, __registeredEvents = {} })
local _ver = { "1.0.1", 2 }

local apiPath = ...

--#REGION ˚♡ Require Utilities, and Events ♡˚

local lib = { "Utilities", "Events" }
for i = 1, 2 do
  if i == 2 and __race == "events" then
    __race = nil
    return
  end
  local str = lib[i]
  local path = apiPath .. "/lib/" .. str:lower()
  assert(pcall(function() require(path) end),
    "\n§4Could not find FOX's API " .. str .. "§c")
  require(path)
end

--#ENDREGION
--#REGION ˚♡ Require modules ♡˚

assert(apiPath:find("FOXAPI"), "\n§4FOX's API was not installed correctly!§c", 2)
local modulePaths = listFiles(apiPath .. ".modules", true)
---@type any[]
local modules = { _n = 0 }
local requiredModules = {}

-- Search through API for modules
for i = 1, #modulePaths do
  local path = modulePaths[i]
  local module = (__race and path == __race[1]) and __race[2] or require(path)
  assert(type(module) == "table" and module._api[1] == "FOXAPI",
    string.format('\n§4Unknown script "%s" found in FOXAPI modules folder!§c',
      path:match("modules.%s*(.*)")), 2)
  assert(type(module) == "table" and module._api[3] <= _ver[2],
    string.format(
      "\n§4%s requires a newer version of FOX's API! Expected v%s, installed version is v%s§c",
      module._name, module._api[2], _ver[1]), 2)
  modules[module._name] = module
  if module._require then
    requiredModules[module._name] = module._require[1]
  end
  modules._n = modules._n + 1
end
if modules._n == 0 then
  warn("\n§6FOX's API could not find any modules to load!§e")
end

-- Handle a module requiring another module
for name, requiredName in pairs(requiredModules) do
  assert(modules[requiredName], string.format('\n§4"%s" requires "%s" which wasn\'t found!§c',
    name, requiredName), 2)
  assert(modules[requiredName]._ver[2] >= modules[name]._require[3],
    string.format("\n§4%s is outdated! A version of v%s or newer is required by another module!§c",
      requiredName, modules[name]._require[2]), 2)
end

if debug then printJson(string.format("FOX's API successfully loaded %i modules!\n", modules._n)) end

--#ENDREGION

avatar:store("FOXAPI", { _ver = _ver, _mod = modules })
return FOXAPI

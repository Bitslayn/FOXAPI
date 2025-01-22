---@meta _
--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's API Events v1.0.0

Handles creating and firing custom events.

--]]

local debugMode = false -- Set this to true to log custom event timings when running events:call()

local apiPath = ...
if not FOXAPI then
  __race = "events"
  require(apiPath:match("(.*)lib") .. "api")
end

--#REGION ˚♡ Custom event registration ♡˚

local FOXMetatable = getmetatable(FOXAPI)

---@class EventsAPI
FOXMetatable.__events = FOXMetatable.__events

---`FOXAPI` Registers a custom event that can be called like a normal event
function FOXMetatable.__events:new(eventName)
  local event = {
    clear = function()
      FOXMetatable.__registeredEvents[eventName] = {}
    end,

    getRegisteredCount = function(_, name)
      return FOXMetatable.__registeredEvents[eventName][name] and
          FOXMetatable.__registeredEvents[eventName][name]._n or 0
    end,

    register = function(_, func, name)
      if name then
        FOXMetatable.__registeredEvents[eventName][name] =
            FOXMetatable.__registeredEvents[eventName][name] or { _n = 0 }
        FOXMetatable.__registeredEvents[eventName][name][func] = func
      else
        FOXMetatable.__registeredEvents[eventName][func] = func
      end
    end,

    remove = function(_, callback)
      local n = 0
      if FOXMetatable.__registeredEvents[eventName][callback] then
        n = type(callback) == "string" and FOXMetatable.__registeredEvents[eventName][callback].n or
            1
        FOXMetatable.__registeredEvents[eventName][callback] = nil
      end
      return n
    end,
  }
  FOXMetatable.__registeredEvents[eventName] = {}
  FOXMetatable.__events[eventName:lower()] = event
  FOXMetatable.__events[eventName:upper()] = event
end

---`FOXAPI` Calls a custom event and runs all their functions
function FOXMetatable.__events:call(eventName, ...)
  assert(self == events, string.format("bad argument: userdata expected, got %s", type(self)))
  local retTbl = {}
  local ret_index = 0
  local startTime = client:getSystemTime()
  for _, func in pairs(FOXMetatable.__registeredEvents[eventName]) do
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
  if debugMode and host:isHost() then
    print(string.format("Successfully called %d %s event%s in %dms", ret_index, eventName,
      ret_index == 1 and "" or "s", client:getSystemTime() - startTime))
  end
  return retTbl
end

--#ENDREGION
--#REGION ˚♡ Custom event handler ♡˚

local Events_index = figuraMetatables.EventsAPI.__index
local Events_newindex = figuraMetatables.EventsAPI.__newindex

function figuraMetatables.EventsAPI:__index(key)
  return FOXMetatable.__events[key] or Events_index(self, key)
end

function figuraMetatables.EventsAPI:__newindex(key, value)
  if FOXMetatable.__events[key] then
    FOXMetatable.__events[key]:register(value)
  else
    Events_newindex(self, key, value)
  end
end

--#ENDREGION

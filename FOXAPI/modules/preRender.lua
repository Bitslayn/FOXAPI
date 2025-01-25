---@meta _
--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
Pre Render Event Module v1.0.0
A FOXAPI Module

Registers a custom PRE_RENDER event.

--]]

local apiPath, moduleName = ...
assert(apiPath:find("FOXAPI.modules"), "\n§4FOX's API was not installed correctly!§c")
local _module = {
  _api = { "FOXAPI", "1.0.0", 1 },
  _name = "Pre Render Event",
  _desc = "Registers a custom PRE_RENDER event.",
  _ver = { "1.0.0", 1 },
}
if not FOXAPI then
  __race = { apiPath:gsub("/", ".") .. "." .. moduleName, _module }
  require(apiPath:match("(.*)modules") .. "api")
end

--#REGION ˚♡ PRE_RENDER event ♡˚

local FOXMetatable = getmetatable(FOXAPI)

---@class EventsAPI
---`FOXAPI` This event runs before modelparts render.
---> ```lua
---> (callback) function(delta: number, ctx: string, matrix: Matrix4)
---> ```
---> ***
---> A callback that is given the current tick delta, the context that the avatar is rendering in, and the matrix used
---> to render the avatar.
---@field PRE_RENDER Event.Render | Event.Render.func
---`FOXAPI` This event runs before modelparts render.
---> ```lua
---> (callback) function(delta: number, ctx: string, matrix: Matrix4)
---> ```
---> ***
---> A callback that is given the current tick delta, the context that the avatar is rendering in, and the matrix used
---> to render the avatar.
---@field pre_render Event.Render | Event.Render.func
FOXMetatable.__events = FOXMetatable.__events
FOXMetatable.__registeredEvents.pre_render = {}

local isHost = host:isHost()

local _PRE_RENDER = {
  clear = function()
    for _, callback in pairs(FOXMetatable.__registeredEvents.pre_render) do
      if type(callback) == "table" then
        for _, value in pairs(callback) do
          value:remove()
        end
      elseif type(callback) == "ModelPart" then
        callback:remove()
      end
    end
    FOXMetatable.__registeredEvents.pre_render = {}
  end,

  getRegisteredCount = function(_, name)
    return FOXMetatable.__registeredEvents.pre_render[name] and
        FOXMetatable.__registeredEvents.pre_render[name]._n or 0
  end,

  register = function(_, func, name)
    local random = math.random()
    if name then
      FOXMetatable.__registeredEvents.pre_render[name] = FOXMetatable.__registeredEvents.pre_render
          [name] or
          { _n = 0 }
      FOXMetatable.__registeredEvents.pre_render[name][func] = models
          :newPart("_eventsProxy-" .. random, isHost and "Gui" or nil)
          :setPreRender(func)
      FOXMetatable.__registeredEvents.pre_render[name]._n = FOXMetatable.__registeredEvents
          .pre_render[name]._n +
          1
    else
      FOXMetatable.__registeredEvents.pre_render[func] = models
          :newPart("_eventsProxy-" .. random, isHost and "Gui" or nil)
          :setPreRender(func)
    end
  end,

  remove = function(_, callback)
    local n = 0
    if type(callback) == "string" then
      for _, value in pairs(FOXMetatable.__registeredEvents.pre_render[callback]) do
        if type(value) == "ModelPart" then
          value:remove()
          n = n + 1
        end
      end
      FOXMetatable.__registeredEvents.pre_render[callback] = nil
    elseif type(callback) == "function" then
      FOXMetatable.__registeredEvents.pre_render[callback]:remove()
      n = 1
    end
    return n
  end,
}

FOXMetatable.__events.PRE_RENDER = _PRE_RENDER
FOXMetatable.__events.pre_render = _PRE_RENDER

--#ENDREGION

return _module

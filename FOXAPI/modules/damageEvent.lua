---@meta _
--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's Damage Event v1.0.1
A FOXAPI Module

Creates a custom event which fires whenever an entity is damaged.

Github Download: https://github.com/Bitslayn/FOXAPI/blob/main/FOXAPI/modules/damageEvent.lua
Github Docs: https://github.com/Bitslayn/FOXAPI/wiki/Damage-Event

--]]

-- Do not touch anything in this file unless you know what you are doing!

local apiPath, moduleName = ...
assert(apiPath:find("FOXAPI.modules"), "\n§4FOX's API was not installed correctly!§c")
local _module = {
  _api = { "FOXAPI", "1.1.3", 8 },
  _name = "FOX's Damage Event",
  _desc = "Creates a custom event which fires whenever an entity is damaged.",
  _ver = { "1.0.1", 2 },
}
if not FOXAPI then
  __race = { apiPath:gsub("/", ".") .. "." .. moduleName, _module }
  require(apiPath:match("(.*)modules") .. "api")
end

--#REGION ˚♡ Config ♡˚

-- How long in ticks should your attacks be held for when determining damage sources. Heavily depends on ping.
-- If it takes more than this amount of ticks for the server to register you've attacked something, increase this number.
local sourceTimeout = 10

--#ENDREGION
--#REGION ˚♡ Entity Locator ♡˚

local entities = {}

---@param id Minecraft.soundID
function events.on_play_sound(id, pos, _, _, _, _, path)
  if not path then return end
  if not (id:find("entity") or id:find("step") or id:find("hurt") or id:find("death")) then return end

  local entity = raycast:entity(pos, pos + vec(0, 1, 0))
  ---@diagnostic disable-next-line: undefined-field
  if not (entity and entity.getHealth) then return end

  local type = entity:getType()
  local uuid = entity:getUUID()
  entities[type] = entities[type] or {}
  entities[type][uuid] = { entity = entity, health = nil }
end

--#ENDREGION
--#REGION ˚♡ Listen for Pain ♡˚

events:new("entity_damage")

local targets = {}

local function checkHealth(type)
  if not entities[type] then return end
  for uuid, tbl in pairs(entities[type]) do
    local healthType = tbl.oldHealth and "newHealth" or "oldHealth"
    tbl[healthType] = tbl.entity:getHealth()
    if tbl.oldHealth == 0 or tbl.newHealth == 0 then
      entities[type][uuid] = nil
    end
    if healthType == "newHealth" then
      local damage = tbl.oldHealth - tbl.newHealth
      if damage > 0 then
        events:call("damage", tbl.entity, targets[uuid] and player or nil, damage)
      end
      tbl.newHealth = nil
      tbl.oldHealth = nil
      targets[uuid] = nil
    end
  end
end

local checkQueue = {}

function events.on_play_sound(id, _, _, _, _, _, path)
  if not path then return end
  if not (id:find("hurt") or id:find("death")) then return end
  local type = table.concat({ id:match("^(.-):entity%.(.-)%..-$") }, ":")

  checkHealth(type)
  checkQueue[type] = 2
end

function events.tick()
  for type, tick in pairs(checkQueue) do
    checkQueue[type] = tick - 1
    if checkQueue[type] > 0 then return end
    checkHealth(type)
    checkQueue[type] = nil
  end
end

--#ENDREGION
--#REGION ˚♡ Source ♡˚

--#REGION ˚♡ Swinging ♡˚

function events.render()
  if not player:isSwingingArm() then return end
  local entity = player:getTargetedEntity(4.5)
  if not entity then return end
  local uuid = entity:getUUID()
  targets[uuid] = sourceTimeout
end

--#ENDREGION
--#REGION ˚♡ Projectiles ♡˚

local function projectileEvent(_, projectile)
  local pos = projectile:getPos()
  local entity = raycast:entity(pos, pos + projectile:getVelocity(), function(entity)
    return entity:isAlive() -- Make sure entity doesn't target itself
  end)
  if not entity then return end
  local uuid = entity:getUUID()
  targets[uuid] = sourceTimeout
end

local projectileEvents = { "trident_render", "arrow_render" }
for _, eventName in pairs(projectileEvents) do
  events[eventName]:register(projectileEvent)
end

--#ENDREGION
--#REGION ˚♡ Flush Sources ♡˚

function events.tick()
  for uuid, tick in pairs(targets) do
    targets[uuid] = tick - 1
    if targets[uuid] <= 0 then
      targets[uuid] = nil
    end
  end
end

--#ENDREGION

--#ENDREGION
--#REGION ˚♡ Annotations ♡˚

local FOXMetatable = getmetatable(FOXAPI)

---@class Event.Damage: Event
---@alias Event.Damage.func
---| fun(entity: Entity, source: Player|nil, damage: number)
---@class EventsAPI
---`FOXAPI` This event runs when any entity takes damage.
---> ```lua
---> (callback) function(entity: Entity, source: Player|nil, damage: number)
---> ```
---> ***
---> A callback that is given the data of the entity taking damage, the entity which dealt the damage or nil (can only be player due to limitations), and the amount of damage taken.
---@field entity_damage Event.Damage | Event.Damage.func
---`FOXAPI` This event runs when any entity takes damage.
---> ```lua
---> (callback) function(entity: Entity, source: Player|nil, damage: number)
---> ```
---> ***
---> A callback that is given the data of the entity taking damage, the entity which dealt the damage or nil (can only be player due to limitations), and the amount of damage taken.
---@field ENTITY_DAMAGE Event.Damage | Event.Damage.func
FOXMetatable.__events = FOXMetatable.__events

--#ENDREGION

return _module

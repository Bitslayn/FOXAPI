---@meta _
--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's AFK Module v1.0.0
A FOXAPI Module

Lets you create an AFK timer in your nameplate and run functions while you're AFK.

Github Download: https://github.com/Bitslayn/FOXAPI/blob/main/FOXAPI/modules/afk.lua
Github Docs: https://github.com/Bitslayn/FOXAPI/wiki/FoxAFK

--]]

-- Do not touch anything in this file unless you know what you are doing!

local apiPath, moduleName = ...
assert(apiPath:find("FOXAPI.modules"), "\n§4FOX's API was not installed correctly!§c")
local _module = {
  _api = { "FOXAPI", "1.1.2", 7 },
  _name = "FOX's AFK Module",
  _desc = "Lets you create an AFK timer in your nameplate and run functions while you're AFK.",
  _ver = { "1.0.0", 1 },
}
if not FOXAPI then
  __race = { apiPath:gsub("/", ".") .. "." .. moduleName, _module }
  require(apiPath:match("(.*)modules") .. "api")
end
---@diagnostic disable: missing-fields

--#REGION ˚♡ Global Variables ♡˚

FOXAPI.afk = {}
FOXAPI.afk.config = {}
local mod = FOXAPI.afk
local cfg = mod.config

--#ENDREGION
--#REGION ˚♡ Main ♡˚

--#REGION ˚♡ Helper Functons ♡˚

--#REGION ˚♡ Format Timer ♡˚

local hmmss, mss = "%d:%02d:%02d", "%d:%02d" -- Time formatting codes DO NOT MODIFY

-- Converts time in ticks to a readable format
local function formatTime(tick)
  local rawSeconds = math.floor(tick / 20)

  local hours, minutes, seconds =
      math.floor(rawSeconds / 3600), math.floor((rawSeconds % 3600) / 60), rawSeconds % 60

  -- Format the time, including the hours when the player is AFK for longer than an hour
  return hours > 0 and (cfg.hmmss or hmmss):format(hours, minutes, seconds) or
      (cfg.mss or mss):format(minutes, seconds)
end

--#ENDREGION
--#REGION ˚♡ Checks ♡˚

local lookDir -- The last recorded look direction

-- Checks if the look direction changes
local function checkLookDir()
  local currentLookDir = player:getLookDir()
  if lookDir == currentLookDir then return end
  lookDir = currentLookDir
  return true
end

local keyPressed -- Becomes true a key was pressed

-- Checks if a key was pressed since the last check
local function checkKeyPressed()
  if not keyPressed then return end
  keyPressed = false
  return true
end

-- Functionally check if a movement key was pressed
function events.key_press()
  if not player:isLoaded() or host:getScreen() then return end
  if player:getVelocity():length() == 0 then return end
  keyPressed = true
end

--#ENDREGION

--#ENDREGION
--#REGION ˚♡ Timers ♡˚

local _world_getTime = world.getTime

local internalTimer = 1               -- The internal timer, limiting how often this module runs checks and updates the nameplate
local idle = true                     -- Becomes false when the timer and delay are equal. Functions are allowed to run when not idle.
local AFKoverride = false             -- When this is true, forces the player to be AFK. This becomes false the next time the player does something to get out of AFK
local afkTimestamp = _world_getTime() -- The time it was when you were last AFK
local format = " [AFK %s]"            -- How the AFK string should be formatted DO NOT MODIFY
local blank = ""
mod.afkTick = 0                       -- The actual amount of time the player has been AFK for
mod.isAFK = false                     -- Whether or not the player is currently AFK

-- Run the timers and checks every timeInterval ticks
local function runTimers()
  -- Wait until internal timer expires
  local delay = cfg.timeDelay or 10
  internalTimer = internalTimer % delay + 1
  idle = internalTimer ~= delay
  if idle then return end

  -- Run this every timer expiry
  mod.afkTick = _world_getTime() - afkTimestamp
  mod.isAFK = (cfg.timeUntilAFK or 2400) <= mod.afkTick or AFKoverride
  mod.afk = formatTime(mod.afkTick)
  mod.fancyAFK = mod.isAFK and (cfg.fancyFormatting or format):format(mod.afk) or blank

  -- Stop here if the player isn't doing anything or cannot be checked for actions
  if not player:isLoaded() then return end
  if not (checkLookDir() or checkKeyPressed()) then return end

  -- Run if the player is no longer AFK
  afkTimestamp = _world_getTime()
  if not mod.isAFK then return end

  -- Run this if the player was just AFK
  AFKoverride = false
  pings.foxafk(false)
end

--#ENDREGION
--#REGION ˚♡ Pings ♡˚

---Set the current AFK state.
---
---If the value is `true`, forces the player to be AFK. If it is `false`, resets the AFK timer and makes the player no longer AFK.
---
---If the value is a number, sets the AFK timestamp. (World time since player last did an action)
---@param value number|boolean
function pings.foxafk(value)
  local _type = type(value)
  if _type == "number" then
    afkTimestamp = value
  elseif _type == "boolean" then
    AFKoverride = value
    if value then return end
    afkTimestamp = _world_getTime()
  end
end

-- Reping
if host:isHost() then
  local repingTimer = 1 -- The current reping tick

  -- Run the reping timer
  function events.tick()
    -- Wait until reping timer expires
    repingTimer = repingTimer % (cfg.repingDelay or 800) + 1
    if repingTimer ~= (cfg.repingDelay or 800) then return end

    -- Run this every timer expiry
    pings.foxafk(afkTimestamp)
  end
end

--#ENDREGION
--#REGION ˚♡ Nameplate Handler ♡˚

local originalMethods = {}
local afkNameplates = {} -- All the nameplate texts before replacing the ${afk}
local placeholder = "${afk}"

function events.post_render() -- Using post_render here because the ${afk} has to be replaced last (Paladin please make a post_tick I beg you)
  if idle then return end
  if not mod.afk then return end
  for self, tbl in pairs(afkNameplates) do
    -- Replace the ${afk} in the nameplates with either the fancy timestamp or a blank string
    originalMethods[tbl[1]](self, tbl[2]:gsub(placeholder, mod.fancyAFK))
  end
end

local listSelf -- The original self of list nameplates

-- This function runs on post_world_render for player list nameplates if the unloaded config is true
local function playerlistNameplate()
  if idle then return end
  local tbl = afkNameplates[listSelf]
  if not (mod.afk and tbl) then return end
  -- Replace the ${afk} in the nameplates with either the fancy timestamp or a blank string
  originalMethods[tbl[1]](listSelf, tbl[2]:gsub(placeholder, mod.fancyAFK))
end

--#ENDREGION

--#ENDREGION
--#REGION ˚♡ Initialization ♡˚

--#REGION ˚♡ Helper Functions ♡˚

--#REGION ˚♡ Overwrite Nameplate Metatables ♡˚

-- The metatables to be asserted into
local metatables = {
  figuraMetatables.NameplateCustomization,
  figuraMetatables.EntityNameplateCustomization,
  figuraMetatables.NameplateCustomizationGroup,
}

-- Overwrites all the nameplate customization indexes to append custom methods
local function overwriteMetatables()
  for _, meta in pairs(metatables) do
    local meta_index = meta.__index
    originalMethods[meta_index] = meta_index.setText
    meta_index.setText = function(self, text)
      listSelf = self == nameplate.LIST and self or listSelf
      afkNameplates[self] = (text and text:find(placeholder)) and { meta_index, text }
      originalMethods[meta_index](self, text and text:gsub(placeholder, mod.fancyAFK or blank))
      return self
    end
  end
end

--#ENDREGION
--#REGION ˚♡ Update Nameplates ♡˚

-- Every nameplate type
local nameplateTypes = { nameplate.CHAT, nameplate.ENTITY, nameplate.LIST }

-- What the nameplates are set to during post-init
local nameplateCache = {}

-- Since the metatables are overwritten during post-init, this runs to make sure all nameplates are updated
local function updateNameplates()
  for _, object in pairs(nameplateTypes) do
    object:setText(nameplateCache[object])
  end
end

-- Makes sure the player's playerlist nameplate's ${afk} is set even when the unloaded config is false
local function fixPlayerlistNameplate()
  for _, object in pairs(nameplateTypes) do
    local text = object:getText()
    nameplateCache[object] = text
    object:setText(text and text:gsub(placeholder, blank))
  end
end

--#ENDREGION

--#ENDREGION
--#REGION ˚♡ Post-Init ♡˚

local tickType                -- The type of tick instruction used
local targetType, currentType -- The instruction type that is currently used to run timers

-- Allows for the timers to be hotswapped to and from world_tick depending on if the player is loaded
local function hotswapTimers()
  targetType = player:isLoaded() and "tick" or tickType
  if currentType ~= targetType then
    local lastTimersType = currentType
    events[targetType]:register(runTimers)
    currentType = targetType
    if not lastTimersType then return end
    events[lastTimersType]:remove(runTimers)
  end
end

-- The top function is called by the bottom function in either `world_tick` or `tick` depending on the unloaded config

local function postInit()
  events[tickType]:remove(postInit)
  overwriteMetatables()
  updateNameplates()
end

local waitTick = 0 -- Timer used to delay initialization
local permissionLevels = { HIGH = true, MAX = true }

local function postInitMain()
  -- Wait a tick before initializing
  waitTick = waitTick + 1
  if waitTick ~= 2 then return end
  events.world_tick:remove(postInitMain)
  fixPlayerlistNameplate()

  tickType = (type(cfg.runUnloaded) == "nil" and permissionLevels[avatar:getPermissionLevel()] or cfg.runUnloaded) and
      "world_tick" or "tick"
  if not (type(cfg.usePlaceholder) == "nil" or cfg.usePlaceholder) then return end
  events[tickType]:register(postInit) -- Initialize nameplate metatables and handlers
  if cfg.runUnloaded == false then
    events.tick:register(runTimers)
  else
    events.world_tick:register(hotswapTimers)
  end
  if not tickType then return end
  events.post_world_render:register(playerlistNameplate)
end
events.world_tick:register(postInitMain)

--#ENDREGION

--#ENDREGION
--#REGION ˚♡ Annotations ♡˚

if false then
  ---@class afk
  ---@field afkTick integer The current time in ticks you've been AFK for.
  ---@field isAFK boolean Whether or not you're currently AFK.
  ---@field afk string The formatted time you've been AFK for like `3:00` for `3600` ticks.
  ---@field fancyAFK string The fancy formatted time you've been AFK for like ` [AFK 3:00]` for `3600` ticks. Is blank when you aren't AFK. The space in front is intentional. Uses the fancyFormatting config.
  FOXAPI.afk = FOXAPI.afk

  ---@class afk.config
  ---Defaults to `2400` or 2 minutes in ticks
  ---
  ---How long in ticks you have to wait to become AFK for.
  ---@field timeUntilAFK integer
  ---Whether to update your nameplate using world instructions while your player is unloaded.
  ---
  ---The default is `true` when your avatar is set to `HIGH` or `MAX` permissions and `false` when it's set lower. Setting this config will force enable or disable this feature on any permission level.
  ---@field runUnloaded boolean
  ---Defaults to `800` or 40 seconds in ticks
  ---
  ---How often the AFK timestamp should be repinged. This should be infrequent.
  ---@field repingDelay integer
  ---Defaults to `10` or 1/2 second in ticks
  ---
  ---How frequent in ticks the module does stuff. This also affects how precise the AFK timer is going to be.
  ---@field timeDelay integer
  ---Defaults to `" [AFK %s]"` or [AFK 3:00] with a space
  ---
  ---How the AFK string should be formatted when replacing ${afk} in nameplates. The %s is replaced with the time like `3:00`.
  ---@field fancyFormatting string
  ---Defaults to `true`
  ---
  ---If this is set to `false`, the system for replacing ${afk} placeholders in the nameplate will be disabled.
  ---@field usePlaceholder boolean
  ---Defaults to `"%d:%02d:%02d"` or 0:00:00
  ---
  ---How the AFK timer should be formatted when the player has been AFK for **more than** an hour.
  ---@field hmmss string
  ---Defaults to `"%d:%02d"` or 0:00
  ---
  ---How the AFK timer should be formatted when the player has been AFK for **less than** an hour.
  ---@field mss string
  FOXAPI.afk.config = FOXAPI.afk.config
end

--#ENDREGION

return _module
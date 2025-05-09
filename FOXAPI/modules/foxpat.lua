---@meta _
--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's Patpat Module v1.2.1
A FOXAPI Module

Lets you pat other players, entities, and skulls.
Forked from Auria's patpat https://github.com/lua-gods/figuraLibraries/blob/main/patpat/patpat.lua

Github Docs: https://github.com/Bitslayn/FOXAPI/wiki/Foxpat

--]]

-- DO NOT insert your own code here. This is a library module/API, not a script.

local path = ...
assert(string.find(path, "FOXAPI.modules"), "\n§4FOX's API was not installed correctly!§c")
local _module = {
  _api = { "FOXAPI", "1.1.3", 8 },
  _name = "FOX's Patpat Module",
  _desc = "Lets you pat other players, entities, and skulls.",
  _ver = { "1.2.1", 17 },
}
if not FOXAPI then
  __race = { string.gsub(table.concat({ ... }, "/"), "/", "."), _module }
  require(string.match(path, "(.*)modules") .. "api")
end

--#REGION ˚♡ Whitelists/blacklists ♡˚

-- Change these values to your liking; just don't delete the table. (There's no way to make these external configs as they are pre-processed)

local lists = {
  block = { -- List of blocks that should be pattable. Takes a pattern or generic like "minecraft:stone". Use * to match all. Blacklist gets applied before whitelist.
    whitelist = {
      "head",
      "skull",
      "carved_pumpkin",
      "jack_o_lantern",
      "minecraft:observer",
      "minecraft:spawner",
      "minecraft:trial_spawner",
    },
    blacklist = {
      "minecraft:piston_head",
    },
  },
  entity = { -- List of entites that should be pattable. Takes a pattern or generic like "minecraft:stone". Use * to match all. Blacklist gets applied before whitelist.
    whitelist = {
      "*",
    },
    blacklist = {
      "boat",
      "minecart",
      "item_frame",
      "minecraft:painting",
      "minecraft:area_effect_cloud",
      "minecraft:interaction",
      "minecraft:armor_stand",
    },
  },
}
--#ENDREGION
--#REGION ˚♡ Entity sound overrides ♡˚

-- Allows you to change which sounds entities play for entities. This is useful if an entity doesn't have an ambient or idle sound.
-- Overrides can be either a sound id, entity id, or a function which returns a sound id. Functions are given the entity being patted, or nothing if patting a mob spawner.
-- IMPORTANT Make sure to check if entity is actually defined to avoid erroring.

---@type table<Minecraft.entityID, fun(entity: Entity?): sound: Minecraft.soundID>|table<Minecraft.entityID, Minecraft.entityID>|table<Minecraft.entityID, Minecraft.soundID>
local entitySoundOverrides = {
  -- Sound overrides to play sound of another entity type
  ["minecraft:cave_spider"] = "minecraft:spider",
  ["minecraft:mooshroom"] = "minecraft:cow",
  ["minecraft:trader_llama"] = "minecraft:llama",

  -- Sound overrides to play sound by id
  ["minecraft:bee"] = "minecraft:entity.bee.pollinate",
  ["minecraft:creeper"] = "minecraft:entity.creeper.primed",
  ["minecraft:iron_golem"] = "minecraft:entity.iron_golem.repair",
  ["minecraft:magma_cube"] = "minecraft:entity.slime.squish",
  ["minecraft:pufferfish"] = "minecraft:entity.puffer_fish.flop",
  ["minecraft:slime"] = "minecraft:entity.slime.squish",
  ["minecraft:sniffer"] = "minecraft:entity.sniffer.idle",
  ["minecraft:tadpole"] = "minecraft:entity.tadpole.flop",

  -- Sound overrides using a function returning a sound id
  ["minecraft:allay"] = function(entity)
    if not entity then return "minecraft:entity.allay.ambient_without_item" end
    local nbt = entity:getNbt()
    local isHoldingItem = nbt and nbt.HandItems[1] and nbt.HandItems[1].id
    return isHoldingItem and "minecraft:entity.allay.ambient_with_item" or
        "minecraft:entity.allay.ambient_without_item"
  end,
  ["minecraft:axolotl"] = function(entity)
    if not entity then return "minecraft:entity.axolotl.idle_air" end
    local nbt = entity:getNbt()
    local isInWater = nbt and nbt.Air and nbt.Air == 6000
    return isInWater and "minecraft:entity.axolotl.idle_water" or "minecraft:entity.axolotl.idle_air"
  end,
  ["minecraft:breeze"] = function(entity)
    if not entity then return "minecraft:entity.breeze.idle_ground" end
    local nbt = entity:getNbt()
    local isOnGround = nbt and nbt.OnGround and nbt.OnGround == 1
    return isOnGround and "minecraft:entity.breeze.idle_ground" or "minecraft:entity.breeze.idle_air"
  end,
  ["minecraft:wolf"] = function(entity)
    if not entity then return "minecraft:entity.wolf.ambient" end
    local nbt = entity:getNbt()
    local variant = nbt.sound_variant and "_" .. nbt.sound_variant:match("minecraft:(.*)") or ""
    local mood = nbt.AngerTime == 0 and "ambient" or "growl"
    return ("minecraft:entity.wolf%s.%s"):format(variant, mood)
  end,
}

--#ENDREGION

-- Do not touch anything below this line unless you know what you are doing! Chances are, what you are trying to configure already can be configured externally.

--#REGION ˚♡ Init vars and functions ♡˚

local scripts = listFiles("/", true)
assert(not (table.match(scripts, "patpat") or
    table.match(scripts, "bunnypat") or
    table.match(scripts, "Patpat") or
    table.match(scripts, "petpet")),
  "FOXPat does not work with other patpat scripts", 2)

local isHost = host:isHost()

---@class foxpat
FOXAPI.foxpat = {}
FOXAPI.foxpat.config = {}
local cfg = FOXAPI.foxpat.config

events:new("entity_pat")
events:new("skull_pat")
events:new("patting")

local lastBoundingBox, lastActAsInteractable

function events.tick()
  if lastBoundingBox ~= cfg.boundingBox then
    lastBoundingBox = cfg.boundingBox
    avatar:store("patpat.boundingBox", cfg.boundingBox)
  end
  if lastActAsInteractable ~= cfg.actAsInteractable then
    lastActAsInteractable = cfg.actAsInteractable
    avatar:store("foxpat.actAsInteractable", cfg.actAsInteractable)
  end
end

local matchPattern = '"([%%w_:%%-%%.]-%s[%%w_:%%-%%.]-)"'
local soundsRegistry = client.getRegistry("sound_event")
local noteBlockImitation = table.gmatch(soundsRegistry,
  string.format(matchPattern, "note_block.imitate"))

local cache = {
  uuidHash = {},     -- [uuid] = hash
  uuidHashMap = {},  -- [hash] = uuid
  coordHash = {},    -- [coord] = hash
  coordHashMap = {}, -- [hash] = coord
}

local function packUUID(uuid)
  -- Check if this UUID has been cached
  if not cache.uuidHash[uuid] then
    -- Convert small portion of UUID into a string that can be pinged
    local packedUUID = ""
    local uuidShort = string.match(uuid, "%-(%w*)$")
    for i = 1, 6, 2 do
      packedUUID = packedUUID .. string.char(tonumber(string.sub(uuidShort, i, i + 1), 16))
    end
    -- Store caches
    cache.uuidHash[uuid] = packedUUID
    cache.uuidHashMap[packedUUID] = uuid
    return packedUUID
  else
    return cache.uuidHash[uuid] -- Skip packing and read from cache
  end
end
function events.entity_init()
  packUUID(player:getUUID()) -- Append the current player to cache so self patting works
end

local function unpackUUID(packedUUID)
  -- Check if this UUID has been cached
  if not cache.uuidHashMap[packedUUID] then
    -- Convert UUID from string into readable UUID
    local uuidShort = ""
    for i = 1, #packedUUID do
      uuidShort = uuidShort .. string.format("%02x", string.byte(packedUUID:sub(i, i)))
    end
    -- Get UUID from target entity
    local myPos = player:getPos():add(0, player:getEyeHeight(), 0)
        :add(isHost and renderer:getEyeOffset() or player:getVariable().eyePos) -- If not on host, get from variable
    local target = raycast:entity(myPos, myPos + player:getLookDir():mul(5, 5, 5),
      function(entity) return entity ~= player end)
    if not target then return end -- Make sure there is an entity to get UUID from
    local targetUUID = target:getUUID()
    -- Check target entity to see if UUID matches
    if not targetUUID:find(uuidShort) then return end
    local uuid = target:getUUID()
    -- Store caches
    cache.uuidHash[uuid] = packedUUID
    cache.uuidHashMap[packedUUID] = uuid
    return uuid
  else
    return cache.uuidHashMap[packedUUID] -- Skip unpacking and read from cache
  end
end

local function packCoord(coord)
  local entry = table.concat({ coord:unpack() }, ",")

  -- Check if this coordinate has been cached
  if not cache.coordHash[entry] then
    -- Convert coordinate to position relative to chunk cube with combined x and z
    local blockPosXZ = coord.xz:reduce(16, 16):mul(1, 16)
    local combinedXZ = blockPosXZ.x + blockPosXZ.y
    local finalPos = { combinedXZ, coord.y % 16 }
    -- Convert vec2 coordinate to a string that can be pinged
    local packedCoord = ""
    for i = 1, 2 do
      packedCoord = packedCoord .. string.char(finalPos[i])
    end
    -- Store caches
    cache.coordHash[entry] = packedCoord
    cache.coordHashMap[packedCoord] = coord
    return packedCoord
  else
    return cache.coordHash[entry] -- Skip packing and read from cache
  end
end

local function unpackCoord(packedCoord)
  -- Get the cubic chunk of the patted block
  local pos = player:getTargetedBlock():getPos()
  local chunk = pos.xyz:sub(pos:reduce(16, 16, 16))
  -- Clear caches if the chunk of the patted block is different
  if cache.lastChunk ~= chunk then
    cache.lastChunk = chunk
    cache.coordHash, cache.coordHashMap = {}, {}
  end

  -- Check if this coordinate has been cached
  if not cache.coordHashMap[packedCoord] then
    -- Convert string into vec2 coordinate
    local coord = {}
    for i = 1, #packedCoord do
      coord[i] = string.byte(string.sub(packedCoord, i, i))
    end
    -- Convert vec2 coord into vec3
    local finalPos = vec(
      (coord[1] % 16) + chunk.x,
      coord[2] + chunk.y,
      (math.floor(coord[1] / 16)) + chunk.z
    )
    -- Store caches
    cache.coordHash[table.concat({ finalPos:unpack() }, ",")] = packedCoord
    cache.coordHashMap[packedCoord] = finalPos
    return finalPos
  else
    return cache.coordHashMap[packedCoord] -- Skip unpacking and read from cache
  end
end

local function getAvatarVarsFromBlock(block)
  if not string.match(block.id, "head") then return {} end
  local SkullOwner = block:getEntityData().SkullOwner
  return world.avatarVars()
      [client.intUUIDToString(table.unpack(SkullOwner and SkullOwner.Id or {}))] or {}
end


--#ENDREGION
--#REGION ˚♡ Pat functions ♡˚

--#REGION ˚♡ Handle being patted ♡˚

local entityPatters, skullPatters = {}, {}
local entityPattersCount, skullPattersCount = 0, {}

function events.tick()
  -- Entity pat timers
  for uuid, time in pairs(entityPatters) do
    if time <= 0 then
      entityPattersCount = entityPattersCount - 1
      entityPatters[uuid] = nil
      events:call("entity_pat", world.getEntity(uuid), "UNPAT")
    else
      entityPatters[uuid] = time - 1
    end
  end
  -- Skull pat timers
  for i, headPatters in pairs(skullPatters) do
    local patted = false
    local pos = headPatters.pos
    for uuid, time in pairs(headPatters.list) do
      if time <= 0 then
        local j = tostring(pos)
        skullPattersCount[j] = skullPattersCount[j] - 1
        headPatters.list[uuid] = nil
        events:call("skull_pat", world.getEntity(uuid), "UNPAT", pos)
      else
        headPatters.list[uuid] = time - 1
        patted = true
      end
    end
    if not patted then
      skullPatters[i] = nil
    end
  end
end

local function parseReturns(retTbl)
  return table.contains(retTbl, "%[true"), table.contains(retTbl, "true%]")
end

avatar:store("petpet", function(uuid, time)
  time = time or cfg.holdFor or 10
  local entity = world.getEntity(uuid)
  local prev = entityPatters[uuid]
  if not prev then
    entityPattersCount = entityPattersCount + 1
  end
  entityPatters[uuid] = time
  local noPats, noHearts = parseReturns(
    events:call("entity_pat", entity, prev and "WHILE_PAT" or "PAT")
  )
  avatar:store("patpat.noHearts", noHearts)
  return noPats, noHearts
end)

avatar:store("petpet.playerHead", function(uuid, time, x, y, z)
  if not (x and y and z) then return end
  time = time or cfg.holdFor or 10
  local entity = world.getEntity(uuid)
  local pos = vec(math.floor(x), y, math.floor(z))
  local i = tostring(pos)
  skullPatters[i] = skullPatters[i] or { list = {}, pos = pos }
  skullPattersCount[i] = skullPattersCount[i] or 0
  local prev = skullPatters[i].list[uuid]
  if not prev then
    skullPattersCount[i] = skullPattersCount[i] + 1
  end
  skullPatters[i].list[uuid] = time
  local noPats, noHearts = parseReturns(
    events:call("skull_pat", entity, prev and "WHILE_PAT" or "PAT", pos)
  )
  avatar:store("patpat.noHearts", noHearts)
  return noPats, noHearts
end)

--#ENDREGION
--#REGION ˚♡ Handle patting others ♡˚

local function patResponse(avatarVars, noPats, noHearts, entity, block, boundingBox, pos)
  -- Call events for when the player is patting
  local returns = { parseReturns(events:call("patting", entity, block, boundingBox,
    not (noHearts or avatarVars["patpat.noHearts"]))) } -- Keep old compatibility
  noPats, noHearts = noPats or returns[1], noHearts or returns[2]

  -- Play pat animation and swinging
  if not noPats then
    if avatarVars["foxpat.actAsInteractable"] then
      host:swingArm()
    else
      if cfg.swingArm or (type(cfg.swingArm) == "nil" and true) then
        host:swingArm()
      end
      if type(cfg.patAnimation) == "Animation" then
        cfg.patAnimation:play()
      elseif type(cfg.patAnimation) == "table" then
        for _, anim in pairs(cfg.patAnimation) do
          if type(anim) == "Animation" then
            anim:play()
          end
        end
      end
    end
  end

  -- Emit particles (This module is written in a way to allow you to modify your own particles, please do not modify code directly)
  if not (noHearts or avatarVars["patpat.noHearts"]) then
    pos = pos - boundingBox.x_z * 0.5 + vectors.random() * boundingBox
    particles[particles:isPresent(cfg.patParticle) and cfg.patParticle or "minecraft:heart"]:pos(pos)
        :scale(1):spawn()
  end
end

local vector3Index = figuraMetatables.Vector3.__index
local myUuid = avatar:getUUID()

local patTimer = 0
function events.tick()
  if patTimer == 0 then return end
  patTimer = patTimer - 1
  if patTimer == 0 then
    if type(cfg.patAnimation) == "Animation" then
      cfg.patAnimation:stop()
    elseif type(cfg.patAnimation) == "table" then
      for _, anim in pairs(cfg.patAnimation) do
        if type(anim) == "Animation" then
          anim:stop()
        end
      end
    end
  end
end

local soundCache = {}
local soundOverrideParsers = {
  ["func"] = function(entityType, entity)
    local soundName

    local functionSound = entitySoundOverrides[entityType](entity)
    soundName = sounds:isPresent(functionSound) and functionSound

    return soundName
  end,
  ["sound"] = function(entityType)
    local soundName

    if not soundCache[entityType] then
      soundName = entitySoundOverrides[entityType] --[[@as Minecraft.soundID]]
      soundCache[entityType] = sounds:isPresent(soundName) and soundName
    else
      soundName = soundCache[entityType]
    end

    return soundName
  end,
  ["entity"] = function(entityType)
    local soundName, potentialSounds

    if not soundCache[entityType] then
      -- Parses mod name and entity name, turning it into a pattern to search for mod sounds
      local entityPattern = string.format('(%s:entity.%s.-)"',
        string.match(entitySoundOverrides[entityType] --[[@as Minecraft.entityID]] or entityType,
          "^(.-):(.-)$"))
      -- Gmatches all the sounds this mob can play
      potentialSounds = table.gmatch(soundsRegistry, entityPattern)
      -- Finds a sound in potential sounds with "ambient" in it
      soundName = table.match(potentialSounds, string.format(matchPattern, "ambient")) or
          table.match(potentialSounds, string.format(matchPattern, "idle"))
      -- Caches the sound for this mob
      soundCache[entityType] = sounds:isPresent(soundName) and soundName
    else
      soundName = soundCache[entityType]
    end

    if soundName then return soundName end

    if cfg.debug and isHost then
      if entitySoundOverrides[entityType] and not soundName then
        printJson("§cEntity sound override function for this entity didn't return a valid sound!\n")
      elseif potentialSounds[1] then
        printJson(
          "§cAmbient sound for the targeted mob could not be found! An entity sound override is recommended to fix this issue. Below is a list of sounds this mob can play.\n")
        print(potentialSounds)
      else
        printJson(
          "§cCould not find sounds for the targeted mob! An entity sound override is recommended to fix this issue.\n")
      end
    end
  end,
}

local function getEntitySound(entityType, entity)
  local override = entitySoundOverrides[entityType]
  local overrideType = type(override) == "function" and "func" or
      sounds:isPresent(override --[[@as Minecraft.soundID]]) and "sound" or "entity"

  local soundName = soundOverrideParsers[overrideType](entityType, entity)

  return soundName
end

--#REGION ˚♡ Entity ♡˚

local function foxpatEntityPing(u)
  if not player:isLoaded() then return end
  local unpackedUUID = unpackUUID(u)
  if not unpackedUUID then return end
  local entity = world.getEntity(unpackedUUID)
  if not entity then return end

  -- Play sounds for entities
  if (cfg.playMobSounds or (type(cfg.playMobSounds) == "nil" and true)) and not (entity:isPlayer() or entity:isSilent()) then
    local soundName = getEntitySound(entity:getType(), entity)

    if soundName then
      local nbt = entity:getNbt()
      sounds:playSound(soundName, entity:getPos(), 0.5,
        (cfg.mobSoundPitch or 1) * ((nbt.Age or -(nbt.IsBaby or -1)) >= 0 and 1 or 1.5) +
        (math.random() - 0.5) * (cfg.mobSoundRange or 0.25))
    end
  end

  local avatarVars = entity:getVariable()
  local pos = entity:getPos()

  -- Get bounding box or fallback to vanilla bounding box
  local vecSuccess, boundingBox = pcall(vector3Index, avatarVars["patpat.boundingBox"], "xyz")
  if not vecSuccess then
    boundingBox = entity:getBoundingBox()
  end

  -- Call petpet function and process avatar reaction
  local patSuccess, noPats, noHearts = pcall(avatarVars["petpet"], myUuid, cfg.holdFor or 10)
  if patSuccess then
    -- Support foxpat 1.0 and 1.1
    local noPatsHearts = pcall(rawget, noPats, "") and { parseReturns(noPats) }
    if noPatsHearts then
      noPats, noHearts = table.unpack(noPatsHearts)
    end
  end
  patResponse(avatarVars, patSuccess and noPats, patSuccess and noHearts, entity, nil, boundingBox,
    pos)
  patTimer = cfg.holdFor or 10
end

function pings.foxpatEntity(...)
  if isHost then return end
  foxpatEntityPing(...)
end

--#ENDREGION
--#REGION ˚♡ Block ♡˚

local function foxpatBlockPing(c)
  if not player:isLoaded() then return end

  local blockPos = unpackCoord(c).xyz

  local block = world.getBlockState(blockPos)
  if block:isAir() or block.id == "minecraft:water" or block.id == "minecraft:lava" then return end

  -- Play sounds for blocks
  if cfg.playNoteSounds or (type(cfg.playNoteSounds) == "nil" and true) then
    local blockData = block:getEntityData()
    local blockMatch = string.match(block.id, ":(.-)_")
    local soundName
    local mobSpawner = blockData and (blockData.SpawnData or blockData.spawn_data)
    local spawnerEntity = mobSpawner and mobSpawner.entity and mobSpawner.entity.id
    if spawnerEntity then
      -- Find sound for mob spawners
      if (cfg.playMobSounds or (type(cfg.playMobSounds) == "nil" and true)) then
        soundName = getEntitySound(spawnerEntity)
      end
    elseif blockMatch then
      -- Find sound for player skull
      soundName = blockData and blockData.note_block_sound or
          table.match(noteBlockImitation, string.format(matchPattern, blockMatch))
      soundName = sounds:isPresent(soundName) and soundName
    end
    if soundName then
      sounds:playSound(soundName, blockPos:add(0.5, 0, 0.5), 0.5,
        (cfg.noteSoundPitch or 1) + (math.random() - 0.5) * (cfg.noteSoundRange or 0.25))
    end
  end


  -- Get bounding box
  local avatarVars = getAvatarVarsFromBlock(block)
  local blockShape = block:getOutlineShape()[1]
  if not blockShape then return end
  local boundingBox = blockShape[2]:sub(blockShape[1]):add(0.3, 0, 0.3)

  -- Call petpet function and process avatar reaction
  local patSuccess, noPats, noHearts = pcall(avatarVars["petpet.playerHead"], myUuid,
    cfg.holdFor or 10,
    blockPos:unpack())
  patResponse(avatarVars, patSuccess and noPats, patSuccess and noHearts, nil, block, boundingBox,
    blockPos:add(0.5, 0, 0.5))
  patTimer = cfg.holdFor or 10
end

function pings.foxpatBlock(...)
  if isHost then return end
  foxpatBlockPing(...)
end

--#ENDREGION

--#ENDREGION

--#ENDREGION
--#REGION ˚♡ PlayerAPI ♡˚

---@class Player
local PlayerAPI = figuraMetatables.PlayerAPI.__index

local function isPatted(...)
  local args = { ... }
  local pos
  if type(args[1]) == "Vector3" then
    pos = args[1]
  elseif args[1] then
    pos = vec(table.unpack(args))
  end
  return (pos and (skullPattersCount[tostring(pos)] or 0) or entityPattersCount) > 0
end

---`FOXAPI` Returns if the player is currently being patted. If a coordinate is provided, returns if a skull at that position is being patted.
---@param x number?
---@param y number?
---@param z number?
---@return boolean
---@nodiscard
function PlayerAPI:isPatted(x, y, z)
  return isPatted(x, y, z)
end

---`FOXAPI` Returns if the player is currently being patted. If a coordinate is provided, returns if a skull at that position is being patted.
---@param pos Vector3?
---@return boolean
---@nodiscard
function PlayerAPI:isPatted(pos)
  return isPatted(pos)
end

--#ENDREGION
--#REGION ˚♡ Host ♡˚

if not isHost then return _module end

--#REGION ˚♡ Unpack whitelists/blacklists ♡˚

local function processRegistry(registry, config)
  local whitelist, blacklist = config.whitelist, config.blacklist
  local function processList(list)
    for i = 1, #list do
      local str = list[i]
      if not table.contains(registry, string.format('"%s"', str)) then
        local matchTbl = table.gmatch(registry, string.format(matchPattern, str))
        for j = 1, #matchTbl do table.insert(list, matchTbl[j]) end
        list[i] = nil
      end
    end
  end

  processList(whitelist)
  processList(blacklist)

  config.whitelist = table.invert(whitelist)
  config.blacklist = table.invert(blacklist)
end

processRegistry(client.getRegistry("minecraft:entity_type"), lists.entity)
processRegistry(client.getRegistry("minecraft:block"), lists.block)

--#ENDREGION
--#REGION ˚♡ Init vars ♡˚

---@type function
local foxpat
local shiftHeld
local patting, patTime, firstPat = false, 0, true
local pattingSelf, patSelfTime, firstSelfPat = false, 0, true

local configAPI = config:loadFrom("FOXAPI", "foxpat") or {
  keybinds = {
    crouch = "key.keyboard.left.shift",
    pat = "key.mouse.right",
    patSelf = "key.mouse.middle",
    toggleDebug = "key.keyboard.page.up",
  },
}
config:saveTo("FOXAPI", "foxpat", configAPI)
local k = configAPI.keybinds

--#ENDREGION
--#REGION ˚♡ Keybinds ♡˚

---@type Keybind[]
local b = {
  crouch = keybinds
      :newKeybind("FOXPat - Crouch", "key.keyboard.left.shift")
      :setKey(k.crouch or "key.keyboard.left.shift"),
  pat = keybinds
      :newKeybind("FOXPat - Pat", "key.mouse.right")
      :setKey(k.pat or "key.mouse.right"),
  patSelf = keybinds
      :newKeybind("FOXPat - Pat Self", "key.mouse.middle")
      :setKey(k.patSelf or "key.mouse.middle"),
  toggleDebug = keybinds:newKeybind("FOXPat - Toggle Debug", "key.keyboard.page.up")
      :setKey(k.toggleDebug or "key.keyboard.page.up"),
}

function events.tick()
  if host:getScreen() ~= "org.figuramc.figura.gui.screens.KeybindScreen" then return end
  for key, keyCode in pairs(k) do
    if b[key]:getKey() ~= keyCode then
      k[key] = b[key]:getKey()
      config:saveTo("FOXAPI", "foxpat", configAPI)
    end
  end
end

b.crouch:onPress(function() shiftHeld = true end)
b.crouch:onRelease(function() shiftHeld = false end)

local shouldPat = true

b.pat:onPress(function()
  if not host:getScreen() and not action_wheel:isEnabled() and player:isLoaded() then
    shouldPat = foxpat()
    if not shouldPat then return end
    patting = true
    return shouldPat
  end
end)
b.pat:onRelease(function()
  patting = false
  firstPat = true
  patTime = 0
end)

b.patSelf:onPress(function()
  if not host:getScreen() and not action_wheel:isEnabled() and player:isLoaded() then
    pattingSelf = true
    return foxpat(true)
  end
end)
b.patSelf:onRelease(function()
  pattingSelf = false
  firstSelfPat = true
  patSelfTime = 0
end)

b.toggleDebug:onPress(function()
  cfg.debug = not cfg.debug
  host:actionbar(toJson({
    text = "FOXPat - " .. (cfg.debug and "Enabled" or "Disabled") .. " debug mode",
    color = "#fc6c85",
  }))
end)

function events.tick()
  if patting then
    patTime = patTime + 1
    if patTime % (cfg.patDelay or 3) == 0 then foxpat() end
  end
  if pattingSelf then
    patSelfTime = patSelfTime + 1
    if patSelfTime % (cfg.patDelay or 3) == 0 then foxpat(true) end
  end
end

--#ENDREGION
--#REGION ˚♡ Main pat function ♡˚

local function checkWhitelist(list, id)
  local _list = lists[list]
  return not (_list.whitelist[id] or table.contains(_list.whitelist, "*")) or
      (_list.blacklist[id] or table.contains(_list.blacklist, "*"))
end

local function checkCrouching(vars, self)
  return not vars["foxpat.actAsInteractable"] and
      ((not self and firstPat) or (self and firstSelfPat)) and
      not shiftHeld and b.crouch:getID() ~= -1
end

local function checkEmptyHand(vars)
  return not vars["foxpat.actAsInteractable"] and
      ((cfg.requireEmptyHand or (type(cfg.requireEmptyHand) == "nil" and true)) and player:getItem(1).id ~= "minecraft:air") or
      ((cfg.requireEmptyOffHand or cfg.requireEmptyOffHand) and player:getItem(2).id ~= "minecraft:air")
end

local printed
function copyPrint(str)
  if printed then return end
  printed = true
  if not cfg.debug then return end
  printJson(toJson({
    text = str .. " §7(click to copy)\n",
    clickEvent = { action = "copy_to_clipboard", value = str },
  }))
end

foxpat = function(self)
  local successfulPat

  local myPos = player:getPos():add(0, player:getEyeHeight(), 0):add(renderer:getEyeOffset())

  local block, hitPos = player:getTargetedBlock(true, 5)
  local dist = (myPos - hitPos):length()
  local isBlock = true

  printed = false
  local entity = self and player or
      raycast:entity(myPos, myPos + player:getLookDir():mul(5, 5, 5),
        function(entity)
          if entity ~= player then
            copyPrint(entity:getType())
            return not checkWhitelist("entity", entity:getType())
          end
          return false
        end)
  local entityPos = entity and entity:getPos()

  if entity then
    local newDist = (myPos - (entityPos or player:getPos())):length()
    isBlock = not (newDist < dist or #block:getCollisionShape() == 0)
  end

  if isBlock then
    copyPrint(block.id)
    if checkWhitelist("block", block.id) then return end

    local blockVars = getAvatarVarsFromBlock(block)
    if blockVars["patpat.noPats"] or checkCrouching(blockVars, self) or checkEmptyHand(blockVars) then return end

    local blockPos = block:getPos()
    local packedCoord = packCoord(blockPos)
    foxpatBlockPing(packedCoord)
    pings.foxpatBlock(packedCoord)
    successfulPat = true
  else
    local entityVars = entity:getVariable()
    if entityVars["patpat.noPats"] or checkCrouching(entityVars, self) or checkEmptyHand(entityVars) then return end

    local entityUUID = entity:getUUID()
    local packedUUID = packUUID(entityUUID)
    foxpatEntityPing(packedUUID)
    pings.foxpatEntity(packedUUID)
    successfulPat = true
  end

  if self then
    copyPrint("minecraft:player")
    firstSelfPat = cfg.requireCrouch
  else
    firstPat = cfg.requireCrouch
  end
  return successfulPat or self
end

--#ENDREGION

--#ENDREGION
--#REGION ˚♡ Annotations ♡˚

local FOXMetatable = getmetatable(FOXAPI)

---@class Event.EntityPat: Event
---@class Event.SkullPat: Event
---@class Event.Patting: Event
---@alias Event.Pat.state
---| "PAT"
---| "UNPAT"
---| "WHILE_PAT"
---@alias Event.EntityPat.func
---| fun(patter?: Player, state?: Event.Pat.state): (cancel: boolean|boolean[]?)
---@alias Event.SkullPat.func
---| fun(patter?: Player, state?: Event.Pat.state, coordinates?: Vector3): (cancel: boolean|boolean[]?)
---@alias Event.Patting.func
---| fun(entity?: Entity, block?: BlockState, boundingBox?: Vector3, allowHearts?: boolean): (cancel: boolean|boolean[]?)
---@class EventsAPI
---`FOXAPI` This event runs when you get patted or unpatted.
---> ```lua
---> (callback) function(patter: Player, state: integer)
--->  -> cancel: boolean|boolean[]?
---> ```
---> ***
---> A callback that is given the data of the player patting you or your skull, and the current patting state.
---
---
---Return `true` to cancel both visually patting and hearts. Return `{ boolean, boolean }` to cancel one or the other.
---@field entity_pat Event.EntityPat | Event.EntityPat.func
---`FOXAPI` This event runs when you get patted or unpatted.
---> ```lua
---> (callback) function(patter: Player, state: integer)
--->  -> cancel: boolean|boolean[]?
---> ```
---> ***
---> A callback that is given the data of the player patting you or your skull, and the current patting state.
---
---
---Return `true` to cancel both visually patting and hearts. Return `{ boolean, boolean }` to cancel one or the other.
---@field ENTITY_PAT Event.EntityPat | Event.EntityPat.func
---`FOXAPI` This event runs when one of your skulls gets patted or unpatted.
---> ```lua
---> (callback) function(patter: Player, state: integer, coordinates: Vector3)
--->  -> cancel: boolean|boolean[]?
---> ```
---> ***
---> A callback that is given the data of the player patting you or your skull, the current patting state, and the coordinates of this skull.
---
---
---Return `true` to cancel both visually patting and hearts. Return `{ boolean, boolean }` to cancel one or the other.
---@field skull_pat Event.SkullPat | Event.SkullPat.func
---`FOXAPI` This event runs when one of your skulls gets patted or unpatted.
---> ```lua
---> (callback) function(patter: Player, state: integer, coordinates: Vector3)
--->  -> cancel: boolean|boolean[]?
---> ```
---> ***
---> A callback that is given the data of the player patting you or your skull, the current patting state, and the coordinates of this skull.
---
---
---Return `true` to cancel both visually patting and hearts. Return `{ boolean, boolean }` to cancel one or the other.
---@field SKULL_PAT Event.SkullPat | Event.SkullPat.func
---`FOXAPI` This event runs when you pat another player, entity, or block. It can be used as an alternative to summoning particles.
---> ```lua
---> (callback) function(entity: Player, block: BlockState, boundingBox: Vector3, allowHearts: boolean)
--->  -> cancel: boolean|boolean[]?
---> ```
---> ***
---> A callback that is given the data of the entity you're patting or nil, and the block you are patting or nil, the bounding box, and if the player you're patting allows hearts or not.
---
---
---Return `true` to cancel both visually patting and hearts. Return `{ boolean, boolean }` to cancel one or the other.
---@field patting Event.Patting | Event.Patting.func
---`FOXAPI` This event runs when you pat another player, entity, or block. It can be used as an alternative to summoning particles.
---> ```lua
---> (callback) function(entity: Player, block: BlockState, boundingBox: Vector3, allowHearts: boolean)
--->  -> cancel: boolean|boolean[]?
---> ```
---> ***
---> A callback that is given the data of the entity you're patting or nil, and the block you are patting or nil, the bounding box, and if the player you're patting allows hearts or not.
---
---
---Return `true` to cancel both visually patting and hearts. Return `{ boolean, boolean }` to cancel one or the other.
---@field PATTING Event.Patting | Event.Patting.func
FOXMetatable.__events = FOXMetatable.__events

---@class foxpat.config
---Defaults to `true`
---
---Whether patting should swing your arm. Recommended to turn this off when you set a pat animation.
---@field swingArm boolean?
---@field patAnimation Animation? What animation should be played while you're patting.
---Defaults to `"minecraft:heart"`
---
---What particle should play while you're patting.
---@field patParticle Minecraft.particleID?
---Defaults to `true`
---
---Whether patting a mob plays a sound.
---@field playMobSounds boolean?
---Defaults to `1`
---
---The pitch mob sounds will be played at.
---@field mobSoundPitch number?
---Defaults to `0.25`
---
---How varied the mob sound pitch will be.
---@field mobSoundRange number?
---Defaults to `true`
---
---Whether patting a player head plays the noteblock sound associated with that head.
---@field playNoteSounds boolean?
---Defaults to `1`
---
---Set the pitch player head noteblock sounds will be played at.
---@field noteSoundPitch number?
---Defaults to `0.25`
---
---How varied the noteblock sound pitch will be.
---@field noteSoundRange number?
---Defaults to `false`
---
---Whether you have to be crouching after your first crouch to continue patting.
---@field requireCrouch boolean?
---Defaults to `true`
---
---Whether an empty hand is required for patting.
---@field requireEmptyHand boolean?
---Defaults to `false`
---
---Whether an empty offhand is required for patting.
---@field requireEmptyOffHand boolean?
---Defaults to `false`
---
---If you want another player to simply right click you or your player head without crouching or while holding an item.
---@field actAsInteractable boolean?
---Defaults to `3`
---
---How often patting should occur in ticks.
---@field patDelay number?
---Defaults to `10`
---
---How long should it be after the last pat before you're considered no longer patting. Shouldn't be made less than `patDelay`.
---@field holdFor number?
---@field boundingBox Vector3? A custom bounding box that defines where people can pat you and the area that hearts get spawned on you.
---@field debug boolean? Whether debug mode is enabled. Debug mode prints the id of the entity or block you are patting.
FOXAPI.foxpat.config = FOXAPI.foxpat.config

--#ENDREGION

return _module

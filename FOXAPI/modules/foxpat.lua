---@meta _
--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's Patpat Module v1.0.2
A FOXAPI Module

Lets you pat other players, entities, and skulls.
Forked from Auria's patpat https://github.com/lua-gods/figuraLibraries/blob/main/patpat/patpat.lua

--]]

local apiPath, moduleName = ...
assert(apiPath:find("FOXAPI.modules"), "\n§4FOX's API was not installed correctly!§c")
local _module = {
  _api = { "FOXAPI", "1.0.2", 3 },
  _name = "FOX's Patpat Module",
  _desc = "Lets you pat other players, entities, and skulls.",
  _ver = { "1.0.2", 3 },
}
if not FOXAPI then
  __race = { apiPath:gsub("/", ".") .. "." .. moduleName, _module }
  require(apiPath:match("(.*)modules") .. "api")
end

--#REGION ˚♡ Configs ♡˚
FOXAPI.patConfig = {
  --#REGION ˚♡ Simple ♡˚

  swingArm = true,                 -- Whether patting should swing your arm. Recommended to turn this off when you set a pat animation.
  patAnimation = nil,              -- What animation should be played while you're patting.
  patParticle = "minecraft:heart", -- What particle should play while you're patting. Can be set to nil.

  playMobSounds = true,            -- Whether patting a mob plays a sound.
  mobSoundPitch = 1.5,             -- Set the pitch mob sounds will be played at.
  playNoteSounds = true,           -- Whether patting a player head plays the noteblock sound associated with that head.
  noteSoundPitch = 1.5,            -- Set the pitch player head noteblock sounds will be played at.

  requireCrouch = false,           -- Whether you have to be crouching after your first crouch to continue patting.
  requireEmptyHand = false,        -- Whether an empty hand is required for patting.
  requireEmptyOffHand = false,     -- Whether an empty offhand is required for patting.

  --#ENDREGION
  --#REGION ˚♡ Advanced ♡˚

  actAsInteractable = false, -- If you want another player to simply right click you or your player head without crouching or while holding an item.

  patDelay = 3,              -- How often patting should occur in ticks.
  holdFor = 10,              -- How long should it be after the last pat before you're considered no longer patting. Shouldn't be made less than patDelay.
  -- boundingBox = vec(0.6, 1.7999, 0.6), -- A custom bounding box that defines where people can pat you and the area that hearts get spawned on you.

  keycodes = {
    pat = "key.mouse.right",
    patSelf = "key.mouse.middle",
    crouch = "key.keyboard.left.shift", -- If this is set to nil, you don't have to crouch to start patting.
  },

  -- List of blocks that should be pattable. Takes a pattern or generic like "minecraft:stone". Use * to match all. Blacklist gets applied before whitelist.
  block = {
    whitelist = {
      "head",
      "skull",
      "minecraft:carved_pumpkin",
      "minecraft:jack_o_lantern",
    },
    blacklist = { "minecraft:piston_head" },
  },

  -- List of entites that should be pattable. Takes a pattern or generic like "minecraft:stone". Use * to match all. Blacklist gets applied before whitelist.
  entity = {
    whitelist = { "*" },
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

  --#ENDREGION
}
--#ENDREGION

-- Do not touch anything beyond this point unless you know what you are doing!

--#REGION ˚♡ Init vars and functions ♡˚

local cfg = FOXAPI.patConfig

events:new("entity_pat")
events:new("skull_pat")
events:new("patting")

avatar:store("patpat.boundingBox", cfg.boundingBox)
avatar:store("foxpat.actAsInteractable", cfg.actAsInteractable)

local noteBlockImitation = table.gmatch(client.getRegistry("sound_event"),
  '"([%w_:%-%.]-' .. "note_block.imitate" .. '[%w_:%-%.]-)"')

local cache = {
  uuidObfu = {},     -- [uuid] = obfuscation
  uuidObfuMap = {},  -- [obfuscation] = uuid
  coordObfu = {},    -- [coord] = obfuscation
  coordObfuMap = {}, -- [obfuscation] = coord
}

local function packUUID(uuid)
  -- Check if this UUID has been cached
  if not cache.uuidObfu[uuid] then
    -- Convert small portion of UUID into a string that can be pinged
    local packedUUID = ""
    local uuidShort = uuid:match("%-(%w*)$")
    for i = 1, 6, 2 do
      packedUUID = packedUUID .. string.char(tonumber(uuidShort:sub(i, i + 1), 16))
    end
    -- Store caches
    cache.uuidObfu[uuid] = packedUUID
    cache.uuidObfuMap[packedUUID] = uuid
    return packedUUID
  else
    return cache.uuidObfu[uuid] -- Skip packing and read from cache
  end
end

local function unpackUUID(packedUUID)
  -- Check if this UUID has been cached
  if not cache.uuidObfuMap[packedUUID] then
    -- Convert UUID from string into readable UUID
    local uuidShort = ""
    for i = 1, #packedUUID do
      uuidShort = uuidShort .. string.format("%02x", string.byte(packedUUID:sub(i, i)))
    end
    -- Get UUID from target entity
    local target = player:getTargetedEntity()
    if not target then return end -- Make sure there is an entity to get UUID from
    local targetUUID = target:getUUID()
    -- Check target entity to see if UUID matches
    if not targetUUID:find(uuidShort) then return end
    local uuid = target:getUUID()
    -- Store caches
    cache.uuidObfu[uuid] = packedUUID
    cache.uuidObfuMap[packedUUID] = uuid
    return uuid
  else
    return cache.uuidObfuMap[packedUUID] -- Skip unpacking and read from cache
  end
end

local function packCoord(coord)
  local entry = table.concat({ coord:unpack() }, ",")

  -- Check if this coordinate has been cached
  if not cache.coordObfu[entry] then
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
    cache.coordObfu[entry] = packedCoord
    cache.coordObfuMap[packedCoord] = coord
    return packedCoord
  else
    return cache.coordObfu[entry] -- Skip packing and read from cache
  end
end

local function unpackCoord(packedCoord)
  -- Get the cubic chunk of the patted block
  local pos = player:getTargetedBlock():getPos()
  local chunk = pos.xyz:sub(pos:reduce(16, 16, 16))
  -- Clear caches if the chunk of the patted block is different
  if cache.lastChunk ~= chunk then
    cache.lastChunk = chunk
    cache.coordObfu, cache.coordObfuMap = {}, {}
  end

  -- Check if this coordinate has been cached
  if not cache.coordObfuMap[packedCoord] then
    -- Convert string into vec2 coordinate
    local coord = {}
    for i = 1, #packedCoord do
      coord[i] = string.byte(packedCoord:sub(i, i))
    end
    -- Convert vec2 coord into vec3
    local finalPos = vec(
      (coord[1] % 16) + chunk.x,
      coord[2] + chunk.y,
      (math.floor(coord[1] / 16)) + chunk.z
    )
    -- Store caches
    cache.coordObfu[table.concat({ finalPos:unpack() }, ",")] = packedCoord
    cache.coordObfuMap[packedCoord] = finalPos
    return finalPos
  else
    return cache.coordObfuMap[packedCoord] -- Skip unpacking and read from cache
  end
end

local function getAvatarVarsFromBlock(block)
  if not block.id:match("head") then return {} end
  return world.avatarVars()[client.intUUIDToString(table.unpack(
    block:getEntityData().SkullOwner and block:getEntityData().SkullOwner.Id or {}
  ))] or {}
end


--#ENDREGION
--#REGION ˚♡ Pat functions ♡˚

--#REGION ˚♡ Handle being patted ♡˚

local myPatters = { entity = {}, skull = {} }

function events.tick()
  for uuid, time in pairs(myPatters.entity) do
    if time <= 0 then
      events:call("entity_pat", world.getEntity(uuid), 1)
      myPatters.entity[uuid] = nil
    else
      myPatters.entity[uuid] = time - 1
    end
  end
  for i, headPatters in pairs(myPatters.skull) do
    local patted = false
    local pos = headPatters.pos
    for uuid, time in pairs(headPatters.list) do
      if time <= 0 then
        events:call("skull_pat", world.getEntity(uuid), 1, pos)
        headPatters.list[uuid] = nil
      else
        headPatters.list[uuid] = time - 1
        patted = true
      end
    end
    if not patted then
      myPatters.skull[i] = nil
    end
  end
end

avatar:store("petpet", function(uuid, time)
  time = math.clamp(time or 0, cfg.holdFor, 100)
  local entity = world.getEntity(uuid)
  local prev = myPatters.entity[uuid]
  myPatters.entity[uuid] = time
  return events:call("entity_pat", entity, prev and 2 or 0)
end)

avatar:store("petpet.playerHead", function(uuid, time, x, y, z)
  if not x or not y or not z then return end
  time = math.min(time or cfg.holdFor, 100)
  local pos = vec(x, y, z)
  local i = tostring(pos)
  local patters = myPatters.skull[i]
  if not patters then
    patters = {}
    myPatters.skull[i] = { list = patters, pos = pos }
  end

  local entity = world.getEntity(uuid)
  local prev = patters[uuid]
  patters[uuid] = time
  return events:call("skull_pat", entity, prev and 2 or 0, pos)
end)

--#ENDREGION
--#REGION ˚♡ Handle patting others ♡˚

local function parseReturns(retTbl)
  return { table.contains(retTbl, "%[true"), table.contains(retTbl, "true%]") }
end

local function patResponse(avatarVars, ret, entity, block, boundingBox, pos)
  local noPats, noHearts = false, false

  -- Process returns from entity_pat and skull_pat events
  local returns = parseReturns(ret)
  noPats, noHearts = noPats or returns[1], noHearts or returns[2]

  -- Call events for when the player is patting
  local ret2 = events:call("patting", entity, block, boundingBox,
    noHearts or avatarVars["patpat.noHearts"] and false or true) -- Keep old compatibility

  -- Process returns from patting events
  returns = parseReturns(ret2)
  noPats, noHearts = noPats or returns[1], noHearts or returns[2]

  -- Play pat animation and swinging
  if not noPats then
    if cfg.swingArm then
      host:swingArm()
    end
    if type(cfg.patAnimation) == "Animation" then
      ---@diagnostic disable-next-line: undefined-field
      cfg.patAnimation:play()
    end
  end

  -- Emit particles
  if not noHearts and not avatarVars["patpat.noHearts"] then -- Keep old compatibility, particles:isPresent(cfg.patParticle) not working on 1.21.x until RC7
    pos = pos - boundingBox.x_z * 0.5 + vec(
      math.random(),
      math.random(),
      math.random()
    ) * boundingBox
    particles[cfg.patParticle]:pos(pos):size(1):spawn()
  end
end

local vector3Index = figuraMetatables.Vector3.__index
local myUuid = avatar:getUUID()

--#REGION ˚♡ Entity ♡˚

local function foxpatEntityPing(u)
  if not player:isLoaded() then return end
  local unpackedUUID = unpackUUID(u)
  if not unpackedUUID then return end
  local entity = world.getEntity(unpackedUUID)
  if not entity then return end

  -- Play sounds for entities
  if cfg.playMobSounds and not entity:isPlayer() then
    local soundName = string.format("minecraft:entity.%s.ambient",
      entity:getType():match("minecraft:(.*)"))
    if sounds:isPresent(soundName) then
      sounds[soundName]:setPos(entity:getPos()):setPitch(cfg.mobSoundPitch or 1):play()
    end
  end

  local avatarVars = entity:getVariable()
  local pos = entity:getPos()

  -- Get bounding box or fallback to vanilla bounding box
  local success, boundingBox = pcall(vector3Index, avatarVars["patpat.boundingBox"], "xyz")
  if not success then
    boundingBox = entity:getBoundingBox()
  end

  -- Call petpet function and process avatar reaction
  local _, ret = pcall(avatarVars["petpet"], myUuid, cfg.holdFor)
  patResponse(avatarVars, ret, entity, nil, boundingBox, pos)
end

function pings.foxpatEntity(...)
  if host:isHost() then return end
  foxpatEntityPing(...)
end

--#ENDREGION
--#REGION ˚♡ Block ♡˚

local function foxpatBlockPing(c)
  if not player:isLoaded() then return end

  local blockPos = unpackCoord(c).xyz

  local block = world.getBlockState(blockPos)
  if block:isAir() or block.id == "minecraft:water" or block.id == "minecraft:lava" then return end

  -- Play sounds for skulls
  if cfg.playNoteSounds then
    local blockData = block:getEntityData()
    local blockMatch = block.id:match("minecraft:(.*)_")
    local soundName
    if blockMatch then
      soundName = blockData and blockData.note_block_sound or
          table.match(noteBlockImitation, '"([%w_:%-%.]-' .. blockMatch .. '[%w_:%-%.]-)"')
    end
    if sounds:isPresent(soundName) then
      sounds[soundName]:setPos(blockPos):setPitch(cfg.noteSoundPitch or 1):play()
    end
  end

  -- Get bounding box
  local avatarVars = getAvatarVarsFromBlock(block)
  local blockShape = block:getOutlineShape()[1]
  if not blockShape then return end
  local boundingBox = blockShape[2]:sub(blockShape[1]):add(0.3, 0, 0.3)

  -- Call petpet function and process avatar reaction
  local _, ret = pcall(avatarVars["petpet.playerHead"], myUuid, cfg.holdFor,
    blockPos:unpack())
  patResponse(avatarVars, ret, nil, block, boundingBox, blockPos:add(0.5, 0, 0.5))
end

function pings.foxpatBlock(...)
  if host:isHost() then return end
  foxpatBlockPing(...)
end

--#ENDREGION

if host:isHost() then
  --#REGION ˚♡ Unpack whitelists/blacklists ♡˚

  local function processRegistry(registry, config)
    local function processList(list)
      for i = 1, #list do
        local str = list[i]
        if not table.contains(registry, string.format('"%s"', str)) then
          local list_index = 1
          local matchTbl = table.gmatch(registry, '"([%w_:%-%.]-' .. str .. '[%w_:%-%.]-)"')
          for j = 1, #matchTbl do
            table.insert(list, matchTbl[j])
            list_index = list_index + 1
          end
          list[i] = nil
        end
      end
    end

    processList(config.whitelist)
    processList(config.blacklist)

    config.whitelist = table.invert(config.whitelist)
    config.blacklist = table.invert(config.blacklist)
  end

  processRegistry(client.getRegistry("minecraft:entity_type"), cfg.entity)
  processRegistry(client.getRegistry("minecraft:block"), cfg.block)

  --#ENDREGION

  local foxpat = function(self) end
  local shiftHeld
  local patting, patTime, firstPat = false, 0, true
  local pattingSelf, patSelfTime, firstSelfPat = false, 0, true

  local crouchButton = keybinds:newKeybind("FOXPat - Crouch",
    cfg.keycodes.crouch or "key.keyboard.unknown")
  local patButton = keybinds:newKeybind("FOXPat - Pat", cfg.keycodes.pat)
  local patSelfButton = keybinds:newKeybind("FOXPat - Pat Self", cfg.keycodes.patSelf)

  --#REGION ˚♡ Keybinds ♡˚

  crouchButton.press = function() shiftHeld = true end
  crouchButton.release = function() shiftHeld = false end

  patButton.press = function()
    if not host:getScreen() and not action_wheel:isEnabled() and player:isLoaded() then
      patting = true
      foxpat()
    end
  end
  patButton.release = function()
    patting = false
    firstPat = true
    patTime = 0
  end

  patSelfButton.press = function()
    if not host:getScreen() and not action_wheel:isEnabled() and player:isLoaded() then
      pattingSelf = true
      foxpat(true)
    end
  end
  patSelfButton.release = function()
    pattingSelf = false
    firstSelfPat = true
    patSelfTime = 0
  end

  function events.tick()
    if patting then
      patTime = patTime + 1
      if patTime % cfg.patDelay == 0 then
        foxpat()
      end
    end
    if pattingSelf then
      patSelfTime = patSelfTime + 1
      if patSelfTime % cfg.patDelay == 0 then
        foxpat(true)
      end
    end
  end

  --#ENDREGION

  foxpat = function(self)
    if cfg.requireEmptyHand and player:getItem(1).id ~= "minecraft:air" then return end
    if cfg.requireEmptyOffHand and player:getItem(2).id ~= "minecraft:air" then return end

    local myPos = player:getPos():add(0, player:getEyeHeight(), 0)
    local eyeOffset = renderer:getEyeOffset()
    if eyeOffset then myPos = myPos + eyeOffset end

    local block, hitPos = player:getTargetedBlock(true, 5)
    local dist = (myPos - hitPos):length()
    local targetType = "block"

    local entity, entityPos
    if self then
      entity, entityPos = player, player:getPos()
    else
      entity, entityPos = player:getTargetedEntity(5)
    end
    if entity then
      local newDist = (myPos - entityPos):length()
      if newDist < dist then
        targetType = "entity"
      end
    end

    if targetType == "block" then
      if not (cfg.block.whitelist[block.id] or table.contains(cfg.block.whitelist, "*")) or
          (cfg.block.blacklist[block.id] or table.contains(cfg.block.blacklist, "*")) then
        return
      end

      local blockVars = getAvatarVarsFromBlock(block)
      if blockVars["patpat.noPats"] then return end -- Keep old compatibility
      if ((not self and firstPat) or (self and firstSelfPat)) and
          not shiftHeld and
          not blockVars["foxpat.actAsInteractable"] and
          cfg.keycodes.crouch then
        return
      end

      local blockPos = block:getPos()
      local packedCoord = packCoord(blockPos)
      foxpatBlockPing(packedCoord)
      pings.foxpatBlock(packedCoord)
    else
      local entityType = entity:getType()
      if not (cfg.entity.whitelist[entityType] or table.contains(cfg.entity.whitelist, "*")) or
          (cfg.entity.blacklist[entityType] or table.contains(cfg.entity.blacklist, "*")) then
        return
      end

      local entityVars = entity:getVariable()
      if entityVars["patpat.noPats"] then return end -- Keep old compatibility
      if ((not self and firstPat) or (self and firstSelfPat)) and
          not shiftHeld and
          not entityVars["foxpat.actAsInteractable"] and
          cfg.keycodes.crouch then
        return
      end

      local entityUUID = entity:getUUID()
      local packedUUID = packUUID(entityUUID)
      foxpatEntityPing(packedUUID)
      pings.foxpatEntity(packedUUID)
    end
    if self then
      firstSelfPat = cfg.requireCrouch
    else
      firstPat = cfg.requireCrouch
    end
  end
end

--#ENDREGION

--#ENDREGION
--#REGION ˚♡ Annotations ♡˚

local FOXMetatable = getmetatable(FOXAPI)

---@class Event.EntityPat: Event
---@class Event.SkullPat: Event
---@class Event.Patting: Event
---@alias Event.Pat.state
---| 0 # Pat
---| 1 # Unpat
---| 2 # While pat
---@alias Event.EntityPat.func
---| fun(patter?: Player, state?: Event.Pat.state): (cancel: boolean|boolean[]?)
---@alias Event.SkullPat.func
---| fun(patter?: Player, state?: Event.Pat.state, coordinates?: Vector3): (cancel: boolean|boolean[]?)
---@alias Event.Patting.func
---| fun(entity?: Player, block?: BlockState, boundingBox?: Vector3, allowHearts?: boolean): (cancel: boolean|boolean[]?)
---@class EventsAPI
---`FOXAPI` This event runs when you get patted or unpatted.
---> ```lua
---> (callback) function(patter: Player, state: integer)
--->  -> cancel: boolean|boolean[]?
---> ```
---> ***
---> A callback that is given the data of the player patting you or your skull, and the current patting state.<br><br>Return `true` to cancel both visually patting and hearts. Return `{ boolean, boolean }` to cancel one or the other.
---@field entity_pat Event.EntityPat | Event.EntityPat.func
---`FOXAPI` This event runs when you get patted or unpatted.
---> ```lua
---> (callback) function(patter: Player, state: integer)
--->  -> cancel: boolean|boolean[]?
---> ```
---> ***
---> A callback that is given the data of the player patting you or your skull, and the current patting state.<br><br>Return `true` to cancel both visually patting and hearts. Return `{ boolean, boolean }` to cancel one or the other.
---@field ENTITY_PAT Event.EntityPat | Event.EntityPat.func
---`FOXAPI` This event runs when one of your skulls gets patted or unpatted.
---> ```lua
---> (callback) function(patter: Player, state: integer, coordinates: Vector3)
--->  -> cancel: boolean|boolean[]?
---> ```
---> ***
---> A callback that is given the data of the player patting you or your skull, the current patting state, and the coordinates of this skull.<br><br>Return `true` to cancel both visually patting and hearts. Return `{ boolean, boolean }` to cancel one or the other.
---@field skull_pat Event.SkullPat | Event.SkullPat.func
---`FOXAPI` This event runs when one of your skulls gets patted or unpatted.
---> ```lua
---> (callback) function(patter: Player, state: integer, coordinates: Vector3)
--->  -> cancel: boolean|boolean[]?
---> ```
---> ***
---> A callback that is given the data of the player patting you or your skull, the current patting state, and the coordinates of this skull.<br><br>Return `true` to cancel both visually patting and hearts. Return `{ boolean, boolean }` to cancel one or the other.
---@field SKULL_PAT Event.SkullPat | Event.SkullPat.func
---`FOXAPI` This event runs when you pat another player, entity, or block. It can be used as an alternative to summoning particles.
---> ```lua
---> (callback) function(entity: Player, block: BlockState, boundingBox: Vector3, allowHearts: boolean)
--->  -> cancel: boolean|boolean[]?
---> ```
---> ***
---> A callback that is given the data of the entity you're patting or nil, and the block you are patting or nil, the bounding box, and if the player you're patting allows hearts or not.<br><br>Return `true` to cancel both visually patting and hearts. Return `{ boolean, boolean }` to cancel one or the other.
---@field patting Event.Patting | Event.Patting.func
---`FOXAPI` This event runs when you pat another player, entity, or block. It can be used as an alternative to summoning particles.
---> ```lua
---> (callback) function(entity: Player, block: BlockState, boundingBox: Vector3, allowHearts: boolean)
--->  -> cancel: boolean|boolean[]?
---> ```
---> ***
---> A callback that is given the data of the entity you're patting or nil, and the block you are patting or nil, the bounding box, and if the player you're patting allows hearts or not.<br><br>Return `true` to cancel both visually patting and hearts. Return `{ boolean, boolean }` to cancel one or the other.
---@field PATTING Event.Patting | Event.Patting.func
FOXMetatable.__events = FOXMetatable.__events

--#ENDREGION

return _module

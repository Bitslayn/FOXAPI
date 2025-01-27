---@meta _
--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's Patpat Module v1.0.6
A FOXAPI Module

Lets you pat other players, entities, and skulls.
Forked from Auria's patpat https://github.com/lua-gods/figuraLibraries/blob/main/patpat/patpat.lua

--]]

local apiPath, moduleName = ...
assert(apiPath:find("FOXAPI.modules"), "\n§4FOX's API was not installed correctly!§c")
local _module = {
  _api = { "FOXAPI", "1.0.3", 4 },
  _name = "FOX's Patpat Module",
  _desc = "Lets you pat other players, entities, and skulls.",
  _ver = { "1.0.6", 7 },
}
if not FOXAPI then
  __race = { apiPath:gsub("/", ".") .. "." .. moduleName, _module }
  require(apiPath:match("(.*)modules") .. "api")
end

-- Looking for configs? They've been moved to Examples\Foxpat\foxpatConfig.lua in github
--#REGION ˚♡ Whitelists/blacklists ♡˚

local lists = {

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
}
--#ENDREGION

-- Do not touch anything beyond this point unless you know what you are doing!

--#REGION ˚♡ Init vars and functions ♡˚

FOXAPI.foxpat = {}
FOXAPI.foxpat.config = {}

events:new("entity_pat")
events:new("skull_pat")
events:new("patting")

avatar:store("patpat.boundingBox", FOXAPI.foxpat.config.boundingBox)
avatar:store("foxpat.actAsInteractable",
  FOXAPI.foxpat.config.actAsInteractable or
  (type(FOXAPI.foxpat.config.actAsInteractable) == "nil" and false))

function events.tick()
  if player:getVariable("foxpat.boundingBox") ~= FOXAPI.foxpat.config.boundingBox then
    avatar:store("foxpat.boundingBox", FOXAPI.foxpat.config.boundingBox)
  end
  if player:getVariable("foxpat.actAsInteractable") ~= FOXAPI.foxpat.config.actAsInteractable or (type(FOXAPI.foxpat.config.actAsInteractable) == "nil" and false) then
    avatar:store("foxpat.actAsInteractable",
      FOXAPI.foxpat.config.actAsInteractable or
      (type(FOXAPI.foxpat.config.actAsInteractable) == "nil" and false))
  end
end

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
  -- Entity pat timers
  for uuid, time in pairs(myPatters.entity) do
    if time <= 0 then
      events:call("entity_pat", world.getEntity(uuid), 1)
      myPatters.entity[uuid] = nil
    else
      myPatters.entity[uuid] = time - 1
    end
  end
  -- Skull pat timers
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
  time = math.clamp(time or 0, FOXAPI.foxpat.config.holdFor or 10, 100)
  local entity = world.getEntity(uuid)
  local prev = myPatters.entity[uuid]
  myPatters.entity[uuid] = time
  return events:call("entity_pat", entity, prev and 2 or 0)
end)

avatar:store("petpet.playerHead", function(uuid, time, x, y, z)
  if not x or not y or not z then return end
  time = math.min(time or (FOXAPI.foxpat.config.holdFor or 10), 100)
  local pos = vec(math.floor(x), y, math.floor(z))
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
    not (noHearts or avatarVars["patpat.noHearts"])) -- Keep old compatibility

  -- Process returns from patting events
  returns = parseReturns(ret2)
  noPats, noHearts = noPats or returns[1], noHearts or returns[2]

  -- Play pat animation and swinging
  if not noPats then
    if FOXAPI.foxpat.config.swingArm or (type(FOXAPI.foxpat.config.swingArm) == "nil" and true) then
      host:swingArm()
    end
    if type(FOXAPI.foxpat.config.patAnimation) == "Animation" then
      ---@diagnostic disable-next-line: undefined-field
      FOXAPI.foxpat.config.patAnimation:play()
    end
  end

  -- Emit particles
  if not noHearts and not avatarVars["patpat.noHearts"] then -- Keep old compatibility, particles:isPresent(FOXAPI.foxpat.config.patParticle) not working on 1.21.x until RC7
    pos = pos - boundingBox.x_z * 0.5 + vec(
      math.random(),
      math.random(),
      math.random()
    ) * boundingBox
    particles[FOXAPI.foxpat.config.patParticle or "minecraft:heart"]:pos(pos):size(1):spawn()
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
  if (FOXAPI.foxpat.config.playMobSounds or (type(FOXAPI.foxpat.config.playMobSounds) == "nil" and true)) and not entity:isPlayer() and not entity:isSilent() then
    local soundName = string.format("%s:entity.%s.ambient",
      entity:getType():match("^(.-):(.-)$"))
    if sounds:isPresent(soundName) then
      sounds[soundName]:setPos(entity:getPos()):setPitch((FOXAPI.foxpat.config.mobSoundPitch or 1) *
        ((entity:getNbt().Age or -(entity:getNbt().IsBaby or -1)) >= 0 and 1 or 1.5)):play()
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
  local _, ret = pcall(avatarVars["petpet"], myUuid, FOXAPI.foxpat.config.holdFor or 10)
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
  if FOXAPI.foxpat.config.playNoteSounds or (type(FOXAPI.foxpat.config.playNoteSounds) == "nil" and true) then
    local blockData = block:getEntityData()
    local blockMatch = block.id:match(":(.-)_")
    local soundName
    if blockMatch then
      soundName = blockData and blockData.note_block_sound or
          table.match(noteBlockImitation, '"([%w_:%-%.]-' .. blockMatch .. '[%w_:%-%.]-)"')
    end
    if sounds:isPresent(soundName) then
      sounds[soundName]:setPos(blockPos):setPitch(FOXAPI.foxpat.config.noteSoundPitch or 1):play()
    end
  end

  -- Get bounding box
  local avatarVars = getAvatarVarsFromBlock(block)
  local blockShape = block:getOutlineShape()[1]
  if not blockShape then return end
  local boundingBox = blockShape[2]:sub(blockShape[1]):add(0.3, 0, 0.3)

  -- Call petpet function and process avatar reaction
  local _, ret = pcall(avatarVars["petpet.playerHead"], myUuid, FOXAPI.foxpat.config.holdFor or 10,
    blockPos:unpack())
  patResponse(avatarVars, ret, nil, block, boundingBox, blockPos:add(0.5, 0, 0.5))
end

function pings.foxpatBlock(...)
  if host:isHost() then return end
  foxpatBlockPing(...)
end

--#ENDREGION

--#ENDREGION

--#ENDREGION
--#REGION ˚♡ Host ♡˚

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

  processRegistry(client.getRegistry("minecraft:entity_type"), lists.entity)
  processRegistry(client.getRegistry("minecraft:block"), lists.block)

  --#ENDREGION
  --#REGION ˚♡ Init vars ♡˚

  local foxpat = function(self) end
  local shiftHeld
  local patting, patTime, firstPat = false, 0, true
  local pattingSelf, patSelfTime, firstSelfPat = false, 0, true

  local configFile = "FOXAPI"
  local configAPI = config:loadFrom(configFile, "foxpat") or {
    keybinds = {
      crouch = "key.keyboard.left.shift",
      pat = "key.mouse.right",
      patSelf = "key.mouse.middle",
    },
  }
  config:saveTo(configFile, "foxpat", configAPI)

  --#ENDREGION
  --#REGION ˚♡ Keybinds ♡˚

  ---@type Keybind[]
  local buttons = {
    crouch = keybinds
        :newKeybind("FOXPat - Crouch", "key.keyboard.left.shift")
        :setKey(configAPI.keybinds.crouch or "key.keyboard.left.shift"),
    pat = keybinds
        :newKeybind("FOXPat - Pat", "key.mouse.right")
        :setKey(configAPI.keybinds.pat or "key.mouse.right"),
    patSelf = keybinds
        :newKeybind("FOXPat - Pat Self", "key.mouse.middle")
        :setKey(configAPI.keybinds.patSelf or "key.mouse.middle"),
  }

  function events.tick()
    if host:getScreen() ~= "org.figuramc.figura.gui.screens.KeybindScreen" then return end
    for key, keyCode in pairs(configAPI.keybinds) do
      if buttons[key]:getKey() ~= keyCode then
        configAPI.keybinds[key] = buttons[key]:getKey()
        config:saveTo(configFile, "foxpat", configAPI)
      end
    end
  end

  buttons.crouch:onPress(function() shiftHeld = true end)
  buttons.crouch:onRelease(function() shiftHeld = false end)

  buttons.pat:onPress(function()
    if not host:getScreen() and not action_wheel:isEnabled() and player:isLoaded() then
      patting = true
      foxpat()
    end
  end)
  buttons.pat:onRelease(function()
    patting = false
    firstPat = true
    patTime = 0
  end)

  buttons.patSelf:onPress(function()
    if not host:getScreen() and not action_wheel:isEnabled() and player:isLoaded() then
      pattingSelf = true
      foxpat(true)
    end
  end)
  buttons.patSelf:onRelease(function()
    pattingSelf = false
    firstSelfPat = true
    patSelfTime = 0
  end)

  function events.tick()
    if patting then
      patTime = patTime + 1
      if patTime % (FOXAPI.foxpat.config.patDelay or 3) == 0 then
        foxpat()
      end
    end
    if pattingSelf then
      patSelfTime = patSelfTime + 1
      if patSelfTime % (FOXAPI.foxpat.config.patDelay or 3) == 0 then
        foxpat(true)
      end
    end
  end

  --#ENDREGION
  --#REGION ˚♡ Main pat function ♡˚

  foxpat = function(self)
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
      if not (lists.block.whitelist[block.id] or table.contains(lists.block.whitelist, "*")) or
          (lists.block.blacklist[block.id] or table.contains(lists.block.blacklist, "*")) then
        return
      end

      local blockVars = getAvatarVarsFromBlock(block)
      if blockVars["patpat.noPats"] then return end -- Keep old compatibility
      -- Check crouching
      if not blockVars["foxpat.actAsInteractable"] and
          ((not self and firstPat) or (self and firstSelfPat)) and
          not shiftHeld and buttons.crouch:getID() ~= -1 then
        return
      end
      -- Check empty hand
      if not blockVars["foxpat.actAsInteractable"] and
          ((FOXAPI.foxpat.config.requireEmptyHand or (type(FOXAPI.foxpat.config.requireEmptyHand) == "nil" and true)) and player:getItem(1).id ~= "minecraft:air") or
          ((FOXAPI.foxpat.config.requireEmptyOffHand or (type(FOXAPI.foxpat.config.requireEmptyOffHand) == "nil" and false)) and player:getItem(2).id ~= "minecraft:air") then
        return
      end

      local blockPos = block:getPos()
      local packedCoord = packCoord(blockPos)
      foxpatBlockPing(packedCoord)
      pings.foxpatBlock(packedCoord)
    else
      local entityType = entity:getType()
      if not (lists.entity.whitelist[entityType] or table.contains(lists.entity.whitelist, "*")) or
          (lists.entity.blacklist[entityType] or table.contains(lists.entity.blacklist, "*")) then
        return
      end

      local entityVars = entity:getVariable()
      if entityVars["patpat.noPats"] then return end -- Keep old compatibility
      -- Check crouching
      if not entityVars["foxpat.actAsInteractable"] and
          ((not self and firstPat) or (self and firstSelfPat)) and
          not shiftHeld and buttons.crouch:getID() ~= -1 then
        return
      end
      -- Check empty hand
      if not entityVars["foxpat.actAsInteractable"] and
          ((FOXAPI.foxpat.config.requireEmptyHand or (type(FOXAPI.foxpat.config.requireEmptyHand) == "nil" and true)) and player:getItem(1).id ~= "minecraft:air") or
          ((FOXAPI.foxpat.config.requireEmptyOffHand or (type(FOXAPI.foxpat.config.requireEmptyOffHand) == "nil" and false)) and player:getItem(2).id ~= "minecraft:air") then
        return
      end

      local entityUUID = entity:getUUID()
      local packedUUID = packUUID(entityUUID)
      foxpatEntityPing(packedUUID)
      pings.foxpatEntity(packedUUID)
    end
    if self then
      firstSelfPat = FOXAPI.foxpat.config.requireCrouch or
      (type(FOXAPI.foxpat.config.requireCrouch) == "nil" and false)
    else
      firstPat = FOXAPI.foxpat.config.requireCrouch or
      (type(FOXAPI.foxpat.config.requireCrouch) == "nil" and false)
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

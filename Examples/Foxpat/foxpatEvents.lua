require("FOXAPI.api")

-- This script should not be put into the FOXAPI modules folder!

--#REGION ˚♡ Events ♡˚

-- These only apply to example events lower in this script.
local noPats = false   -- Set this to true to prevent other players from visually patting you.
local noHearts = false -- Set this to true to prevent players from spawning hearts on you.

--#REGION ˚♡ Simple events ♡˚

local playerEvents = {    -- Functions to run when your player gets patted. Uses events.entity_pat(), scroll down to see how it's used.
	onPat = function(entity) -- Fires the first time you are patted

	end,
	onUnpat = function(entity) -- Fires when you stop getting patted

	end,
	togglePat = function(entity, isPetted) -- Fires both when you start and stop getting patted

	end,
	oncePat = function(entity) -- Fires each time you are patted

	end,
	whilePat = function(patters) -- Fires every tick while you're patted

	end,
}

local skullEvents = { -- Similar to the functions above but for when your skull is patted.
	onPat = function(entity, coordinates) end,
	onUnpat = function(entity, coordinates) end,
	togglePat = function(entity, isPetted, coordinates) end,
	oncePat = function(entity, coordinates) end,
	whilePat = function(patters) end,
}

--#ENDREGION
--#REGION ˚♡ Register simple events ♡˚

-- Check the annotations for each event to read how to use them. (Hover your mouse over entity_pat in function events.entity_pat)

function events.entity_pat(entity, state)
	if state == 0 then
		playerEvents.onPat(entity)
	elseif state == 1 then
		playerEvents.onUnpat(entity)
	elseif state ~= 2 then
		playerEvents.togglePat(entity, state == 0)
	else
		playerEvents.oncePat(entity)
	end
	return { noPats, noHearts }
end

function events.skull_pat(entity, state, coordinates)
	if state == 0 then
		skullEvents.onPat(entity, coordinates)
	elseif state == 1 then
		skullEvents.onUnpat(entity, coordinates)
	elseif state ~= 2 then
		skullEvents.togglePat(entity, state == 0, coordinates)
	elseif state == 2 then
		skullEvents.oncePat(entity, coordinates)
	end
	return { noPats, noHearts }
end

--#ENDREGION
--#REGION ˚♡ Register whilePat event ♡˚

local lastPat = 0
local numberOfPatters, numberOfSkullPatters = 0, 0
local entityPatters, skullPatters = {}, {}

function events.entity_pat(entity, state)
	lastPat = world.getTime()
	if state == 0 then
		numberOfPatters = numberOfPatters + 1
		table.insert(entityPatters, entity)
	elseif state == 1 then
		numberOfPatters = numberOfPatters - 1
		table.remove(entityPatters, table.find(entityPatters, entity))
	end
end

function events.skull_pat(entity, state)
	lastPat = world.getTime()
	if state == 0 then
		numberOfSkullPatters = numberOfSkullPatters + 1
		table.insert(skullPatters, entity)
	elseif state == 1 then
		numberOfSkullPatters = numberOfSkullPatters - 1
		table.remove(skullPatters, table.find(skullPatters, entity))
	end
end

function events.tick()
	if numberOfPatters > 0 then
		playerEvents.whilePat(entityPatters)
	end
	if numberOfSkullPatters > 0 then
		skullEvents.whilePat(skullPatters)
	end
	if lastPat + FOXAPI.foxpat.config.holdFor < world.getTime() then
		numberOfPatters, numberOfSkullPatters = 0, 0
		entityPatters, skullPatters = {}, {}
	end
end

--#ENDREGION

--#ENDREGION

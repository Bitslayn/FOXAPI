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
}

local skullEvents = { -- Similar to the functions above but for when your skull is patted.
	onPat = function(entity, coordinates) end,
	onUnpat = function(entity, coordinates) end,
	togglePat = function(entity, isPetted, coordinates) end,
	oncePat = function(entity, coordinates) end,
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

-- Uncomment this if you wish to use a custom particle system.

-- function events.patting(entity, block, boundingBox, allowHearts)
-- 	if allowHearts then -- Players who do not consent to hearts should be respected. Do NOT play ANY sounds or particles on them if this is false.
-- 		local pos
-- 		if block then
-- 			pos = block:getPos():add(0.5, 0, 0.5)
-- 		elseif entity then
-- 			pos = entity:getPos()
-- 		end
-- 		pos = pos - boundingBox.x_z * 0.5 + vec(
-- 			math.random(),
-- 			math.random(),
-- 			math.random()
-- 		) * boundingBox
-- 		particles["minecraft:heart"]:pos(pos):size(1):spawn()
-- 	end
-- 	return { false, true } -- Cancel particles but not swinging
-- end

--#ENDREGION

--#ENDREGION

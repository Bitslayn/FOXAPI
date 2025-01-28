require("FOXAPI.api")

-- This script should not be put into the FOXAPI modules folder!

local noPats = false   -- Set this to true to prevent other players from visually patting you.
local noHearts = false -- Set this to true to prevent players from spawning hearts on you.

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
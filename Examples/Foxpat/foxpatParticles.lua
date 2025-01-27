require("FOXAPI.api")

-- This script should not be put into the FOXAPI modules folder!

function events.patting(entity, block, boundingBox, allowHearts)
	if allowHearts then -- Players who do not consent to hearts should be respected. Do NOT play ANY sounds or particles on them if this is false.
		local pos
		if block then
			pos = block:getPos():add(0.5, 0, 0.5)
		elseif entity then
			pos = entity:getPos()
		end
		pos = pos - boundingBox.x_z * 0.5 + vec(
			math.random(),
			math.random(),
			math.random()
		) * boundingBox
		particles["minecraft:heart"]:pos(pos):scale(1):spawn()
	end
	return { false, true } -- Cancel particles but not swinging
end
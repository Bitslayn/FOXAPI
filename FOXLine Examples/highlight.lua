-- Block hitboxes/highlight
local fox = require("FOXAPI.api")
local enable = false
if host:isHost() then
  if not enable then return end
  local highlighted, lastHighlighted
  local shape
  local drawnCubes = {}
  local reach = host:getReachDistance()
  function events.tick()
    -- Check the block the player is looking at and set the highlighted variable if that block has a hitbox
    local block, hitPos = player:getTargetedBlock(true, 100)
    shape = block:getOutlineShape()
    local n = #shape
    highlighted = n ~= 0 and block:getPos() or nil
    if highlighted and (player:getPos():add(0, player:getEyeHeight(), 0):add(renderer:getEyeOffset()) - hitPos):length() > reach then
      highlighted = nil
    end

    -- Check if the block hitbox changes
    if highlighted ~= lastHighlighted or player:getSwingTime() == 1 then -- Checking for swinging arm is the easiest way to guess if the hitbox shape changed
      lastHighlighted = highlighted

      -- First, clear all the existing lines. Don't want to start creating hitboxes all over the place.
      for i, cube in pairs(drawnCubes) do
        cube:remove()
        drawnCubes[i] = nil
      end

      -- Second, create boxes from lines at the block hitbox coordinates.
      for _, outline in pairs(shape) do
        if highlighted then
          table.insert(drawnCubes, fox.cube.new():setPos(highlighted + outline[1]):setSize(outline[2] - outline[1]))
        end
      end
    end

    -- RGB hitbox
    for _, cube in ipairs(drawnCubes) do
      for _, line in ipairs(cube) do
        line:setColor(vectors.hsvToRGBA((world.getTime() % 100) / 100, 1, 1, 0.4))
      end
    end
  end
end
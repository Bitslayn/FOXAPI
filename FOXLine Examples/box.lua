-- Cube with dotted lines
local fox = require("FOXAPI.api")
local enable = false
if host:isHost() then
  if not enable then return end
  function events.entity_init()
    local cube = fox.cube.new():setCenter(0.5, 1, 0.5):setPos(player:getPos())
    for _, line in ipairs(cube) do
      line:setDottedLine(1, 4):setOutlineColor(vec(0, 0, 0))
    end
    cube[1]:setColor(vectors.hexToRGB("#ff0000")):setDottedLine(8, 2, 1, 2) -- Red
    cube[2]:setColor(vectors.hexToRGB("#00ff00")):setDottedLine(8, 2, 1, 2) -- Green
    cube[3]:setColor(vectors.hexToRGB("#7f7fff")):setDottedLine(8, 2, 1, 2) -- Blue
  end
end

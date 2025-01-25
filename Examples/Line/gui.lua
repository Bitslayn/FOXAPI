-- Screen border
local fox = require("FOXAPI.api")
local enable = false -- Set this to true to enable this script

-- This script should not be put into the FOXAPI modules folder!

if host:isHost() then
  if not enable then return end
  local width = 10
  local square = fox.square.new():setCenter(0, 0):setPos(-width, -width):setSize(client.getScaledWindowSize() - width * 2)
  for _, line in ipairs(square) do
    line:setBorderColor(vec(0, 0, 0)):width(width):setOutlineZOffset(1):setOutlineRenderType("END_PORTAL"):setDashedLine(1, 4)
  end
end

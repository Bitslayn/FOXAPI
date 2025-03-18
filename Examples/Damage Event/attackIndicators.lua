require("FOXAPI.api")

---@type table<number, indicator>
local indicators = {}

-- Moves all indicators and removes indicators after 15 ticks

function events.tick()
  for i, indicator in pairs(indicators) do
    indicator.tick = indicator.tick + 1
    if indicator.tick < 15 then return end
    indicator.task:remove()
    indicator.gimbal:remove()
    indicator.part:remove()
    indicators[i] = nil
  end
end

-- Lerps all indicators

function events.render(delta, context)
  if context == "PAPERDOLL" then return end
  for _, indicator in pairs(indicators) do
    indicator.part:setPos((indicator.pos * 16) + vec(0, indicator.tick + delta, 0))
  end
end

-- Creates a new indicator

local function newIndicator(pos, num)
  ---@class indicator
  local indicator = {
    part = models:newPart(tostring(math.random()), "World"),
    tick = 0,
    pos = pos,
  }
  indicator.gimbal = indicator.part
      :setPos(indicator.pos * 16)
      :newPart(tostring(math.random()), "Camera")
  indicator.task = indicator.gimbal
      :newText(tostring(math.random()))
      :setText("§c" .. string.format("%.2f", num))
      :setOutline(true)
      :setAlignment("CENTER")
      :setScale(0.4)
  table.insert(indicators, indicator)
end

-- Damage event runs function to create indicators

function events.damage(entity, source, damage)
  -- Avoid creating multiple damage indicators by checking if the target player has this script installed.
  if entity:getVariable("hasDamageIndicators") and entity ~= player then return end -- Keep this
  if not (entity == player or source == player) then return end
  newIndicator(entity:getPos() + entity:getBoundingBox()._y_, damage)
end

avatar:store("hasDamageIndicators", true) -- Keep this

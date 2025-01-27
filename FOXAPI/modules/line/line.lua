---@meta _
--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's Line Module v1.0.0
A FOXAPI Module

Lets you draw lines.

--]]

local apiPath, moduleName = ...
assert(apiPath:find("FOXAPI.modules"), "\n§4FOX's API was not installed correctly!§c")
local _module = {
  _api = { "FOXAPI", "1.0.3", 4 },
  _name = "FOX's Line Module",
  _desc = "Lets you draw lines.",
  _ver = { "1.0.1", 2 },
}
if not FOXAPI then
  __race = { apiPath:gsub("/", ".") .. "." .. moduleName, _module }
  require(apiPath:match("(.*)modules") .. "api")
end

---Contains all the registered lines
---@type FOXAPI.Line[]
FOXAPI.lines = {}
---Line module functions
FOXAPI.line = {}

-- Localized function calls
local _client_getScaledWindowSize = client.getScaledWindowSize
local _client_getGuiScale = client.getGuiScale
local _client_getCameraPos = client.getCameraPos
local _vectors_worldToScreenSpace = vectors.worldToScreenSpace
local _math_atan = math.atan2

local function _generateDashTexture(...)
  local dashes = { ... }

  local w, p = 0, ""
  for _, n in pairs(dashes) do
    w = w + n
    p = p .. "_" .. tostring(n)
  end

  local name = "_foxLine" .. p

  if not textures[name] then
    local tex = textures:newTexture("_foxLine" .. p, w, 1)
    local pos = 0
    for i = 1, #dashes do
      pos = pos + (dashes[i - 1] or 0)
      tex:fill(pos, 0, dashes[i], 1, i % 2 == 1 and vec(1, 1, 1, 1) or vec(0, 0, 0, 0))
    end
    return tex
  else
    return textures[name]
  end
end

local function _generateOutlineDashTexture(...)
  local dashes = { ... }
  local _dashes = {}
  for i, n in ipairs(dashes) do
    _dashes[i] = (n + (i % 2 == 1 and 1 or -1)) * 2
  end
  _dashes[1] = _dashes[1] - 1
  _dashes[#_dashes + 1] = 1
  return _generateDashTexture(table.unpack(_dashes))
end

local _radToDeg = (180 / math.pi)

local windowSize, guiScale, cameraPos
local function _calculateVars()
  windowSize = _client_getScaledWindowSize():div(-2, -2)
  guiScale = _client_getGuiScale()
  cameraPos = _client_getCameraPos()
end
_calculateVars()
function events.tick() _calculateVars() end

--#REGION newLine()

---Creates a new line.
---@nodiscard
local function _newLine()
  --#REGION ˚♡ Init ♡˚
  assert(host:isHost(),
    "This function is meant to run on the host only! Consider putting this function inside a host:isHost() check",
    2)

  ---@class FOXAPI.Line
  local _self = setmetatable({}, FOXAPI.line)
  local _tbl = {}

  _tbl.dash = _generateDashTexture(1)
  _tbl.dashIndex = { 1 }
  _tbl.color = vec(1, 1, 1, 1)
  _tbl.outlineColor = vec(0, 0, 0, 1)
  _tbl.width = 2
  _tbl.distance = nil
  _tbl.outlineDistance = nil
  _tbl.visible = true
  _tbl.outlineVisible = false
  _tbl.anchor = "world"
  _tbl.renderType = "TRANSLUCENT"

  -- Define modelparts and parameter defaults
  ---@type ModelPart
  _tbl.linePart = models:newPart("_foxLine-" .. tostring(math.random()), "GUI")
  ---@type SpriteTask
  _tbl.lineSprite = _tbl.linePart:newSprite("line")
      :setTexture(_tbl.dash):setColor(_tbl.color)
  ---@type SpriteTask
  _tbl.outlineSprite = _tbl.linePart:newSprite("outline")
      :setTexture(_tbl.dash):setColor(_tbl.outlineColor)

  _tbl.lineName = _tbl.linePart:getName()


  local function _calculateAnchor()
    local _type1, _type2 = type(_tbl.pos1), type(_tbl.pos2)
    if _type1 == _type2 then
      _tbl.anchor = _type1 == "Vector3" and "world" or "screen"
    else
      _tbl.anchor = "mixed"
      _tbl.flipped = _type1 == "Vector3"
    end
  end

  --#ENDREGION
  --#REGION ˚♡ Render ♡˚

  -- Calculate line positions to screen
  local calcScreen = {
    world = function()                                                               -- Both points are worldspace
      local pos2 = _vectors_worldToScreenSpace(_tbl.pos2)
      if pos2 == _tbl.lastPos2 and _tbl.lastWindowSize == windowSize then return end -- Stop here if the line hasn't move
      _tbl.lastPos2, _tbl.lastWindowSize = pos2, windowSize
      local pos1 = _vectors_worldToScreenSpace(_tbl.pos1)
      if pos1.z < 1 or pos2.z < 1 then return true end -- Stop here if the line is off screen
      local distance = (_tbl.pos1 - cameraPos):length()
      return pos1, pos2, distance
    end,
    screen = function()                                                              -- Both points are screenspace
      local pos1, pos2 = _tbl.pos1, _tbl.pos2
      if pos2 == _tbl.lastPos2 and _tbl.lastWindowSize == windowSize then return end -- Stop here if the line hasn't move
      _tbl.lastPos2, _tbl.lastWindowSize = pos2, windowSize
      return (pos1 / windowSize) - 1, (pos2 / windowSize) - 1
    end,
    mixed = function() -- Points on different coordinate spaces
      local pos1, pos2 = _tbl.flipped and _tbl.pos2 or _tbl.pos1,
          _vectors_worldToScreenSpace(_tbl.flipped and _tbl.pos1 or _tbl.pos2)
      if pos2 == _tbl.lastPos2 and _tbl.lastWindowSize == windowSize then return end -- Stop here if the line hasn't move
      _tbl.lastPos2, _tbl.lastWindowSize = pos2, windowSize
      if pos2.z < 1 then return true end                                             -- Stop here if the line is off screen
      return (pos1 / windowSize) - 1, pos2
    end,
  }

  local function _render()
    assert(_tbl.pos1 and _tbl.pos2,
      "Error in render! A line's first and/or second position was undefined!", 2)
    if not _tbl.visible then return end

    -- Calculate line positions to screen
    local pos1, pos2, distance = calcScreen[_tbl.anchor]()
    if not pos1 then return end
    if pos1 == true then
      _tbl.lineSprite:setVisible(false)
      _tbl.outlineSprite:setVisible(false)
      return
    end

    -- Calculate line
    local secondPoint = pos2.xy:add(1, 1):mul(windowSize):augmented(0)
    if _tbl.lastPos ~= secondPoint then
      _tbl.lastPos = secondPoint
      local firstPoint = pos1.xy:add(1, 1):mul(windowSize):augmented(0)

      local length = (firstPoint - secondPoint):length()
      local angle =
          _math_atan(firstPoint.y - secondPoint.y, firstPoint.x - secondPoint.x) * _radToDeg
      distance = (distance or 0) + (_tbl.distance or 0)
      local region = length / _tbl.dash:getDimensions().x * 1000 / _tbl.width * 2

      -- Draw line
      local visible = _tbl.visible and _tbl.renderType ~= "NONE"
      _tbl.lineSprite:setVisible(visible)
      if visible then
        _tbl.lineSprite:setSize(length, _tbl.width / guiScale):setRegion(region)
      end

      local outlineVisible = _tbl.outlineVisible and _tbl.renderType ~= "NONE"
      _tbl.outlineSprite:setVisible(outlineVisible)
      if outlineVisible then
        _tbl.outlineSprite:setSize(length, (_tbl.width * 2) / guiScale):setRegion(region)
      end

      _tbl.linePart:setPos(firstPoint):setRot(0, 0, angle)
      -- Offset by the width and sort by distance
      _tbl.lineSprite:setPos(0, _tbl.width / guiScale / 2, distance)
      _tbl.outlineSprite:setPos(0, _tbl.width / guiScale,
        distance + (_tbl.outlineDistance or 0) + 0.01)
    end
  end

  --#ENDREGION
  --#REGION ˚♡ Returned functions ♡˚

  --#REGION ˚♡ Generic ♡˚

  --#REGION pos()

  ---Sets this line's first and second positions. If a Vec2 is provided, the position is screenspace. If it's Vec3 then it's worldspace.
  ---@overload fun(self, x1: number, y1: number, z1: number, x2: number, y2: number, z2: number): FOXAPI.Line
  ---@overload fun(self, pos1: Vector2|Vector3, x2: number, y2: number, z2: number): FOXAPI.Line
  ---@overload fun(self, x1: number, y1: number, z1: number, pos2: Vector2|Vector3): FOXAPI.Line
  ---@overload fun(self, pos1: Vector2|Vector3, pos2: Vector2|Vector3): FOXAPI.Line
  local function _pos(_, ...)
    local _args = { ... }
    local _type1, _type2, _type4 = type(_args[1]), type(_args[2]), type(_args[4])
    if _type1 == "number" and _type4 == "number" then
      _tbl.pos1, _tbl.pos2 = vec(_args[1], _args[2], _args[3]), vec(_args[4], _args[5], _args[6])
    elseif (_type1 == "Vector2" or _type1 == "Vector3") and (_type2 == "Vector2" or _type2 == "Vector3") then
      _tbl.pos1, _tbl.pos2 = _args[1], _args[2]
    elseif (_type1 == "Vector2" or _type1 == "Vector3") and _type2 == "number" then
      _tbl.pos1, _tbl.pos2 = _args[1], vec(_args[2], _args[3], _args[4])
    elseif _type1 == "number" and (_type4 == "Vector2" or _type4 == "Vector3") then
      _tbl.pos1, _tbl.pos2 = vec(_args[1], _args[2], _args[3]), _args[4]
    end
    _tbl.pos1, _tbl.pos2 = _tbl.pos1 or vec(0, 0, 0), _tbl.pos2 or vec(0, 0, 0)
    _calculateAnchor()
    return _self
  end
  _self.pos = _pos
  _self.setPos = _pos
  _self.posAB = _pos
  _self.setPosAB = _pos

  --#ENDREGION
  --#REGION firstPos()

  ---Sets this line's first position. If a Vec2 is provided, the position is screenspace. If it's Vec3 then it's worldspace.
  ---@overload fun(self, x: number, y: number, z?: number): FOXAPI.Line
  ---@overload fun(self, vec): FOXAPI.Line
  local function _firstPos(_, ...)
    local _args = { ... }
    local _type1 = type(_args[1])
    if _type1 == "number" then
      _tbl.pos1 = vec(_args[1], _args[2], _args[3])
    elseif (_type1 == "Vector2" or _type1 == "Vector3") then
      _tbl.pos1 = _args[1]
    else
      _tbl.pos1 = vec(0, 0, 0)
    end
    _calculateAnchor()
    return _self
  end
  _self.firstPos = _firstPos
  _self.setFirstPos = _firstPos
  _self.posA = _firstPos
  _self.setPosA = _firstPos

  --#ENDREGION
  --#REGION secondPos()

  ---Sets this line's second position. If a Vec2 is provided, the position is screenspace. If it's Vec3 then it's worldspace.
  ---@overload fun(self, x: number, y: number, z?: number): FOXAPI.Line
  ---@overload fun(self, vec): FOXAPI.Line
  local function _secondPos(_, ...)
    local _args = { ... }
    local _type1 = type(_args[1])
    if _type1 == "number" then
      _tbl.pos2 = vec(_args[1], _args[2], _args[3])
    elseif (_type1 == "Vector2" or _type1 == "Vector3") then
      _tbl.pos2 = _args[1]
    else
      _tbl.pos2 = vec(0, 0, 0)
    end
    _calculateAnchor()
    return _self
  end
  _self.secondPos = _secondPos
  _self.setSecondPos = _secondPos
  _self.posB = _secondPos
  _self.setPosB = _secondPos

  --#ENDREGION
  --#REGION getPos()

  ---Returns this line's first and second positions.
  ---@return Vector2|Vector3 # First position
  ---@return Vector2|Vector3 # Second position
  local function _getPos() return _tbl.pos1, _tbl.pos2 end
  _self.getPos = _getPos
  _self.getPosAB = _getPos

  --#ENDREGION
  --#REGION width()

  ---Sets this line's width. Defaults to 1.
  ---@overload fun(self, width?: number): FOXAPI.Line
  local function _setWidth(_, width)
    _tbl.width = width and width * 2 or 2
    return _self
  end
  _self.width = _setWidth
  _self.setWidth = _setWidth

  --#ENDREGION
  --#REGION getWidth()

  ---Returns this line's width.
  ---@return number
  local function _getWidth() return _tbl.width / 2 end
  _self.getWidth = _getWidth

  --#ENDREGION
  --#REGION setVisible()

  ---Sets whether this line is visible. Defaults to true.
  ---@overload fun(self, visible?: boolean): FOXAPI.Line
  local function _setVisible(_, visible)
    _tbl.visible = visible
    _tbl.lineSprite:setVisible(false)
    return _self
  end
  _self.visible = _setVisible
  _self.setVisible = _setVisible

  --#ENDREGION
  --#REGION isVisible()

  ---Returns whether this line is visible. Doesn't return whether the line is currently on screen. For that, call `getTrueVisibility` instead.
  ---@return boolean
  local function _isVisible() return _tbl.visible end
  _self.isVisible = _isVisible

  --#ENDREGION
  --#REGION getTrueVisibility()

  ---Returns whether this line is actually visible on screen.
  ---@return boolean
  local function _getTrueVisibility() return _tbl.lineSprite:isVisible() end
  _self.getTrueVisibility = _getTrueVisibility

  --#ENDREGION
  --#REGION setDottedLine()

  ---Sets this line to a dotted line defined by the numbers. Every odd number is the length of the dash and every even number are spaces between dashes. Defaults to 1 or a solid line.
  ---@overload fun(self, dashes?: number): FOXAPI.Line
  local function _setDottedLine(_, ...)
    _tbl.dash = ... and _generateDashTexture(...) or _generateDashTexture(1)
    _tbl.outlineDash = ... and _generateOutlineDashTexture(...) or _generateDashTexture(1)
    _tbl.dashIndex = { ... }
    _tbl.lineSprite:setTexture(_tbl.dash, 1000, 1)
    _tbl.outlineSprite:setTexture(_tbl.outlineDash, 1000, 1)
    return _self
  end
  _self.dottedLine = _setDottedLine
  _self.setDottedLine = _setDottedLine
  _self.dashedLine = _setDottedLine
  _self.setDashedLine = _setDottedLine

  --#ENDREGION
  --#REGION getDottedLine()

  ---Returns the numbers used to create this line's dotted line.
  ---@return number ...
  local function _getDottedLine() return table.unpack(_tbl.dashIndex) end
  _self.getDottedLine = _getDottedLine
  _self.getDashedLine = _getDottedLine

  --#ENDREGION
  --#REGION remove()

  ---Removes this line
  local function _remove()
    FOXAPI.lines[_tbl.lineName] = nil
    _tbl.linePart:remove()
    _tbl.lineSprite:remove()
    _tbl.outlineSprite:remove()
    _render = nil
    _self = nil
    _tbl = nil
  end
  _self.remove = _remove

  --#ENDREGION

  --#ENDREGION
  --#REGION ˚♡ Inner line ♡˚

  --#REGION color()

  ---Sets this line's color. Takes a vector. Defaults to white.
  ---@overload fun(self, color?: Vector3|Vector4): FOXAPI.Line
  local function _setColor(_, color)
    local _type = type(color)
    assert(_type == "Vector3" or _type == "Vector4", "Expected Vector3 or Vector4, got " .. _type, 2)
    _tbl.color = color or vec(1, 1, 1, 1)
    _tbl.lineSprite:setColor(_tbl.color)
    return _self
  end
  _self.color = _setColor
  _self.setColor = _setColor

  --#ENDREGION
  --#REGION getColor()

  ---Returns this line's color.
  ---@return Vector3|Vector4
  local function _getColor() return _tbl.color end
  _self.getColor = _getColor

  --#ENDREGION
  --#REGION setZOffset()

  ---Sets this line's z offset from the screen in blocks. Negative offsets bring the line closer.
  ---@overload fun(self, distance?: number): FOXAPI.Line
  local function _setZOffset(_, distance)
    _tbl.distance = distance
    return _self
  end
  _self.zOffset = _setZOffset
  _self.setZOffset = _setZOffset

  --#ENDREGION
  --#REGION getZOffset()

  ---Returns this line's z offset. Returns nil unless overridden.
  ---@return number|nil
  local function _getZOffset() return _tbl.distance end
  _self.getZOffset = _getZOffset

  --#ENDREGION
  --#REGION setRenderType()

  ---Sets this line's render type. Defaults to translucent.
  ---@overload fun(self, renderType?: ModelPart.renderType): FOXAPI.Line
  local function _setRenderType(_, renderType)
    _tbl.renderType = renderType or "TRANSLUCENT"
    _tbl.lineSprite:setRenderType(renderType)
    return _self
  end
  _self.renderType = _setRenderType
  _self.setRenderType = _setRenderType

  --#ENDREGION
  --#REGION getRenderType()

  ---Returns this line's render type
  ---@return ModelPart.renderType
  local function _getRenderType() return _tbl.renderType end
  _self.getRenderType = _getRenderType

  --#ENDREGION

  --#ENDREGION
  --#REGION ˚♡ Outer line ♡˚

  --#REGION outlineColor()

  ---Sets this line's outline color. Takes a vector. If the color is nil, the outline is removed.
  ---@overload fun(self, color?: Vector3|Vector4): FOXAPI.Line
  local function _setOutlineColor(_, color)
    _tbl.outlineVisible = color
    local _type = type(color)
    assert(_type == "Vector3" or _type == "Vector4", "Expected Vector3 or Vector4, got " .. _type, 2)
    _tbl.outlineColor = color
    _tbl.outlineSprite:setColor(_tbl.outlineColor)
    return _self
  end
  _self.outlineColor = _setOutlineColor
  _self.setOutlineColor = _setOutlineColor
  _self.borderColor = _setOutlineColor
  _self.setBorderColor = _setOutlineColor

  --#ENDREGION
  --#REGION getOutlineColor()

  ---Returns this line's outline color.
  ---@return Vector3|Vector4
  local function _getOutlineColor() return _tbl.outlineColor end
  _self.getOutlineColor = _getOutlineColor
  _self.getBorderColor = _getOutlineColor

  --#ENDREGION
  --#REGION setZOffset()

  ---Sets this line's outline's z offset from the screen in blocks.
  ---@overload fun(self, distance?: number): FOXAPI.Line
  local function _setOutlineZOffset(_, distance)
    _tbl.outlineDistance = math.max(distance, 0)
    return _self
  end
  _self.outlineZOffset = _setOutlineZOffset
  _self.setOutlineZOffset = _setOutlineZOffset
  _self.borderZOffset = _setOutlineZOffset
  _self.setBorderZOffset = _setOutlineZOffset

  --#ENDREGION
  --#REGION getZOffset()

  ---Returns this line's outline's z offset. Returns nil unless overridden.
  ---@return number|nil
  local function _getOutlineZOffset() return _tbl.outlineDistance end
  _self.getOutlineZOffset = _getOutlineZOffset
  _self.getBorderZOffset = _getOutlineZOffset

  --#ENDREGION
  --#REGION setOutlineRenderType()

  ---Sets this line's outline's render type. Defaults to translucent.
  ---@overload fun(self, renderType?: ModelPart.renderType): FOXAPI.Line
  local function _setOutlineRenderType(_, renderType)
    _tbl.outlineRenderType = renderType or "TRANSLUCENT"
    _tbl.outlineSprite:setRenderType(renderType)
    return _self
  end
  _self.outlineRenderType = _setOutlineRenderType
  _self.setOutlineRenderType = _setOutlineRenderType
  _self.borderRenderType = _setOutlineRenderType
  _self.setBorderRenderType = _setOutlineRenderType

  --#ENDREGION
  --#REGION getOutlineRenderType()

  ---Returns this line's outline's render type
  ---@return ModelPart.renderType
  local function _getOutlineRenderType() return _tbl.outlineRenderType end
  _self.getOutlineRenderType = _getOutlineRenderType
  _self.getBorderRenderType = _getOutlineRenderType

  --#ENDREGION

  --#ENDREGION

  --#ENDREGION
  ---@diagnostic disable-next-line: missing-fields
  FOXAPI.lines[_tbl.lineName] = { _tbl, _render }
  return _self
end
FOXAPI.line.new = _newLine

--#ENDREGION
--#REGION clearLines()

---Removes all registered lines
local function _clearLines() for _, line in ipairs(FOXAPI.lines) do line:remove() end end
FOXAPI.line.clear = _clearLines

--#ENDREGION

models:newPart("_eventsProxy", "Gui"):setPreRender(function()
  for _, line in pairs(FOXAPI.lines) do line[2]() end
end)

return _module

---@meta _
--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's Square Module v1.0.0
A FOXAPI Module

Lets you draw squares using the line module.

--]]

local apiPath, moduleName = ...
assert(apiPath:find("FOXAPI.modules"), "\n§4FOX's API was not installed correctly!§c")
local _module = {
  _api = { "FOXAPI", "1.0.0", 1 },
  _name = "FOX's Square Module",
  _desc = "Lets you draw squares using FOX's Line Module.",
  _require = { "FOX's Line Module", "1.0.0", 1 },
  _ver = { "1.0.0", 1 },
}
if not FOXAPI then
  __race = { apiPath:gsub("/", ".") .. "." .. moduleName, _module }
  require(apiPath:match("(.*)modules") .. "api")
end

---@diagnostic disable: param-type-mismatch

---Contains all the registered squares
---@type FOXAPI.Square[]
FOXAPI.squares = {}
---Square module functions
FOXAPI.square = {}

--#REGION newSquare()

---Creates a new square out of lines. Booleans can be passed to prevent some lines from being created.
---@param ... boolean If true will prevent a line from being created. The order is north, east, south, west.
---@nodiscard
local function _newSquare(...)
  --#REGION ˚♡ Init ♡˚
  assert(host:isHost(),
    "This function is meant to run on the host only! Consider putting this function inside a host:isHost() check",
    2)
  local args = { ... }

  ---@class FOXAPI.Square
  ---@field private [number] FOXAPI.Line
  local _self = setmetatable({}, FOXAPI.square)
  local _tbl = {}
  table.insert(FOXAPI.squares, _tbl)

  ---@type Vector2|Vector3
  _tbl.pos = vec(0, 0, 0)
  _tbl.size = vec(1, 1)
  _tbl.center = vec(1, 1)
  _tbl.matrix = matrices.rotation3(0, 0, 0)

  local lineMap = {
    { vec(1, 1), vec(0, 1) }, -- North
    { vec(0, 0), vec(0, 1) }, -- East
    { vec(0, 0), vec(1, 0) }, -- South
    { vec(1, 1), vec(1, 0) }, -- West
  }

  -- Remove lines where argument is true
  for i = #lineMap, 1, -1 do
    if args[i] then
      table.remove(lineMap, i)
    end
  end

  -- Create lines
  for _, v in ipairs(lineMap) do
    if type(_tbl.pos) == "Vector3" then
      table.insert(_self, FOXAPI.line.new():pos(
        (v[1].x_y * _tbl.size.x_y - (_tbl.center.x_y * _tbl.size.x_y))
        :transform(_tbl.matrix):add(_tbl.pos),
        (v[2].x_y * _tbl.size.x_y - (_tbl.center.x_y * _tbl.size.x_y))
        :transform(_tbl.matrix):add(_tbl.pos)
      ))
    elseif type(_tbl.pos) == "Vector2" then
      table.insert(_self, FOXAPI.line.new():pos(
        (v[1] * _tbl.size - (_tbl.center * _tbl.size))
        :transform(_tbl.matrix:deaugmented()):add(_tbl.pos),
        (v[2] * _tbl.size - (_tbl.center * _tbl.size))
        :transform(_tbl.matrix:deaugmented()):add(_tbl.pos)
      ))
    end
  end

  local function _updateLines()
    for i, v in ipairs(_self) do
      if type(_tbl.pos) == "Vector3" then
        v:pos(
          (lineMap[i][1].x_y * _tbl.size.x_y - (_tbl.center.x_y * _tbl.size.x_y))
          :transform(_tbl.matrix):add(_tbl.pos),
          (lineMap[i][2].x_y * _tbl.size.x_y - (_tbl.center.x_y * _tbl.size.x_y))
          :transform(_tbl.matrix):add(_tbl.pos)
        )
      elseif type(_tbl.pos) == "Vector2" then
        v:pos(
          (lineMap[i][1] * _tbl.size - (_tbl.center * _tbl.size))
          :transform(_tbl.matrix:deaugmented()):add(_tbl.pos),
          (lineMap[i][2] * _tbl.size - (_tbl.center * _tbl.size))
          :transform(_tbl.matrix:deaugmented()):add(_tbl.pos)
        )
      end
    end
  end

  --ENDREGION
  --#REGION ˚♡ Returned functions ♡˚

  --#REGION pos()

  ---Sets this square's position. Defaults to vec(0, 0, 0).
  ---@overload fun(self, x: number, y: number, z: number): FOXAPI.Square
  ---@overload fun(self, pos: Vector2|Vector3): FOXAPI.Square
  local function _pos(_, ...)
    local _args = { ... }
    local _type1 = type(_args[1])
    if _type1 == "number" then
      _tbl.pos = vec(_args[1], _args[2], _args[3])
    elseif _type1 == "Vector2" or _type1 == "Vector3" then
      _tbl.pos = _args[1]
    else
      _tbl.pos = vec(0, 0, 0)
    end
    _updateLines()
    return _self
  end
  _self.pos = _pos
  _self.setPos = _pos

  --#ENDREGION
  --#REGION getPos()

  ---Returns this square's position.
  ---@return Vector2|Vector3
  local function _getPos() return _tbl.pos end
  _self.getPos = _getPos

  --#ENDREGION
  --#REGION size()

  ---Sets this square's size. Defaults to vec(1, 1).
  ---@overload fun(self, x: number, y: number): FOXAPI.Square
  ---@overload fun(self, size?: Vector2): FOXAPI.Square
  local function _setSize(_, ...)
    local _args = { ... }
    local _type1 = type(_args[1])
    if _type1 == "number" then
      _tbl.size = vec(_args[1], _args[2])
    elseif _type1 == "Vector2" then
      _tbl.size = _args[1]
    else
      _tbl.size = vec(1, 1)
    end
    _updateLines()
    return _self
  end
  _self.size = _setSize
  _self.setSize = _setSize

  --#ENDREGION
  --#REGION getSize()

  ---Returns this square's size.
  ---@return Vector2
  local function _getSize() return _tbl.size end
  _self.getSize = _getSize

  --#ENDREGION
  --#REGION center()

  ---Sets this square's center. vec(0, 0) is the bottom right corner, vec(0.5, 0.5) is the center, and vec(1, 1) is the top left corner. Defaults to vec(0, 0).
  ---@overload fun(self, x: number, y: number): FOXAPI.Square
  ---@overload fun(self, center?: Vector2): FOXAPI.Square
  local function _setCenter(_, ...)
    local _args = { ... }
    local _type1 = type(_args[1])
    if _type1 == "number" then
      _tbl.center = vec(_args[1], _args[2]):mul(-1, -1):add(1, 1)
    elseif _type1 == "Vector2" then
      _tbl.center = _args[1]:mul(-1, -1):add(1, 1)
    else
      _tbl.center = vec(1, 1)
    end
    _updateLines()
    return _self
  end
  _self.center = _setCenter
  _self.setCenter = _setCenter

  --#ENDREGION
  --#REGION getCenter()

  ---Returns this square's center.
  ---@return Vector2
  local function _getCenter() return _tbl.center * -1 + 1 end
  _self.getCenter = _getCenter

  --#ENDREGION
  --#REGION matrix()

  ---Sets this square's matrix. Takes a Matrix3
  ---@overload fun(self, matrix: Matrix3): FOXAPI.Square
  local function _matrix(_, matrix)
    _tbl.matrix = matrix
    _updateLines()
    return _self
  end
  _self.matrix = _matrix
  _self.setMatrix = _matrix

  --#ENDREGION
  --#REGION getMatrix()

  ---Returns this square's matrix.
  ---@return Matrix3
  local function _getMatrix() return _tbl.matrix end
  _self.getMatrix = _getMatrix

  --#ENDREGION
  --#REGION remove()

  ---Removes this square
  local function _remove() for _, line in ipairs(_self) do line:remove() end end
  _self.remove = _remove

  --#ENDREGION

  --#ENDREGION
  return _self
end
FOXAPI.square.new = _newSquare

--#ENDREGION
--#REGION clearSquares()

---Removes all registered squares
local function _clearSquares() for _, square in ipairs(FOXAPI.squares) do square:remove() end end
FOXAPI.square.clear = _clearSquares

--#ENDREGION

return _module

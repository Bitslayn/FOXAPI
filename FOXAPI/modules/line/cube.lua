---@meta _
--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's Cube Module v1.0.0
A FOXAPI Module

Lets you draw cubes using the line module.

--]]

local apiPath, moduleName = ...
assert(apiPath:find("FOXAPI.modules"), "\n§4FOX's API was not installed correctly!§c")
local _module = {
  _api = { "FOXAPI", "1.0.0", 1 },
  _name = "FOX's Cube Module",
  _desc = "Lets you draw cubes using FOX's Line Module.",
  _require = { "FOX's Line Module", "1.0.0", 1 },
  _ver = { "1.0.0", 1 },
}
if not FOXAPI then
  __race = { apiPath:gsub("/", ".") .. "." .. moduleName, _module }
  require(apiPath:match("(.*)modules") .. "api")
end

---Contains all the registered cubes
---@type FOXAPI.Cube[]
FOXAPI.cubes = {}
---Cube module functions
FOXAPI.cube = {}

--#REGION newCube()

---Creates a new cubes out of lines. Booleans can be passed to prevent some lines from being created.
---@param ... boolean If true will prevent a line from being created. The order is 1-3 south-east, 4-6 north-west, 7-9 north-east, 10-12 south-west.
---@nodiscard
local function _newCube(...)
  --#REGION ˚♡ Init ♡˚
  assert(host:isHost(),
    "This function is meant to run on the host only! Consider putting this function inside a host:isHost() check",
    2)
  local args = { ... }

  ---@class FOXAPI.Cube
  ---@field private [number] FOXAPI.Line
  local _self = setmetatable({}, FOXAPI.cube)
  local _tbl = {}
  table.insert(FOXAPI.cubes, _tbl)

  _tbl.pos = vec(0, 0, 0)
  _tbl.size = vec(1, 1, 1)
  _tbl.center = vec(0, 0, 0)
  _tbl.matrix = matrices.rotation3(0, 0, 0)

  local lineMap = {
    { vec(0, 0, 0), vec(1, 0, 0) }, -- South
    { vec(0, 0, 0), vec(0, 1, 0) }, -- South-east
    { vec(0, 0, 0), vec(0, 0, 1) }, -- East

    { vec(1, 0, 1), vec(1, 0, 0) }, -- West
    { vec(1, 0, 1), vec(1, 1, 1) }, -- North-west
    { vec(1, 0, 1), vec(0, 0, 1) }, -- North

    { vec(0, 1, 1), vec(0, 1, 0) }, -- East
    { vec(0, 1, 1), vec(0, 0, 1) }, -- North-east
    { vec(0, 1, 1), vec(1, 1, 1) }, -- North

    { vec(1, 1, 0), vec(1, 1, 1) }, -- West
    { vec(1, 1, 0), vec(1, 0, 0) }, -- South-west
    { vec(1, 1, 0), vec(0, 1, 0) }, -- South
  }

  -- Remove lines where argument is true
  for i = #lineMap, 1, -1 do
    if args[i] then
      table.remove(lineMap, i)
    end
  end

  local windowSize = client.getScaledWindowSize() -- I don't want to do this, fixes the cube being too small on the screen with no way of making it bigger.
  windowSize:mul(windowSize.y / windowSize.x, 1)

  local function _project(vec3)
    return vec3.xy:div(vec3.z, vec3.z):mul(windowSize)
  end

  -- Create lines
  for _, v in ipairs(lineMap) do
    if type(_tbl.pos) == "Vector3" then
      table.insert(_self, FOXAPI.line.new():pos(
        (v[1] * _tbl.size - (_tbl.center * _tbl.size))
        :transform(_tbl.matrix):add(_tbl.pos),
        (v[2] * _tbl.size - (_tbl.center * _tbl.size))
        :transform(_tbl.matrix):add(_tbl.pos)
      ))
    elseif type(_tbl.pos) == "Vector2" then
      table.insert(_self, FOXAPI.line.new():pos(
        _project((v[1] * _tbl.size - (_tbl.center * _tbl.size))
          :transform(_tbl.matrix)):add(_tbl.pos),
        _project((v[2] * _tbl.size - (_tbl.center * _tbl.size))
          :transform(_tbl.matrix)):add(_tbl.pos)
      ))
    end
  end
  local function _updateLines()
    for i, v in ipairs(_self) do
      if type(_tbl.pos) == "Vector3" then
        v:pos(
          (lineMap[i][1] * _tbl.size - (_tbl.center * _tbl.size))
          :transform(_tbl.matrix):add(_tbl.pos),
          (lineMap[i][2] * _tbl.size - (_tbl.center * _tbl.size))
          :transform(_tbl.matrix):add(_tbl.pos)
        )
      elseif type(_tbl.pos) == "Vector2" then
        v:pos(
          _project((lineMap[i][1] * _tbl.size - (_tbl.center * _tbl.size))
            :transform(_tbl.matrix)):add(_tbl.pos),
          _project((lineMap[i][2] * _tbl.size - (_tbl.center * _tbl.size))
            :transform(_tbl.matrix)):add(_tbl.pos)
        )
      end
    end
  end

  --ENDREGION
  --#REGION ˚♡ Returned functions ♡˚

  --#REGION pos()

  ---Sets this cube's position. Defaults to vec(0, 0, 0).
  ---@overload fun(self, x: number, y: number, z: number): FOXAPI.Cube
  ---@overload fun(self, pos: Vector2|Vector3): FOXAPI.Cube
  local function _pos(_, ...)
    local _args = { ... }
    local _type1 = type(_args[1])
    assert(_type1 == "Vector3", "Invalid type! Position only supports vec3!", 2)
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

  ---Returns this cube's position.
  ---@return Vector2|Vector3
  local function _getPos() return _tbl.pos end
  _self.getPos = _getPos

  --#ENDREGION
  --#REGION size()

  ---Sets this cube's size. Defaults to vec(1, 1, 1).
  ---@overload fun(self, x: number, y: number, z: number): FOXAPI.Cube
  ---@overload fun(self, size?: Vector3): FOXAPI.Cube
  local function _setSize(_, ...)
    local _args = { ... }
    local _type1 = type(_args[1])
    if _type1 == "number" then
      _tbl.size = vec(_args[1], _args[2], _args[3])
    elseif _type1 == "Vector3" then
      _tbl.size = _args[1]
    else
      _tbl.size = vec(1, 1, 1)
    end
    _updateLines()
    return _self
  end
  _self.size = _setSize
  _self.setSize = _setSize

  --#ENDREGION
  --#REGION getSize()

  ---Returns this cube's size.
  ---@return Vector3
  local function _getSize() return _tbl.size end
  _self.getSize = _getSize

  --#ENDREGION
  --#REGION center()

  ---Sets this cube's center. vec(0, 0, 0) is the bottom right corner, vec(0.5, 0.5, 0.5) is the center, and vec(1, 1, 1) is the top left corner. Defaults to vec(0, 0, 0).
  ---@overload fun(self, x: number, y: number, z: number): FOXAPI.Cube
  ---@overload fun(self, center?: Vector2): FOXAPI.Cube
  local function _setCenter(_, ...)
    local _args = { ... }
    local _type1 = type(_args[1])
    if _type1 == "number" then
      _tbl.center = vec(_args[1], _args[2], _args[3]):mul(-1, -1, -1):add(1, 1, 1)
    elseif _type1 == "Vector3" then
      _tbl.center = _args[1]:mul(-1, -1, -1):add(1, 1, 1)
    else
      _tbl.center = vec(0, 0, 0)
    end
    _updateLines()
    return _self
  end
  _self.center = _setCenter
  _self.setCenter = _setCenter

  --#ENDREGION
  --#REGION getCenter()

  ---Returns this cube's center.
  ---@return Vector3
  local function _getCenter() return _tbl.center * -1 + 1 end
  _self.getCenter = _getCenter

  --#ENDREGION
  --#REGION matrix()

  ---Sets this cube's matrix. Takes a Matrix3
  ---@overload fun(self, matrix: Matrix3): FOXAPI.Cube
  local function _matrix(_, matrix)
    _tbl.matrix = matrix
    _updateLines()
    return _self
  end
  _self.matrix = _matrix
  _self.setMatrix = _matrix

  --#ENDREGION
  --#REGION getMatrix()

  ---Returns this cube's matrix.
  ---@return Matrix3
  local function _getMatrix() return _tbl.matrix end
  _self.getMatrix = _getMatrix

  --#ENDREGION
  --#REGION remove()

  ---Removes this cube
  local function _remove() for _, line in ipairs(_self) do line:remove() end end
  _self.remove = _remove

  --#ENDREGION

  --#ENDREGION
  return _self
end
FOXAPI.cube.new = _newCube

--#ENDREGION
--#REGION clearCubes()

---Removes all registered cubes
local function _clearCubes() for _, cube in ipairs(FOXAPI.cubes) do cube:remove() end end
FOXAPI.cube.clear = _clearCubes

--#ENDREGION

return _module

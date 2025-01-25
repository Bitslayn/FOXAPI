-- Debug tracers
local fox = require("FOXAPI.api")
local enable = false
local extra = "line" -- "cube", "square", "line", or false
if host:isHost() then
  if not enable then return end
  local tracked = {}
  function events.entity_init()
    function events.pre_render(delta)
      local players = world.getPlayers()
      -- Create new tracer if none is made for this player
      for k, v in pairs(players) do
        if not tracked[k] and v ~= player then
          tracked[k] = { fox.line.new():setPos(-client.getScaledWindowSize() / 2, vec(0, 0, 0))
              :setZOffset(-100) }
          if extra == "cube" and fox.cube then
            table.insert(tracked[k], fox.cube.new():setCenter(0.5, 1, 0.5):setSize(0.6, 1.8, 0.6))
          end
          if extra == "square" and fox.square then
            table.insert(tracked[k], fox.square.new():setCenter(0.5, 0.5):setSize(0.6, 0.6))
          end
          if extra == "line" then
            table.insert(tracked[k], fox.line.new())
          end
        end
      end
      -- Move second point for existing tracers, or remove if player no longer exists
      local color = vectors.hsvToRGBA((world.getTime() % 100) / 100, 1, 1, 1)
      for k, v in pairs(tracked) do
        local _player = players[k]
        if _player then                               -- If the player still exists
          local _playerPos = _player:getPos(delta)
          v[1]:setSecondPos(_playerPos):setColor(color) -- Set position and color of line
          if (fox.cube and extra == "cube") or (fox.square and extra == "square") then
            v[2]:setPos(_playerPos)                   -- Set position of square or cube
            for _, line in ipairs(v[2]) do
              line:setColor(color)                    -- Set the color of each line in the square or cube
            end
          elseif extra == "line" then
            v[2]:setPos(_playerPos, _playerPos + vec(0, 1.8, 0)):setColor(color) -- Set the color of line
          end
        else
          for _, _v in ipairs(v) do _v:remove() end -- Remove both the line and square
          tracked[k] = nil
        end
      end
    end
  end
end

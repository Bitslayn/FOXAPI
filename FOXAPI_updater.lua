--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's API Updater

Checks for updates to modules or the api itself.
Can be installed to your data folder.

--]]

function events.entity_init()
  --#REGION ˚♡ Externally hook into FOXAPI ♡˚

  if not host:isHost() then return end -- Remove this line if this script is in your data folder
  require("FOXAPI.api") -- MAKE SURE THIS REQUIRES THE RIGHT PATH


  local variable = player:getVariable("FOXAPI")
  local ver, mod = type(variable._ver) == "table" and variable._ver,
      type(variable._mod) == "table" and variable._mod
  if not (ver and mod) then return end

  --#ENDREGION
  --#REGION ˚♡ Module Update Checker ♡˚

  local lang = {
    singleUpdate = "§lUpdate v%s for %s is available!",
    individualUpdates = "§l%s v%s",
    severalUpdates = "§lFOXAPI has %i updates available!",
    updaterError = "§4An unexpected error has occured!",
    ignoreUpdate = "§lIgnoring update for %s v%s",
    downloadButton = "[Download]",
    ignoreButton = "[Ignore]",
    expandButton = "[Expand]",
  }

  FOXupdates = {}
  local updateCount = 0
  local ignoredUpdates = config:loadFrom("FOXAPI", "ignoredUpdates") or {}

  --#REGION ˚♡ Messages ♡˚

  -- The prompt which shows the download and ignore buttons
  local prompted = false
  function promptUpdateDownloads()
    if prompted then return end
    prompted = true
    for i = 1, updateCount do
      printJson(toJson({
        {
          text = updateCount == 1 and
              (lang.singleUpdate:format(FOXupdates[i].version, FOXupdates[i].name) .. "\n") or
              (lang.individualUpdates:format(FOXupdates[i].name, FOXupdates[i].version) .. " "),
          color = "#fc6c85",
        },
        {
          text = lang.downloadButton .. " ",
          color = "blue",
          clickEvent = {
            action = "open_url",
            value = FOXupdates[i].url,
          },
        },
        {
          text = lang.ignoreButton .. "\n",
          color = "red",
          clickEvent = {
            action = "figura_function",
            value = "ignoreUpdate(FOXupdates[" .. tostring(i) .. "])",
          },
        },
      }))
    end
  end

  -- The prompt which shows the expand button
  function promptSeveralUpdates()
    printJson(toJson({
      {
        text = lang.severalUpdates:format(updateCount) .. " ",
        color = "#fc6c85",
      },
      {
        text = lang.expandButton,
        color = "green",
        clickEvent = {
          action = "figura_function",
          value = "promptUpdateDownloads()",
        },
      },
    }))
  end

  -- Ignore update
  function ignoreUpdate(_mod)
    if ignoredUpdates[_mod.name] == _mod.protocol then return end
    printJson(toJson({
      text = lang.ignoreUpdate:format(_mod.name, _mod.version),
      color = "#fc6c85",
    }))
    ignoredUpdates[_mod.name] = _mod.protocol
    config:saveTo("FOXAPI", "ignoredUpdates", ignoredUpdates)
  end

  --#ENDREGION
  --#REGION ˚♡ Update checker ♡˚

  -- Check for updates
  local function checkUpdates(mods)
    for _, _mod in pairs(mods) do
      if (_mod.isAPI and ver[2] or mod[_mod.name]._ver[2]) < _mod.protocol and ignoredUpdates[_mod.name] ~= _mod.protocol then
        updateCount = updateCount + 1
        FOXupdates[updateCount] = _mod
      end
    end
    if updateCount > 1 then
      promptSeveralUpdates()
    else
      promptUpdateDownloads()
    end
  end

  -- Grab avatar vars from player skull
  local updateProxy = models:newPart("FOXAPI.updateProxy", "Gui"):setScale(0)
  updateProxy:newItem("FOXAPI.updateProxy.skull")
      :setItem("minecraft:player_head{SkullOwner:Bitslayn}")
  local function awaitAvatarVariables()
    local vars = world.avatarVars()["55648b2f-a2f5-4a21-8e4f-fe904239f8b6"]
    if not vars then return end
    pcall(checkUpdates, vars["FOXAPI.versions"])
    updateProxy:remove()
    events.tick:remove(awaitAvatarVariables)
  end
  events.tick:register(awaitAvatarVariables)

  --#ENDREGION

  --#ENDREGION
end

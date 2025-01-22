# FOX's API

## Downloading the API

Download the entire FOXAPI folder containing `FOXAPI\lib`, `FOXAPI\modules` and `FOXAPI\api.lua`. Move that folder to your avatar's directory.

## Downloading Modules

Downloaded modules go into the modules folder `FOXAPI\modules`. Only modules written for FOXAPI should be put in this folder. Subfolders are supported.

### Require

All modules and libraries are returned from a single require to `FOXAPI\api.lua`. Here's an example of how you can require a module.

```lua
-- This may be different for you. Make sure you path to the api script,
-- not to a module script
local fox = require("FOXAPI.api")

-- Using the line module to create a line
fox.line.new():setPos(-client.getScaledWindowSize() / 2, vec(0, 0, 0))

-- Using the FOXpat module to edit a config
fox.patConfig.patButton = "key.mouse.right"
```

Some functions of this API are also global (With the use of a require)

```lua
require("FOXAPI.api") -- OR local fox = require("FOXAPI.api")

-- FOXpat event
function events.entity_pat(entity, state)
  print("Patted by " .. entity)
end
```
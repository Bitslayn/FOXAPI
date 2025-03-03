# FOX's API

## Downloading the API

[Download](https://download-directory.github.io/?url=https%3A%2F%2Fgithub.com%2FBitslayn%2FFOXAPI%2Ftree%2Fmain%2FFOXAPI) the entire FOXAPI folder containing `api.lua` and the modules folder. Move the FOXAPI folder to your avatar's directory.

## Updating Modules

Downloaded modules go into the modules folder `FOXAPI\modules`. Only modules written for FOXAPI should be put in this folder. Subfolders are supported.

## Using FOXAPI

All modules and libraries are returned from a single require to `FOXAPI\api.lua`. Here's an example of how you can require a module.

```lua
local line = require("FOXAPI.api").line

-- Using the line module to create a line
line.new():setPos(-client.getScaledWindowSize() / 2, vec(0, 0, 0))

local foxpat = require("FOXAPI.api").foxpat

-- Editing a FOXPat config
foxpat.config.patParticle = "minecraft:heart"
```

Some functions of this API are also global (With the use of a require)

```lua
local foxpat = require("FOXAPI.api").foxpat

-- FOXPat event
function events.entity_pat(entity, state)
  print("Patted by " .. entity)
end
```

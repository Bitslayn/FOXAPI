## Downloading the API

[Download](https://download-directory.github.io/?url=https%3A%2F%2Fgithub.com%2FBitslayn%2FFOXAPI%2Ftree%2Fmain%2FFOXAPI) the entire FOXAPI folder containing `api.lua` and the modules folder. Move the FOXAPI folder to your avatar's directory.

## Modules

FOXAPI is a modular API meaning that all its features are split into separate smaller scripts. **When you first download FOXAPI using the link above, all modules will be downloaded at once** Navigate to the `FOXAPI\modules` folder and delete any modules you wish to not use (this includes subfolders).

If you already have FOXAPI, you can update modules separately by downloading their files and replacing the module in `FOXAPI\modules` with the updated one.

Normal scripts that have not been written for FOXAPI shouldn't be placed in the modules folder.

## Using FOXAPI

All modules and libraries can be used by requiring FOXAPI itself `FOXAPI\api.lua`. Here's an example of how you can require a module.

FOX's Line Module example

```lua
local line = require("FOXAPI.api").line

-- Using the line module to create a line
line.new():setPos(-client.getScaledWindowSize() / 2, vec(0, 0, 0))
```

FOX's Patpat Module example

```lua
local foxpat = require("FOXAPI.api").foxpat

-- Editing a FOXPat config
foxpat.config.patParticle = "minecraft:heart"

-- Using an event
function events.entity_pat(entity, state)
  print("Patted by " .. entity)
end
```

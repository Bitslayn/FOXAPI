Foxpat allows you to pat other players by holding crouch and right clicking.

# Examples

There is an easy-to-use script with events similar to Auria's patpat. You can find that [here](https://github.com/Bitslayn/FOXAPI/blob/main/Examples/Foxpat/foxpatEvents.lua).

## Play a sound each time you're patted

```lua
local foxpat = require("FOXAPI/api").foxpat

function events.entity_pat()
  if state == 1 then return end -- Don't play the sound if the state is 1 (State of 1 is when you stop being patted)
  sounds["entity.fox.ambient"]:setPos(player:getPos()):play()
end
```

---

## Emit a custom particle when you pat someone

```lua
local foxpat = require("FOXAPI/api").foxpat

function events.patting(entity, block, boundingBox, allowHearts)
  if allowHearts then -- Players who do not consent to hearts should be respected. Do NOT play ANY sounds or particles on them if this is false.
    local pos
    if block then
      pos = block:getPos():add(0.5, 0, 0.5)
    elseif entity then
      pos = entity:getPos()
    end
    pos = pos - boundingBox.x_z * 0.5 + vectors.random() * boundingBox
    particles:newParticle("minecraft:bubble", pos)
  end
  return { false, true } -- Cancel particles but not swinging
end
```

---

## Emit a custom particle when you pat someone (Using Manuel's [confetti](https://github.com/Manuel-3/figura-scripts/blob/main/src/confetti/confetti.lua))

> [!WARNING]  
> This example is incomplete and requires that you know how to use confetti!

```lua
local foxpat = require("FOXAPI/api").foxpat
local confetti = require("confetti")

confetti.registerSprite("particle", ...) -- Register your particle here (Incomplete)

local function newParticle(pos)
  confetti.newParticle("particle",
    pos, vec(0, 0, 0), {
      billboard = true,
      ticker = function(particle)
        -- Your code here (Incomplete)
      end,
    })
end

function events.patting(entity, block, boundingBox, allowHearts)
  if allowHearts then -- Players who do not consent to hearts should be respected. Do NOT play ANY sounds or particles on them if this is false.
    local pos
    if block then
      pos = block:getPos():add(0.5, 0, 0.5)
    elseif entity then
      pos = entity:getPos()
    end
    pos = pos - boundingBox.x_z * 0.5 + vectors.random() * boundingBox
    newParticle(pos) -- Create a particle using the custom function defined above
  end
  return { false, true } -- Cancel particles but not swinging
end
```

# Events

Uses Figura's EventsAPI. As such, events can be registered the same way you register built-in events. For more information on events, check out the [Figura Wiki](https://figura-wiki.pages.dev/globals/Events/Event)

> [!NOTE]
> FOXAPI custom events are not global. You need to require the api to use these events.

## `ENTITY_PAT()`

This event runs when you get patted or unpatted. The state is the status of the pat event. `"PAT"` is for when you're first patted, `"UNPAT"` is when you stop being patted, and `"WHILE_PAT"` is for the duration of you being patted.

**Callback:**

| Name   | Type   | Description                    |
| ------ | ------ | ------------------------------ |
| patter | Player | The player that is patting you |
| state  | number | The current patting state      |

**Returns:**

Can either be a table or a single boolean. Returning a single boolean is like returning the same thing in both table entries.

| Type      | Description                                              |
| --------- | -------------------------------------------------------- |
| swing     | Return true here to cancel swinging or patting animation |
| particles | Return true here to cancel patting particles             |

**Example:**

```lua
local foxpat = require("FOXAPI/api").foxpat

-- Pat example (using NOT equals)
function events.entity_pat(patter, state)
  if state ~= "UNPAT" then -- Don't check for state == "PAT" as it's only "PAT" on first pat
    print("Being patted by " .. patter:getName())
  end
end

-- Unpat example (using equals)
function events.entity_pat(patter, state)
  if state == "UNPAT" then
    print("Stopped being patted by " .. patter:getName())
  end
end
```

---

## `SKULL_PAT()`

This event runs when one of your skulls gets patted or unpatted. The state is the status of the pat event. `"PAT"` is for when you're first patted, `"UNPAT"` is when you stop being patted, and `"WHILE_PAT"` is for the duration of you being patted.

**Callback:**

| Name        | Type    | Description                   |
| ----------- | ------- | ----------------------------- |
| patter      | Player  | The player patting your skull |
| state       | number  | The current patting state     |
| coordinates | Vector3 | This skull's coordinates      |

**Returns:**

Can either be a table or a single boolean. Returning a single boolean is like returning the same thing in both table entries.

| Type      | Description                                              |
| --------- | -------------------------------------------------------- |
| swing     | Return true here to cancel swinging or patting animation |
| particles | Return true here to cancel patting particles             |

**Example:**

```lua
local foxpat = require("FOXAPI/api").foxpat

-- Pat example (using NOT equals)
function events.skull_pat(patter, state, coordinates)
  if state ~= "UNPAT" then -- Don't check for state == "PAT" as it's only "PAT"
    print("Your skull at " .. tostring(coordinates) .. " is being patted by " .. patter:getName())
  end
end

-- Unpat example (using equals)
function events.skull_pat(patter, state, coordinates)
  if state == "UNPAT" then
    print("Your skull at " .. tostring(coordinates) .. " stopped being patted by " .. patter:getName())
  end
end
```

---

## `PATTING()`

This event runs when you pat another player, entity, or block. It can be used as an alternative to summoning particles.

**Callback:**

| Name        | Type        | Description                                                                             |
| ----------- | ----------- | --------------------------------------------------------------------------------------- |
| entity      | Entity?     | Data of the entity you are patting if you're patting an entity                          |
| block       | BlockState? | Data of the block you are patting if you're patting a block                             |
| boundingBox | Vector3     | The bounding box of the entity or block you're patting                                  |
| allowHearts | boolean     | If you're patting a player and that player doesn't allow hearts, this will become false |

**Returns:**

Can either be a table or a single boolean. Returning a single boolean is like returning the same thing in both table entries.

| Type      | Description                                                       |
| --------- | ----------------------------------------------------------------- |
| swing     | Return true here to cancel **YOUR** swinging or patting animation |
| particles | Return true here to cancel **YOUR** patting particles             |

**Example:**

```lua
local foxpat = require("FOXAPI/api").foxpat

function events.patting(entity, block, boundingBox, allowHearts)
  print("You are patting something")
end
```

# Configuration

Foxpat has several configs which you could change. All configs can be changed by overwriting the table entry. An example of setting the `swingArm` config is shown below. A script also exists which lets you define all configs at once [here](https://github.com/Bitslayn/FOXAPI/blob/main/Examples/Foxpat/foxpatConfig.lua).

```lua
local foxpat = require("FOXAPI/api").foxpat
foxpat.config.swingArm = true
```

> [!NOTE]
> Just like with events, you need to require the api to do this.

## `swingArm`

Whether patting should swing your arm. Recommended to turn this off when you set a pat animation.

| Type    | Default |
| ------- | ------- |
| boolean | `true`  |

## `patAnimation`

What animation should be played while you're patting.

| Type      | Default |
| --------- | ------- |
| Animation | -       |

## `patParticle`

What particle should play while you're patting.

| Type                 | Default             |
| -------------------- | ------------------- |
| Minecraft.particleID | `"minecraft:heart"` |

## `playMobSounds`

Whether patting a mob plays a sound.

| Type    | Default |
| ------- | ------- |
| boolean | `true`  |

## `mobSoundPitch`

The pitch mob sounds will be played at.

| Type   | Default |
| ------ | ------- |
| number | `1`     |

## `mobSoundRange`

How varied the mob sound pitch will be.

| Type   | Default |
| ------ | ------- |
| number | `0.25`  |

## `playNoteSounds`

Whether patting a player head plays the noteblock sound associated with that head.

| Type    | Default |
| ------- | ------- |
| boolean | `true`  |

## `noteSoundPitch`

Set the pitch player head noteblock sounds will be played at.

| Type   | Default |
| ------ | ------- |
| number | `1`     |

## `noteSoundRange`

How varied the noteblock sound pitch will be.

| Type   | Default |
| ------ | ------- |
| number | `0.25`  |

## `requireCrouch`

Whether you have to be crouching after your first crouch to continue patting.

| Type    | Default |
| ------- | ------- |
| boolean | `false` |

## `requireEmptyHand`

Whether an empty hand is required for patting.

| Type    | Default |
| ------- | ------- |
| boolean | `true`  |

## `requireEmptyOffHand`

Whether an empty offhand is required for patting.

| Type    | Default |
| ------- | ------- |
| boolean | `false` |

## `actAsInteractable`

If you want another player to simply right click you or your player head without crouching or while holding an item.

| Type    | Default |
| ------- | ------- |
| boolean | `false` |

## `patDelay`

How often patting should occur in ticks.

| Type   | Default |
| ------ | ------- |
| number | `3`     |

## `holdFor`

How long should it be after the last pat before you're considered no longer patting. Shouldn't be made less than `patDelay`.

| Type   | Default |
| ------ | ------- |
| number | `10`    |

## `boundingBox`

A custom bounding box that defines where people can pat you and the area that hearts get spawned on you.

| Type    | Default |
| ------- | ------- |
| Vector3 | -       |

# Avatar Variables

A list of each avatar variable and what they do.

## `petpet`

A function run by the patter after pinging, passes the patter's uuid and how long until that pat expires stored in `holdFor`. Used for player-to-player communication of pats.

Type - `Function`

**Parameters:**

$\color{#FF0000}{*}$ required

| Name                      | Type   | Description                                 |
| ------------------------- | ------ | ------------------------------------------- |
| uuid $\color{#FF0000}{*}$ | string | The uuid of the player patting you          |
| time $\color{#FF0000}{*}$ | number | The amount of ticks before this pat expires |

---

## `petpet.playerHead`

A function run by the patter after pinging, passes the patter's uuid, how long until that pat expires stored in `holdFor`, and the x, y, and z coordinates of the skull being patted. Used for player-to-player communication of pats.

Type - `Function`

**Parameters:**

$\color{#FF0000}{*}$ required

| Name                      | Type   | Description                                 |
| ------------------------- | ------ | ------------------------------------------- |
| uuid $\color{#FF0000}{*}$ | string | The uuid of the player patting your skull   |
| time $\color{#FF0000}{*}$ | number | The amount of ticks before this pat expires |
| x $\color{#FF0000}{*}$    | number | The skull's x coordinate                    |
| y $\color{#FF0000}{*}$    | number | The skull's y coordinate                    |
| z $\color{#FF0000}{*}$    | number | The skull's z coordinate                    |

---

## `patpat.noPats`

A variable which, if made true, signifies you don't wish to be patted. This prevents players using a patpat from swinging, playing a custom patting animation, and emitting particles on your player. In patpat libraries/scripts, this is defined by the `noPats` config.

Type - `Boolean`

---

## `patpat.noHearts`

A variable which, if made true, signifies to players you don't want patpat particles emitted from your player when they pat you. In patpat libraries/scripts, this is defined by the `noHearts` config.

Type - `Boolean`

---

## `patpat.boundingBox`

A custom bounding box defining the area particles can spawn in. If you use Bunnypat, this also acts as the hitbox using raycasting aabb. In patpat libraries/scripts, this is defined by the `boundingBox` config.

Type - `Vector3`

---

## `foxpat.actAsInteractable`

Makes players able to "interact" with you or your skulls without having to crouch and even if you're holding an item. This ignores the `requireEmptyHand` and `requireCrouch` configs.

Type - `Boolean`

---

## `eyePos`

Exposes your `renderer:getEyeOffset()` to other players. Is used in FOX's PlayerScale and Chloe's piano and drums. Not set by FOXPat and only read for players who move their camera pivots.

Type - `Vector3`

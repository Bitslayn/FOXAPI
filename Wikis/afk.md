FoxAFK is an AFK handler which shows your AFK status and how long you've been AFK for in your nameplate. You will go AFK after 2 minutes of not moving.

# Examples

## Nameplate Placeholder

Sets your nameplate to `Steve [AFK 3:00]` when you are AFK and `Steve` when you aren't.

> [!IMPORTANT]
> The \${afk} placeholder works only on nameplates and not text tasks. Look at further examples if you are using a custom text task nameplate.

```lua
-- Set nameplate on init, a require isn't required
nameplate.ALL:setText("Steve${afk}")
```

More information on Nameplates: https://figura-wiki.pages.dev/globals/Nameplate

## Manual Nameplate

If you wish to manually add the AFK indicator in your nameplate. Can be useful if you want to use this with text tasks.

### Simple
```lua
require("FOXAPI.api") -- Require FOXAPI

local foxafk = FOXAPI.afk -- Access FoxAFK module globals
foxafk.config.usePlaceholder = false -- Disable the placeholder system

function events.tick()
  nameplate.ALL("Steve" .. foxapi.fancyAFK) -- Set your nameplate to Steve [AFK 3:00] but manually
end
```

### Advanced
```lua
require("FOXAPI.api") -- Require FOXAPI

local foxafk = FOXAPI.afk -- Access FoxAFK module globals
foxafk.config.usePlaceholder = false -- Disable the placeholder system

function events.tick()
  if foxapi.isAFK then
    nameplate.ALL("Steve [AFK " .. foxapi.afk .. "]" ) -- Set your nameplate to Steve [AFK 3:00] but manually
  else
    nameplate.ALL("Steve") -- Set your nameplate to Steve
  end
end
```

---

# Configuration
FoxAFK has several configs which you could change. All configs can be changed by overwriting the table entry in `FOXAPI.afk.config`. An example of setting the `timeUntilAFK` config is shown below.

```lua
require("FOXAPI.api") -- Require FOXAPI

local foxafk = FOXAPI.afk -- Access FoxAFK module globals
foxafk.config.timeUntilAFK = 20 * 60 -- Set AFK time to 60 seconds converted to ticks
```

## `timeUntilAFK`
How long in ticks you have to wait to become AFK for.

| Type | Default |
| - | - |
| integer | `2400` (2 minutes in ticks) |

## `runUnloaded`
Whether to update your nameplate using world instructions while your player is unloaded.

The default is `true` when your avatar is set to `HIGH` or `MAX` permissions and `false` when it's set lower. Setting this config will force enable or disable this feature on any permission level.

| Type | Default |
| - | - |
| boolean | *Conditional* |

## `repingDelay`
How often the AFK timestamp should be repinged. This should be infrequent.

| Type | Default |
| - | - |
| integer | `800` (40 seconds in ticks) |

## `timeDelay`
How frequent in ticks the module does stuff. This also affects how precise the AFK timer is going to be.

| Type | Default |
| - | - |
| integer | `10` (1/2 second in ticks) |

## `fancyFormatting`
How the AFK string should be formatted when replacing ${afk} in nameplates. The %s is replaced with the time like `3:00`.

| Type | Default |
| - | - |
| string | `" [AFK %s]"` |

## `usePlaceholder`
If this is set to `false`, the system for replacing ${afk} placeholders in the nameplate will be disabled.

| Type | Default |
| - | - |
| boolean | `true` |

## `hmmss`
How the AFK timer should be formatted when the player has been AFK for **more than** an hour.

| Type | Default |
| - | - |
| string | `"%d:%02d:%02d"` (0:00:00) |

## `mss`
How the AFK timer should be formatted when the player has been AFK for **less than** an hour.

| Type | Default |
| - | - |
| string | `"%d:%02d:%02d"` (0:00) |

# Variables
These variables should only be read, not written to. Like configs, FOXAPI should be required to read them.

## `afkTick`

| Type | Description |
| - | - |
| integer | The current time in ticks you've been AFK for. |

## `isAFK`

| Type | Description |
| - | - |
| boolean | Whether or not you're currently AFK. |

## `afk`

| Type | Description |
| - | - |
| string | The formatted time you've been AFK for like `3:00` for `3600` ticks. |

## `fancyAFK`

| Type | Description |
| - | - |
| string | The fancy formatted time you've been AFK for like ` [AFK 3:00]` for `3600` ticks. Is blank when you aren't AFK. The space in front is intentional. Uses the fancyFormatting config. |
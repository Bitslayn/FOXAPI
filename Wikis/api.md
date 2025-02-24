FOXAPI has a few functions which are used by the modules. 

# Events
Uses Figura's EventsAPI. As such, events can be registered the same way you register built-in events. For more information on events, check out the [Figura Wiki](https://figura-wiki.pages.dev/globals/Events/Event)

> [!NOTE]
> FOXAPI custom events are not global. You need to require the api to use these events.

## `new()`
Registers a custom event that can be called like a normal event. The super simple method.

**Parameters:**

$\color{#FF0000}{*}$ required

| Name | Type | Description |
| - | - | - |
| eventName $\color{#FF0000}{*}$ | string | What to call your event |

```lua
events:new("my_event")

function events.my_event() -- Can work as all lowercase or all capital
  print("My event ran")
end
```

---

## `newRaw()`
Registers a custom event that can be called like a normal event. The passed table must have a `register` function

This is a really advanced method and if you're ever needing to use this, you already know the basics of how events work. If you need an example of this, you can look at how the [preRender module](https://github.com/Bitslayn/FOXAPI/blob/7cc6c3bc5eb666f068aa0141a4d450f2da9bdad1/FOXAPI/modules/preRender.lua) was made.

**Parameters:**

$\color{#FF0000}{*}$ required

| Name | Type | Description |
| - | - | - |
| eventName $\color{#FF0000}{*}$ | string | What to call your event |
| event $\color{#FF0000}{*}$ | table | The event table |

```lua
events:newRaw("my_event", {
  register = function(_, func, name)

  end,
  remove = function(_, callback)

  end,
  clear = function()

  end,
  getRegisteredCount = function(_, name)

  end,
})

function events.my_event() -- Can work as all lowercase or all capital
  print("My event ran")
end
```

---

## `call()`
Calls a custom event and runs all their functions

**Parameters:**

$\color{#FF0000}{*}$ required

| Name | Type | Description |
| - | - | - |
| eventName $\color{#FF0000}{*}$ | string | The name of the custom event to call |
| parameters | any... | Parameters to pass into the events |

**Returns:**

| Type | Description |
| - | - |
| table | A table of returns from each event function |

```lua
-- First registered event
function events.my_event(param1, param2)
  print(param1 .. param2) -- Prints foobar
  return "Hello world!"
end

-- Second registered event
function events.my_event(param1, param2)
  print(param1 .. param2) -- Prints foobar
  return true
end

-- Call the events
print(events:call("my_event", "foo", "bar")) -- Parameter true, prints { "Hello world!", true }
```

# Functions
Miscellaneous functions.

## Generic

### `assert()`
Raises an error if the value of its argument v is false (i.e., `nil` or `false`); otherwise, returns all its arguments. In case of error, `message` is the error object; when absent, it defaults to `"assertion failed!"`

This is an internal function I modified to include a traceback level.

**Parameters:**

$\color{#FF0000}{*}$ required

| Name | Type | Description |
| - | - | - |
| v | any | An argument to evaluate |
| message | string | The error message, or "Assertion failed!" |
| level | number | The traceback level |

**Returns:**

| Type | Description |
| - | - |
| v | The evaluated argument |

```lua
local str = {} -- Not a string
-- Check if str is a string, errors with the message "String expected, got table" and the traceback level set to 2
assert(type(str) == "string", "String expected, got " .. type(str), 2)
```

## Vectors

### `hexToRGBA()`
Parses a hexadecimal string and converts it into a color vector.

The `#` is optional and the hex color can have any length, though only the first 8 digits are read. If the hex string is 4 digits long, it is treated as a short hex string. Returns `vec(0, 0, 0, 1)` if the hex string is invalid. Some special strings are also accepted in place of a hex string.

Written with the help of AuriaFoxGirl

**Parameters:**

$\color{#FF0000}{*}$ required

| Name | Type | Description |
| - | - | - |
| hex | string | The 8 digit hex code, or color name |

**Returns:**

| Type | Description |
| - | - |
| Vector4 | The RGBA color as a vector |

```lua
print(vectors.hexToRGBA("#ff880088")) -- Prints vec(1, 0.53333, 0, 0.53333)
```

---

### `intToRGBA()`
Converts the given integer into a color vector.

If `int` is `nil`, it will default to `0`.

**Parameters:**

$\color{#FF0000}{*}$ required

| Name | Type | Description |
| - | - | - |
| int | integer | The integer color |

**Returns:**

| Type | Description |
| - | - |
| Vector4 | The RGBA color as a vector |

```lua
print(vectors.intToRGBA(0x88ff8800)) -- Prints vec(1, 0.53333, 0, 0.53333)
```

---

### `hsvToRGBA()`
Converts the given HSV values to a color vector.

If `h`, `s`, `v`, or `a` are `nil`, they will default to `0`.

**Parameters:**

$\color{#FF0000}{*}$ required

| Name | Type | Description |
| - | - | - |
| int $\color{#FF0000}{*}$ | integer | The integer color |

**Returns:**

| Type | Description |
| - | - |
| Vector4 | The RGBA color as a vector |

```lua
print(vectors.hsvToRGBA(32, 1, 1, 0.5)) -- Prints vec(1, 0, 0, 0.5)
```

## Config

### `saveTo()`
Saves the given key and value to the provided config file without changing the active config file.

If `value` is `nil`, the key is removed from the config.

**Parameters:**

$\color{#FF0000}{*}$ required

| Name | Type | Description |
| - | - | - |
| file $\color{#FF0000}{*}$ | string | The name of the file to save to |
| name $\color{#FF0000}{*}$ | string | The key to save the value into |
| value | any | - |

```lua
config:saveTo("MyFile", "Key", "Value")
```

---

### `loadFrom()`
Loads the given key from the provided config file without changing the active config file.

**Parameters:**

$\color{#FF0000}{*}$ required

| Name | Type | Description |
| - | - | - |
| file $\color{#FF0000}{*}$ | string | The name of the file to load from |
| name $\color{#FF0000}{*}$ | string | The key to load the value of |

**Returns:**

| Type | Description |
| - | - |
| any | - |

```lua
print(config:loadFrom("MyFile", "Key")) -- "Value"
```

## `Table`

### `contains()`
Returns whether the pattern matches the table. Uses json.

**Parameters:**

$\color{#FF0000}{*}$ required

| Name | Type | Description |
| - | - | - |
| table $\color{#FF0000}{*}$ | table | The table to search through |
| pattern $\color{#FF0000}{*}$ | string | The pattern to search for in the table |

**Returns:**

| Type | Description |
| - | - |
| boolean | Whether the pattern matched the table |

```lua
local tbl = { "Foxes are cute", "and so are you" }
print(table.contains(tbl, "%w* are cute")) -- true
```

---

### `match()`
Return the first match in the table. Uses json.

**Parameters:**

$\color{#FF0000}{*}$ required

| Name | Type | Description |
| - | - | - |
| table $\color{#FF0000}{*}$ | table | The table to search through |
| pattern $\color{#FF0000}{*}$ | string | The pattern to search for in the table |

**Returns:**

| Type | Description |
| - | - |
| string | The match found in the table |

```lua
local tbl = { "Foxes are cute", "and so are you" }
print(table.match(tbl, "(%w*) are cute")) -- "Foxes"
```

---

### `gmatch()`
Match all the values that match the given value in the table. Uses json.

**Parameters:**

$\color{#FF0000}{*}$ required

| Name | Type | Description |
| - | - | - |
| table $\color{#FF0000}{*}$ | table | The table to search through |
| pattern $\color{#FF0000}{*}$ | string | The pattern to search for in the table |

**Returns:**

| Type | Description |
| - | - |
| table | Matches found in the table |

```lua
local tbl = { "Foxes are cute", "That is cute" }
print(table.gmatch(tbl, "(%w*) %w* cute")) -- { "Foxes", "That" }
```

---

### `invert()`
Returns an inverted table with all keys becoming values and values becoming keys.

**Parameters:**

$\color{#FF0000}{*}$ required

| Name | Type | Description |
| - | - | - |
| table $\color{#FF0000}{*}$ | table | The table to invert |

**Returns:**

| Type | Description |
| - | - |
| table | The table with all keys and values flipped |

```lua
local tbl = { [1] = "A", [2] = "B" }
print(table.invert(tbl)) -- { A = 1, B = 2 }
```

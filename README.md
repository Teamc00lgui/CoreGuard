# CoreGuard
Makes your exploit GUI secure. CoreGui is a project made by **x_c00lkidd_x**.

## How to use?
To use CoreGuard in your project, you need:

* Your script.
* The CoreGuard code integrated directly into the script.
* A `ScreenGui` created by your script.
* The `CoreGuard:Mount()` and `CoreGuard:Monitor()` calls after your GUI is created.

### Example

```lua
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MyGui"

local CoreGuard = {}

-- CoreGuard code goes here

CoreGuard:Mount(ScreenGui)
CoreGuard:Monitor(ScreenGui)
```

CoreGuard automatically attempts to use `CoreGui` first.

If `CoreGui` is unavailable, CoreGuard automatically falls back to `PlayerGui`.

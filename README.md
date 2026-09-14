# CoreGuard

Makes your exploit GUI secure. CoreGuard is a project made by **x_c00lkidd_x**.

## Version

`0.1.1` is the latest stable version.

## How to use?

CoreGuard can be used in two ways:

### Remote library

You can load the latest pinned release directly from GitHub:

```lua
local CoreGuardSource = game:HttpGet(
    "https://raw.githubusercontent.com/Teamc00lgui/CoreGuard/v0.1.1/CoreGuard.luau"
)

local CoreGuard = loadstring(CoreGuardSource)()

CoreGuard:Init({
    Players = Players,
    CoreGui = CoreGui,
    RunService = RunService
})

CoreGuard:Mount(ScreenGui)
CoreGuard:Monitor(ScreenGui)
```

Your project must provide the required services through `CoreGuard:Init()` and create its own `ScreenGui`.

The release tag in the URL keeps the project pinned to a specific CoreGuard version.

### Integrated library

CoreGuard can also be integrated directly into your script.

```lua
local CoreGuard = {}

CoreGuard.Name = "CoreGuard"
CoreGuard.Version = "0.1.1"

-- CoreGuard implementation

CoreGuard:Init({
    Players = Players,
    CoreGui = CoreGui,
    RunService = RunService
})

CoreGuard:Mount(ScreenGui)
CoreGuard:Monitor(ScreenGui)
```

When integrated, the CoreGuard implementation becomes part of your project and does not need to be downloaded at runtime.

## How CoreGuard works

CoreGuard automatically attempts to mount the GUI into `CoreGui`.

If `CoreGui` is unavailable, CoreGuard automatically falls back to `PlayerGui`.

CoreGuard can also monitor the mounted GUI and recover it if necessary.

## API

### `CoreGuard:Init(Services)`

Initializes CoreGuard with the services required by the library.

### `CoreGuard:Mount(ScreenGui)`

Attempts to mount the provided `ScreenGui` into `CoreGui`. If that fails, CoreGuard falls back to `PlayerGui`.

### `CoreGuard:Monitor()`

Starts monitoring the GUI.

### `CoreGuard:Shutdown()`

Stops CoreGuard and disconnects its active monitoring connections.

## x_c00lkidd_x projects that use CoreGuard

* 007n7's hub

## Repository

CoreGuard is maintained separately so it can be reused across multiple projects.

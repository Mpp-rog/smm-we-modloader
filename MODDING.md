# SMM:WE Modloader — Modding Guide & API Reference

The Lua modloader lets you change the game at runtime: run code on every
frame, react to room changes, draw buttons on screen, share data with the
game, and open TCP sockets — all from a small Lua script in a zip file.

- **Delivery:** each mod is a `.zip` containing a top-level `main.lua`.
- **Runtime:** Lua 5.4 (full standard libraries) embedded in the game via the
  `swe_lua` native extension.
- **Safety:** one broken mod can never crash or block the game — its error is
  logged and the game (and every other mod) keeps running.
- **Platforms:** designed for Windows and Linux. Everything documented here
  was verified running on the Linux build.

> ⚠️ **Mods are not sandboxed.** A mod runs with the full power of Lua's
> `io` / `os` libraries — it can read and write files and run shell commands.
> Only install mods you trust.

---

## 1. Quick start

### Making a mod

```
mymod/
  main.lua      <- required, must be at the zip root (or one folder deep)
  anything else <- optional; extracted next to main.lua
```

```sh
cd mymod
zip -r ../mymod.zip main.lua
```

### Installing it

Drop the zip into the game's **`mods/`** folder:

| OS      | mods folder                                        |
|---------|----------------------------------------------------|
| Linux   | `~/.config/SMM_WE/mods/`                           |
| Windows | `<game folder>/mods/` (next to the game executable) |

The folder is created automatically on first launch. Start the game — every
`.zip` in `mods/` is extracted to `mods/<safe-name>/` and its `main.lua` is
executed, in filename order (prefix numbers like `01_`, `02_` control order).

### Your first mod

```lua
-- main.lua
swe.log("Hello from my mod!")

swe.on("on_game_start", function()
  swe.log("The game just started")
end)

swe.on("on_update", function(room)
  -- runs every step (60x/s); keep it cheap!
end)
```

Check `~/.config/SMM_WE/modloader.log` if something isn't working.

### Zip layouts that work

| Layout | Result |
|---|---|
| `main.lua` at zip root | ✅ loaded |
| `mymod/main.lua` (one folder deep) | ✅ auto-flattened, loaded |
| `a/b/main.lua` (two+ folders deep) | ❌ not found |
| no `main.lua` at all | ❌ skipped, logged as `NO_MAIN` |

---

## 2. Lua environment

Mods run in a single shared Lua 5.4 state with:

- **Full standard libraries** — `math`, `string`, `table`, `io`, `os`,
  `coroutine`, `utf8`, `package`, … (verified present).
- **A `net` socket library** (see [§6](#6-networking)).
- **The `swe` API** (this document), injected by the loader before your mod
  runs.

All mods share one state: globals and variables leak between mods. Namespace
your globals (`mymod.foo`) and prefer `swe.store_*` with a unique key prefix.

---

## 3. `swe` API (what your mod can call)

### `swe.on(event, fn) -> boolean`

Register a callback for an event (see [§4](#4-events)). Returns `true` on
success; returns `false` (never throws) if `event` isn't a string or `fn`
isn't a function.

```lua
swe.on("on_enter_room", function(room)
  swe.log("entered " .. room)
end)
```

Multiple mods can listen to the same event; all callbacks run, in
registration order. If one throws, the error is logged and **the other
callbacks still run**.

### `swe.log(msg)`

Print to the game log, prefixed `[mod] `. Shows up on stdout and in the
runner's console.

### `swe.store_set(key, value) -> value` / `swe.store_get(key)`

The **mod store**: a shared key/value table bridged to the game (see
[§5](#5-the-store-talking-to-the-game)). Keys are plain strings; values can be any Lua value.

```lua
swe.store_set("mymod.score", 42)
swe.store_set("mymod.name", "Buffy")
local score = swe.store_get("mymod.score") or 0
```

### `swe.mods()`

Returns the raw store table (the same table `store_get`/`store_set` use) —
useful for iterating everything a mod (or the game) has published:

```lua
for k, v in pairs(swe.mods()) do
  swe.log(k .. " = " .. tostring(v))
end
```

### `swe.net.*`

Networking (see [§6](#6-networking)): `listen`, `connect`, `accept`, `send`,
`recv`, `close`, `sendline`.

---

## 4. Events

| Event | When | Arguments |
|---|---|---|
| `on_game_start` | once, after all mods are loaded | — |
| `on_update` | every step (60×/s) — your tick hook | `room` (string) |
| `on_enter_room` | when a new room begins | `room` (string) |
| `on_room_end` | right before the current room ends | `room` (string) |
| `on_button_click` | when one of your buttons is clicked | `key`, `action` (strings) |

```lua
swe.on("on_enter_room", function(room)
  if room == "rm_mario11" then
    swe.log("Level 1-1!")
  end
end)
```

**`on_update` fires 60 times per second.** Do the heavy work on
`on_enter_room` / `on_game_start` and keep the tick handler light.

---

## 5. The store (talking to the game)

The store is one flat string-keyed table shared between Lua and the game's
GML code. Both directions are verified working:

```lua
-- Lua -> game: the game polls these keys from GML every frame
swe.store_set("mymod.speed", 2.5)
swe.store_set("mymod.status", "ready")

-- game -> Lua: the game writes into the same table (e.g. its own state)
local v = swe.store_get("mymod.speed")  -- 2.5
```

From GML, the game reads types like this (`scr_modloader`):

```gml
var spd = mod_store_get_num("mymod.speed");        // 2.5
var st  = mod_store_get_str("mymod.status");       // "ready"
var ty  = mod_store_get_type("mymod.speed");       // 3 (number)
```

`mod_store_get_type` codes: **0** missing/nil, **1** boolean, **3** number,
**4** string, **5** table, **6** function. (GML can only pull out numbers and
strings — store tables/functions are for Lua-to-Lua use.)

**Convention:** prefix your keys with your mod name (`mymod.*`) so mods
can't stomp each other.

---

## 6. Networking

Raw TCP sockets from Lua, verified with a real loopback round-trip:

| Function | Returns | Notes |
|---|---|---|
| `net.listen(port)` | fd (number) | `port = 0` picks a free port |
| `net.accept(server_fd)` | new fd, or `-1` if no pending connection | |
| `net.connect(host, port)` | fd (number) | failure may only surface later — check `send`/`recv` results |
| `net.send(fd, data)` | bytes sent, or `-1` on error | |
| `net.recv(fd)` | data string, or `false` if nothing/error | |
| `net.close(fd)` | | |

`swe.net` mirrors these one-to-one and adds `swe.net.sendline(fd, s)` (sends
`s .. "\n"`).

### Example: tiny echo server + client (same game, two mods — or one)

```lua
-- server mod
local srv = swe.net.listen(45999)

swe.on("on_update", function(room)
  local cli = swe.net.accept(srv)
  if cli and cli >= 0 then
    local data = swe.net.recv(cli)
    if data then
      swe.log("server got: " .. data)
      swe.net.send(cli, "pong: " .. data)
    end
    swe.net.close(cli)
  end
end)
```

```lua
-- client mod
local cli = swe.net.connect("127.0.0.1", 45999)
swe.net.send(cli, "ping")
local reply = swe.net.recv(cli)
swe.log("client got: " .. tostring(reply))
swe.net.close(cli)
```

Since `on_update` is your pump, use it for non-blocking accept/recv loops.
`accept` returning `-1` and `recv` returning `false` just mean "nothing
waiting" — not fatal errors.

---

## 7. On-screen buttons (mod UI)

Declare buttons through the store and the game draws them every frame, on
top of everything, in every room — and routes clicks back to you.

### Store contract

| Key | Type | Meaning |
|---|---|---|
| `btn.count` | number | how many buttons to draw (max **8**) |
| `btn.<i>.enabled` | number | `1` = show, `0` = hide (`i` is 0-based) |
| `btn.<i>.x` `btn.<i>.y` | number | position in **GUI coordinates (384×216 screen space)** |
| `btn.<i>.w` `btn.<i>.h` | number | size in GUI pixels |
| `btn.<i>.label` | string | text drawn on the button |
| `btn.<i>.action` | string | `"crash"` = deliberately hard-crash the game; anything else fires `on_button_click` |

### Example: working button with a click handler

```lua
local n = 0

swe.store_set("btn.count", 1)
swe.store_set("btn.0.enabled", 1)
swe.store_set("btn.0.x", 8)
swe.store_set("btn.0.y", 174)     -- near the bottom of the 384x216 GUI
swe.store_set("btn.0.w", 120)
swe.store_set("btn.0.h", 30)
swe.store_set("btn.0.label", "Click me")
swe.store_set("btn.0.action", "mymod.click")

swe.on("on_button_click", function(key, action)
  if action == "mymod.click" then
    n = n + 1
    swe.store_set("btn.0.label", "Clicked " .. n .. "x")
  end
end)
```

Buttons highlight red on hover. The label is re-read from the store every
frame, so updating `btn.<i>.label` updates the button live. Keep buttons
inside 384×216 — that's the game's GUI coordinate space.

(`action = "crash"` exists for testing the loader's crash-isolation path; it
deliberately kills the process, so don't ship it in a real mod.)

---

## 8. Putting it together: a complete example mod

```lua
-- main.lua -- room tracker with an on-screen counter
local entered, ticks = {}, 0

swe.log("roomtracker loaded")

swe.store_set("rt.rooms", 0)
swe.store_set("btn.count", 1)
swe.store_set("btn.0.enabled", 1)
swe.store_set("btn.0.x", 8)
swe.store_set("btn.0.y", 8)
swe.store_set("btn.0.w", 150)
swe.store_set("btn.0.h", 24)
swe.store_set("btn.0.label", "rooms: 0")
swe.store_set("btn.0.action", "rt.reset")

swe.on("on_game_start", function()
  swe.log("tracker ready")
end)

swe.on("on_enter_room", function(room)
  if not entered[room] then
    entered[room] = true
    local total = swe.store_get("rt.rooms") + 1
    swe.store_set("rt.rooms", total)
    swe.store_set("btn.0.label", "rooms: " .. total)
    swe.log("first visit to " .. room)
  end
end)

swe.on("on_update", function(room)
  ticks = ticks + 1
  if ticks % 600 == 0 then
    swe.store_set("rt.uptime", ticks / 60)   -- seconds, readable from GML
  end
end)

swe.on("on_button_click", function(key, action)
  if action == "rt.reset" then
    entered, ticks = {}, 0
    swe.store_set("rt.rooms", 0)
    swe.store_set("btn.0.label", "rooms: 0")
  end
end)
```

---

## 9. Troubleshooting

Everything the loader does is logged to **`modloader.log`** in the game's
save folder (`~/.config/SMM_WE/` on Linux) and to stdout.

| Log line | Meaning |
|---|---|
| `Lua modloader initialised` | the Lua state booted fine |
| `found N zip(s) in assets/mods/` | your zips were seen |
| `extracted zip: X (HAVE_MAIN)` | unzip worked, `main.lua` found |
| `zip missing main.lua after extract: X (...)` | bad zip layout — see §1 |
| `error in 'name': ...` | Lua error in that mod; it's skipped, game continues |
| `loaded N mod(s)` | summary at the end of loading |
| `loaded mod 'name'` | your mod made it |

Common problems:

- **Nothing happens** — is the zip directly in `mods/`, not a subfolder? Is
  it a real zip (not renamed)?
- **Mod silently skipped** — check `error in '<name>'` in the log; it's
  usually a Lua syntax error, reported with line number.
- **Button doesn't show** — `btn.count` and `btn.<i>.enabled` must both be ≥1,
  `w`/`h` must be > 0.
- **Clicks do nothing** — handle `on_button_click` and match your own
  `action` string.

---

## 10. GML API reference (for game/extension developers)

`scripts/scr_modloader` — call these from game code. All of them degrade
gracefully: when the loader isn't up they're safe no-ops.

### Lifecycle

| Function | Description |
|---|---|
| `mod_ready()` / `mod_live()` | `true` when the Lua state exists and mods are on |
| `mod_init()` | create the Lua state, open libs, run the bootstrap; returns success |
| `mod_load_all()` | extract + run every `mods/*.zip`; returns loaded count |
| `mod_shutdown()` | close the Lua state, switch mods off (idempotent) |

The game wires these in `obj_persistent`: `mod_init()` + `mod_load_all()` +
`mod_fire("on_game_start")` at Game Start, `mod_enterscene()`/`mod_tick()` in
Step, `mod_roomend()` on Room End, `mod_ui_draw()` in Draw GUI, and
`mod_shutdown()` on Game End.

### Firing events into mods

| Function | Description |
|---|---|
| `mod_arg_clear()` | reset the staged argument list (max **8** args) |
| `mod_arg_num(i, v)` | stage number arg `i` (0-based) |
| `mod_arg_str(i, s)` | stage string arg `i` |
| `mod_fire(ev)` | run all callbacks for `ev`; returns count run, or **negative** count if some threw |

```gml
mod_arg_clear();
mod_arg_str(0, room_get_name(room));
mod_fire("on_enter_room");
mod_arg_clear();
```

### Mod store bridge

| Function | Description |
|---|---|
| `mod_store_get_num(key)` | number, `0` if not a number |
| `mod_store_get_str(key)` | string, `""` if not a string |
| `mod_store_get_type(key)` | 0 nil · 1 bool · 3 number · 4 string · 5 table · 6 function |
| `mod_store_set_num(key, v)` | write a number |
| `mod_store_set_str(key, s)` | write a string |

### UI / misc

| Function | Description |
|---|---|
| `mod_ui_draw()` | draws + click-handles every `btn.*` declared in the store (max 8) |
| `mod_log(msg)` | append to `modloader.log` + debug output |
| `mod_crash()` | deliberately hard-crash the game (test helper; uncatchable) |

### Raw extension functions (`swe_lua`)

Everything above is built on these; use them directly for things the
modloader doesn't wrap (e.g. calling a Lua global function from GML):

| Function | Description |
|---|---|
| `sl_newstate()` / `sl_openlibs(L)` / `sl_close(L)` | state lifecycle |
| `sl_dostring(L, code)` | run a Lua chunk; `0` = OK |
| `sl_lasterror()` | last Lua error (static buffer) |
| `sl_setglobal_num(L, name, v)` / `sl_setglobal_str(L, name, s)` | write a Lua global |
| `sl_getglobal_type(L, name)` | type code (see store types above) |
| `sl_getglobal_num(L, name)` / `sl_getglobal_str(L, name)` | read a Lua global |
| `sl_arg_clear()` / `sl_arg_num(i, v)` / `sl_arg_str(i, s)` | stage call args |
| `sl_pcall(L, fname, argc)` | call global Lua function `fname` with staged args (`0` = OK) |
| `sl_result_type()` / `sl_result_num()` / `sl_result_str()` | read the return value of the last `sl_pcall` |
| `sl_fire(L, evname)` | fire an event's hooks; returns run count, `-n` if `n` threw |
| `sl_store_set_num/str(key, v)` · `sl_store_get_num/str/type(key)` | mod store |

### Verified engine behaviors (heads-up for extenders)

- **No `return`/`break` inside `try` blocks** in modloader code — on the VM
  runner they can unwind the enclosing loop/function and silently skip mods.
- One shared Lua state for all mods; `sl_dostring` handles `main.lua` files
  up to at least **1 MB** (tested) without truncation.
- Hook errors are isolated per callback: `sl_fire` returns `-n` when `n`
  callbacks threw, the error text is in `sl_lasterror()`, and the remaining
  callbacks still run.
- Zip extraction runs through the system `unzip` with absolute paths
  resolved via a save-dir marker file (`mod_shell_root()`), because GML file
  functions and the Lua-spawned shell resolve `working_directory`
  differently on Linux.

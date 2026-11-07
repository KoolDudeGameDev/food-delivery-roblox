# Deliver a Parcel (Roblox)

A cosy, funny delivery tycoon set in a small Filipino town. Take food and parcel orders from the
warehouse, ride across town, and run the last few metres on foot, because a Chihuahua is waiting
at the gate. Spend your pesos turning a cardboard box into a mansion and roller blades into a
motorcycle with a sidecar. Play solo or with friends.

## The browser game was the prototype

Deliver a Parcel started as a browser game. That version proved the idea and stays playable:

- Play the prototype: <https://deliver-a-parcel.vercel.app>
- Its code: <https://github.com/KoolDudeGameDev/deliver-a-parcel>

This repository is the real game, rebuilt for Roblox in Luau. The prototype's numbers (pay,
timers, chasers, rides and homes) carry over as starting values. The prototype's code does not.

## Where it's going

The design lives in [`design/`](design/):

- [`GDD.md`](design/GDD.md) is the game design document, and the centre of development.
- [`World-Layout-Blueprint.md`](design/World-Layout-Blueprint.md) covers the town's districts,
  roads, houses, lots and chaser areas.
- [`MVP-Tracker.md`](design/MVP-Tracker.md) shows what is built and tested so far, against the
  GDD's MVP acceptance criteria.

**Status:** early development. The graybox town and the first delivery loop work: take an order
at the board, follow the beam, reach the door before the timer runs out, and get paid by the
server. Chasers, rides, shops and events come next.

## Building it

You need [Roblox Studio](https://create.roblox.com/) and [Rokit](https://github.com/rojo-rbx/rokit).

1. Run `rokit install` in this folder. It installs the pinned Rojo 7.7.1.
2. Run `rojo serve`.
3. Open any place in Studio (a blank Baseplate is fine; the town builds itself from code), then
   choose **Plugins > Rojo > Connect**.
4. Press Play.

If you move or delete a folder under `src/` or `tests/`, restart `rojo serve` and connect again.
Otherwise Studio silently stops syncing.

To run the tests, use Studio's command bar:

```lua
local t = game:GetService("ServerStorage").Tests
local r = t.Runner:Clone(); r.Parent = t
local ok, res = pcall(function() return require(r).run() end)
r:Destroy(); print(ok and res or ("runner error: " .. tostring(res)))
```

## Layout

| Path | What |
| --- | --- |
| `src/shared/` | Rules and data both sides read: `Config`, `Pay`, `Offers`, `PlayerData`, `WorldLayout`, `Data/*` |
| `src/server/` | Everything that decides money or state: `WorldBuilder`, `DataService` (ProfileStore), `LotService`, `OrderService` |
| `src/client/` | Input, screens and effects: `Hud`, `Board`, `Waypoint` |
| `tests/` | `*.spec.luau` specs and the `Runner` |

**Rule:** the server decides money. The client only asks ("accept this offer") and never says
what it earned.

## Credits and licence

The code is MIT licensed (see [`LICENSE`](LICENSE)). ProfileStore by loleris is vendored under
Apache-2.0 (see [`third_party/`](third_party/)). Models and sounds are listed in
[`CREDITS.md`](CREDITS.md).

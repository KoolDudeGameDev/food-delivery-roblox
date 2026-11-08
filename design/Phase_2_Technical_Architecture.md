# Phase 2: technical architecture

GDD §15 calls for a Technical Architecture Document as Phase 2's deliverable. This one describes
the build **as it is** on `main`. When the code changes, change this page with it. Scope and the
exit test live in [Roadmap.md](Roadmap.md); status lives in [MVP-Tracker.md](MVP-Tracker.md).

## Toolchain

- **Rojo 7.7.1**, pinned in `rokit.toml`. `default.project.json` maps the folders below into the
  place. Meshes never go through Rojo (it drops `MeshPart.MeshId`), so Toolbox models live only
  in the place file, at `ServerStorage.Assets/<Role>`.
- **ProfileStore** is vendored at `src/server/Packages/ProfileStore.luau`.
- The place is published as the private experience "food-delivery", with Roblox version history.

## Where code runs

| Place in the tree | Source | Runs on |
| --- | --- | --- |
| `ReplicatedStorage.Shared` | `src/shared` | Both. Pure rules and data, no side effects, unit-tested |
| `ReplicatedStorage.Remotes` | `default.project.json` | The client↔server boundary (below) |
| `ServerScriptService.Server` | `src/server` | Server only. Owns all state that matters |
| `StarterPlayerScripts.Client` | `src/client` | Client only. Draws the state and sends requests |
| `ServerStorage.Tests` | `tests` | Studio only, through `Runner.luau` |
| `ServerStorage.Assets` | the place file | Art that `WorldBuilder.art(role)` swaps in for graybox |

**The rule:** the server decides money, orders, saves and speed. The client only asks, and
draws what the server tells it.

## Server boot order

`Main.server.luau` starts the services in this order:

1. **WorldBuilder.build**: the graybox town into `Workspace.World/<District>` and
   `Workspace.Gameplay/<System>`, from `WorldLayout`.
2. **WorldService**: the day clock and the events (rain, brownout, fiesta, Undas), shown as
   `workspace` attributes.
3. **MoveService**: the only service that sets `WalkSpeed` (ride, parcel weight, stun and
   sprint stamina).
4. **LotService**: one lot per session, the owner sign and the home model.
5. **OrderService**: the board, accept, timers, delivery and pay.
6. **GateService**: gates open for a carried order, or for anyone already inside.
7. **ChaserService**: dogs, simulated on the server.
8. **RideService**: the ride models, welded to the player, parked at the gates.
9. **ShopService**: purchases.
10. **DataService**, last of all. Every other service registers `DataService.onLoaded` first,
    so none of them misses a player.

## Remotes

| Remote | Kind | Direction | What the server checks |
| --- | --- | --- | --- |
| `AcceptOrder` | RemoteFunction | client → server | The data is loaded. The id is a string of at most 32 characters. One request per 0.25 s. The player is within `HUB_REACH` + 2 m of the board. The offer is on this player's board. `Offers.problem` passes (carry capacity and the order limit) |
| `Buy` | RemoteFunction | client → server | The item is a string of at most 40 characters. One request per 0.3 s. The data is loaded. The player is in range of the dealer, the mechanic or their own lot, depending on the item. Then `Shop.buy` checks the price and the order of purchases |
| `Sprint` | RemoteEvent | client → server | The argument is a boolean. Stamina is the server's own count |
| `State` | RemoteEvent | server → client | Pushes the player's cash, orders, offers, goals, rides and home |
| `Notify` | RemoteEvent | server → client | Toasts and cues (accepted, paid, bitten) |
| `Mount`, `Intro` | RemoteEvent | — | Stubs with no handler yet. The Intro arrives in the Phase 3 close-out |

**There is no "deliver" remote.** The server's tick sees the character within `DELIVER_REACH`
of the doorstep and pays. That means a client can't claim a delivery, but it does trust the
character's position. The teleport check is part of the MVP gate (GDD §14.3 criterion 3).

**State the clients read without a remote.** These are attributes the server sets:
- on `workspace`: `Rain`, `Brownout`, `Festival`;
- on each dog: `X`, `Z`, `Yaw`, `State`, `Chasing`, `BiteAt`;
- on each player: `Stamina`, `Winded`, `LotId`;
- on each gate: `Open`.

## Saves

- **Store:** ProfileStore `PlayerData_v1`, one profile per player (`Player_<UserId>`). In Studio
  without API access it falls back to a mock store, which resets every playtest.
- **Session lock:** a second server that opens the same profile ends the first session, and the
  player there is kicked ("Your save was opened on another server"). Progress can't be
  duplicated (GDD §13.4).
- **Schema** (`src/shared/PlayerData.luau`, `VERSION = 1`): `cash`, `delivered`, `homeTier`,
  `ratingSum`, `ratingCount`, `streak`, `regulars`, `owned`, `parts`, `equipped`, `goals`.
- **On load:** `Reconcile()` fills in missing fields, then `PlayerData.sanitize` checks every one
  of them. Numbers become whole numbers from 0 up. Ids must exist in `WorldLayout`. Only real
  rides are kept, and part levels are kept within their price lists. The equipped ride must be
  owned, and goals must be known. **A new saved field needs a default and a sanitize check.**
- **Writes:** services call `DataService.changed(player)` after every change. `SaveThrottle`
  merges those calls into one save per player per 6 s. Leaving the game always saves, and
  ProfileStore saves everyone on shutdown.

## Tests

- **What's covered:** the pure rules in `src/shared` (`Pay`, `Offers`, `Goals`, `Shop`,
  `PlayerData`, `ChaserRules`, `WorldClock`, `WorldLayout`) and `SaveThrottle`. Each has a
  `tests/<Name>.spec.luau`.
- **In Studio:** `Runner.run()` clones the code into a sandbox and runs every spec (the snippet
  is in `README.md`). It should print `N passed, 0 failed`.
- **Without Studio:** the pure specs run on the Luau CLI through a bundle script, kept in the
  vault as `luau-cli-test-bundle.py`. `luau-compile --null` is a quick syntax check.
- **Not unit-tested:** the services, because they need a live DataModel. The exit test below
  covers them.

## Exit checklist (Phase 2)

- [ ] The Studio suite prints `N passed, 0 failed`.
- [ ] Studio **Test > Clients and Servers** with 2 players: both spawn at their own lots, see
      the same dogs and gates, and each player's board and cash stay separate.
- [ ] On the published place, with Studio API access on:
  - [ ] earn cash, buy something, leave;
  - [ ] rejoin: the cash and the purchase are still there.
- [ ] Two-server lock: join a live server, then force a second session (for example a second
      Studio session on the published place). The first session ends with the "opened on
      another server" kick, and no cash is duplicated.

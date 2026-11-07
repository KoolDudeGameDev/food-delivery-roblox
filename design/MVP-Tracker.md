# MVP tracker

This tracks progress against the [GDD](GDD.md): the §14.3 acceptance criteria and the §15 phases.
A status changes only when the work behind it has been verified. A design written down is not a
feature built (GDD §15.1).

Statuses: Not Started, In Progress, Blocked, Testing, Completed.

## MVP acceptance criteria (GDD §14.3)

| # | Criterion | Status | Notes |
| --- | --- | --- | --- |
| 1 | A new player can understand and complete a delivery | Testing | Board, beam waypoint, timer, door, pay. Needs a playtest with someone new to the game |
| 2 | The server validates order acceptance, delivery and payment | Testing | `OrderService`: the board is in reach, the offer exists, carry is free, a rate limit; the doorstep distance and the deadline are checked on the server. Pay comes from `Pay`, with unit tests |
| 3 | Invalid or duplicate reward requests are rejected | Testing | Bad ids, gone offers and out-of-reach requests are refused. An order is removed before it pays |
| 4 | Chasers work in multiplayer without breaking order state | Not Started | Milestone 2. Yards and their breeds are already in the layout |
| 5 | Players can buy and visibly equip upgrades | Not Started | Milestone 4 |
| 6 | Home and progression data persist across sessions | In Progress | ProfileStore saves cash, deliveries, ratings, streak, regulars and home tier, with a check on load. Not yet tested with a live DataStore |
| 7 | Concurrent sessions cannot duplicate progression | In Progress | ProfileStore's session lock is in place. Not yet tested across two servers |
| 8 | Multiple players can use the same server reliably | Testing | Each player gets a lot and their own board. Needs a 2-player Studio test |
| 9 | The experience is playable on mobile | In Progress | Touch-sized buttons, Roblox touch controls. Not yet tested on a real phone |
| 10 | Repeated deliveries remain enjoyable in playtests | Not Started | |

## Phases (GDD §15)

| Phase | Status | Notes |
| --- | --- | --- |
| 1. Concept validation and game design | Completed | GDD v1.0 and World Layout Blueprint v0.1 |
| 2. Technical foundation and architecture | Testing | Rojo, Rokit, remotes, ProfileStore, shared rules with tests, the Blueprint §15 hierarchy |
| 3. Core gameplay | In Progress | The delivery loop works. Chasers are next |
| 4–9 | Not Started | |

## Open decisions (GDD §16, Blueprint §17)

These are not settled. The game uses the prototype's current behaviour, marked as a reference
value to tune:

- Bonus stacking and caps. Home, regular, streak and event bonuses add together, then night pay
  multiplies the total. There is no cap.
- Failure payout. A timeout pays nothing, rates the delivery one star and ends the streak. A
  damaged order loses tip in proportion to its condition.
- Distance pay. The prototype pays ₱0.40 per metre past 60 m from the hub. The GDD's phrase "up
  to +40%" describes the same constant.
- Lot spacing. Lots are at least 72.4 m apart, centre to centre (Blueprint §17, question 5),
  because the prototype's seeded sites are reused.
- District boundaries are assigned by position in `WorldLayout.districtAt`. This is provisional
  until the graybox test.

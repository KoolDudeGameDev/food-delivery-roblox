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
| 4 | Chasers work in multiplayer without breaking order state | Testing | `ChaserService` runs every dog on the server with `ChaserRules`, which has unit tests (a Chihuahua catches a runner and a Great Dane doesn't; dogs stay in their yard; bites wait 1.2 s; jumping clears small dogs). A bite hurts carried orders (fragile ones twice as much) and ends the streak. Each player's screen glides the dogs to the server's positions. Needs a 2-player playtest |
| 5 | Players can buy and visibly equip upgrades | Testing | Dealer (6 rides, bought in order), mechanic (parts that change the model, speed and carry, up to 4 orders), home (house ladder, ride choice). `ShopService` checks you're at the right place, then `Shop` (unit tested) decides. Rides weld under you, park at the gate when you enter a yard, and come back when you leave. Sprint runs on a server stamina bar. Needs a playtest, including another player seeing your ride |
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
| 3. Core gameplay | Testing | The delivery loop, chasers, and a minimap and town map are built |
| 4. Progression and economy | In Progress | Rides, parts, gate parking, sprint, the dealer, mechanic and home shops, and daily goals (3 a day, the same for everyone). Paint, garden decor and the economy balance pass are still to do |
| 6. Events (launch foundation, GDD §10.1) | In Progress | A 20-minute day and night clock with night pay and street lamps, rain (+10%), brownouts (lamps out, at night), fiesta (food +25%, bunting) and Undas (cemetery +50%, visitors), all run on the server so the town is shared |
| 5. World building and content | In Progress | The town follows the World Layout Blueprint: T-junctions only, the Community District together in the west, footpath shortcuts, direction signs, the roadside kit, crop fields, house variety, lot fences, windows and candles. Toolbox art and audio wait for a session with the Studio tools |
| 7–9 | Not Started | |

## Open decisions (GDD §16, Blueprint §17)

These are not settled. The game uses the prototype's current behaviour, marked as a reference
value to tune:

- Bonus stacking and caps. Home, regular, streak and event bonuses add together, then night pay
  multiplies the total. There is no cap.
- Failure payout. A timeout pays nothing, rates the delivery one star and ends the streak. A
  damaged order loses tip in proportion to its condition.
- Distance pay. The prototype pays ₱0.40 per metre past 60 m from the hub. The GDD's phrase "up
  to +40%" describes the same constant.
- Lot spacing. Lots are at least 72 m apart, centre to centre (Blueprint §17, question 5).
  Five reuse the prototype's seeded sites, and two moved to fit the new layout. A test checks
  the spacing, and that nothing overlaps or sits on a road.
- Footprint (Blueprint §17, question 7) is about 500 x 500 m, provisional until the graybox
  playtest. The town core is the prototype's; houses split 7 inner / 7 outer / 7 rural; a dirt
  loop runs through the rural outskirts.
- The warehouse hub is off-centre, in its own paved yard in the north-east block of the centre,
  beside the road through the middle of town (question 1).
- The cemetery is on the south-west edge, reached down a quiet side road, and can't be seen from
  the hub (question 2).
- The rural outskirts are in the first release (question 3), and the lots are spread round town
  (question 4).
- Roads meet only at T-junctions and bends (Blueprint §5.2). Connectors between the rings are
  staggered, and a test fails on any four-way crossing.
- Reserved corridors run north, south and south-west (the Future Link) to the map edge, each
  closed with a barrier (Blueprint §14).
- Acceleration and rain grip. The prototype's movement blend is ported to the client: rides
  take accel × grip to reach speed, turn and stop, and rain grip is 0.55. The prototype's
  acceleration parts are sold again. The server still caps speed.
- Day length is 20 minutes, the lower end of the Blueprint's provisional 20–25 minute target
  (§11.1). The prototype used 6 minutes. To tune.
- Dogs stand and bark for 0.6 s before they chase (`DOG_ALERT`). Gregory asked for a visible
  warning, and the length is to tune.
- Lamps and windows switch on over the half hour after 17:30, each at its own moment. A brownout
  flickers for 1.5 s first. To tune.
- The "finish a shady job" daily goal waits for night jobs.

## World Layout Blueprint alignment (§18 tracker)

| Workstream | Status |
| --- | --- |
| District structure | Built (Community District consolidated in the middle-west) |
| Road network | Built, T-junctions only, with footpath shortcuts and signs |
| Customer-house distribution | Built, 7/7/7 |
| Home-lot layout | Built, spread round town, fenced |
| Encounter geography | Built: yards, and the alert-then-chase warning. The cemetery night encounter (White Lady) is next |
| Environmental behaviour | Built: day and night, staggered lamps and windows, brownout, rain visibility and grip, fiesta, Undas |
| Audio direction | Not started (needs Creator Store sounds, through the Studio tools) |
| Asset kit | Graybox with `art()` hooks. Toolbox pass not started |
| World blockout validation | Layout tests pass. Needs a playtest |

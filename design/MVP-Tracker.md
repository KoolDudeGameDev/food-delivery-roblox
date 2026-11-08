# MVP tracker

This tracks progress against the [GDD](GDD.md) (§14 MVP, §15 phases) and the
[World Layout Blueprint](World-Layout-Blueprint.md). A status changes only when the work behind it
has been verified. A design written down is not a feature built (GDD §15.1).

Statuses: Not Started, In Progress, Blocked, Testing, Completed.

- **Testing** means built, with its rules unit-tested, and waiting for a playtest.
- **Last review:** 2026-11-08.

PR #1 (`town-map-and-chase`) was merged into `main` on 2026-11-07. The playtest it was waiting
for is still open (Next up, item 1). The phase order and exit tests are in
[Roadmap.md](Roadmap.md); this file is the only place status is kept.

## MVP scope (GDD §14.1)

| System | MVP scope | Status | What's there, and what's missing |
| --- | --- | --- | --- |
| World | Original town blockout and core locations | Testing | Blueprint graybox, about 500 m: 21 houses (7/7/7) and the cemetery, the hub, the dealer, the mechanic, the market, the Community District, 7 lots, a T-junction road network, signs and props. Toolbox art for the sari-sari, small and medium houses (bahay kubo), market stalls, palms and trees. **Missing:** art for the other roles (below) |
| Orders | Food and parcel orders | Testing | Food and parcel, plus Fragile, Rush and Bulky; a per-player board of 3 offers lasting 30 s, with difficulty stars |
| Delivery | Accept, carry, timer, gate parking, door validation, payment | Testing | All of it on the server, plus gates that open only for the right order, a visible carried package and the conveyor |
| Chasers | Dog sizes and a limited set of breeds | Testing | 5 sizes, 13 breeds (with the cat and the goose), alert-bark-chase, bites, knockback, stun |
| Economy | Server-authoritative pesos and purchases | Testing | Only the server changes cash. Buys are checked for range, price and order |
| Vehicles | Initial ride ladder and core parts | Testing | 6 rides, with speed, acceleration and carry parts shown on the model, gate parking, sprint, headlights |
| Homes | Home ladder and individual persistent property | Testing | 5 tiers, saved per player, built on a lot each session. House paint (₱250, at home), ride paint (₱120, at the mechanic) and 6 garden decorations (prototype prices), 2026-11-08 |
| Saving | Reliable player data persistence | In Progress | ProfileStore with a session lock, every field checked on load, throttled saves. **Not tested** against a live DataStore |
| Multiplayer | Shared town and basic interaction | Testing | Shared world, dogs, events and lots. **Not tested** with 2 players |
| UI | Intro, HUD, order board, shops, notifications | Testing | HUD (the prototype's layout), board, goals, shops, minimap and full map, toasts. The Intro on every join (2026-11-08): a rider name (TextService-filtered, shown over the head), saved and checked by the server. Players keep their own Roblox avatar (Gregory, 2026-11-08: no rider outfit). Needs a phone check |
| World conditions | Day/night and a stable subset of conditions | Testing | 20-minute day, night pay, lamps, rain (pay, visibility, grip), brownout, fiesta, Undas |
| Goals | Basic daily objectives | Testing | 3 a day, the same for everyone, paid once each |

Added by Gregory, 2026-11-08: **ride hits**. A fast rider sends whoever they hit flying, sometimes minus a limb, and they pull together where they land. Orders are never touched. Testing: the fling, the limbs and the mend are checked with one player; it needs a 2-player test.

Beyond the MVP but in the existing design, not started:
- night jobs (shady packages and police);
- citizens and road traffic.

## MVP acceptance criteria (GDD §14.3)

| # | Criterion | Status | Notes |
| --- | --- | --- | --- |
| 1 | A new player can understand and complete a delivery | Testing | Gregory completed a paid delivery in Studio (₱69, an earlier build). Still needs a playtest with someone new to the game |
| 2 | The server validates order acceptance, delivery and payment | Testing | `OrderService` checks reach, that the offer exists, carry and a rate limit; it checks the doorstep distance and the deadline; `Pay` is unit tested |
| 3 | Invalid or duplicate reward requests are rejected | Testing | Bad ids, gone offers and out-of-reach requests are refused, and an order is removed before it pays. **Gap:** delivery trusts the character's position, so a teleport check is due in phase 8 |
| 4 | Chasers work in multiplayer without breaking order state | Testing | Server-run `ChaserRules` (unit tested). Needs a 2-player playtest |
| 5 | Players can buy and visibly equip upgrades | Testing | `Shop` is unit tested. Gregory's playtest found the blank shop panel, which is fixed and needs a retest |
| 6 | Home and progression data persist across sessions | In Progress | Needs a published place with API access, then a rejoin test |
| 7 | Concurrent sessions cannot duplicate progression | In Progress | Session lock in place. Needs a two-server test |
| 8 | Multiple players can use the same server reliably | Testing | Needs Studio's 2-player test |
| 9 | The experience is playable on mobile | In Progress | Touch-sized UI, a SPRINT button. Needs a real phone |
| 10 | Repeated deliveries remain enjoyable in playtests | Not Started | |

## Phases (GDD §15)

| Phase | Status | Notes |
| --- | --- | --- |
| 1. Concept validation and game design | Completed | GDD v1.0 and World Layout Blueprint v0.1 |
| 2. Technical foundation and architecture | Testing | Rojo and Rokit, remotes, ProfileStore, shared rules with 60 unit tests, the Blueprint §15 hierarchy. Documented in [Phase_2_Technical_Architecture.md](Phase_2_Technical_Architecture.md), with its exit checklist |
| 3. Core gameplay | Testing | The delivery loop, chasers, the map, gates, the conveyor, carried packages |
| 4. Progression and economy | In Progress | Rides, parts, homes, shops, sprint, daily goals, streaks, regulars. **Next:** paint and decor, and the economy check |
| 5. World building and content | In Progress | The Blueprint graybox is complete. The soundscape is in, and the first Toolbox art (6 roles). **Next:** the remaining art roles |
| 6. Events and live-service systems | In Progress | The launch-foundation events (§10.1) are running. Seasonal calendar events (§10.3) come later |
| 7. Endgame and long-term retention | Not Started | Collections, prestige and franchise wait until the base progression has been tested (GDD §12.3) |
| 8. Testing, balancing and optimization | Not Started | |
| 9. Launch and post-launch operations | Not Started | |

## Next up, in order

This follows [Roadmap.md](Roadmap.md) (GDD §15, closing one phase at a time) and Gregory's
priority: gameplay first, polish after.

1. **Playtest `main` and close Phase 2.** Run the Studio suite, the 2-player test and the save
   checks in the [Phase 2 exit checklist](Phase_2_Technical_Architecture.md#exit-checklist-phase-2).
   Look for:
   - flicker;
   - gates opening for the right order;
   - the dog's warning before it chases;
   - the conveyor and the carried package;
   - the shops;
   - rain grip.
2. **Finish the art pass** (sound and 6 art roles done 2026-11-07, see `CREDITS.md`).
   - Gregory: listen to the sounds and tune the volumes in `Data/Sounds.luau`; replace the three
     public-upload animal calls if a licensed one turns up.
   - Roles still graybox: `House_large` (the bahay na bato in the series are whole compounds, too
     big), `Home_1..5`, `Warehouse`, `Dealer`, `Mechanic`, `Barangay`, `Tower`, `Shrub`,
     `WaitingShed`, `Bench`, `Bin`. `Dog_<breed>` and `Ride_<key>` need rigs with the parts the
     animation moves (`Leg`, `Tail`, `Head`), so they stay graybox.
   - Toolbox houses have no `Door` part and no `Window` tags, so they skip the door animation and
     the lit windows at night. Every stall shares one canopy colour.
   - Save the place and back it up to the vault.
3. ~~**The Intro**~~ Built 2026-11-08 (`NameService`, `client/Intro`). Players keep their own
   Roblox avatar; the rider outfit was dropped (Gregory's call).
4. ~~**Paint and decor**~~ Built 2026-11-08: the prototype's 10 paints for house and ride, and its 6 garden things (flower bed, flag, gnome, fountain, pet dog, string lights). Needs a real purchase in a playtest.
5. **Economy check** (GDD §16): simulated 2026-11-08 ([Economy-Check.md](Economy-Check.md)): first
   ride at about minute 6, first home upgrade at about 10. Gregory sets the targets, the bonus cap
   and the failure payout; the bulk playtest checks the real minutes.
6. **Night content:** ~~the White Lady~~ built 2026-11-08 (prototype `ghost.js`: cemetery after dark, 3.4 m/s, 40% order damage, far-corner return; `workspace.SetClock` jumps the day for playtests). Next: shady jobs and police. The casual target means
   reviewing the 25% arrest cost first (GDD Appendix A).
7. **Living town:** citizens and road traffic.
8. **Phase 8:**
   - a real-phone pass;
   - a performance profile with 7 players;
   - exploit hardening (movement and teleport checks on delivery);
   - a live DataStore and two-server test.
9. **Phase 9:**
   - icon and thumbnails;
   - the maturity questionnaire;
   - badges;
   - a friends' playtest.

Later, all proposals in the GDD:
- team deliveries and community milestones (§9.2);
- seasonal events (§10.3);
- reputation and licences (§7.2);
- the franchise (§12).

## Open decisions (GDD §16, Blueprint §17)

The game uses the prototype's behaviour for each of these, marked as a value to tune.

- **Bonus stacking and caps.** Home, regular, streak and event bonuses add together, then night
  pay multiplies the total. There is no cap.
- **Failure payout.** A timeout pays nothing, rates the delivery one star and ends the streak. A
  damaged order loses tip in proportion to its condition.
- **Distance pay.** ₱0.40 per metre past 60 m from the hub. The GDD's phrase "up to +40%"
  describes the same constant.
- **Day length.** 20 minutes, the lower end of the Blueprint's provisional 20–25 minutes
  (§11.1). The prototype used 6 minutes.
- **Dog warning.** Dogs stand and bark for 0.6 s before they chase (`DOG_ALERT`). Gregory asked
  for the warning.
- **Lights.** Lamps and windows switch on over the half hour after 17:30, and a brownout
  flickers for 1.5 s first.
- **Rain grip.** Rides take accel × grip to reach speed, turn and stop, with rain grip at 0.55.
  The server still caps speed.
- **The shady-job daily goal** waits for night jobs.

Settled (Blueprint §17):
1. The warehouse hub is offset, in the north-east block beside the centre road.
2. The cemetery sits on the south-west edge, down a quiet lane, out of sight of the hub.
3. The rural outskirts are in the first release.
4. Lots are spread round town.
5. Lots are at least 72 m apart, centre to centre.
6. The ground is one continuous flat stretch.
7. The footprint is about 500 m, provisional until the graybox playtest.

The roads meet only at T-junctions (§5.2), and corridors run north, south and south-west
(§14).

## World Layout Blueprint alignment (§18 tracker)

| Workstream | Status |
| --- | --- |
| District structure | Built (Community District in the middle-west) |
| Road network | Built: T-junctions only, footpath shortcuts, signs |
| Customer-house distribution | Built: 7/7/7 |
| Home-lot layout | Built: spread round town, fenced |
| Encounter geography | Built: yards, alert-then-chase, and the White Lady in the cemetery at night (2026-11-08) |
| Environmental behaviour | Built: day and night, staggered lamps and windows, brownout, rain visibility and grip, fiesta, Undas |
| Animation (§13) | Built: dogs, gates, doors, the conveyor, package handling, lights, riding poses. Wind on trees and flags is not built |
| Audio direction (§12) | Built: beds by district and time (birds, rural, crickets, rain and thunder), placed street walla, conveyor, cemetery wind, fiesta music, barks from the dog, the till on pay. Needs a listen |
| Asset kit (§10) | Toolbox art for 6 roles (sari-sari, bahay kubo small and medium, stalls, palm, tree). The rest graybox |
| World blockout validation (§16) | Layout tests pass. Needs a playtest |

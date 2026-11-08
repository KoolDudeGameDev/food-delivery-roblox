# Roadmap

The phases from GDD §15, in the order the project now works through them. This page holds only
**scope and exit tests**. Status lives in one place, [MVP-Tracker.md](MVP-Tracker.md).

## How phases work

- **We close one phase at a time.** A phase is closed when its exit test passes in a playtest,
  not when its code is written. Code for later phases may already exist; it still counts as
  open until its own exit test passes.
- **Only the phase being closed gets a detailed spec** (`Phase_<n>_<Name>.md`). The others stay
  as the short entries below until their turn comes, so a change to the core loop rewrites
  one document, not eight.
- **Every exit test includes two standing checks:**
  1. **Server authority.** Every new remote checks its argument types, reach and rate, and the
     server decides money (GDD §13.2–13.3).
  2. **Phone.** The new UI works on a real phone, at touch size.
- **The numbers in exit tests are Gregory's to set** ("N" below). The GDD leaves them open
  (§16), so they are never invented here.

## Order

```
2 Foundation → 3 Core loop → 4 Progression → 5 World → 6 Events
  → MVP gate (QA slice of 8 + friends soft launch, a slice of 9)
  → 7 Endgame → 8 Release candidate → 9 Public launch and live ops
```

Phase 7 comes after the MVP gate because GDD §12.3 holds prestige and collections until the base
progression has been tested with real players.

## Phases

| # | Phase | Scope | Exit test |
| --- | --- | --- | --- |
| 2 | Technical foundation | Rojo tree, remotes, ProfileStore saves, shared rules with unit tests, the graybox. Spec: [Phase_2_Technical_Architecture.md](Phase_2_Technical_Architecture.md) | The test suite passes. Two clients join one Studio server. A save survives a rejoin on the published place. A second server can't open a save that's already open |
| 3 | Core loop | Board, accept, carry, timer, gates, doorstep delivery, pay, dogs, rides, the HUD, and **the Intro** (name, skin, clothes) | A player new to the game finishes a delivery from the Intro onward without help. Two players run deliveries side by side, with dogs, and neither breaks the other's orders |
| 4 | Progression and economy | Ride and part purchases, carry capacity, homes, streaks, regulars, daily goals, house and ride paint, decor | Purchases survive a rejoin. A timed fresh-start session buys its first ride within **N** minutes and its first home upgrade within **N** minutes. Bonus caps and the failure payout are decided (GDD §16) |
| 5 | World | The art pass on every `ServerStorage.Assets` role, citizens and road traffic, environmental animation, the day/night cycle, lighting, weather visuals, ambient audio | The whole town is reachable and readable on a phone. **N** players stay above **N** FPS on a low-end device. No graybox remains in a player's normal route |
| 6 | Events | The framework: start, run, end and reward. Event orders, an event schedule in the UI, the White Lady and night jobs. The launch events (rain, brownout, fiesta, Undas) already run | Each event starts, runs, pays and ends cleanly while deliveries continue, in a 2-player test |
| MVP | MVP gate | GDD §14.3's 10 criteria. Takes the needed slice of 8 (live DataStore, two-server lock, teleport check on delivery, phone) and of 9 (a friends' playtest) | All 10 of the GDD §14.3 criteria pass. Criterion 10 ("repeated deliveries stay enjoyable") passes on a playtest question with a bar of **N** |
| 7 | Endgame and retention | Franchise prestige, collections, advanced rides, community goals | Players from the soft launch say they have a goal past the next purchase, with a bar of **N** |
| 8 | Release candidate | Full balance, multiplayer and exploit QA, performance profiling with a full server, the onboarding pass | No known critical bug or exploit path. Performance on target devices meets the Phase 5 numbers with a full server |
| 9 | Launch and live ops | Icon, thumbnails, description, the maturity questionnaire, analytics, error monitoring, the feedback channel, the patch process | Public. Errors and feedback are watched, and one patch has gone out through the process |

## Next detailed spec

**The Phase 3 close-out**: the Intro, then the 2-player exit test. Phase 3 is built apart from the
Intro, but it isn't closed until its test passes.

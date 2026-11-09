# Economy check (Phase 4)

The roadmap's Phase 4 exit test needs pacing numbers that only Gregory can set (GDD §16). This page
gives a first estimate to set them against. It comes from a simulation of a fresh player's first
hour, played 200 times with the game's real rules: `Offers`, `Pay`, `Shop` and the rating gate.

Re-run it in Studio's command bar after any tuning:

```lua
print(require(game.ServerStorage.Tests.EconomySim).run())
```

## Assumptions, to check against a stopwatch

These are guesses about how people play, not rules of the game:

- **Route:** 1.3 times the straight-line distance.
- **Time at stops:** 6 s at the board, 3 s at each door, 4 s from a parked ride to the door and
  back.
- **Dogs:** one bite in 40% of dog-yard visits.
- **Order choice:** the best-paying offers you can carry, taken nearest first.
- **Left out:** rain, fiesta, Undas and daily-goal rewards.

## Results (2026-11-09, after Gregory's tuning)

Gregory's changes (all marked "to tune" in the code):

- **Bonus cap:** the regular, streak and event bonuses together add at most +15%
  (`Config.BONUS_CAP`). The home bonus sits on top of the cap, then night pay multiplies.
- **Event pay:** rain +5%, fiesta food +10%, Undas cemetery +15% (were 10%, 25%, 50%).
- **Home bonus:** +2% a tier, up to +8% for the mansion (was 3% a tier, up to 12%), because it
  lasts forever. The most a delivery can now earn in bonuses is +23%, then ×1.15 at night.
- **Bicycle at about minute 30:** the bicycle drops from ₱2,500 to ₱1,300 and the skateboard from
  ₱900 to ₱700. A cheaper bicycle alone ended up behind the bungalow in the spending queue.
- **Failure payout:** unchanged. A timeout pays nothing, rates one star and ends the streak.

Minutes after joining, as a median (most players fall in the 10%–90% range). Run with the Luau
CLI, whose random numbers differ from Studio's, so expect small differences in Studio:

| Bought | Price | Minute | 10%–90% | Before |
| --- | --- | --- | --- | --- |
| Roller blades | ₱300 | 5.6 | 4.6–7.3 | 5.7 |
| Wooden shack | ₱400 | 10.6 | 9.2–12.5 | 10.5 |
| Skateboard | ₱700 | 18.1 | 15.6–21.2 | 20.3 |
| Bicycle | ₱1,300 | 30.0 | 25.1–33.0 | 50.6 |
| Bungalow | ₱1,500 | 38.2 | 33.5–43.1 | 32.8 |
| Two-storey house | ₱4,000 | 57 (45% of players reach it in the hour) | | 3% |

- **Deliveries:** about 67 in the first hour (was 63), because the faster bicycle comes sooner.
- **Spending order:** buying rides first or homes first still makes almost no difference.
- **Against the GDD:** the first purchase still lands inside GDD §2.3's "within approximately
  5–10 minutes", and the bicycle now falls inside the 20–40 minute target session (§1.4).

## Still open

- **Pacing targets for the Phase 4 exit test:** first ride by about minute 6, first home upgrade
  by about minute 10, and the bicycle by about minute 30 (Gregory, 2026-11-09). The bulk
  playtest checks the real minutes against these with a stopwatch.

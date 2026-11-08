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

## Results (2026-11-08)

Minutes after joining, as a median (most players fall in the 10%–90% range):

| Bought | Price | Minute | 10%–90% |
| --- | --- | --- | --- |
| Roller blades | ₱300 | 5.7 | 4.7–7.3 |
| Wooden shack | ₱400 | 10.5 | 9.1–12.4 |
| Skateboard | ₱900 | 20.3 | 17.2–23.2 |
| Bungalow | ₱1,500 | 32.8 | 28.3–35.9 |
| Bicycle | ₱2,500 | 50.6 | 44.3–57.1 |
| Two-storey house | ₱4,000 | reached by 3% of players in the hour | |

- **Deliveries:** about 63 in the first hour, roughly one a minute.
- **Spending order:** buying rides first or homes first makes almost no difference, because at
  ₱300 the ride is the only thing you can afford either way.
- **Against the GDD:** the first purchase lands inside GDD §2.3's hypothesis of "a meaningful
  first purchase within approximately 5–10 minutes".

## Decisions for Gregory

These settle the Phase 4 exit test in [Roadmap.md](Roadmap.md):

1. **Pacing targets:**
   - the minute by which a new player should buy their first ride (now about 6);
   - the minute for their first home upgrade (now about 10);
   - whether the bicycle at about minute 51 is too far off for a first session.
2. **Bonus cap:** the home, regular, streak and event bonuses add up with no cap, then night pay
   multiplies the total (GDD §16).
3. **Failure payout:** a timed-out order pays nothing, rates one star and ends your streak. Keep
   that, or pay something?

Once these are set, the bulk playtest checks the real minutes against them.

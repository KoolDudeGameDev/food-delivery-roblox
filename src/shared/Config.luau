-- Tuning numbers. Values are the prototype's (deliver-a-parcel `src/config.js`), which the GDD
-- (Appendix A) lists as reference values: real play should overrule them, never guesses.
-- Distances and speeds are in metres, as in the GDD; STUDS converts them for the world.

local Config = {}

Config.STUDS = 3 -- studs per metre, so a default avatar is about 1.75 m tall

-- Moving on foot
Config.RUN = 6 -- m/s
Config.SPRINT = 9.5
Config.PARCEL_SLOW = 0.75 -- carrying a parcel slows you to this share of your speed
Config.RIDE_SPRINT = 1.35 -- sprinting on a ride
Config.FOOT_ACCEL = 30 -- how fast you get up to speed on foot: near enough at once
Config.RAIN_GRIP = 0.55 -- rides grip this share as well in the rain (prototype)
Config.STAMINA_DRAIN = 30 -- per second while sprinting, out of 100
Config.STAMINA_REGEN = 18
Config.WINDED_UNTIL = 25 -- run out, and you can't sprint again until stamina is back to this
Config.MAX_CARRY = 4 -- orders at once (GDD §4.3)
Config.SHOP_REACH = 8 -- m from a shop's doorstep that counts as "at the shop"

-- Orders
Config.FOOD_TIME = 8 -- s, plus travel time; see Pay.timeLimit
Config.PARCEL_TIME = 14
Config.FOOD_PAY = 30 -- pesos
Config.PARCEL_PAY = 25
Config.FAR_PAY = 0.4 -- pesos per metre past FAR_FROM from the hub (the prototype's formula)
Config.FAR_FROM = 60
Config.STAR_PAY = 0.12 -- per difficulty star above 1
Config.TIP_MAX = 0.6
Config.NIGHT_PAY = 1.15
Config.OFFER_COUNT = 3
Config.OFFER_LIFE = 30 -- s
Config.FOOD_CHANCE = 0.6 -- share of offers that are food, where the house and type allow it
Config.DELIVER_REACH = 2.4 -- m from the doorstep that counts as delivered
Config.HUB_REACH = 4.5 -- m from the hub board that counts as "at the hub"

-- Reasons to come back
Config.STREAK_STEP = 0.02
Config.STREAK_MAX = 0.2
Config.REGULAR_VISITS = 3
Config.REGULAR_BONUS = 0.1
-- The regular, streak and event bonuses together never add more than this; the home bonus sits
-- on top (Gregory 2026-11-09, to tune)
Config.BONUS_CAP = 0.15

-- The day and world events
Config.DAY_LENGTH = 20 * 60 -- s per full day; the Blueprint's provisional 20-25 min (§11.1), to tune
Config.START_TIME = 8.6 -- the clock when a server starts (the prototype starts at 0.36 of a day)
-- Event pay, cut from the prototype's 10% / 25% / 50% to fit the bonus cap (Gregory 2026-11-09, to tune)
Config.RAIN_PAY = 0.05
Config.FIESTA_PAY = 0.1
Config.UNDAS_PAY = 0.15
-- How often events come and how long they last, in seconds { min, max } (prototype values)
Config.RAIN_EVERY, Config.RAIN_LASTS = { 150, 300 }, { 50, 80 }
Config.BROWNOUT_EVERY, Config.BROWNOUT_LASTS = { 60, 140 }, { 20, 35 } -- only at night
Config.FESTIVAL_EVERY, Config.FESTIVAL_LASTS = { 180, 300 }, { 75, 75 }

-- A size sets how a chaser plays: speed (m/s), bite damage (% of each order's condition),
-- knock (m/s of knockback), stun (s), danger (difficulty stars), scale (model size).
Config.DOG_TYPES = {
	tiny = { speed = 8.2, damage = 5, knock = 3, stun = 0.05, danger = 0.5, scale = 0.45 },
	small = { speed = 7.5, damage = 10, knock = 5, stun = 0.15, danger = 1, scale = 0.65 },
	medium = { speed = 6.3, damage = 18, knock = 8, stun = 0.35, danger = 1.5, scale = 1 },
	big = { speed = 5.4, damage = 30, knock = 13, stun = 0.7, danger = 2, scale = 1.35 },
	giant = { speed = 4.6, damage = 45, knock = 19, stun = 1.1, danger = 3, scale = 1.9 },
}
Config.DOG_WANDER = 1.6 -- m/s when nobody's in the yard
Config.DOG_ALERT = 0.6 -- s a dog stands and barks before it chases (Gregory's call; to tune)
Config.BITE_GAP = 1.2 -- s between one dog's bites
Config.DOG_WAKE = 60 -- m: dogs with nobody this close stay asleep, to save the server work

-- The White Lady (GDD §5.1, the prototype's values; to tune)
Config.GHOST_SPEED = 3.4 -- m/s: slower than you, but she never stops
Config.GHOST_DAMAGE = 40 -- % of each order's condition
Config.GHOST_REACH = 1.4 -- m: her touch
Config.GHOST_COOLDOWN = 2.5 -- s she's gone after a scare, so you get a moment to run
Config.GHOST_KNOCK = 12 -- m/s away from her, and GHOST_LIFT up
Config.GHOST_LIFT = 5
Config.GHOST_STUN = 0.5 -- s

-- Night jobs and police (GDD Appendix A, the prototype's values; the GDD asks for these to be
-- reviewed for a casual audience, the arrest cost above all: Gregory's call)
Config.DEALER_MIN = 90 -- m from you that a dealer stands
Config.BUYER_MIN = 120 -- m from the dealer that the buyer waits
Config.DEALER_REACH = 3.6 -- m from the dealer to take the package
Config.DEALER_DELAY = 8 -- s after a job before the next dealer appears
Config.CONTRABAND_PAY = 130 -- pesos, plus CONTRABAND_FAR_PAY per metre from dealer to buyer
Config.CONTRABAND_FAR_PAY = 0.6
Config.ARREST_COST = 0.25 -- share of your cash an arrest takes, with every order you carry
Config.POLICE_PATROL = 8 -- m/s round their loop
Config.POLICE_CHASE = 19 -- m/s after you
Config.POLICE_SEE = 32 -- m: how close you must be for them to spot you
Config.POLICE_LOSE = 55 -- m: further than this ...
Config.POLICE_GIVE_UP = 3 -- ... for this long (s), or in a yard, and they give up
Config.POLICE_CATCH = 2.6 -- m: an arrest
Config.POLICE_GRACE = 6 -- s after an arrest before they'll chase you again
Config.POLICE_LANE = 2.2 -- m inside the ring road's centreline

-- The living town (prototype `traffic.js`, `citizens.js`; to tune)
Config.TRAFFIC_LANE = 2.2 -- m outside the ring road's centreline (the police drive inside it)
Config.TRAFFIC_DAMAGE = 8 -- % of each order when a jeepney or tricycle bumps you
Config.TRAFFIC_COOLDOWN = 2.5 -- s between bumps
Config.TRAFFIC_KNOCK = 14 -- m/s away, and 5 m/s up
Config.TRAFFIC_STUN = 0.35 -- s
Config.HIT_SPEED = 7 -- m/s you must be going to send a walker flying
Config.HIT_FINE = 15 -- pesos, never more than you have
Config.HIT_DAMAGE = 10 -- % of each order
Config.WALKER_FALL = 3.4 -- s a walker is down after a hit

-- Ride hits (Gregory, 2026-11-08): a rider this fast sends whoever they run into flying. All to tune.
Config.RAM_SPEED = 6 -- m/s the rider must be going
Config.RAM_REACH = 2.2 -- m from the rider to whoever they hit
Config.RAM_PUSH = 1.5 -- m/s of fling along the ride's way, per m/s of the rider's speed
Config.RAM_LIFT = 8 -- m/s of fling upwards, plus RAM_LIFT_PER per m/s of the rider's speed
Config.RAM_LIFT_PER = 0.6
Config.RAM_DOWN = 2.5 -- s in pieces before you pull yourself together
Config.RAM_IMMUNE = 4 -- s after a hit before you can be hit again
Config.RAM_DETACH_CHANCE = 0.3 -- share of hits where an arm or a leg comes off

return Config

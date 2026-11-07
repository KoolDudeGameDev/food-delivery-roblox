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

-- Events (not running yet; Pay takes their bonus as an input)
Config.RAIN_PAY = 0.1
Config.FIESTA_PAY = 0.25
Config.UNDAS_PAY = 0.5

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
Config.BITE_GAP = 1.2 -- s between one dog's bites
Config.DOG_WAKE = 60 -- m: dogs with nobody this close stay asleep, to save the server work

return Config

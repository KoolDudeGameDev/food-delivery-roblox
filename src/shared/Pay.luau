-- What an order pays, as pure functions so the server and the tests share them. The formulas
-- are the prototype's (deliver-a-parcel `src/orders.js`), except the stacking (GDD §16, Gregory
-- 2026-11-09): the regular, streak and event bonuses add up to at most BONUS_CAP, the home bonus
-- sits on top of that, then night multiplies. Tune only from playtests.
local Config = require(script.Parent.Config)

local Pay = {}

local function round(x: number): number
	return math.floor(x + 0.5) -- JavaScript's Math.round, for positive numbers
end

-- 1 + the home bonus + the capped share of the rest
local function bonusOf(homeBonus: number?, rest: number): number
	return 1 + (homeBonus or 0) + math.min(rest, Config.BONUS_CAP)
end

-- 1 to 5 stars from distance (m from the hub), the yard's chaser, the place's risk and the type.
function Pay.difficulty(distance: number, dogDanger: number, risk: number, typeStars: number): number
	local stars = 1 + math.max(0, distance - Config.FAR_FROM) / 70 + dogDanger + risk + typeStars
	return math.clamp(round(stars), 1, 5)
end

-- Seconds allowed: what a runner needs to get there plus a margin, so a faster ride keeps more
-- of it as tip.
function Pay.timeLimit(distance: number, food: boolean, orderType, extraTime: number?): number
	local travel = if food
		then Config.FOOD_TIME + distance / Config.RUN * 1.25
		else Config.PARCEL_TIME + distance / Config.RUN * 1.6
	return (travel + (extraTime or 0)) * orderType.time
end

-- The pay shown on the board.
function Pay.offerPay(distance: number, stars: number, food: boolean, orderType): number
	local base = (if food then Config.FOOD_PAY else Config.PARCEL_PAY)
		+ math.max(0, distance - Config.FAR_FROM) * Config.FAR_PAY
	return round(base * (1 + (stars - 1) * Config.STAR_PAY) * orderType.pay)
end

export type DeliveryContext = {
	left: number, -- seconds left on the timer
	fresh: number, -- order condition, 0 to 100
	homeBonus: number?,
	regular: boolean?,
	streak: number?,
	eventBonus: number?,
	night: boolean?,
}

-- What a delivery pays when it reaches the door, and the customer's rating of it.
function Pay.delivery(order: { pay: number, max: number }, ctx: DeliveryContext)
	local timeShare = math.clamp(ctx.left / order.max, 0, 1)
	local condition = math.clamp(ctx.fresh / 100, 0, 1)
	local tip = round(order.pay * Config.TIP_MAX * timeShare * condition)
	local bonus = bonusOf(
		ctx.homeBonus,
		(if ctx.regular then Config.REGULAR_BONUS else 0)
			+ math.min((ctx.streak or 0) * Config.STREAK_STEP, Config.STREAK_MAX)
			+ (ctx.eventBonus or 0)
	)
	local total = round((order.pay + tip) * bonus * (if ctx.night then Config.NIGHT_PAY else 1))
	-- Rush orders run short by design, so the clock counts for less than the condition.
	local rating = math.clamp(round(1 + 4 * (math.min(1, timeShare * 1.6) * 0.5 + condition * 0.5)), 1, 5)
	return { tip = tip, bonus = bonus, total = total, rating = rating }
end

-- A shady job (prototype `orders.js`): it already pays well for the risk, so it gets the home,
-- streak and event bonuses but no tip and no night pay, and the buyer doesn't rate it.
function Pay.deal(pay: number, ctx: { homeBonus: number?, streak: number?, eventBonus: number? }): { total: number }
	local bonus = bonusOf(ctx.homeBonus, math.min((ctx.streak or 0) * Config.STREAK_STEP, Config.STREAK_MAX) + (ctx.eventBonus or 0))
	return { total = round(pay * bonus) }
end

return Pay

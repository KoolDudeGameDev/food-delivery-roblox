-- Pay must match the prototype's formulas (deliver-a-parcel `src/orders.js`). Every expected
-- number here is worked out by hand from those formulas.
local function load()
	local Shared = script.Parent.Parent.Shared
	return require(Shared.Pay), require(Shared.Data.OrderTypes)
end

local function near(a: number, b: number)
	return math.abs(a - b) < 1e-6
end

return {
	difficultyAddsDistanceDogRiskAndType = function()
		local Pay = load()
		-- 1 + (100 - 60) / 70 + 1.5 = 3.07 -> 3
		assert(Pay.difficulty(100, 1.5, 0, 0) == 3)
		assert(Pay.difficulty(10, 0, 0, 0) == 1, "close and easy is one star")
		assert(Pay.difficulty(300, 3, 2, 1) == 5, "capped at five stars")
	end,
	offerPayUsesBaseDistanceStarsAndType = function()
		local Pay, Types = load()
		-- food: 30 + 40 * 0.4 = 46, x 1.24 for 3 stars = 57.04 -> 57
		assert(Pay.offerPay(100, 3, true, Types.normal) == 57)
		-- parcel rush: 25 + 100 * 0.4 = 65, x 1.36 x 1.5 = 132.6 -> 133
		assert(Pay.offerPay(160, 4, false, Types.rush) == 133)
		-- no distance pay inside 60 m
		assert(Pay.offerPay(40, 1, false, Types.normal) == 25)
	end,
	timeLimitIsTravelPlusMargin = function()
		local Pay, Types = load()
		-- food: 8 + 60 / 6 x 1.25 = 20.5
		assert(near(Pay.timeLimit(60, true, Types.normal, 0), 20.5))
		-- parcel rush: (14 + 160 / 6 x 1.6) x 0.55 = 31.1667
		assert(near(Pay.timeLimit(160, false, Types.rush, 0), (14 + 160 / 6 * 1.6) * 0.55))
		-- the cemetery's extra 10 s comes before the type multiplier
		assert(near(Pay.timeLimit(60, false, Types.normal, 10), 14 + 60 / 6 * 1.6 + 10))
	end,
	deliveryAddsTipFromTimeAndCondition = function()
		local Pay = load()
		local r = Pay.delivery({ pay = 57, max = 20 }, { left = 10, fresh = 100 })
		-- tip 57 x 0.6 x 0.5 x 1 = 17.1 -> 17, total 74, rating 1 + 4 x (0.8 x 0.5 + 0.5) = 4.6 -> 5
		assert(r.tip == 17, `tip {r.tip}`)
		assert(r.total == 74, `total {r.total}`)
		assert(r.rating == 5, `rating {r.rating}`)
	end,
	deliveryStacksBonusesAdditivelyThenNight = function()
		local Pay = load()
		local r = Pay.delivery({ pay = 57, max = 20 }, {
			left = 10,
			fresh = 100,
			homeBonus = 0.12,
			regular = true,
			streak = 50, -- capped at +20%
			night = true,
		})
		-- (57 + 17) x (1 + 0.12 + 0.1 + 0.2) x 1.15 = 120.84 -> 121
		assert(near(r.bonus, 1.42), `bonus {r.bonus}`)
		assert(r.total == 121, `total {r.total}`)
	end,
	lateAndWreckedPaysBaseOnlyAndOneStar = function()
		local Pay = load()
		local r = Pay.delivery({ pay = 40, max = 20 }, { left = 0, fresh = 0 })
		assert(r.tip == 0 and r.total == 40 and r.rating == 1)
	end,
}

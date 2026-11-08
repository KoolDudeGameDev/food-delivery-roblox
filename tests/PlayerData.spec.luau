-- Every saved field has a default and is checked when it loads (GDD §13.4).
local function load()
	return require(script.Parent.Parent.Shared.PlayerData)
end

return {
	templateStartsWithNothing = function()
		local PlayerData = load()
		local t = PlayerData.template()
		assert(t.version == PlayerData.VERSION)
		assert(t.cash == 0 and t.delivered == 0 and t.homeTier == 1 and t.streak == 0)
		assert(next(t.regulars) == nil)
	end,
	riderNameAndLookAreSavedAndChecked = function()
		local PlayerData = load()
		local t = PlayerData.template()
		assert(t.name == "" and t.look.outfit == false and t.look.skin == 1)
		local d = PlayerData.template()
		d.name = "This name is far too long"
		d.look = { outfit = true, skin = 99, shirt = 1, pants = 1, hat = 1 }
		PlayerData.sanitize(d)
		assert(d.name == "", `name {d.name}`)
		assert(d.look.outfit == false and d.look.skin == 1, "a bad look goes back to the default")
		local ok = PlayerData.template()
		ok.name = "Juan"
		ok.look = { outfit = true, skin = 4, shirt = 2, pants = 3, hat = 4 }
		PlayerData.sanitize(ok)
		assert(ok.name == "Juan" and ok.look.outfit == true and ok.look.skin == 4 and ok.look.hat == 4)
	end,
	templateIsAFreshTableEachTime = function()
		local PlayerData = load()
		local a, b = PlayerData.template(), PlayerData.template()
		a.regulars.red = 1
		assert(b.regulars.red == nil)
	end,
	sanitizeRepairsBadNumbers = function()
		local PlayerData = load()
		local d = PlayerData.template()
		d.cash = -50
		d.delivered = 0 / 0 -- NaN
		d.ratingSum = math.huge
		d.streak = 2.7
		d.homeTier = 99
		PlayerData.sanitize(d)
		assert(d.cash == 0, `cash {d.cash}`)
		assert(d.delivered == 0, `delivered {d.delivered}`)
		assert(d.ratingSum == 0, `ratingSum {d.ratingSum}`)
		assert(d.streak == 2, `streak {d.streak}`)
		assert(d.homeTier == 1, `homeTier {d.homeTier}`)
	end,
	sanitizeReplacesWrongTypes = function()
		local PlayerData = load()
		local d = PlayerData.template()
		d.cash = "lots"
		d.regulars = "nope"
		PlayerData.sanitize(d)
		assert(d.cash == 0 and type(d.regulars) == "table")
	end,
	sanitizeDropsUnknownRegulars = function()
		local PlayerData = load()
		local d = PlayerData.template()
		d.regulars = { red = 3, atlantis = 5, blue = -1, green = 2 }
		PlayerData.sanitize(d)
		assert(d.regulars.red == 3 and d.regulars.green == 2)
		assert(d.regulars.atlantis == nil and d.regulars.blue == nil)
	end,
	sanitizeKeepsOnlyRealRidesAndLevels = function()
		local PlayerData = load()
		local d = PlayerData.template()
		d.owned = { bicycle = true, hoverboard = true, moped = "yes" }
		d.parts = { bicycle = { tires = 9, basket = 1, rocket = 3 }, hoverboard = { jets = 1 } }
		d.equipped = "moped"
		PlayerData.sanitize(d)
		assert(d.owned.bicycle and not d.owned.hoverboard and not d.owned.moped)
		assert(d.parts.bicycle.tires == 3, "level capped at the last price")
		assert(d.parts.bicycle.basket == 1 and d.parts.bicycle.rocket == nil and d.parts.hoverboard == nil)
		assert(d.equipped == "", "riding something not owned")
	end,
	sanitizeKeepsGoodGoalsAndDropsBadOnes = function()
		local PlayerData = load()
		local d = PlayerData.template()
		d.goals = { day = "2026-11-07", list = { { type = 1, progress = 99, done = true }, { type = 2, progress = 1 }, { type = 3, progress = -4 } } }
		PlayerData.sanitize(d)
		assert(d.goals.day == "2026-11-07" and d.goals.list[1].progress == 8 and d.goals.list[3].progress == 0)
		d.goals = { day = "2026-11-07", list = { { type = 99 }, { type = 1 }, { type = 2 } } }
		PlayerData.sanitize(d)
		assert(d.goals.day == "" and #d.goals.list == 0, "an unknown goal type resets the day")
	end,
	sanitizeKeepsGoodData = function()
		local PlayerData = load()
		local d = PlayerData.template()
		d.cash, d.delivered, d.homeTier, d.ratingSum, d.ratingCount = 1234, 20, 3, 80, 20
		PlayerData.sanitize(d)
		assert(d.cash == 1234 and d.delivered == 20 and d.homeTier == 3 and d.ratingSum == 80 and d.ratingCount == 20)
	end,
}

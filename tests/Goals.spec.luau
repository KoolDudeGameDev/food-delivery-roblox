-- Daily goals (prototype `goals.js`): the same three for everyone on the same day, each paid once.
local function load()
	local Shared = script.Parent.Parent.Shared
	return require(Shared.Goals)
end

return {
	aShadyJobIsADailyGoal = function()
		local Goals = load()
		local i = Goals.indexOf("shady")
		assert(i and Goals.TYPES[i].reward == 300 and Goals.TYPES[i].count == 1, "the prototype's shady goal")
	end,
	sameDaySameGoals = function()
		local Goals = load()
		local a, b = Goals.forDay("2026-11-07"), Goals.forDay("2026-11-07")
		assert(#a == 3)
		for i = 1, 3 do
			assert(a[i].type == b[i].type)
		end
	end,
	threeDifferentGoals = function()
		local Goals = load()
		for d = 1, 28 do
			local list = Goals.forDay(string.format("2026-02-%02d", d))
			assert(list[1].type ~= list[2].type and list[2].type ~= list[3].type and list[1].type ~= list[3].type)
		end
	end,
	aNewDayStartsFresh = function()
		local Goals = load()
		local g = Goals.current({ day = "2026-11-06", list = { { type = 1, progress = 5, done = true } } }, "2026-11-07")
		assert(g.day == "2026-11-07" and #g.list == 3)
		for _, item in g.list do
			assert(item.progress == 0 and not item.done)
		end
	end,
	countingPaysOnceWhenDone = function()
		local Goals = load()
		local g = { day = "x", list = { { type = Goals.indexOf("delivered"), progress = 0, done = false } } }
		local need = Goals.TYPES[Goals.indexOf("delivered")].count
		local paid = 0
		for _ = 1, need + 3 do
			paid += Goals.count(g, "delivered", 1)
		end
		assert(paid == Goals.TYPES[Goals.indexOf("delivered")].reward, `paid {paid}`)
		assert(g.list[1].done and g.list[1].progress == need)
	end,
	aStreakGoalMeasuresTheBestStreak = function()
		local Goals = load()
		local g = { day = "x", list = { { type = Goals.indexOf("streak"), progress = 0, done = false } } }
		Goals.count(g, "streak", 3)
		Goals.count(g, "streak", 1)
		assert(g.list[1].progress == 3, "a broken streak shouldn't lower progress")
		assert(Goals.count(g, "streak", 5) > 0 and g.list[1].done)
	end,
	otherEventsDontCount = function()
		local Goals = load()
		local g = { day = "x", list = { { type = Goals.indexOf("dogYard"), progress = 0, done = false } } }
		assert(Goals.count(g, "delivered", 1) == 0 and g.list[1].progress == 0)
	end,
}

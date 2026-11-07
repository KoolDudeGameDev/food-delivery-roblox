local function load()
	local Shared = script.Parent.Parent.Shared
	return require(Shared.WorldClock)
end

return {
	nightIsBeforeHalfPastSixAndAfterHalfPastFive = function()
		local W = load()
		assert(W.isNight(3) and W.isNight(6.4) and W.isNight(18) and W.isNight(23.9))
		assert(not W.isNight(6.6) and not W.isNight(12) and not W.isNight(17.4))
	end,
	eventBonusesFollowThePrototype = function()
		local W = load()
		local plain = { rain = false, festival = "" }
		assert(W.eventBonus(plain, true, "red") == 0)
		assert(math.abs(W.eventBonus({ rain = true, festival = "" }, false, "red") - 0.1) < 1e-9)
		assert(math.abs(W.eventBonus({ rain = false, festival = "fiesta" }, true, "red") - 0.25) < 1e-9, "fiesta food")
		assert(W.eventBonus({ rain = false, festival = "fiesta" }, false, "red") == 0, "fiesta is food only")
		assert(math.abs(W.eventBonus({ rain = false, festival = "undas" }, false, "cemetery") - 0.5) < 1e-9, "undas cemetery")
		assert(W.eventBonus({ rain = false, festival = "undas" }, false, "red") == 0, "undas is cemetery only")
	end,
	theClockRunsOneDayPerDayLength = function()
		local W, C = load(), require(script.Parent.Parent.Shared.Config)
		assert(math.abs(W.advance(12, C.DAY_LENGTH) - 12) < 1e-9, "a full day comes back round")
		assert(math.abs(W.advance(23, C.DAY_LENGTH / 12) - 1) < 1e-9, "two hours past 11 pm is 1 am")
	end,
}

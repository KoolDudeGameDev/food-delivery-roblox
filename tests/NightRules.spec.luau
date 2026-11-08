-- Night jobs and police (GDD Appendix A; prototype `contraband.js`, `police.js`, `orders.js`).
-- Money is involved, so every rule is pinned. Metres, seconds, pesos.
local function load()
	local Shared = script.Parent.Parent.Shared
	return require(Shared.NightRules), require(Shared.PoliceRules), require(Shared.Config), require(Shared.WorldLayout), require(Shared.Pay)
end

local function runner(id, x, z, wanted, hidden)
	return { id = id, x = x, z = z, wanted = wanted ~= false, hidden = hidden == true }
end

return {
	aDealerStandsFarAwayOffTheRoadAndOutOfYards = function()
		local Night, _, Config, WorldLayout = load()
		local rng = Random.new(3)
		for _ = 1, 50 do
			local spot = Night.spot(rng, 18, -11, Config.DEALER_MIN)
			local d = math.sqrt((spot.x - 18) ^ 2 + (spot.z + 11) ^ 2)
			assert(d >= Config.DEALER_MIN, `only {d} m away`)
			assert(not WorldLayout.onRoad(spot.x, spot.z, 3), "off the road")
			assert(not WorldLayout.yardAt(spot.x, spot.z), "not in a yard")
			assert(math.abs(spot.x) < WorldLayout.EDGE and math.abs(spot.z) < WorldLayout.EDGE, "on the map")
		end
	end,
	aShadyJobPaysForTheDistanceOnAShortClock = function()
		local Night, _, Config = load()
		local job = Night.job({ x = 0, z = 0 }, { x = 120, z = 50 }) -- 130 m apart
		assert(job.pay == 130 + 78, `pay {job.pay}`) -- ₱130 + 130 m x ₱0.60
		assert(math.abs(job.max - (10 + 130 / Config.RUN * 0.9)) < 1e-6, `max {job.max}`)
	end,
	aDealGetsBonusesButNoTipOrNightPay = function()
		local _, _, Config, _, Pay = load()
		local deal = Pay.deal(200, { homeBonus = 0.06, streak = 5, eventBonus = 0.1 })
		assert(deal.total == math.floor(200 * (1 + 0.06 + 5 * Config.STREAK_STEP + 0.1) + 0.5), `total {deal.total}`)
	end,
	theLoopGoesRoundTheRing = function()
		local _, Police = load()
		local x, z = Police.onLoop(10, 0)
		assert(x == -10 and z == -10, `start {x},{z}`)
		x, z = Police.onLoop(10, 10)
		assert(x == 0 and z == -10)
		x, z = Police.onLoop(10, 30)
		assert(x == 10 and z == 0, "down the second side")
		local x2, z2 = Police.onLoop(10, 80 + 10)
		assert(x2 == 0 and z2 == -10, "round again")
	end,
	patrolIgnoresYouUntilYouCarryAPackage = function()
		local _, Police, Config = load()
		local car = Police.new(36, 1, 0)
		local before = car.along
		local r = Police.step(car, { runner("a", car.x + 5, car.z, false) }, 1)
		assert(car.mode == "patrol" and r.spotted == nil, "not wanted")
		assert(math.abs(car.along - before - Config.POLICE_PATROL) < 1e-6, "drives the loop")
		r = Police.step(car, { runner("a", car.x + 5, car.z) }, 0.1)
		assert(car.mode == "chase" and r.spotted == "a", "wanted and in sight")
	end,
	aYardHidesYouAndDistanceKeepsYouUnseen = function()
		local _, Police, Config = load()
		local car = Police.new(36, 1, 0)
		local r = Police.step(car, { runner("a", car.x + 5, car.z, true, true) }, 0.1)
		assert(r.spotted == nil, "hidden in a yard")
		r = Police.step(car, { runner("a", car.x + Config.POLICE_SEE + 5, car.z) }, 0.1)
		assert(r.spotted == nil, "too far to see")
	end,
	theyChaseCatchAndArrest = function()
		local _, Police, Config = load()
		local car = Police.new(36, 1, 0)
		local x0, z0 = car.x, car.z
		Police.step(car, { runner("a", x0 + 20, z0) }, 0.1)
		Police.step(car, { runner("a", x0 + 20, z0) }, 0.5)
		assert(math.abs(car.x - x0 - Config.POLICE_CHASE * 0.5) < 1e-6, `chases at {Config.POLICE_CHASE} m/s`)
		local r = Police.step(car, { runner("a", car.x + 1, car.z) }, 0.01)
		assert(r.arrested == "a" and car.mode == "back", "caught")
	end,
	getFarEnoughForLongEnoughAndYouLoseThem = function()
		local _, Police, Config = load()
		local car = Police.new(36, 1, 0)
		Police.step(car, { runner("a", car.x + 10, car.z) }, 0.1)
		local far = runner("a", car.x + Config.POLICE_LOSE + 50, car.z)
		local r = Police.step(car, { far }, Config.POLICE_GIVE_UP / 2)
		assert(car.mode == "chase" and r.escaped == nil, "not yet")
		r = Police.step(car, { runner("a", car.x + Config.POLICE_LOSE + 50, car.z) }, Config.POLICE_GIVE_UP)
		assert(r.escaped == "a" and car.mode == "back", "lost them")
	end,
	afterwardsTheyDriveBackToTheirLoop = function()
		local _, Police = load()
		local car = Police.new(36, 1, 0)
		car.mode, car.x, car.z = "back", car.x + 15, car.z
		for _ = 1, 40 do
			Police.step(car, {}, 0.25)
		end
		assert(car.mode == "patrol", "back on patrol")
	end,
	theyNeverDriveIntoAYard = function()
		local _, Police, _, WorldLayout = load()
		local h = WorldLayout.byId.red
		local car = Police.new(36, 1, 0)
		car.mode, car.target = "chase", "a"
		car.x, car.z = h.yard.x0 - 1, (h.yard.z0 + h.yard.z1) / 2
		Police.step(car, { runner("a", (h.yard.x0 + h.yard.x1) / 2, car.z, true, true) }, 0.5)
		assert(not WorldLayout.yardAt(car.x, car.z), "stopped at the fence")
	end,
}

-- The living town (prototype `traffic.js`, `citizens.js`): jeepneys and tricycles on the ring
-- roads, walkers on their sidewalks. Each one's place is a pure function of the server clock, so
-- the server and every client agree without sending positions. Metres, seconds, pesos.
local function load()
	local Shared = script.Parent.Parent.Shared
	return require(Shared.TownRules), require(Shared.Config), require(Shared.WorldLayout)
end

local function onSquare(x, z, half)
	return math.abs(math.abs(x) - half) < 1e-6 or math.abs(math.abs(z) - half) < 1e-6
end

return {
	sixVehiclesDriveTheRingRoadsAtTheirOwnSpeed = function()
		local Town, Config, WorldLayout = load()
		assert(#Town.VEHICLES == 6)
		for i, v in Town.VEHICLES do
			local x, z = Town.vehicleAt(i, 100)
			assert(onSquare(x, z, v.half), `vehicle {i} is on its lane`)
			assert(v.half == WorldLayout.RING + Config.TRAFFIC_LANE or v.half == WorldLayout.OUTER + Config.TRAFFIC_LANE)
		end
		local a, b = Town.VEHICLES[1], nil
		local x0, z0 = Town.vehicleAt(1, 0)
		local x1, z1 = Town.vehicleAt(1, 0.5)
		b = math.sqrt((x1 - x0) ^ 2 + (z1 - z0) ^ 2)
		assert(math.abs(b - a.speed * 0.5) < 1e-6, `moves {b} m in half a second`)
	end,
	walkersKeepToTheSidewalksAndAgreeEverywhere = function()
		local Town, _, WorldLayout = load()
		assert(#Town.WALKERS == 12)
		for i, w in Town.WALKERS do
			local x, z = Town.walkerAt(i, 42)
			assert(onSquare(x, z, w.half), `walker {i} on the sidewalk`)
			assert(w.half == WorldLayout.RING - WorldLayout.ROAD_W / 2 - 0.75 or w.half == WorldLayout.OUTER - WorldLayout.ROAD_W / 2 - 0.75)
			local x2, z2 = Town.walkerAt(i, 42)
			assert(x == x2 and z == z2, "the same for everyone")
		end
	end,
	aThirdStayOutAfterDark = function()
		local Town = load()
		local out = 0
		for i in Town.WALKERS do
			assert(Town.walkerOut(i, false), "everyone's out by day")
			if Town.walkerOut(i, true) then
				out += 1
			end
		end
		assert(out == 4, `{out} night owls`)
	end,
	aVehicleBumpsYouUnlessYouJumpIt = function()
		local Town = load()
		local x, z = Town.vehicleAt(1, 10)
		local v = Town.VEHICLES[1]
		assert(Town.bumps(v, x, z, { x = x + v.reach - 0.2, z = z, feet = 0 }), "too close")
		assert(not Town.bumps(v, x, z, { x = x + v.reach + 0.2, z = z, feet = 0 }), "clear")
		assert(not Town.bumps(v, x, z, { x = x, z = z, feet = 2 }), "jumped it")
	end,
	runIntoAWalkerFastAndTheyFly = function()
		local Town, Config = load()
		local fast = { x = 0.5, z = 0, vx = Config.HIT_SPEED + 1, vz = 0, feet = 0 }
		assert(Town.hitsWalker(fast, 0, 0), "fast and close")
		assert(not Town.hitsWalker({ x = 0.5, z = 0, vx = Config.HIT_SPEED - 1, vz = 0, feet = 0 }, 0, 0), "too slow: they just block you")
		assert(not Town.hitsWalker({ x = 3, z = 0, vx = 20, vz = 0, feet = 0 }, 0, 0), "missed")
		assert(Town.fine(500) == Config.HIT_FINE and Town.fine(4) == 4, "never more than you have")
	end,
}

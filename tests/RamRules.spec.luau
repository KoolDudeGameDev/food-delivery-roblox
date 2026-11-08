-- Ride hits (Gregory, 2026-11-08): a fast rider who runs into someone sends them flying, now and
-- then minus an arm or a leg, and they pull themselves together where they land. Orders are never
-- touched. Distances in metres, speeds in m/s.
local function load()
	local Shared = script.Parent.Parent.Shared
	return require(Shared.RamRules), require(Shared.Config)
end

return {
	aFastRiderHitsSomeoneJustAhead = function()
		local Ram, Config = load()
		local v = Config.RAM_SPEED + 4
		assert(Ram.hits({ x = 0, z = 0, vx = 0, vz = v }, { x = 0, z = 1.5 }), "dead ahead")
		assert(Ram.hits({ x = 0, z = 0, vx = v, vz = 0 }, { x = 1.2, z = 0.6 }), "ahead and a little aside")
	end,
	tooSlowBehindOrTooFarIsNoHit = function()
		local Ram, Config = load()
		local fast = Config.RAM_SPEED + 4
		assert(not Ram.hits({ x = 0, z = 0, vx = 0, vz = Config.RAM_SPEED - 0.5 }, { x = 0, z = 1.5 }), "too slow")
		assert(not Ram.hits({ x = 0, z = 0, vx = 0, vz = fast }, { x = 0, z = -1.5 }), "behind")
		assert(not Ram.hits({ x = 0, z = 0, vx = 0, vz = fast }, { x = 0, z = Config.RAM_REACH + 0.5 }), "out of reach")
		assert(not Ram.hits({ x = 0, z = 0, vx = 0, vz = fast }, { x = 2, z = 0.1 }), "beside, not ahead")
	end,
	theFlingFollowsTheRideAndGrowsWithSpeed = function()
		local Ram, Config = load()
		local x, y, z = Ram.fling(0, Config.RAM_SPEED + 2)
		assert(math.abs(x) < 1e-6 and z > 0 and y > 0, "along the ride's way, and up")
		local _, y2, z2 = Ram.fling(0, 22) -- a motorcycle
		assert(z2 > z and y2 > y, "faster flies farther and higher")
		local fx, _, fz = Ram.fling(3, 4)
		assert(math.abs(fx / fz - 3 / 4) < 1e-6, "in the direction of travel")
	end,
	sometimesALimbOrTwoComeOffButNeverTheHead = function()
		local Ram, Config = load()
		local rng = Random.new(7)
		local rolls, withLimbs = 2000, 0
		for _ = 1, rolls do
			local off = Ram.detach(rng)
			assert(#off <= 2, `{#off} limbs`)
			local seen = {}
			for _, joint in off do
				assert(table.find(Ram.LIMBS, joint), `{joint} isn't a limb joint`)
				assert(not seen[joint], "each limb once")
				seen[joint] = true
			end
			if #off > 0 then
				withLimbs += 1
			end
		end
		local share = withLimbs / rolls
		assert(math.abs(share - Config.RAM_DETACH_CHANCE) < 0.05, `limbs came off {share} of the time`)
		assert(not table.find(Ram.LIMBS, "Neck"), "the head stays on: a broken neck kills a Roblox character")
	end,
}

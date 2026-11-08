-- Night jobs as pure rules (prototype `contraband.js`, `world.js` clearSpot): where a dealer or a
-- buyer stands, and what the job pays. NightJobService runs them per player. Metres and pesos.
local Config = require(script.Parent.Config)
local WorldLayout = require(script.Parent.WorldLayout)

local NightRules = {}

local trees: { { x: number, z: number } }? = nil

-- Somewhere open to stand: on the map, off the roads, out of yards, lots and buildings, clear of
-- trees and the very middle of town, and at least `near` from (fromX, fromZ) if it can be. The
-- prototype's clearSpot: 400 tries, else the farthest found.
function NightRules.spot(rng: Random, fromX: number, fromZ: number, near: number): { x: number, z: number }
	trees = trees or WorldLayout.trees()
	local prints = WorldLayout.footprints()
	local reach = WorldLayout.EDGE - 8
	local best, bestD = nil, -1
	for _ = 1, 400 do
		local x, z = rng:NextNumber(-reach, reach), rng:NextNumber(-reach, reach)
		if math.sqrt(x * x + z * z) < 20 or WorldLayout.onRoad(x, z, 3) then
			continue
		end
		local taken = false
		for _, p in prints do
			if x > p.x0 - 2 and x < p.x1 + 2 and z > p.z0 - 2 and z < p.z1 + 2 then
				taken = true
				break
			end
		end
		for _, t in trees :: { { x: number, z: number } } do
			if taken or (t.x - x) ^ 2 + (t.z - z) ^ 2 < 36 then
				taken = true
				break
			end
		end
		if taken then
			continue
		end
		local d = math.sqrt((x - fromX) ^ 2 + (z - fromZ) ^ 2)
		if d >= near then
			return { x = x, z = z }
		elseif d > bestD then
			best, bestD = { x = x, z = z }, d
		end
	end
	return best or { x = -30, z = 30 }
end

-- What the shady package pays, and how long the buyer waits (prototype `takePackage`)
function NightRules.job(dealer: { x: number, z: number }, buyer: { x: number, z: number }): { pay: number, max: number }
	local d = math.sqrt((buyer.x - dealer.x) ^ 2 + (buyer.z - dealer.z) ^ 2)
	return { pay = math.floor(Config.CONTRABAND_PAY + d * Config.CONTRABAND_FAR_PAY + 0.5), max = 10 + d / Config.RUN * 0.9 }
end

return NightRules

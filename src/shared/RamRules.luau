-- Ride hits as pure rules (Gregory, 2026-11-08): who a fast rider hits, how far they fly, and
-- which limbs come off. RamService runs them on the server; orders are never touched. Distances
-- in metres, speeds in m/s.
local Config = require(script.Parent.Config)

local RamRules = {}

-- The joints that may let go, by Motor6D name with spaces taken out (R15 and R6 share these).
-- Never the neck: a Roblox character with a broken neck dies.
RamRules.LIMBS = { "LeftShoulder", "RightShoulder", "LeftHip", "RightHip" }

local AHEAD = 0.5 -- cosine: within about 60 degrees of the way the rider is going

export type Mover = { x: number, z: number, vx: number, vz: number }
export type Spot = { x: number, z: number }

function RamRules.hits(rider: Mover, other: Spot): boolean
	local speed = math.sqrt(rider.vx ^ 2 + rider.vz ^ 2)
	if speed < Config.RAM_SPEED then
		return false
	end
	local dx, dz = other.x - rider.x, other.z - rider.z
	local d = math.sqrt(dx ^ 2 + dz ^ 2)
	if d > Config.RAM_REACH then
		return false
	end
	return d < 0.01 or (dx * rider.vx + dz * rider.vz) / (d * speed) > AHEAD
end

-- The velocity the one who's hit flies off with, in m/s: along the ride's way, and up
function RamRules.fling(vx: number, vz: number): (number, number, number)
	local speed = math.sqrt(vx ^ 2 + vz ^ 2)
	if speed < 1e-6 then
		return 0, Config.RAM_LIFT, 0
	end
	local push = speed * Config.RAM_PUSH
	return vx / speed * push, Config.RAM_LIFT + speed * Config.RAM_LIFT_PER, vz / speed * push
end

-- Now and then one limb comes off, or two
function RamRules.detach(rng: Random): { string }
	if rng:NextNumber() >= Config.RAM_DETACH_CHANCE then
		return {}
	end
	local pool = table.clone(RamRules.LIMBS)
	local off = {}
	for _ = 1, rng:NextInteger(1, 2) do
		table.insert(off, table.remove(pool, rng:NextInteger(1, #pool)) :: string)
	end
	return off
end

return RamRules

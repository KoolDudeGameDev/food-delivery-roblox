-- How a yard's chaser moves and bites: the prototype's dogs (deliver-a-parcel `src/dogs.js`),
-- as pure rules the server runs and the tests check. Positions are in metres. A dog chases
-- the nearest person inside its yard, never leaves the yard (that's what makes it give up at
-- the fence), and a high enough jump clears a small dog.
local Config = require(script.Parent.Config)

local ChaserRules = {}

export type Rect = { x0: number, x1: number, z0: number, z1: number }
export type Dog = {
	houseId: string,
	size: string,
	x: number,
	z: number,
	yaw: number,
	target: { x: number, z: number },
	yard: Rect,
	body: Rect?, -- the house, which a dog runs round rather than through
	home: { x: number, z: number },
	wait: number,
	cd: number,
	chasing: string?,
}
export type Runner = { id: string, x: number, z: number, feet: number }

local EDGE_GAP = 0.8 -- how close to the fence a dog gets

function ChaserRules.new(house, size: string?, body: Rect?): Dog
	local y = house.yard
	local hx, hz = (y.x0 + y.x1) / 2, (y.z0 + y.z1) / 2
	local home = { x = hx + (house.dx or 0) * 4, z = hz + (house.dz or 0) * 4 }
	return {
		houseId = house.id,
		size = size or "medium",
		x = home.x,
		z = home.z,
		yaw = 0,
		target = { x = home.x, z = home.z },
		yard = y,
		body = body,
		home = home,
		wait = 0,
		cd = 0,
		chasing = nil,
	}
end

local function inside(x: number, z: number, r: Rect): boolean
	return x > r.x0 and x < r.x1 and z > r.z0 and z < r.z1
end
ChaserRules.inside = inside

-- One step. Returns who it started chasing and who it bit this step, if anyone.
function ChaserRules.step(dog: Dog, runners: { Runner }, dt: number, rng: Random): { started: string?, bite: string? }
	local kind = Config.DOG_TYPES[dog.size]
	local result = {}

	local nearest, best = nil, math.huge
	for _, r in runners do
		if inside(r.x, r.z, dog.yard) then
			local d = (r.x - dog.x) ^ 2 + (r.z - dog.z) ^ 2
			if d < best then
				nearest, best = r, d
			end
		end
	end
	local was = dog.chasing
	dog.chasing = nearest and nearest.id
	if dog.chasing and dog.chasing ~= was then
		result.started = dog.chasing
	end
	dog.cd -= dt

	local speed = Config.DOG_WANDER
	if nearest then
		dog.target.x, dog.target.z = nearest.x, nearest.z
		speed = kind.speed
	else
		dog.wait -= dt
		if dog.wait < 0 then
			dog.wait = rng:NextNumber(1, 4)
			dog.target.x = dog.home.x + rng:NextNumber(-10, 10)
			dog.target.z = dog.home.z + rng:NextNumber(-10, 10)
		end
	end

	local dx, dz = dog.target.x - dog.x, dog.target.z - dog.z
	local dist = math.sqrt(dx * dx + dz * dz)
	if dist > 0.6 then
		local stepLen = math.min(dist, speed * dt)
		dog.x += dx / dist * stepLen
		dog.z += dz / dist * stepLen
		dog.yaw = math.atan2(dx, dz)
	end
	-- Round the house, not through it: out by the nearest side
	local b = dog.body
	if b and inside(dog.x, dog.z, b) then
		local pushes = { dog.x - b.x0, b.x1 - dog.x, dog.z - b.z0, b.z1 - dog.z }
		local least = math.min(table.unpack(pushes))
		if least == pushes[1] then
			dog.x = b.x0
		elseif least == pushes[2] then
			dog.x = b.x1
		elseif least == pushes[3] then
			dog.z = b.z0
		else
			dog.z = b.z1
		end
	end
	local y = dog.yard
	dog.x = math.clamp(dog.x, y.x0 + EDGE_GAP, y.x1 - EDGE_GAP)
	dog.z = math.clamp(dog.z, y.z0 + EDGE_GAP, y.z1 - EDGE_GAP)

	-- The bigger the dog, the higher you have to jump to clear it
	if nearest and dog.cd <= 0 then
		local reach = 1.1 + 0.55 * kind.scale
		local d = math.sqrt((nearest.x - dog.x) ^ 2 + (nearest.z - dog.z) ^ 2)
		if d < reach and nearest.feet < 0.5 + kind.scale * 0.25 then
			dog.cd = Config.BITE_GAP
			result.bite = nearest.id
		end
	end
	return result
end

return ChaserRules

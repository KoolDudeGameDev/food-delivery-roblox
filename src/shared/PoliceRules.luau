-- Police cars as pure rules (prototype `police.js`). Each car patrols a ring road and ignores you
-- until you carry a shady package. Then, if it sees you, it comes for you: get far enough away
-- for long enough, or into a yard (a car never drives in through a gate), and it gives up and
-- drives back to its loop. Catch you, and it's an arrest. PoliceService runs them. Metres, seconds.
local Config = require(script.Parent.Config)
local WorldLayout = require(script.Parent.WorldLayout)

local PoliceRules = {}

local BACK_SPEED = 1.5 -- times patrol speed, on the way back to the loop

-- A point on a square loop of half-size `half` round the middle of town, `along` metres from
-- its north-west corner, going clockwise; and the way it faces there.
function PoliceRules.onLoop(half: number, along: number): (number, number, number)
	local length = half * 8
	local a = (along % length + length) % length
	local side = math.floor(a / (half * 2))
	local t = a - side * half * 2 - half
	if side == 0 then
		return t, -half, math.pi / 2
	elseif side == 1 then
		return half, t, 0
	elseif side == 2 then
		return -t, half, -math.pi / 2
	end
	return -half, -t, math.pi
end

export type Car = {
	half: number,
	along: number,
	dir: number,
	x: number,
	z: number,
	yaw: number,
	mode: string, -- "patrol", "chase" or "back"
	target: string?,
	lost: number,
}

export type Runner = { id: string, x: number, z: number, wanted: boolean, hidden: boolean }

-- A car on the ring road of half-size `ring`, a lane in from its centreline. dir 1 or -1.
function PoliceRules.new(ring: number, dir: number, along: number): Car
	local half = ring - Config.POLICE_LANE
	local x, z, yaw = PoliceRules.onLoop(half, along)
	return { half = half, along = along, dir = dir, x = x, z = z, yaw = yaw, mode = "patrol", lost = 0 }
end

local function moveTowards(car: Car, tx: number, tz: number, speed: number, dt: number)
	local dx, dz = tx - car.x, tz - car.z
	local d = math.sqrt(dx * dx + dz * dz)
	if d < 1e-6 then
		return
	end
	local step = math.min(speed * dt, d)
	local nx, nz = car.x + dx / d * step, car.z + dz / d * step
	if not WorldLayout.yardAt(nx, nz) then
		car.x, car.z = nx, nz
	end
	car.yaw = math.atan2(dx, dz)
end

-- spotted: the car has just started after them; escaped: they got away; arrested: caught
function PoliceRules.step(car: Car, runners: { Runner }, dt: number): { spotted: string?, escaped: string?, arrested: string? }
	if car.mode == "patrol" then
		local seen, best = nil, Config.POLICE_SEE
		for _, r in runners do
			local d = math.sqrt((r.x - car.x) ^ 2 + (r.z - car.z) ^ 2)
			if r.wanted and not r.hidden and d < best then
				seen, best = r, d
			end
		end
		if seen then
			car.mode, car.target, car.lost = "chase", seen.id, 0
			return { spotted = seen.id }
		end
		car.along += car.dir * Config.POLICE_PATROL * dt
		local nx, nz = PoliceRules.onLoop(car.half, car.along)
		local ax, az = PoliceRules.onLoop(car.half, car.along + car.dir)
		car.x, car.z, car.yaw = nx, nz, math.atan2(ax - nx, az - nz)
		return {}
	elseif car.mode == "chase" then
		local target
		for _, r in runners do
			if r.id == car.target then
				target = r
			end
		end
		if not (target and target.wanted) then
			car.mode, car.target = "back", nil
			return {}
		end
		local d = math.sqrt((target.x - car.x) ^ 2 + (target.z - car.z) ^ 2)
		car.lost = if d > Config.POLICE_LOSE or target.hidden then car.lost + dt else 0
		if car.lost > Config.POLICE_GIVE_UP then
			car.mode, car.target = "back", nil
			return { escaped = target.id }
		end
		moveTowards(car, target.x, target.z, Config.POLICE_CHASE, dt)
		if math.sqrt((target.x - car.x) ^ 2 + (target.z - car.z) ^ 2) < Config.POLICE_CATCH then
			car.mode, car.target = "back", nil
			return { arrested = target.id }
		end
		return {}
	end
	-- Back to the loop, where it left it
	local lx, lz = PoliceRules.onLoop(car.half, car.along)
	moveTowards(car, lx, lz, Config.POLICE_PATROL * BACK_SPEED, dt)
	if math.sqrt((lx - car.x) ^ 2 + (lz - car.z) ^ 2) < 2 then
		car.mode = "patrol"
	end
	return {}
end

return PoliceRules

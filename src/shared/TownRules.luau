-- The living town as pure rules (prototype `traffic.js`, `citizens.js`): jeepneys and tricycles
-- driving the ring roads, and walkers on the inside sidewalks. Where each one is depends only on
-- the server clock (workspace:GetServerTimeNow()), and the list is made from a fixed seed, so the
-- server and every client agree on every position without sending any. TownService decides the
-- bumps and fines; client/Town draws them. Metres, seconds, pesos.
local Config = require(script.Parent.Config)
local PoliceRules = require(script.Parent.PoliceRules)
local WorldLayout = require(script.Parent.WorldLayout)

local TownRules = {}

local SOLID_R = 1 -- m: how close you bump into a walker
local onLoop = PoliceRules.onLoop

local function hexes(list: { string }): { Color3 }
	local out = {}
	for i, h in list do
		out[i] = Color3.fromHex(h)
	end
	return out
end

-- The prototype's vehicles: ring, speed (m/s), kind, paint, reach (m)
local VEHICLE_SPECS = {
	{ WorldLayout.OUTER, 9, "jeepney", "d6402b", 3 },
	{ WorldLayout.OUTER, 9, "jeepney", "2f7de0", 3 },
	{ WorldLayout.RING, 7, "jeepney", "3fae68", 3 },
	{ WorldLayout.OUTER, 8, "tricycle", "e8c23c", 2.2 },
	{ WorldLayout.RING, 7, "tricycle", "8d63d6", 2.2 },
	{ WorldLayout.OUTER, 8, "tricycle", "2fb5a8", 2.2 },
}

export type Vehicle = { half: number, speed: number, kind: string, paint: Color3, reach: number, start: number }
export type Walker = {
	half: number,
	start: number,
	dir: number,
	speed: number,
	scale: number,
	phase: number,
	nightOwl: boolean,
	shirt: Color3,
	skin: Color3,
	hair: Color3,
	pants: Color3,
}

local rng = Random.new(20261108) -- fixed: the same town everywhere

TownRules.VEHICLES = {} :: { Vehicle }
for i, spec in VEHICLE_SPECS do
	local half = spec[1] + Config.TRAFFIC_LANE
	table.insert(TownRules.VEHICLES, {
		half = half,
		speed = spec[2],
		kind = spec[3],
		paint = Color3.fromHex(spec[4]),
		reach = spec[5],
		start = half * 8 * ((i - 1) / 6 + rng:NextNumber() * 0.1),
	})
end

local SKINS = hexes({ "c99a6b", "b5835a", "d8ab7c", "9a6b45" })
local SHIRTS = hexes({ "e0524d", "4d8de0", "e8c23c", "3fae68", "f4f1ea", "e77fb3", "8d63d6", "f0883a" })
local PANTS = hexes({ "2b3a55", "3a3f48", "5a4636", "6c7a89" })
local HAIR = hexes({ "1c1712", "2b211a", "3a2c20" })

local function pick(list: { Color3 }): Color3
	return list[rng:NextInteger(1, #list)]
end

TownRules.WALKERS = {} :: { Walker }
for _, spec in { { WorldLayout.RING, 5 }, { WorldLayout.OUTER, 7 } } do
	local half = spec[1] - WorldLayout.ROAD_W / 2 - 0.75
	for i = 0, spec[2] - 1 do
		local n = #TownRules.WALKERS
		table.insert(TownRules.WALKERS, {
			half = half,
			start = (i + rng:NextNumber() * 0.8) / spec[2] * half * 8,
			dir = if rng:NextNumber() < 0.5 then 1 else -1,
			speed = 1.3 + rng:NextNumber() * 0.9,
			scale = 0.82 + rng:NextNumber() * 0.2,
			phase = rng:NextNumber() * 6,
			nightOwl = n % 3 == 0, -- a third stay out after dark
			shirt = pick(SHIRTS),
			skin = pick(SKINS),
			hair = pick(HAIR),
			pants = pick(PANTS),
		})
	end
end

-- Where a vehicle is at server time t, and which way it faces
function TownRules.vehicleAt(i: number, t: number): (number, number, number)
	local v = TownRules.VEHICLES[i]
	return onLoop(v.half, v.start + v.speed * t)
end

function TownRules.walkerAt(i: number, t: number): (number, number, number)
	local w = TownRules.WALKERS[i]
	local x, z, yaw = onLoop(w.half, w.start + w.dir * w.speed * t)
	return x, z, if w.dir < 0 then yaw + math.pi else yaw
end

-- Out on the street: everyone by day, the night owls after dark
function TownRules.walkerOut(i: number, night: boolean): boolean
	return not night or TownRules.WALKERS[i].nightOwl
end

-- A vehicle at (x, z) bumps a runner it reaches, unless they jump it
function TownRules.bumps(v: Vehicle, x: number, z: number, runner: { x: number, z: number, feet: number }): boolean
	return runner.feet < 1.6 and (runner.x - x) ^ 2 + (runner.z - z) ^ 2 < v.reach ^ 2
end

-- Running into a walker at HIT_SPEED or more sends them flying; slower, they just block you
function TownRules.hitsWalker(runner: { x: number, z: number, vx: number, vz: number, feet: number }, wx: number, wz: number): boolean
	local pace = math.sqrt(runner.vx ^ 2 + runner.vz ^ 2)
	return pace >= Config.HIT_SPEED and runner.feet < 1.2 and (runner.x - wx) ^ 2 + (runner.z - wz) ^ 2 < SOLID_R ^ 2
end

function TownRules.fine(cash: number): number
	return math.min(Config.HIT_FINE, cash)
end

return TownRules

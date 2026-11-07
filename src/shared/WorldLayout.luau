-- The town, in metres, centred on (0, 0) with north at -z. Laid out from the World Layout
-- Blueprint (design/World-Layout-Blueprint.md) at about 500 x 500 m:
--   * the town core is the prototype's: the warehouse hub, an inner and an outer ring road;
--   * customer houses split 7 inner / 7 outer residential / 7 rural (Blueprint §7.1);
--   * a rural dirt-road loop runs through the outskirts past the outer ring;
--   * the cemetery sits on the south-west edge, down a quiet side road (Blueprint §9.3);
--   * the north-south spoke runs on to the map edge, reserved for future districts (§14).
-- Pure data and geometry: the server builds from it, the client draws the map from it, and
-- the tests check it. Ids are stable, because saves use them.
local Config = require(script.Parent.Config)

local WorldLayout = {}

WorldLayout.EDGE = 250 -- half the map
WorldLayout.RING = 36
WorldLayout.OUTER = 118
WorldLayout.RURAL = 205
WorldLayout.ROAD_W = 9
WorldLayout.DIRT_W = 7
WorldLayout.GATE = 3.5 -- half the gate gap
WorldLayout.ROAD_REACH = 23 -- how far a house's path runs to meet the road

local EDGE, RING, OUTER, RURAL = WorldLayout.EDGE, WorldLayout.RING, WorldLayout.OUTER, WorldLayout.RURAL
local ROAD_W, DIRT_W = WorldLayout.ROAD_W, WorldLayout.DIRT_W

export type Road = { w: number, d: number, x: number, z: number, dirt: boolean?, name: string }

local function road(name, w, d, x, z, dirt): Road
	return { name = name, w = w, d = d, x = x, z = z, dirt = dirt }
end

WorldLayout.ROADS = {
	road("InnerN", RING * 2 + ROAD_W, ROAD_W, 0, -RING),
	road("InnerS", RING * 2 + ROAD_W, ROAD_W, 0, RING),
	road("InnerW", ROAD_W, RING * 2 + ROAD_W, -RING, 0),
	road("InnerE", ROAD_W, RING * 2 + ROAD_W, RING, 0),
	road("OuterN", OUTER * 2 + ROAD_W, ROAD_W, 0, -OUTER),
	road("OuterS", OUTER * 2 + ROAD_W, ROAD_W, 0, OUTER),
	road("OuterW", ROAD_W, OUTER * 2 + ROAD_W, -OUTER, 0),
	road("OuterE", ROAD_W, OUTER * 2 + ROAD_W, OUTER, 0),
	-- The spokes: north-south runs to the map edge (expansion corridors), east-west to the loop
	road("SpokeNS", ROAD_W, EDGE * 2, 0, 0),
	road("SpokeEW", RURAL * 2, ROAD_W, 0, 0),
	-- The rural loop, dirt
	road("RuralN", RURAL * 2 + DIRT_W, DIRT_W, 0, -RURAL, true),
	road("RuralS", RURAL * 2 + DIRT_W, DIRT_W, 0, RURAL, true),
	road("RuralW", DIRT_W, RURAL * 2 + DIRT_W, -RURAL, 0, true),
	road("RuralE", DIRT_W, RURAL * 2 + DIRT_W, RURAL, 0, true),
	-- The cemetery's side road
	road("CemeteryLane", DIRT_W, 30, -120, RURAL + 18, true),
}

-- Where the reserved corridors meet the map edge (Blueprint §14): closed for now.
WorldLayout.EXPANSION = {
	{ id = "north", x = 0, z = -EDGE + 4, label = "FUTURE DISTRICT" },
	{ id = "south", x = 0, z = EDGE - 4, label = "FUTURE DISTRICT" },
}

-- The warehouse hub sits in its own paved yard in the north-east block of the crossroads, so
-- both spokes run straight through the middle of town (Blueprint §17, question 1: offset).
WorldLayout.HUB_YARD = { x = 18, z = -18, w = 24, d = 24 }
WorldLayout.HUB = { x = 18, z = -11 } -- the order board, at the front of the yard
WorldLayout.WAREHOUSE = { x = 18, z = -24, w = 22, d = 10 } -- open to the south
WorldLayout.SHOPS = {
	dealer = { x = -19, z = 19, label = "DEALER", color = Color3.fromHex("3f7fd6") },
	mechanic = { x = 19, z = 19, label = "MECHANIC", color = Color3.fromHex("6a6f78") },
}

-- How big a customer's house and yard are; yardU/yardV are half-widths across and deep.
WorldLayout.HOUSE_SIZES = {
	small = { w = 10, d = 7.5, h = 5, floors = 1, yardU = 10.5, yardV = 11 },
	medium = { w = 14, d = 9, h = 6, floors = 1, yardU = 13, yardV = 13 },
	large = { w = 18, d = 10, h = 5.5, floors = 2, yardU = 16, yardV = 15 },
}

export type House = {
	id: string,
	name: string,
	color: Color3,
	x: number,
	z: number,
	dx: number, -- the way the gate faces
	dz: number,
	dog: string?,
	size: string,
	ring: string, -- "inner", "outer" or "rural" (Blueprint §7.1)
	district: string,
	place: string?,
	parcelOnly: boolean?,
	weight: number?,
	extraTime: number?,
	risk: number?,
	nightRisk: number?,
	step: { x: number, z: number }?,
	yard: { x0: number, x1: number, z0: number, z1: number }?,
}

local function house(ring, name, hex, x, z, dx, dz, dog, size): House
	return {
		id = string.lower(name),
		name = name,
		color = Color3.fromHex(hex),
		x = x,
		z = z,
		dx = dx,
		dz = dz,
		dog = dog,
		size = size or "medium",
		ring = ring,
		district = "",
	}
end

WorldLayout.HOUSES = {
	-- Inner residential, around the inner ring: short, beginner-friendly routes, small chasers
	house("inner", "Red", "e0524d", -30, -62, 0, 1, "chihuahua"),
	house("inner", "Blue", "4d8de0", 30, -62, 0, 1, nil, "large"),
	house("inner", "Yellow", "e8c23c", 62, -30, -1, 0, "beagle"),
	house("inner", "Green", "3fae68", 30, 62, 0, -1, nil, "large"),
	house("inner", "Pink", "e77fb3", -30, 62, 0, -1, "shihTzu", "small"),
	house("inner", "Purple", "8d63d6", -62, 30, 1, 0, nil),
	house("inner", "Teal", "2fb5a8", -62, -30, 1, 0, "pomeranian", "small"),
	-- Outer residential, on both sides of the outer ring: moderate routes, more varied gates
	house("outer", "Coral", "f0776a", -30, -96, 0, -1, "cat", "small"),
	house("outer", "Lime", "9ccc3c", 96, -30, 1, 0, "germanShepherd", "large"),
	house("outer", "Navy", "3a5a9a", 30, 96, 0, 1, "aspin"),
	house("outer", "Peach", "f4b183", -96, 30, -1, 0, nil, "small"),
	house("outer", "Gold", "d6a520", 143, -70, -1, 0, "greatDane", "large"),
	house("outer", "Mint", "7fd8b0", 143, 70, -1, 0, "cat"),
	house("outer", "Orange", "f0883a", -143, -70, 1, 0, nil),
	-- Rural outskirts, on the dirt loop: long routes, isolated yards
	house("rural", "Rose", "d85a7f", 70, 182, 0, 1, "dachshund", "small"),
	house("rural", "Sky", "6cc6ff", -70, 182, 0, 1, "husky", "large"),
	house("rural", "Lilac", "b79ae0", -182, 70, -1, 0, "goose", "small"),
	house("rural", "Brown", "9a6a45", -182, -70, -1, 0, "saintBernard", "large"),
	house("rural", "Indigo", "5560c8", -70, -182, 0, -1, "aspin"),
	house("rural", "Cream", "eadfba", 70, -182, 0, -1, "goose"),
	house("rural", "Slate", "6c7a89", 182, 70, 1, 0, "mastiff", "large"),
}

-- The cemetery: the prototype's graveyard (laid out from x 68, z 70), moved to the south-west
-- edge. The builder shifts every prototype coordinate by (ox, oz). The gate is on the east wall.
local CEM = { x0 = -168, z0 = 212, w = 40, d = 36 }
CEM.x1, CEM.z1 = CEM.x0 + CEM.w, CEM.z0 + CEM.d
CEM.ox, CEM.oz = CEM.x0 - 68, CEM.z0 - 70
CEM.gateGap = 3.5
WorldLayout.CEMETERY = CEM
table.insert(WorldLayout.HOUSES, {
	id = "cemetery",
	name = "Cemetery",
	place = "the cemetery",
	color = Color3.fromHex("8fa08a"),
	x = (CEM.x0 + CEM.x1) / 2,
	z = (CEM.z0 + CEM.z1) / 2,
	dx = 1,
	dz = 0,
	size = "medium",
	ring = "rural",
	district = "CemeteryDistrict",
	parcelOnly = true,
	weight = 3,
	extraTime = 10,
	risk = 1,
	nightRisk = 1,
	step = { x = 74.5 + CEM.ox, z = 78.6 + CEM.oz },
	yard = { x0 = CEM.x0, x1 = CEM.x1, z0 = CEM.z0, z1 = CEM.z1 },
})

-- Seven home sites spread round the town, one per player, each facing the middle of the map.
WorldLayout.LOTS = {
	{ id = "lot1", x = 86, z = -75, dx = -1, dz = 0 },
	{ id = "lot2", x = 127, z = 147, dx = 0, dz = -1 },
	{ id = "lot3", x = -93, z = -84, dx = 1, dz = 0 },
	{ id = "lot4", x = 116, z = -148, dx = 0, dz = 1 },
	{ id = "lot5", x = -127, z = -148, dx = 0, dz = 1 },
	{ id = "lot6", x = -112, z = 142, dx = 0, dz = -1 },
	{ id = "lot7", x = -155, z = -30, dx = 1, dz = 0 },
}

-- Landmarks and scenery, as footprints { name, x, z, w, d, district } plus build details.
WorldLayout.TOWERS = {
	{ x = 62, z = -62, w = 16, d = 16, floors = 5, color = "c9ccd4" },
	{ x = -62, z = -62, w = 14, d = 18, floors = 4, color = "e2c9a8" },
	{ x = 62, z = 62, w = 18, d = 14, floors = 3, color = "a9c4d8" },
	{ x = -62, z = 62, w = 16, d = 16, floors = 4, color = "d8b4a8" },
}
WorldLayout.SARI_SARI = { { x = 96, z = 30, face = 1 }, { x = -96, z = -30, face = -1 } }
WorldLayout.BARANGAY = { x = 64, z = 30, w = 12, d = 16 } -- faces west, to the inner ring
WorldLayout.COURT = { x = 30, z = -96 }
WorldLayout.POND = { x = -30, z = 96 }
WorldLayout.PICKLEBALL = { x = -92, z = 90 }

-- The palengke: market stalls on both sidewalks of the north spoke, with bunting overhead.
WorldLayout.MARKET = { z0 = -108, z1 = -48, step = 10, x = 9, w = 4, d = 5 }

-- The Blueprint's districts (§3.1). Houses take theirs from their ring and side of town.
function WorldLayout.districtAt(x: number, z: number): string
	if math.max(math.abs(x), math.abs(z)) > OUTER + 6 then
		return "RuralOutskirts"
	elseif math.max(math.abs(x), math.abs(z)) < RING - ROAD_W then
		return "LogisticsDistrict"
	end
	return if x >= 0 then "ResidentialEast" else "ResidentialWest"
end

-- A house's local frame: v points from the house to the road, u runs across the yard.
local function frame(h: House)
	local px, pz = h.dz, -h.dx
	return function(u: number, v: number): (number, number)
		return h.x + h.dx * v + px * u, h.z + h.dz * v + pz * u
	end
end
WorldLayout.frame = frame

-- Where the house body sits and where the doorstep is, in the house's frame.
function WorldLayout.houseGeometry(h: House)
	local size = WorldLayout.HOUSE_SIZES[h.size]
	local back = -size.yardV + 1.5
	local doorV = back + size.d + 0.1
	return {
		size = size,
		bodyV = back + size.d / 2,
		doorV = doorV,
		stepV = doorV + 1.6,
	}
end

for _, h in WorldLayout.HOUSES do
	if not h.yard then
		local size = WorldLayout.HOUSE_SIZES[h.size]
		local halfX = math.abs(h.dz) * size.yardU + math.abs(h.dx) * size.yardV
		local halfZ = math.abs(h.dx) * size.yardU + math.abs(h.dz) * size.yardV
		h.yard = { x0 = h.x - halfX, x1 = h.x + halfX, z0 = h.z - halfZ, z1 = h.z + halfZ }
	end
	if not h.step then
		local at = frame(h)
		local x, z = at(0, WorldLayout.houseGeometry(h).stepV)
		h.step = { x = x, z = z }
	end
	if h.district == "" then
		h.district = if h.ring == "rural" then "RuralOutskirts" else (if h.x >= 0 then "ResidentialEast" else "ResidentialWest")
	end
end
for _, lot in WorldLayout.LOTS do
	lot.step = { x = lot.x + lot.dx * 10, z = lot.z + lot.dz * 10 }
	lot.w = if lot.dx ~= 0 then 28 else 40
	lot.d = if lot.dx ~= 0 then 40 else 28
	lot.district = WorldLayout.districtAt(lot.x, lot.z)
end

WorldLayout.byId = {}
for _, h in WorldLayout.HOUSES do
	WorldLayout.byId[h.id] = h
end

export type Footprint = { name: string, x0: number, x1: number, z0: number, z1: number, district: string, kind: string }

local function rect(name, kind, district, x, z, w, d): Footprint
	return { name = name, kind = kind, district = district, x0 = x - w / 2, x1 = x + w / 2, z0 = z - d / 2, z1 = z + d / 2 }
end

-- Everything that takes up ground, as rectangles: for overlap tests, trees and the map.
function WorldLayout.footprints(): { Footprint }
	local list = {}
	for _, h in WorldLayout.HOUSES do
		local y = h.yard
		table.insert(list, { name = h.id, kind = "yard", district = h.district, x0 = y.x0, x1 = y.x1, z0 = y.z0, z1 = y.z1 })
	end
	for _, lot in WorldLayout.LOTS do
		table.insert(list, rect(lot.id, "lot", lot.district, lot.x, lot.z, lot.w, lot.d))
	end
	for i, t in WorldLayout.TOWERS do
		table.insert(list, rect(`Tower{i}`, "building", "TownCenter", t.x, t.z, t.w, t.d))
	end
	for i, s in WorldLayout.SARI_SARI do
		table.insert(list, rect(`SariSari{i}`, "building", "TownCenter", s.x, s.z, 9, 14))
	end
	local b = WorldLayout.BARANGAY
	table.insert(list, rect("Barangay", "building", "CommunityDistrict", b.x, b.z, b.w, b.d))
	for key, s in WorldLayout.SHOPS do
		table.insert(list, rect(key, "building", "LogisticsDistrict", s.x, s.z, 15, 10))
	end
	local w = WorldLayout.WAREHOUSE
	table.insert(list, rect("Warehouse", "building", "LogisticsDistrict", w.x, w.z, w.w, w.d))
	-- The paved hub yard holds the warehouse, so it's the one footprint others may sit inside
	local y = WorldLayout.HUB_YARD
	table.insert(list, rect("HubYard", "hub", "LogisticsDistrict", y.x, y.z, y.w, y.d))
	table.insert(list, rect("Court", "ground", "CommunityDistrict", WorldLayout.COURT.x, WorldLayout.COURT.z, 24, 14))
	table.insert(list, rect("Pond", "ground", "CommunityDistrict", WorldLayout.POND.x, WorldLayout.POND.z, 26, 18))
	table.insert(list, rect("Pickleball", "ground", "CommunityDistrict", WorldLayout.PICKLEBALL.x, WorldLayout.PICKLEBALL.z, 14, 26))
	local m = WorldLayout.MARKET
	for z = m.z0, m.z1, m.step do
		for _, s in { -1, 1 } do
			table.insert(list, rect(`Stall{s}_{z}`, "stall", "TownCenter", s * m.x, z, m.w, m.d))
		end
	end
	return list
end

local function inside(x, z, r: Footprint, margin)
	return x > r.x0 - margin and x < r.x1 + margin and z > r.z0 - margin and z < r.z1 + margin
end

function WorldLayout.onRoad(x: number, z: number, margin: number): boolean
	for _, r in WorldLayout.ROADS do
		if math.abs(x - r.x) < r.w / 2 + margin and math.abs(z - r.z) < r.d / 2 + margin then
			return true
		end
	end
	return false
end

-- True if a point is on a road or within margin of anything built.
function WorldLayout.blocked(x: number, z: number, margin: number, footprints: { Footprint }?): boolean
	if WorldLayout.onRoad(x, z, margin) then
		return true
	end
	for _, r in footprints or WorldLayout.footprints() do
		if inside(x, z, r, margin) then
			return true
		end
	end
	return false
end

-- Trees in the open ground, seeded so the town is the same every time.
function WorldLayout.trees(): { { x: number, z: number, s: number } }
	local rng = Random.new(20261107)
	local prints, list = WorldLayout.footprints(), {}
	for _ = 1, 4000 do
		if #list >= 140 then
			break
		end
		local x, z = rng:NextNumber(-EDGE + 6, EDGE - 6), rng:NextNumber(-EDGE + 6, EDGE - 6)
		-- Thicker out in the country than in town
		local rural = math.max(math.abs(x), math.abs(z)) > OUTER + 6
		if (rural or rng:NextNumber() < 0.25) and not WorldLayout.blocked(x, z, 4, prints) then
			local clear = true
			for _, t in list do
				if (t.x - x) ^ 2 + (t.z - z) ^ 2 < 36 then
					clear = false
					break
				end
			end
			if clear then
				table.insert(list, { x = x, z = z, s = rng:NextNumber(0.85, 1.45) })
			end
		end
	end
	return list
end

-- Where a ride parks for a delivery place: just outside its gate, on the road side.
function WorldLayout.parkingSpot(h: House): { x: number, z: number }
	if h.id == "cemetery" then
		return { x = CEM.x1 + 3, z = (CEM.z0 + CEM.z1) / 2 }
	end
	local x, z = frame(h)(WorldLayout.GATE + 2, WorldLayout.HOUSE_SIZES[h.size].yardV + 3)
	return { x = x, z = z }
end

-- The delivery place whose yard a point is in, if any.
function WorldLayout.yardAt(x: number, z: number): House?
	for _, h in WorldLayout.HOUSES do
		local y = h.yard
		if x > y.x0 and x < y.x1 and z > y.z0 and z < y.z1 then
			return h
		end
	end
	return nil
end

-- A point in metres as a world position in studs.
function WorldLayout.studs(x: number, z: number, y: number?): Vector3
	local s = Config.STUDS
	return Vector3.new(x * s, (y or 0) * s, z * s)
end

return WorldLayout

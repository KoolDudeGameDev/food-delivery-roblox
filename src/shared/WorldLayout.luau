-- The town, in metres, centred on (0, 0) with north at -z. Laid out from the World Layout
-- Blueprint (design/World-Layout-Blueprint.md) at about 500 x 500 m:
--   * the town core is the prototype's: the warehouse hub, an inner and an outer ring road;
--   * customer houses split 7 inner / 7 outer residential / 7 rural (Blueprint §7.1);
--   * a rural dirt-road loop runs through the outskirts past the outer ring;
--   * the cemetery sits on the south-west edge, down a quiet side road (Blueprint §9.3);
--   * connectors join the rings at staggered T-junctions, never four-way crossings (§5.2);
--   * the Community District sits together in the middle-west (§3.1 E, §4.1);
--   * corridors run on to the map edge, reserved for future districts (§14).
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

export type Road = { w: number, d: number, x: number, z: number, dirt: boolean?, foot: boolean?, name: string }

local function road(name, w, d, x, z, dirt): Road
	return { name = name, w = w, d = d, x = x, z = z, dirt = dirt }
end

-- A straight connector between two points on one axis; its ends sit on the centrelines of the
-- roads it joins, so every junction is a T (Blueprint §5.2).
local function link(name, x0, z0, x1, z1, width, dirt): Road
	local w = if z0 == z1 then math.abs(x1 - x0) else width
	local d = if x0 == x1 then math.abs(z1 - z0) else width
	return road(name, w, d, (x0 + x1) / 2, (z0 + z1) / 2, dirt)
end

WorldLayout.FOOT_W = 2.5

WorldLayout.ROADS = {
	-- The two rings (their corners are bends)
	road("InnerN", RING * 2 + ROAD_W, ROAD_W, 0, -RING),
	road("InnerS", RING * 2 + ROAD_W, ROAD_W, 0, RING),
	road("InnerW", ROAD_W, RING * 2 + ROAD_W, -RING, 0),
	road("InnerE", ROAD_W, RING * 2 + ROAD_W, RING, 0),
	road("OuterN", OUTER * 2 + ROAD_W, ROAD_W, 0, -OUTER),
	road("OuterS", OUTER * 2 + ROAD_W, ROAD_W, 0, OUTER),
	road("OuterW", ROAD_W, OUTER * 2 + ROAD_W, -OUTER, 0),
	road("OuterE", ROAD_W, OUTER * 2 + ROAD_W, OUTER, 0),
	-- Connectors, staggered so no road runs straight through another: T-junctions only
	link("Centre", -RING, 0, RING, 0, ROAD_W), -- through the middle of town, past the hub
	link("Palengke", 0, -OUTER, 0, -RING, ROAD_W), -- the market street
	link("SouthLink", 0, RING, 0, OUTER, ROAD_W),
	link("WestLink", -OUTER, 20, -RING, 20, ROAD_W), -- through the Community District
	link("EastLink", RING, 20, OUTER, 20, ROAD_W),
	-- The rural loop and its tracks, dirt
	road("RuralN", RURAL * 2 + DIRT_W, DIRT_W, 0, -RURAL, true),
	road("RuralS", RURAL * 2 + DIRT_W, DIRT_W, 0, RURAL, true),
	road("RuralW", DIRT_W, RURAL * 2 + DIRT_W, -RURAL, 0, true),
	road("RuralE", DIRT_W, RURAL * 2 + DIRT_W, RURAL, 0, true),
	link("TrackN", -40, -RURAL, -40, -OUTER, DIRT_W, true),
	link("TrackS", 40, OUTER, 40, RURAL, DIRT_W, true),
	link("TrackW", -RURAL, 50, -OUTER, 50, DIRT_W, true),
	link("TrackE", OUTER, -30, RURAL, -30, DIRT_W, true),
	link("CemeteryLane", -120, RURAL, -120, RURAL + 33, DIRT_W, true),
	-- Reserved corridors to future districts (Blueprint §14), closed at the edge
	link("CorridorN", 0, -EDGE, 0, -RURAL, ROAD_W),
	link("CorridorS", 0, RURAL, 0, EDGE, ROAD_W),
	link("FutureLink", -EDGE, 150, -RURAL, 150, ROAD_W),
}

-- Footpath shortcuts between the rings, on foot (Blueprint §5.1). Never needed for a delivery.
for _, f in { { "FootpathNW", -48, -OUTER, -48, -RING }, { "FootpathSE", 50, RING, 50, OUTER } } do
	local path = link(f[1], f[2], f[3], f[4], f[5], WorldLayout.FOOT_W, true)
	path.foot = true
	table.insert(WorldLayout.ROADS, path)
end

-- Where the reserved corridors meet the map edge: closed for now. yaw turns the barrier across.
WorldLayout.EXPANSION = {
	{ id = "north", x = 0, z = -EDGE + 4, yaw = 0, label = "FUTURE DISTRICT" },
	{ id = "south", x = 0, z = EDGE - 4, yaw = 0, label = "FUTURE DISTRICT" },
	{ id = "southwest", x = -EDGE + 4, z = 150, yaw = math.pi / 2, label = "FUTURE LINK" },
}

-- Direction signs at the main junctions (Blueprint §5.2 rule 5). yaw is the way the sign faces.
WorldLayout.SIGNS = {
	{ x = -14, z = -44, yaw = 0, text = "PALENGKE ↑" },
	{ x = -3, z = -9, yaw = 0, text = "WAREHOUSE →" },
	{ x = 0, z = 9, yaw = math.pi, text = "← DEALER   MECHANIC →" },
	{ x = -129, z = 199, yaw = math.pi, text = "CEMETERY ↓" },
	{ x = -82, z = 13, yaw = 0, text = "COMMUNITY" },
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
	-- The Toolbox houses are scaled to fill w (WorldBuilder), and d is their depth at that scale
	small = { w = 10, d = 11.3, h = 5, floors = 1, yardU = 10.5, yardV = 11 },
	medium = { w = 14, d = 14.8, h = 6, floors = 1, yardU = 13, yardV = 13 },
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
	house("inner", "Purple", "8d63d6", -18, -19, 0, 1, nil, "small"), -- inside the inner ring, on the centre road
	house("inner", "Teal", "2fb5a8", -62, -30, 1, 0, "pomeranian", "small"),
	-- Outer residential, on both sides of the outer ring: moderate routes, more varied gates
	house("outer", "Coral", "f0776a", -30, -96, 0, -1, "cat", "small"),
	house("outer", "Lime", "9ccc3c", 96, -30, 1, 0, "germanShepherd", "large"),
	house("outer", "Navy", "3a5a9a", 30, 96, 0, 1, "aspin"),
	house("outer", "Peach", "f4b183", -30, 96, 0, 1, nil, "small"),
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
-- Sari-sari stores, facing (dx, dz) onto the road; 14 m across the front, 9 m deep.
WorldLayout.SARI_SARI = { { x = 96, z = 38, dx = 1, dz = 0 }, { x = -30, z = 132, dx = 0, dz = -1 } }
-- The Community District (Blueprint §3.1 E, §4.1 middle-west): the court and pond north of the
-- West Link, the barangay hall and pickleball south of it.
WorldLayout.COURT = { x = -95, z = -30, w = 14, d = 24 }
WorldLayout.POND = { x = -95, z = 0, w = 26, d = 18 }
WorldLayout.BARANGAY = { x = -60, z = 38, w = 12, d = 16 } -- faces north, to the West Link
WorldLayout.PICKLEBALL = { x = -92, z = 40, w = 26, d = 14 }

-- The palengke: market stalls on both sidewalks of the north spoke, with bunting overhead.
WorldLayout.MARKET = { z0 = -108, z1 = -48, step = 10, x = 9, w = 4, d = 5 }

-- Roadside props (Blueprint §10.1): waiting sheds at junctions, benches and bins where people
-- gather. yaw is the way the prop faces; w and d are its footprint before turning.
WorldLayout.PROPS = {
	{ kind = "shed", x = 12, z = -127.5, w = 4, d = 2.5, yaw = 0 },
	{ kind = "shed", x = -12, z = 127, w = 4, d = 2.5, yaw = math.pi },
	{ kind = "shed", x = 126.75, z = 30, w = 4, d = 2.5, yaw = -math.pi / 2 },
	{ kind = "bench", x = -15, z = -100, w = 2, d = 0.8, yaw = math.pi / 2 },
	{ kind = "bin", x = -15, z = -103.5, w = 0.8, d = 0.8, yaw = 0 },
	{ kind = "bench", x = -80, z = 11, w = 2, d = 0.8, yaw = 0 },
	{ kind = "bin", x = -77, z = 11, w = 0.8, d = 0.8, yaw = 0 },
	{ kind = "bench", x = 25, z = -8.5, w = 2, d = 0.8, yaw = 0 },
	{ kind = "bin", x = 28, z = -8.5, w = 0.8, d = 0.8, yaw = 0 },
}

-- Crop fields in the rural outskirts (Blueprint §3.1 F): rows of green on brown earth.
WorldLayout.FIELDS = {
	{ x = 170, z = 135, w = 26, d = 20 },
	{ x = -170, z = -150, w = 26, d = 20 },
	{ x = 165, z = -160, w = 24, d = 20 },
}

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
		local w, d = if s.dx ~= 0 then 9 else 14, if s.dx ~= 0 then 14 else 9
		table.insert(list, rect(`SariSari{i}`, "building", "TownCenter", s.x, s.z, w, d))
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
	for _, c in { { "Court", WorldLayout.COURT }, { "Pond", WorldLayout.POND }, { "Pickleball", WorldLayout.PICKLEBALL } } do
		table.insert(list, rect(c[1], "ground", "CommunityDistrict", c[2].x, c[2].z, c[2].w, c[2].d))
	end
	for i, g in WorldLayout.SIGNS do
		table.insert(list, rect(`Sign{i}`, "prop", "", g.x, g.z, 1, 1))
	end
	for i, p in WorldLayout.PROPS do
		local size = math.max(p.w, p.d) -- turned either way, it fits in this square
		table.insert(list, rect(`{p.kind}{i}`, "prop", "", p.x, p.z, size, size))
	end
	for i, f in WorldLayout.FIELDS do
		table.insert(list, rect(`Field{i}`, "ground", "RuralOutskirts", f.x, f.z, f.w, f.d))
	end
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

-- Trees and shrubs in the open ground, seeded so the town is the same every time: palms in town,
-- broadleaf trees out in the country (Blueprint §10.1), and shrubs round the residential streets.
function WorldLayout.trees(): { { x: number, z: number, s: number, kind: string } }
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
				table.insert(list, { x = x, z = z, s = rng:NextNumber(0.85, 1.45), kind = if rural then "broadleaf" else "palm" })
			end
		end
	end
	local shrubs = 0
	for _ = 1, 3000 do
		if shrubs >= 70 then
			break
		end
		local x, z = rng:NextNumber(-OUTER, OUTER), rng:NextNumber(-OUTER, OUTER)
		if not WorldLayout.blocked(x, z, 3, prints) then
			local clear = true
			for _, t in list do
				if (t.x - x) ^ 2 + (t.z - z) ^ 2 < 16 then
					clear = false
					break
				end
			end
			if clear then
				shrubs += 1
				table.insert(list, { x = x, z = z, s = rng:NextNumber(0.8, 1.2), kind = "shrub" })
			end
		end
	end
	return list
end

-- Utility poles just outside the outer ring, in runs along each side, wired pole to pole
-- (Blueprint §10.1). A spot on a junction or anything built is skipped, which breaks the run.
function WorldLayout.poles(): { { { x: number, z: number } } }
	local prints, runs = WorldLayout.footprints(), {}
	local off = OUTER + 8
	for _, side in { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } } do
		local run = {}
		for a = -OUTER, OUTER, 30 do
			local x = if side[1] ~= 0 then side[1] * off else a
			local z = if side[2] ~= 0 then side[2] * off else a
			if WorldLayout.blocked(x, z, 0.8, prints) then
				if #run > 1 then
					table.insert(runs, run)
				end
				run = {}
			else
				table.insert(run, { x = x, z = z })
			end
		end
		if #run > 1 then
			table.insert(runs, run)
		end
	end
	return runs
end

-- Street lamps along both rings (the prototype's spacing), on the sidewalk, with an arm over
-- the road (ox, oz). Spots that land on a junction or anything built are skipped.
function WorldLayout.lamps(): { { x: number, z: number, ox: number, oz: number } }
	local list, prints = {}, WorldLayout.footprints()
	local side = ROAD_W / 2 + 0.9
	for _, ring in { RING, OUTER } do
		local step = if ring == RING then 24 else 42
		for a = -ring + 12, ring - 6, step do
			for _, s in { -1, 1 } do
				for _, spot in { { a, s * (ring + side), 0, -s }, { s * (ring + side), a, -s, 0 } } do
					local x, z = spot[1], spot[2]
					if not WorldLayout.onRoad(x, z, 0.3) and not WorldLayout.blocked(x, z, 0.5, prints) then
						table.insert(list, { x = x, z = z, ox = spot[3], oz = spot[4] })
					end
				end
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

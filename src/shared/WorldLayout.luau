-- The town, in metres, centred on (0, 0) with north at -z: the prototype's 340 x 340 m map
-- (deliver-a-parcel `src/world.js`), tagged with the Blueprint's districts. Pure data and
-- geometry, so the server builds from it and the tests check it. Ids are stable: saves use them.

local Config = require(script.Parent.Config)

local WorldLayout = {}

WorldLayout.EDGE = 170 -- half the map
WorldLayout.RING = 36
WorldLayout.OUTER = 118
WorldLayout.ROAD_W = 9
WorldLayout.GATE = 3.5 -- half the gate gap
WorldLayout.ROAD_REACH = 23 -- how far a house's path runs to meet the road

local RING, OUTER, ROAD_W = WorldLayout.RING, WorldLayout.OUTER, WorldLayout.ROAD_W

-- { width, depth, x, z }
WorldLayout.ROADS = {
	{ RING * 2 + ROAD_W, ROAD_W, 0, -RING },
	{ RING * 2 + ROAD_W, ROAD_W, 0, RING },
	{ ROAD_W, RING * 2 + ROAD_W, -RING, 0 },
	{ ROAD_W, RING * 2 + ROAD_W, RING, 0 },
	{ OUTER * 2 + ROAD_W, ROAD_W, 0, -OUTER },
	{ OUTER * 2 + ROAD_W, ROAD_W, 0, OUTER },
	{ ROAD_W, OUTER * 2 + ROAD_W, -OUTER, 0 },
	{ ROAD_W, OUTER * 2 + ROAD_W, OUTER, 0 },
	{ ROAD_W, OUTER * 2, 0, 0 },
	{ OUTER * 2, ROAD_W, 0, 0 },
}

WorldLayout.HUB = { x = 0, z = 3 } -- the order board
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
	dx: number,
	dz: number,
	dog: string?,
	size: string,
	district: string,
	place: string?,
	parcelOnly: boolean?,
	weight: number?,
	extraTime: number?,
	risk: number?,
	nightRisk: number?,
	step: { x: number, z: number }?,
}

local function house(name, hex, x, z, dx, dz, dog, size): House
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
		district = "",
	}
end

WorldLayout.HOUSES = {
	-- Around the inner ring
	house("Red", "e0524d", -30, -62, 0, 1, "chihuahua"),
	house("Blue", "4d8de0", 30, -62, 0, 1, nil, "large"),
	house("Yellow", "e8c23c", 62, -30, -1, 0, "beagle"),
	house("Orange", "f0883a", 62, 30, -1, 0, nil),
	house("Green", "3fae68", 30, 62, 0, -1, nil, "large"),
	house("Pink", "e77fb3", -30, 62, 0, -1, "shihTzu", "small"),
	house("Purple", "8d63d6", -62, 30, 1, 0, nil),
	house("Teal", "2fb5a8", -62, -30, 1, 0, "pomeranian", "small"),
	-- Just inside the outer ring, gates facing it
	house("Coral", "f0776a", -30, -96, 0, -1, "cat", "small"),
	house("Lime", "9ccc3c", 96, -30, 1, 0, "germanShepherd", "large"),
	house("Navy", "3a5a9a", 30, 96, 0, 1, "aspin"),
	house("Peach", "f4b183", -96, 30, -1, 0, nil, "small"),
	-- Outside the outer ring
	house("Gold", "d6a520", 143, -70, -1, 0, "greatDane", "large"),
	house("Mint", "7fd8b0", 143, 70, -1, 0, "cat"),
	house("Rose", "d85a7f", 70, 143, 0, -1, "dachshund", "small"),
	house("Sky", "6cc6ff", -70, 143, 0, -1, "husky", "large"),
	house("Lilac", "b79ae0", -143, 70, 1, 0, "goose", "small"),
	house("Brown", "9a6a45", -143, -70, 1, 0, "saintBernard", "large"),
	house("Indigo", "5560c8", -70, -143, 0, 1, "aspin"),
	house("Cream", "eadfba", 0, -143, 0, 1, "goose"),
	house("Slate", "6c7a89", 70, -143, 0, 1, "mastiff", "large"),
}

-- The cemetery takes parcels at one grave by the west wall, and counts as a delivery place.
WorldLayout.CEMETERY = { x0 = 68, x1 = 108, z0 = 70, z1 = 106, gateGap = 3.5 }
table.insert(WorldLayout.HOUSES, {
	id = "cemetery",
	name = "Cemetery",
	place = "the cemetery",
	color = Color3.fromHex("8fa08a"),
	x = 88,
	z = 88,
	dx = -1,
	dz = 0,
	size = "medium",
	district = "CemeteryDistrict",
	parcelOnly = true,
	weight = 3,
	extraTime = 10,
	risk = 1,
	nightRisk = 1,
	step = { x = 74.5, z = 78.6 },
})

-- Seven home sites, one per player, each facing the middle of the map. These are the
-- prototype's seeded sites (seed 20261102), computed once; centres are at least 72.4 m apart.
WorldLayout.LOTS = {
	{ id = "lot1", x = 82, z = -70, dx = -1, dz = 0 },
	{ id = "lot2", x = 127, z = 147, dx = 0, dz = -1 },
	{ id = "lot3", x = -93, z = -84, dx = 1, dz = 0 },
	{ id = "lot4", x = 116, z = -148, dx = 0, dz = 1 },
	{ id = "lot5", x = -127, z = -148, dx = 0, dz = 1 },
	{ id = "lot6", x = -112, z = 142, dx = 0, dz = -1 },
	{ id = "lot7", x = -152, z = -19, dx = 1, dz = 0 },
}

-- Scenery the graybox builds: { x, z, w, d, floors, colour }
WorldLayout.TOWERS = {
	{ 62, -62, 16, 16, 5, "c9ccd4" },
	{ -62, -62, 14, 18, 4, "e2c9a8" },
	{ 62, 62, 18, 14, 3, "a9c4d8" },
	{ -62, 62, 16, 16, 4, "d8b4a8" },
}
WorldLayout.SARI_SARI = { { x = 96, z = 30, face = 1 }, { x = -96, z = -30, face = -1 } }
WorldLayout.COURT = { x = 30, z = -96 }
WorldLayout.POND = { x = -30, z = 96 }
WorldLayout.PICKLEBALL = { x = -92, z = 90 }

-- The Blueprint's districts (§3.1), assigned by position. Provisional until the graybox test.
function WorldLayout.districtAt(x: number, z: number): string
	if math.max(math.abs(x), math.abs(z)) > OUTER then
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
	if not h.step then
		local at = frame(h)
		local x, z = at(0, WorldLayout.houseGeometry(h).stepV)
		h.step = { x = x, z = z }
	end
	if h.district == "" then
		h.district = WorldLayout.districtAt(h.x, h.z)
	end
end
for _, lot in WorldLayout.LOTS do
	lot.step = { x = lot.x + lot.dx * 10, z = lot.z + lot.dz * 10 }
	lot.district = WorldLayout.districtAt(lot.x, lot.z)
end

WorldLayout.byId = {}
for _, h in WorldLayout.HOUSES do
	WorldLayout.byId[h.id] = h
end

-- A point in metres as a world position in studs.
function WorldLayout.studs(x: number, z: number, y: number?): Vector3
	local s = Config.STUDS
	return Vector3.new(x * s, (y or 0) * s, z * s)
end

return WorldLayout

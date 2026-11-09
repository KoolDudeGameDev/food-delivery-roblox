-- The built-in art kit: stylized models made of parts, for every role that has no vetted Toolbox
-- model yet (WorldBuilder.kit). Toolbox art in ServerStorage.Assets still wins when it's there.
-- Each role is a function of its footprint that returns boxes in the model's own frame, in
-- metres: x across, y up (the box's centre), z towards the front, the ground at y = 0.
--   { name, w, h, d, colour, x, y, z, options? }
-- options: m (material), rx/ry/rz (turns, radians), shape ("Ball", "Cylinder": along x),
-- alpha (transparency), ghost (no collision), tag ("Window" lights at night, "Paint" takes the
-- player's house paint).

export type Box = { any }

local Kit = {}

local R2 = math.sqrt(2)
local QUARTER = math.pi / 4

local function add(list: { Box }, name: string, w: number, h: number, d: number, color: string, x: number, y: number, z: number, o: { [string]: any }?)
	table.insert(list, { name, w, h, d, color, x, y, z, o })
end

-- A 45° gable roof, ridge along x, on walls d deep that top out at y. A square beam turned on
-- its edge fills both gable ends (its lower half sits inside the walls or underground), and two
-- slabs make the roof, over metres past the walls.
local function gable(list: { Box }, w: number, d: number, y: number, endColor: string, roofColor: string, over: number, paint: boolean?, roofMat: string?)
	local s = d / R2
	add(list, "Gable", w, s, s, endColor, 0, y, 0, { rx = QUARTER, tag = if paint then "Paint" else nil })
	local t, L = 0.3, (d / 2 + over) * R2
	for _, side in { 1, -1 } do
		add(list, "Roof", w + over * 2, t, L, roofColor, 0, y + d / 2 - L / (2 * R2) + t / (2 * R2), side * (L + t) / (2 * R2), { rx = side * QUARTER, m = roofMat or "Slate" })
	end
	add(list, "Ridge", w + over * 2, 0.35, 0.35, roofColor, 0, y + d / 2 + 0.2, 0, { rx = QUARTER })
end

-- A slab hinged along x at (y, z) that runs out towards +z, tipped down by angle (up if negative)
local function tilt(list: { Box }, name: string, w: number, len: number, color: string, x: number, y: number, z: number, angle: number, o: { [string]: any }?)
	local opts = table.clone(o or {})
	opts.rx = angle
	add(list, name, w, 0.12, len, color, x, y - math.sin(angle) * len / 2, z + math.cos(angle) * len / 2, opts)
end

-- A window on a wall facing +z (or -z, or ±x with side), lit at night, with a darker frame
local function window(list: { Box }, x: number, y: number, z: number, w: number, h: number, frame: string, side: string?)
	local glass, border = { tag = "Window", ghost = true }, { ghost = true }
	if side == "x" then
		add(list, "WindowFrame", 0.08, h + 0.3, w + 0.3, frame, x, y, z, border)
		add(list, "Window", 0.1, h, w, "7fa6c9", x + (if x > 0 then 0.03 else -0.03), y, z, glass)
	else
		add(list, "WindowFrame", w + 0.3, h + 0.3, 0.08, frame, x, y, z, border)
		add(list, "Window", w, h, 0.1, "7fa6c9", x, y, z + (if z > 0 then 0.03 else -0.03), glass)
	end
end

-- A pot with a round shrub in it
local function plant(list: { Box }, x: number, z: number, size: number)
	add(list, "Pot", size * 0.7, size * 0.6, size * 0.7, "b5653d", x, size * 0.3, z, { ghost = true })
	add(list, "PotPlant", size, size, size, "3f9a52", x, size * 0.95, z, { shape = "Ball", ghost = true })
end

-- The warehouse hub: orange corrugated walls, open at the front for the counter and the
-- conveyor (WorldBuilder adds those), a low teal roof, racks of parcels and lamps inside.
function Kit.Warehouse(p): { Box }
	local list = {}
	local w, d, H = p.w, p.d, 7
	local orange, trim, steel, roof = "ff7a45", "e06a38", "4a5058", "3fa3a8"
	add(list, "Back", w, H, 0.4, orange, 0, H / 2, -d / 2 + 0.2)
	for _, s in { -1, 1 } do
		add(list, "Side", 0.4, H, d, orange, s * (w / 2 - 0.2), H / 2, 0)
		for _, f in { -1, 1 } do
			add(list, "Post", 0.6, H + 0.2, 0.6, steel, s * w / 2, (H + 0.2) / 2, f * d / 2, { m = "Metal" })
		end
	end
	add(list, "Header", w + 0.6, 1, 0.6, trim, 0, H - 0.5, d / 2)
	add(list, "HeaderStripe", w + 0.62, 0.25, 0.62, "ffd23f", 0, H - 0.85, d / 2)
	-- A low gable, ridge along x; the triangles at the sides are stepped to fill them
	local angle, over = 0.22, 0.8
	local run = d / 2 + over
	local rise = d / 2 * math.tan(angle)
	for _, side in { 1, -1 } do
		add(list, "Roof", w + 1.2, 0.25, run / math.cos(angle), roof, 0, H + rise - run / 2 * math.tan(angle) + 0.12, side * run / 2, { rx = side * angle })
		add(list, "GableLow", 0.4, rise / 2, d * 0.75, orange, side * (w / 2 - 0.2), H + rise / 4, 0)
		add(list, "GableHigh", 0.4, rise / 2, d * 0.3, orange, side * (w / 2 - 0.2), H + rise * 0.75, 0)
	end
	-- The posts that hold the ORDERS sign up over the front (WorldBuilder puts the sign at 8.9 m)
	for _, x in { -4, 4 } do
		add(list, "SignPost", 0.25, 2.4, 0.25, steel, x, H + 1.1, d / 2 - 0.1, { m = "Metal" })
	end
	-- High windows along the back wall, and lamps under the roof: both glow at night
	for _, x in { -w / 3, 0, w / 3 } do
		add(list, "Window", 3, 0.8, 0.1, "7fa6c9", x, 5.6, -d / 2 + 0.45, { tag = "Window", ghost = true })
		add(list, "Lamp", 1.4, 0.2, 0.5, "fff1c4", x, H - 0.3, 0, { tag = "Window", ghost = true })
	end
	-- Racks of parcels against the back wall
	for _, x in { -w / 2 + 3.5, w / 2 - 3.5 } do
		for _, u in { -2.4, 2.4 } do
			add(list, "RackPost", 0.15, 3.6, 1.2, steel, x + u, 1.8, -d / 2 + 1.1, { m = "Metal" })
		end
		for i, y in { 0.6, 1.8, 3.0 } do
			add(list, "Shelf", 4.9, 0.1, 1.2, "8a8f99", x, y, -d / 2 + 1.1, { m = "Metal" })
			for j = 0, 2 do
				local size = 0.6 + ((i + j) % 3) * 0.12
				add(list, "Parcel", size, size, size, if (i + j) % 2 == 0 then "c49a6c" else "b5875a", x - 1.6 + j * 1.6, y + 0.05 + size / 2, -d / 2 + 1.1, { m = "Cardboard" })
			end
		end
	end
	-- A pallet of parcels and a hand truck by the east wall
	add(list, "Pallet", 1.6, 0.25, 1.2, "a87b4a", w / 2 - 2, 0.125, -0.5, { m = "WoodPlanks" })
	add(list, "Parcels", 1.4, 1.1, 1, "c49a6c", w / 2 - 2, 0.8, -0.5, { m = "Cardboard" })
	add(list, "Wrap", 1.45, 0.3, 1.05, "e8eef2", w / 2 - 2, 1.05, -0.5, { alpha = 0.3 })
	return list
end

-- A shop with a false front behind its sign (WorldBuilder puts the sign at 7.8 m, 5.2 m out)
local function shopShell(list: { Box }, color: string, w: number, d: number, H: number, deep: number)
	add(list, "Body", w, H, deep, color, 0, H / 2, -d / 2 + deep / 2, { m = "Concrete" })
	add(list, "Roof", w + 0.4, 0.3, d + 0.2, "3a3f48", 0, H + 0.15, 0)
	add(list, "FalseFront", w, 3.2, 0.3, color, 0, H + 1.6 - 0.1, d / 2 - 0.15, { m = "Concrete" })
	add(list, "FalseFrontCap", w + 0.3, 0.25, 0.5, "f4f1ea", 0, H + 3.1, d / 2 - 0.15)
end

-- The ride dealer: a blue showroom with a glass front, a striped awning and rides on show.
function Kit.Dealer(p): { Box }
	local list = {}
	local w, d, H = 15, 10, 6
	local color = p.color
	shopShell(list, color, w, d, H, d - 2) -- the showroom fills the front 2 m
	add(list, "Fascia", w, 1.3, 2, color, 0, H - 0.65, d / 2 - 1, { m = "Concrete" })
	for _, s in { -1, 1 } do
		add(list, "ShowroomSide", 0.3, H - 1.3, 2, color, s * (w / 2 - 0.15), (H - 1.3) / 2, d / 2 - 1, { m = "Concrete" })
	end
	add(list, "ShowroomFloor", w - 0.6, 0.2, 2, "d9dde3", 0, 0.1, d / 2 - 1, { m = "Marble" })
	add(list, "Glass", w - 0.6, H - 1.5, 0.12, "a8d8f0", 0, (H - 1.3) / 2 + 0.1, d / 2 - 0.1, { m = "Glass", alpha = 0.45 })
	for i = 0, 4 do
		add(list, "Mullion", 0.18, H - 1.3, 0.2, "f4f1ea", -w / 2 + 0.3 + i * (w - 0.6) / 4, (H - 1.3) / 2, d / 2 - 0.05)
	end
	-- The striped awning over the glass
	local stripes = 9
	for i = 0, stripes - 1 do
		tilt(list, "Awning", w / stripes, 1.7, if i % 2 == 0 then "ffffff" else "ffd23f", -w / 2 + (i + 0.5) * w / stripes, H - 1.35, d / 2, 0.45, { m = "Fabric" })
	end
	-- Rides on show: a bicycle and a skateboard on a stand
	local y0 = 0.2
	for _, x in { -5.05, -3.95 } do
		add(list, "Wheel", 0.12, 0.75, 0.75, "222222", x, y0 + 0.38, d / 2 - 1, { shape = "Cylinder", ry = math.pi / 2, ghost = true })
	end
	add(list, "Frame", 1.1, 0.1, 0.1, "2fae57", -4.5, y0 + 0.75, d / 2 - 1, { ghost = true })
	add(list, "Seat", 0.35, 0.1, 0.18, "222222", -4.9, y0 + 1.0, d / 2 - 1, { ghost = true })
	add(list, "Bars", 0.08, 0.45, 0.5, "aaaaaa", -4.05, y0 + 0.95, d / 2 - 1, { ghost = true })
	add(list, "Stand", 1.2, 0.5, 0.8, "f4f1ea", 4.5, y0 + 0.25, d / 2 - 1)
	add(list, "Deck", 1.1, 0.06, 0.3, "d6402b", 4.5, y0 + 0.56, d / 2 - 1, { ghost = true })
	plant(list, -w / 2 + 0.6, d / 2 + 0.5, 0.9)
	plant(list, w / 2 - 0.6, d / 2 + 0.5, 0.9)
	return list
end

-- The mechanic: a concrete garage with an open bay, a moped on the lift, tyres and a drum.
function Kit.Mechanic(p): { Box }
	local list = {}
	local w, d, H = 15, 10, 6
	local color, dark, orange = p.color, "3a3f48", "ff8a3d"
	local bayX, bayW, bayH = -2, 8, 4
	add(list, "Roof", w + 0.4, 0.3, d + 0.2, dark, 0, H + 0.15, 0)
	add(list, "Back", w, H, 0.4, color, 0, H / 2, -d / 2 + 0.2, { m = "Concrete" })
	for _, s in { -1, 1 } do
		add(list, "Side", 0.4, H, d, color, s * (w / 2 - 0.2), H / 2, 0, { m = "Concrete" })
	end
	local left, right = bayX - bayW / 2, bayX + bayW / 2
	add(list, "FrontLeft", left + w / 2, H, 0.4, color, (-w / 2 + left) / 2, H / 2, d / 2 - 0.2, { m = "Concrete" })
	add(list, "FrontRight", w / 2 - right, H, 0.4, color, (right + w / 2) / 2, H / 2, d / 2 - 0.2, { m = "Concrete" })
	add(list, "BayHeader", bayW, H - bayH, 0.4, color, bayX, bayH + (H - bayH) / 2, d / 2 - 0.2, { m = "Concrete" })
	add(list, "FalseFront", w, 3.2, 0.3, color, 0, H + 1.5, d / 2 - 0.15, { m = "Concrete" })
	add(list, "FalseFrontCap", w + 0.3, 0.25, 0.5, orange, 0, H + 3.1, d / 2 - 0.15)
	-- The roller door, rolled most of the way up, and hazard stripes under the header
	add(list, "RollerDoor", bayW - 0.2, 0.9, 0.15, "c9ccd4", bayX, bayH - 0.45, d / 2 - 0.45, { m = "Metal" })
	for i = 0, 7 do
		add(list, "Hazard", bayW / 8, 0.3, 0.05, if i % 2 == 0 then "ffd23f" else "222222", left + (i + 0.5) * bayW / 8, bayH + 0.15, d / 2 + 0.02, { ghost = true })
	end
	add(list, "Floor", w - 0.8, 0.12, d - 0.8, "8a8f99", 0, 0.06, 0, { m = "Concrete" })
	-- Inside: a pegboard of tools, and a moped up on the lift
	add(list, "Pegboard", 5, 2.2, 0.08, "c9a96b", bayX, 2.4, -d / 2 + 0.45, { m = "WoodPlanks" })
	for i, c in { "d6402b", "3f7fd6", "aaaaaa", "ffd23f", "aaaaaa" } do
		add(list, "Tool", 0.18, 0.9 - i % 2 * 0.3, 0.06, c, bayX - 2 + i * 0.7, 2.4, -d / 2 + 0.5, { ghost = true })
	end
	for _, x in { bayX - 1.6, bayX + 1.6 } do
		add(list, "LiftPost", 0.3, 2, 0.3, orange, x, 1, -0.5, { m = "Metal" })
	end
	add(list, "LiftArm", 3.6, 0.15, 1.2, "4a5058", bayX, 1.2, -0.5, { m = "Metal" })
	for _, x in { bayX - 0.6, bayX + 0.6 } do
		add(list, "Wheel", 0.15, 0.6, 0.6, "222222", x, 1.6, -0.5, { shape = "Cylinder", ry = math.pi / 2, ghost = true })
	end
	add(list, "Moped", 1.4, 0.5, 0.45, "e0443a", bayX, 1.95, -0.5, { ghost = true })
	-- The office window, and the yard stuff out front
	window(list, w / 2 - 2.6, 2.2, d / 2 + 0.02, 2.4, 1.4, "f4f1ea")
	for i = 0, 2 do
		add(list, "Tyre", 0.3, 0.85, 0.85, "222222", -w / 2 + 0.9, 0.15 + i * 0.3, d / 2 + 0.8, { shape = "Cylinder", rz = math.pi / 2 })
	end
	add(list, "Tyre", 0.3, 0.85, 0.85, "222222", -w / 2 + 2.1, 0.43, d / 2 + 0.7, { shape = "Cylinder", ry = math.pi / 2 })
	add(list, "OilDrum", 1, 0.7, 0.7, "d6402b", w / 2 - 0.7, 0.5, d / 2 + 0.7, { shape = "Cylinder", rz = math.pi / 2 })
	add(list, "DrumBand", 0.08, 0.72, 0.72, "222222", w / 2 - 0.7, 0.7, d / 2 + 0.7, { shape = "Cylinder", rz = math.pi / 2, ghost = true })
	return list
end

-- The barangay hall: two cream storeys with blue bands, a pediment with the seal, a canopy over
-- the doors, windows all round. WorldBuilder adds the sign (5 m up), the flag and the notices.
function Kit.Barangay(p): { Box }
	local list = {}
	local w, d, H = p.w, p.d, 7.6
	local cream, blue, wood = "f4efe4", "2f6db5", "6b4a2e"
	local front = d / 2
	add(list, "Body", w, H, d, cream, 0, H / 2, 0, { m = "Plaster" })
	add(list, "BaseBand", w + 0.1, 0.8, d + 0.1, blue, 0, 0.4, 0)
	add(list, "FloorBand", w + 0.1, 0.25, d + 0.1, blue, 0, 3.6, 0)
	add(list, "Cornice", w + 0.5, 0.4, d + 0.5, blue, 0, H + 0.2, 0)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			add(list, "Pilaster", 0.5, H, 0.5, blue, sx * w / 2, H / 2, sz * d / 2)
		end
	end
	-- The pediment, its lower half hidden in the walls, and the barangay seal on it
	local s = 6 / R2
	add(list, "Pediment", s, s, 0.6, cream, 0, H + 0.4, front - 0.35, { rz = QUARTER, m = "Concrete" })
	add(list, "Seal", 0.1, 1.3, 1.3, "ffd23f", 0, H + 1.4, front - 0.02, { shape = "Cylinder", ry = math.pi / 2 })
	-- Doors, and the canopy over them below the sign
	add(list, "HallDoor", 2.4, 2.8, 0.15, wood, 0, 1.4, front + 0.05, { m = "WoodPlanks" })
	add(list, "Canopy", 4, 0.15, 1.5, blue, 0, 3.1, front + 0.75)
	for _, x in { -1.8, 1.8 } do
		add(list, "CanopyPost", 0.18, 3, 0.18, "f4f1ea", x, 1.5, front + 1.4)
	end
	for _, x in { -4, 4 } do
		window(list, x, 1.9, front + 0.04, 1.6, 1.4, blue)
	end
	for _, x in { -3.6, 0, 3.6 } do
		window(list, x, 6.3, front + 0.04, 1.6, 1, blue)
	end
	window(list, 0, 1.9, -front - 0.04, 1.6, 1.4, blue)
	for _, sx in { -1, 1 } do
		for _, z in { -5, -1.5, 2, 5.5 } do
			window(list, sx * (w / 2 + 0.04), 1.9, z, 1.6, 1.3, blue, "x")
			window(list, sx * (w / 2 + 0.04), 5.9, z, 1.6, 1.1, blue, "x")
		end
	end
	return list
end

-- An apartment block: storeys of ribbon windows between ledges, a plinth of shopfronts, a
-- parapet, and a water tank on the roof. Keeps the graybox height, 6 m per layout floor.
function Kit.Tower(p): { Box }
	local list = {}
	local w, d, H = p.w, p.d, p.floors * 6
	local storey = 3
	local storeys = math.floor(H / storey)
	add(list, "Body", w, H, d, p.color, 0, H / 2, 0, { m = "Concrete" })
	add(list, "Plinth", w + 0.4, storey, d + 0.4, "8a8f99", 0, storey / 2, 0, { m = "Concrete" })
	for _, f in { { 0, 1 }, { 0, -1 }, { 1, 0 }, { -1, 0 } } do
		local alongX = f[1] == 0
		local face = if alongX then d / 2 else w / 2
		local span = (if alongX then w else d) - 1.6
		local ox, oz = f[1] * (face + 0.22), f[2] * (face + 0.22)
		add(list, "Shopfront", if alongX then span else 0.1, 1.8, if alongX then 0.1 else span, "a8d8f0", f[1] * (face + 0.22), 1.3, f[2] * (face + 0.22), { tag = "Window", ghost = true })
		ox, oz = f[1] * (face + 0.04), f[2] * (face + 0.04)
		for k = 1, storeys - 1 do
			add(list, "Ribbon", if alongX then span else 0.1, 1.3, if alongX then 0.1 else span, "7fa6c9", ox, k * storey + 1.4, oz, { tag = "Window", ghost = true })
		end
		-- Mullions up the face, one part each
		local columns = math.max(2, math.floor(span / 3.2))
		for c = 0, columns do
			local u = -span / 2 + c * span / columns
			add(list, "Mullion", if alongX then 0.3 else 0.12, H - storey, if alongX then 0.12 else 0.3, p.color, if alongX then u else ox + f[1] * 0.04, storey + (H - storey) / 2, if alongX then oz + f[2] * 0.04 else u, { ghost = true })
		end
	end
	for k = 1, storeys - 1 do
		add(list, "Ledge", w + 0.3, 0.2, d + 0.3, "f4f1ea", 0, k * storey, 0)
	end
	-- The roof: parapet, stair house and water tank
	add(list, "Parapet", w + 0.3, 0.9, 0.3, "f4f1ea", 0, H + 0.45, d / 2)
	add(list, "Parapet", w + 0.3, 0.9, 0.3, "f4f1ea", 0, H + 0.45, -d / 2)
	add(list, "Parapet", 0.3, 0.9, d, "f4f1ea", w / 2, H + 0.45, 0)
	add(list, "Parapet", 0.3, 0.9, d, "f4f1ea", -w / 2, H + 0.45, 0)
	add(list, "StairHouse", 3, 2.6, 3, p.color, -w / 4, H + 1.3, -d / 4, { m = "Concrete" })
	for _, sx in { -0.7, 0.7 } do
		for _, sz in { -0.7, 0.7 } do
			add(list, "TankLeg", 0.15, 1.8, 0.15, "4a5058", w / 4 + sx, H + 0.9, d / 4 + sz, { m = "Metal" })
		end
	end
	add(list, "WaterTank", 2, 2.2, 2.2, "4d8de0", w / 4, H + 2.8, d / 4, { shape = "Cylinder", rz = math.pi / 2 })
	return list
end

-- A large customer house, a bahay na bato: a stone ground floor, an upper floor in the house's
-- own colour that overhangs it, capiz windows, a tiled gable roof. "Door" swings on delivery.
function Kit.House_large(p): { Box }
	local list = {}
	local w, d, fh = 18, 10, 5.5
	local color = p.color
	local wood, stone, tile = "5a3a28", "c9b79c", "b5532f"
	local up = d + 0.8
	add(list, "GroundFloor", w, fh, d, stone, 0, fh / 2, 0, { m = "Cobblestone" })
	add(list, "Beam", w + 1, 0.35, d + 1, wood, 0, fh, 0, { m = "WoodPlanks" })
	add(list, "UpperFloor", w + 0.8, fh, up, color, 0, fh * 1.5, 0, { m = "WoodPlanks" })
	gable(list, w + 0.8, up, fh * 2, color, tile, 0.8, false, "ClayRoofTiles")
	add(list, "Door", 2, 3.4, 0.3, wood, 0, 1.7, d / 2 + 0.15)
	add(list, "DoorArch", 2.8, 0.5, 0.3, "a8977c", 0, 3.65, d / 2 + 0.12)
	-- Capiz windows upstairs, front and back; barred ones downstairs
	for _, x in { -6.75, -2.25, 2.25, 6.75 } do
		window(list, x, fh * 1.5, up / 2 + 0.04, 2.6, 2.4, wood)
	end
	for _, x in { -4.5, 4.5 } do
		window(list, x, fh * 1.5, -up / 2 - 0.04, 2.6, 2.4, wood)
	end
	for _, x in { -5.5, 5.5 } do
		window(list, x, 2.4, d / 2 + 0.04, 1.4, 1.6, "3a3f48")
		for _, b in { -0.4, 0, 0.4 } do
			add(list, "Bar", 0.08, 1.6, 0.08, "222222", x + b, 2.4, d / 2 + 0.12, { ghost = true })
		end
	end
	return list
end

-- The player's home tiers (Data/Homes). w, d and h are the tier's footprint and height, so the
-- garden decor (Cosmetics) still fits round it. Parts tagged Paint take the house paint.

-- 1. A cardboard box with its flaps open, a blue tarp on sticks and a crate
function Kit.Home_1(p): { Box }
	local list = {}
	local w, d = p.w, p.d
	local h = p.h * 0.7
	local card = "c49a6c"
	add(list, "Box", w, h, d, card, 0, h / 2, 0, { tag = "Paint", m = "Cardboard" })
	add(list, "Tape", w + 0.04, 0.3, 0.3, "e0cfa4", 0, h - 0.1, d / 2 - 0.1)
	add(list, "Opening", 1.4, 1.7, 0.06, "4a3826", -w / 4, 0.85, d / 2 + 0.02)
	add(list, "Scrawl", 1.6, 0.5, 0.04, "3a3f48", w / 5, h * 0.6, d / 2 + 0.02, { alpha = 0.6, ghost = true })
	local a, flap = 0.6, d * 0.35
	tilt(list, "Flap", w, flap, card, 0, h, d / 2, -a, { tag = "Paint", ghost = true, m = "Cardboard" })
	tilt(list, "Flap", w, flap, card, 0, h, -d / 2 - math.cos(a) * flap, a, { tag = "Paint", ghost = true, m = "Cardboard" })
	for _, s in { -1, 1 } do
		add(list, "Flap", d * 0.35, 0.12, d, card, s * (w / 2 + math.cos(a) * d * 0.175), h + math.sin(a) * d * 0.175, 0, { rz = s * a, tag = "Paint", ghost = true, m = "Cardboard" })
	end
	-- The tarp on two sticks, sloping off the east side of the box
	add(list, "Tarp", 2.6, 0.06, d * 0.9, "3f7fd6", w / 2 + 1.25, h * 0.75, 0, { rz = -0.35, m = "Fabric" })
	for _, z in { -d * 0.4, d * 0.4 } do
		add(list, "Stick", 0.1, h * 0.55, 0.1, "8a6a4a", w / 2 + 2.4, h * 0.27, z, { m = "Wood" })
	end
	add(list, "Crate", 0.8, 0.6, 0.8, "a87b4a", w / 2 + 1.3, 0.3, d * 0.2, { m = "WoodPlanks" })
	return list
end

-- 2. A wooden shack on short stilts, with a rusty tin roof, a propped shutter and a crate step
function Kit.Home_2(p): { Box }
	local list = {}
	local w, d = p.w, p.d
	local plank, dark, tin = "a87b4a", "5a3a28", "8f8a80"
	local floor, wall = 0.85, 3.35
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			add(list, "Stilt", 0.3, floor, 0.3, dark, sx * (w / 2 - 0.3), floor / 2, sz * (d / 2 - 0.3), { m = "Wood" })
		end
	end
	add(list, "Deck", w, 0.25, d, dark, 0, floor - 0.125, 0, { m = "WoodPlanks" })
	add(list, "Walls", w, wall, d, plank, 0, floor + wall / 2, 0, { m = "WoodPlanks", tag = "Paint" })
	-- The lean-to roof, high at the back; the back wall rises to meet it
	local top = floor + wall
	local rise, run = 0.8, d + 1.2
	local angle = math.atan(rise / run)
	add(list, "BackTop", w, rise, 0.25, plank, 0, top + rise / 2, -d / 2 + 0.125, { m = "WoodPlanks", tag = "Paint" })
	for _, s in { -1, 1 } do
		add(list, "SideTop", 0.25, rise / 2, d * 0.6, plank, s * (w / 2 - 0.125), top + rise / 4, -d * 0.2, { m = "WoodPlanks", tag = "Paint" })
	end
	add(list, "Roof", w + 1, 0.15, run / math.cos(angle), tin, 0, top + rise / 2 + 0.1, 0, { rx = angle, m = "CorrodedMetal" })
	add(list, "HomeDoor", 1.4, 2.4, 0.1, dark, -w / 4, floor + 1.2, d / 2 + 0.05, { m = "WoodPlanks" })
	window(list, w / 4, floor + 1.8, d / 2 + 0.04, 1.4, 1.1, dark)
	tilt(list, "Shutter", 1.7, 0.9, dark, w / 4, floor + 2.5, d / 2 + 0.1, -0.7, { m = "WoodPlanks", ghost = true })
	add(list, "Step", 1, 0.5, 0.8, "8a6a4a", -w / 4, 0.25, d / 2 + 0.5, { m = "WoodPlanks" })
	plant(list, w / 4 + 1.4, d / 2 + 0.6, 0.8)
	return list
end

-- 3. A bungalow: painted walls on a stone base, a red gable roof, a porch over the door
function Kit.Home_3(p): { Box }
	local list = {}
	local w, d, H = p.w, p.d, 4
	local wall = "e8d8b0"
	add(list, "Walls", w, H, d, wall, 0, H / 2, 0, { m = "Plaster", tag = "Paint" })
	add(list, "Base", w + 0.1, 0.5, d + 0.1, "9a8f84", 0, 0.25, 0, { m = "Slate" })
	gable(list, w, d, H, wall, "c0472e", 0.7, true, "ClayRoofTiles")
	add(list, "HomeDoor", 1.6, 2.6, 0.12, "5a3a28", 0, 1.3, d / 2 + 0.06, { m = "WoodPlanks" })
	add(list, "PorchRoof", 5, 0.15, 2, "c0472e", 0, 3, d / 2 + 1)
	for _, x in { -2.3, 2.3 } do
		add(list, "PorchPost", 0.2, 3, 0.2, "f4f1ea", x, 1.5, d / 2 + 1.9)
	end
	for _, x in { -w / 2 + 3, w / 2 - 3 } do
		window(list, x, 2.1, d / 2 + 0.04, 1.8, 1.4, "f4f1ea")
		add(list, "Sill", 2.2, 0.12, 0.3, "f4f1ea", x, 1.3, d / 2 + 0.15)
	end
	for _, s in { -1, 1 } do
		for _, z in { -d / 4, d / 4 } do
			window(list, s * (w / 2 + 0.04), 2.1, z, 1.6, 1.3, "f4f1ea", "x")
		end
	end
	window(list, 0, 2.1, -d / 2 - 0.04, 1.8, 1.3, "f4f1ea")
	return list
end

-- 4. A two-storey house: a white floor band, a garage, a balcony upstairs, a slate roof
function Kit.Home_4(p): { Box }
	local list = {}
	local w, d, fh = p.w, p.d, 3.6
	local wall, trim = "f0e2c8", "ffffff"
	add(list, "Walls", w, fh * 2, d, wall, 0, fh, 0, { m = "Plaster", tag = "Paint" })
	add(list, "FloorBand", w + 0.2, 0.3, d + 0.2, trim, 0, fh, 0)
	add(list, "Base", w + 0.1, 0.4, d + 0.1, "9a8f84", 0, 0.2, 0, { m = "Slate" })
	gable(list, w, d, fh * 2, wall, "4d5a6b", 0.8, true, "RoofShingles")
	add(list, "GarageDoor", 5, 2.8, 0.12, "d9dde3", w / 4 + 1, 1.4, d / 2 + 0.06, { m = "Metal" })
	add(list, "HomeDoor", 1.4, 2.4, 0.12, "5a3a28", -2, 1.2, d / 2 + 0.06, { m = "WoodPlanks" })
	window(list, -w / 2 + 3, 1.9, d / 2 + 0.04, 2, 1.4, trim)
	-- The balcony and its sliding door
	local bx = -w / 4
	add(list, "Balcony", 8, 0.25, 1.4, trim, bx, fh + 0.12, d / 2 + 0.7)
	add(list, "Rail", 8, 0.9, 0.08, trim, bx, fh + 0.7, d / 2 + 1.36, { alpha = 0.15 })
	for _, s in { -1, 1 } do
		add(list, "Rail", 0.08, 0.9, 1.4, trim, bx + s * 4, fh + 0.7, d / 2 + 0.7, { alpha = 0.15 })
	end
	window(list, bx, fh + 1.4, d / 2 + 0.04, 3, 2.2, trim)
	for _, x in { w / 4 - 1.5, w / 4 + 3.5 } do
		window(list, x, fh + 1.7, d / 2 + 0.04, 1.8, 1.4, trim)
	end
	for _, x in { -w / 3, 0, w / 3 } do
		window(list, x, fh + 1.7, -d / 2 - 0.04, 1.8, 1.4, trim)
		window(list, x, 1.9, -d / 2 - 0.04, 1.8, 1.4, trim)
	end
	for _, s in { -1, 1 } do
		window(list, s * (w / 2 + 0.04), fh + 1.7, 0, 1.8, 1.4, trim, "x")
	end
	return list
end

-- 5. A mansion: a tall central block with a columned portico, two wings with balustrades
function Kit.Home_5(p): { Box }
	local list = {}
	local w, d = p.w, p.d
	local wall, white = "f4efe4", "ffffff"
	local cw, ch = 13, 10.5
	local ww, wh = (w - cw) / 2, 7
	add(list, "Centre", cw, ch, d, wall, 0, ch / 2, 0, { m = "Plaster", tag = "Paint" })
	gable(list, cw, d, ch, wall, "4d5a6b", 0.6, true, "RoofShingles")
	for _, s in { -1, 1 } do
		local x = s * (cw + ww) / 2
		add(list, "Wing", ww, wh, d - 1.5, wall, x, wh / 2, -0.75, { m = "Plaster", tag = "Paint" })
		add(list, "WingRoof", ww + 0.3, 0.3, d - 1.2, "9a8f84", x, wh + 0.15, -0.75)
		add(list, "Balustrade", ww, 0.7, 0.2, white, x, wh + 0.65, d / 2 - 1.5)
		add(list, "Balustrade", 0.2, 0.7, d - 1.5, white, s * (w / 2 - 0.1), wh + 0.65, -0.75)
		for _, f in { 0, 1 } do
			for _, u in { -ww / 3, 0, ww / 3 } do
				window(list, x + u, 1.9 + f * 3.4, d / 2 - 1.46, 1.6, 1.6, white)
			end
		end
	end
	add(list, "Base", w + 0.1, 0.5, d + 0.1, "bfc3c9", 0, 0.25, 0, { m = "Marble" })
	-- The portico: steps, four columns, an entablature and a stepped pediment
	local pz = d / 2 + 1.1
	for i, step in { 3.4, 2.6, 1.8 } do
		add(list, "Step", 10, 0.18, step, "d6d9de", 0, (i - 0.5) * 0.18, d / 2 + step / 2, { m = "Marble" })
	end
	for _, x in { -4.5, -1.5, 1.5, 4.5 } do
		add(list, "Column", 7, 0.8, 0.8, white, x, 0.54 + 3.5, pz, { shape = "Cylinder", rz = math.pi / 2, m = "Marble" })
	end
	add(list, "Entablature", 11, 0.6, 2.6, white, 0, 7.84, d / 2 + 1.0, { m = "Marble" })
	for i, pw in { 9, 6, 3 } do
		add(list, "Pediment", pw, 0.55, 2.4, white, 0, 7.84 + 0.3 + (i - 0.5) * 0.55, d / 2 + 1.0, { m = "Marble" })
	end
	add(list, "HomeDoor", 2.6, 3.4, 0.12, "5a3a28", 0, 0.54 + 1.7, d / 2 + 0.06, { m = "WoodPlanks" })
	for f = 0, 2 do
		for _, x in { -4.5, 4.5 } do
			window(list, x, 2.2 + f * 3.4, d / 2 + 0.04, 1.6, 1.8, white)
		end
	end
	for f = 1, 2 do
		window(list, 0, 2.2 + f * 3.4, d / 2 + 0.04, 1.6, 1.8, white)
	end
	return list
end

return Kit

-- Builds the graybox town from WorldLayout, in the Blueprint's hierarchy (§15):
-- Workspace.World/<District> for scenery, Workspace.Gameplay/<System> for what play depends on.
-- Art comes first from vetted Toolbox models in ServerStorage.Assets (by role name; see
-- CREDITS.md). The graybox block is the fallback, so the town always builds.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)

local WorldBuilder = {}

local S = Config.STUDS
local hex = Color3.fromHex

local DISTRICTS = {
	"TownCenter",
	"ResidentialEast",
	"ResidentialWest",
	"CommunityDistrict",
	"LogisticsDistrict",
	"RuralOutskirts",
	"CemeteryDistrict",
	"ExpansionReserve",
}
local SYSTEMS = { "CustomerHouses", "HomeLots", "EncounterZones", "DeliveryPoints", "VehicleSpawnPoints" }

local world: Folder, gameplay: Folder

local function folder(name: string, parent: Instance): Folder
	local f = parent:FindFirstChild(name) or Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f :: Folder
end

-- An anchored box. Sizes and the centre are in metres; y is the centre's height.
local function block(parent: Instance, name: string, w: number, h: number, d: number, color: Color3, x: number, y: number, z: number, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = Vector3.new(math.max(w * S, 0.05), math.max(h * S, 0.05), math.max(d * S, 0.05))
	p.Position = Vector3.new(x * S, y * S, z * S)
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
WorldBuilder.block = block

-- A sign: text on the front face of a thin board.
local function sign(parent: Instance, text: string, w: number, h: number, x: number, y: number, z: number, yaw: number, bg: Color3, fg: Color3): Part
	local board = block(parent, "Sign", w, h, 0.15, bg, x, y, z)
	board.CFrame = CFrame.new(board.Position) * CFrame.Angles(0, yaw, 0)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back -- the face looking along +z before the turn
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = fg
	label.Text = text
	label.Parent = gui
	gui.Parent = board
	return board
end
WorldBuilder.sign = sign

-- An invisible spot with a prompt on it: shop doors and home lots. Separate from the
-- building, so Toolbox art can replace the building without losing the prompt.
local function promptSpot(parent: Instance, name: string, x: number, z: number, action: string, object: string): Part
	local spot = block(parent, name, 1, 1, 1, Color3.new(1, 1, 1), x, 1.5, z)
	spot.Transparency, spot.CanCollide, spot.CanQuery, spot.CanTouch = 1, false, false, false
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = name
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = Config.SHOP_REACH * S
	prompt.RequiresLineOfSight = false
	prompt.Parent = spot
	return spot
end

-- A vetted Toolbox model for this role, placed at a pivot, or nil to fall back to graybox.
local function art(role: string, pivot: CFrame, parent: Instance): Model?
	local assets = ServerStorage:FindFirstChild("Assets")
	local source = assets and assets:FindFirstChild(role)
	if not (source and source:IsA("Model")) then
		return nil
	end
	local model = source:Clone()
	model:PivotTo(pivot)
	model.Parent = parent
	return model
end
WorldBuilder.art = art

local function yawFacing(dx: number, dz: number): number
	return math.atan2(dx, dz) -- turns +z to point along (dx, dz)
end

-- Flat ground pieces stack in layers a clear 0.25 studs apart (tops, in studs), and nothing flat
-- is textured, so nothing flickers as the camera moves.
local LAYER = { base = 0.25, detail = 0.5, sidewalk = 0.75, road = 1.0 }

local function flat(parent: Instance, name: string, w: number, d: number, color: Color3, x: number, z: number, top: number, material: Enum.Material?): Part
	local p = block(parent, name, w, 0.1, d, color, x, 0, z, material)
	p.Size = Vector3.new(w * S, 0.2, d * S)
	p.Position = Vector3.new(x * S, top - 0.1, z * S)
	return p
end

local function buildGround()
	local edge = WorldLayout.EDGE
	-- One flat, untextured green: the low-poly look, with nothing to shimmer. (Terrain grass
	-- grew animated blades over the whole town.)
	workspace.Terrain:Clear()
	block(world, "Ground", edge * 2 + 40, 1, edge * 2 + 40, hex("6fc46a"), 0, -0.5, 0)
	-- A hedge round the map
	for _, s in { -1, 1 } do
		block(world, "Hedge", edge * 2 + 4, 4, 2, hex("3e8c4a"), 0, 2, s * (edge + 1))
		block(world, "Hedge", 2, 4, edge * 2 + 4, hex("3e8c4a"), s * (edge + 1), 2, 0)
	end
end

local function buildRoads()
	local roads = folder("Roads", world)
	for _, r in WorldLayout.ROADS do
		-- Every road of a kind shares one height and colour, so crossings are seamless
		if r.dirt then
			flat(roads, r.name, r.w, r.d, hex("c9a878"), r.x, r.z, LAYER.detail)
		else
			flat(roads, `{r.name}Sidewalk`, r.w + 3, r.d + 3, hex("bfc3c9"), r.x, r.z, LAYER.sidewalk)
			flat(roads, r.name, r.w, r.d, hex("4a4f57"), r.x, r.z, LAYER.road)
		end
	end
	-- The reserved corridors end in a barrier until their districts are built (Blueprint §14)
	local reserve = world.ExpansionReserve
	for _, e in WorldLayout.EXPANSION do
		local stripes = block(reserve, `Barrier_{e.id}`, WorldLayout.ROAD_W + 3, 1.2, 0.5, hex("ff7a45"), e.x, 0.6, e.z)
		stripes.Material = Enum.Material.SmoothPlastic
		local yaw = if e.z < 0 then math.pi else 0
		sign(reserve, e.label, 8, 1.4, e.x, 2.4, e.z, yaw, hex("ffd23f"), hex("222222"))
	end
end

local function buildHub()
	local logistics = world.LogisticsDistrict
	local hub = WorldLayout.HUB
	local yard = WorldLayout.HUB_YARD
	flat(logistics, "HubYard", yard.w, yard.d, hex("cfd3da"), yard.x, yard.z, LAYER.base)

	-- The warehouse, open at the front (south), with the counter and the ORDERS sign
	local warehouse = folder("Warehouse", logistics)
	local w = WorldLayout.WAREHOUSE
	local front = w.z + w.d / 2
	if not art("Warehouse", CFrame.new(WorldLayout.studs(w.x, w.z)), warehouse) then
		local orange = hex("ff7a45")
		block(warehouse, "Back", w.w, 7, 0.6, orange, w.x, 3.5, w.z - w.d / 2)
		block(warehouse, "SideW", 0.6, 7, w.d, orange, w.x - w.w / 2, 3.5, w.z)
		block(warehouse, "SideE", 0.6, 7, w.d, orange, w.x + w.w / 2, 3.5, w.z)
		block(warehouse, "Roof", w.w + 1, 0.5, w.d + 1, hex("e06a38"), w.x, 7.25, w.z)
		block(warehouse, "Lintel", w.w + 1, 0.8, 0.6, orange, w.x, 6.6, front - 0.1)
		sign(warehouse, "ORDERS", 11, 2.8, w.x, 8.9, front + 0.1, 0, hex("d6402b"), Color3.new(1, 1, 1))
	end
	block(warehouse, "Counter", w.w - 1.4, 1.1, 1.2, hex("6a6f78"), w.x, 0.7, front - 0.6, Enum.Material.Metal)

	-- The order board: the prompt opens it, and accepting is checked against HUB_REACH from here
	local board = block(logistics, "OrderBoard", 4, 2.6, 0.3, hex("2b2f36"), hub.x, 1.9, hub.z - 2.6)
	sign(logistics, "ORDER BOARD", 3.8, 0.8, hub.x, 3.6, hub.z - 2.5, 0, hex("ffd23f"), hex("222222"))
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BoardPrompt"
	prompt.ActionText = "Order board"
	prompt.ObjectText = "Deliveries"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = Config.HUB_REACH * S + 4
	prompt.RequiresLineOfSight = false
	prompt.Parent = board
	CollectionService:AddTag(board, "OrderBoard")
	local ring = block(logistics, "HubRing", 0.05, Config.HUB_REACH * 2, Config.HUB_REACH * 2, hex("4dff88"), hub.x, 0, hub.z, Enum.Material.Neon)
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.1, ring.Size.Y, ring.Size.Z)
	ring.CFrame = CFrame.new(hub.x * S, LAYER.detail - 0.05, hub.z * S) * CFrame.Angles(0, 0, math.rad(90))
	ring.Transparency = 0.6
	ring.CanCollide = false

	for key, shop in WorldLayout.SHOPS do
		local f = folder(shop.label, logistics)
		if not art(key == "dealer" and "Dealer" or "Mechanic", CFrame.new(WorldLayout.studs(shop.x, shop.z)), f) then
			block(f, "Body", 15, 6, 10, shop.color, shop.x, 3, shop.z)
			block(f, "Roof", 16, 0.4, 11, hex("3a3f48"), shop.x, 6.2, shop.z)
		end
		-- The shop's front faces north (-z), towards its doorstep
		sign(f, shop.label, 10, 2.4, shop.x, 7.8, shop.z - 5.2, math.pi, Color3.new(1, 1, 1), hex("222222"))
		local door = promptSpot(f, if key == "dealer" then "DealerPrompt" else "MechanicPrompt", shop.x, shop.z - 8.4, "Shop", shop.label)
		door:SetAttribute("Shop", key)
	end
end

local function buildHouse(h)
	local at = WorldLayout.frame(h)
	local geo = WorldLayout.houseGeometry(h)
	local size, U, V, GATE = geo.size, geo.size.yardU, geo.size.yardV, WorldLayout.GATE
	local model = Instance.new("Model")
	model.Name = h.name
	model:SetAttribute("HouseId", h.id)
	model:SetAttribute("District", h.district)
	model.Parent = gameplay.CustomerHouses
	local yaw = yawFacing(h.dx, h.dz)

	-- A straight piece between two yard points, u and v in the house's frame
	local function piece(name, u0, v0, u1, v1, height, color)
		local ax, az = at(u0, v0)
		local bx, bz = at(u1, v1)
		local w, d = math.max(math.abs(bx - ax), 0.4), math.max(math.abs(bz - az), 0.4)
		return block(model, name, w, height, d, color, (ax + bx) / 2, height / 2, (az + bz) / 2)
	end

	-- Fence round the yard, with the gate gap facing the road
	local white = hex("f3efe4")
	piece("FenceBack", -U, -V, U, -V, 2, white)
	piece("FenceLeft", -U, -V, -U, V, 2, white)
	piece("FenceRight", U, -V, U, V, 2, white)
	piece("FenceFrontLeft", -U, V, -GATE, V, 2, white)
	piece("FenceFrontRight", GATE, V, U, V, 2, white)
	for _, s in { -1, 1 } do
		local x, z = at(s * GATE, V)
		block(model, "GatePost", 0.6, 4, 0.6, h.color, x, 2, z)
	end
	local gx, gz = at(0, V)
	local gate = block(model, "GateArch", GATE * 2 + 0.6, 0.5, 0.6, h.color, gx, 4, gz)
	gate.CFrame = CFrame.new(gate.Position) * CFrame.Angles(0, yaw, 0)
	sign(model, h.name:upper(), 3, 0.9, gx, 4.9, gz, yaw, Color3.new(1, 1, 1), hex("222222"))

	-- The house, near the back of the yard
	local hx, hz = at(0, geo.bodyV)
	local body = art(`House_{h.size}`, CFrame.new(WorldLayout.studs(hx, hz)) * CFrame.Angles(0, yaw, 0), model)
	if not body then
		local floors = size.h * size.floors
		local walls = block(model, "Body", size.w, floors, size.d, h.color, hx, floors / 2, hz)
		walls.CFrame = CFrame.new(walls.Position) * CFrame.Angles(0, yaw, 0)
		local roof = block(model, "Roof", size.w + 1.4, 1.2, size.d + 1.4, hex("8a4b38"), hx, floors + 0.6, hz)
		roof.CFrame = CFrame.new(roof.Position) * CFrame.Angles(0, yaw, 0)
		local dx, dz = at(0, geo.doorV)
		local door = block(model, "Door", 2, 3.4, 0.3, hex("5a3a28"), dx, 1.7, dz)
		door.CFrame = CFrame.new(door.Position) * CFrame.Angles(0, yaw, 0)
	end

	-- Path from the road through the gate, and the doorstep
	local p0x, p0z = at(0, geo.doorV + 2.4)
	local p1x, p1z = at(0, WorldLayout.ROAD_REACH)
	local path = flat(model, "Path", 5, math.sqrt((p1x - p0x) ^ 2 + (p1z - p0z) ^ 2), hex("d9c79a"), (p0x + p1x) / 2, (p0z + p1z) / 2, LAYER.base)
	path.CFrame = CFrame.new(path.Position) * CFrame.Angles(0, yaw, 0)
	local step = flat(model, "Doorstep", 4, 2.2, hex("bdb8aa"), h.step.x, h.step.z, LAYER.detail)
	step.CFrame = CFrame.new(step.Position) * CFrame.Angles(0, yaw, 0)

	-- The gate parking spot on the road side, where rides wait (RideService)
	local spot = WorldLayout.parkingSpot(h)
	local pad = block(gameplay.VehicleSpawnPoints, `{h.id}Parking`, 0.1, 0.1, 0.1, hex("ffffff"), spot.x, 0.1, spot.z)
	pad.Transparency, pad.CanCollide, pad.CanQuery, pad.CanTouch = 1, false, false, false
	pad:SetAttribute("HouseId", h.id)

	-- Yard bounds for chasers (milestone 2)
	local zone = block(gameplay.EncounterZones, `{h.id}Yard`, 0.1, 4, 0.1, hex("ff0000"), h.x, 2, h.z)
	zone.Size = Vector3.new((if h.dx ~= 0 then V else U) * 2 * S, 4 * S, (if h.dx ~= 0 then U else V) * 2 * S)
	zone.Transparency, zone.CanCollide, zone.CanQuery, zone.CanTouch = 1, false, false, false
	zone:SetAttribute("HouseId", h.id)
	zone:SetAttribute("Dog", h.dog or "")
end

local function deliveryPoint(h)
	local p = block(gameplay.DeliveryPoints, h.id, 1, 0.2, 1, hex("ffd23f"), h.step.x, 0.1, h.step.z)
	p.Transparency, p.CanCollide, p.CanQuery, p.CanTouch = 1, false, false, false
	p:SetAttribute("HouseId", h.id)
	CollectionService:AddTag(p, "DeliveryPoint")
end

local function buildCemetery()
	local f = world.CemeteryDistrict
	local c = WorldLayout.CEMETERY
	local x, z = (c.x0 + c.x1) / 2, (c.z0 + c.z1) / 2
	local stone = hex("8b8f96")
	local side = (c.z1 - c.z0) / 2 - c.gateGap
	flat(f, "Grass", c.x1 - c.x0, c.z1 - c.z0, hex("6f8a62"), x, z, LAYER.base)
	block(f, "WallN", c.x1 - c.x0 + 0.6, 1.6, 0.6, stone, x, 0.8, c.z0)
	block(f, "WallS", c.x1 - c.x0 + 0.6, 1.6, 0.6, stone, x, 0.8, c.z1)
	block(f, "WallW", 0.6, 1.6, c.z1 - c.z0, stone, c.x0, 0.8, z)
	block(f, "WallE1", 0.6, 1.6, side, stone, c.x1, 0.8, c.z0 + side / 2)
	block(f, "WallE2", 0.6, 1.6, side, stone, c.x1, 0.8, c.z1 - side / 2)
	for _, s in { -1, 1 } do
		block(f, "GatePost", 0.9, 3.4, 0.9, stone, c.x1, 1.7, z + s * c.gateGap)
	end
	block(f, "GateBar", 0.7, 0.5, c.gateGap * 2 + 0.9, hex("2b2f36"), c.x1, 3.6, z)
	sign(f, "CEMETERY", 6, 1.5, c.x1 + 0.4, 4.7, z, math.pi / 2, hex("2b2f36"), hex("e8e4d8"))

	-- The rest is the prototype's graveyard, laid out from (68, 70) and shifted into place
	local function at(name, w, h, d, color, px, y, pz)
		return block(f, name, w, h, d, color, px + c.ox, y, pz + c.oz)
	end
	flat(f, "Path", 40.5, 3.6, hex("d9c79a"), 92.75 + c.ox, 88 + c.oz, LAYER.detail)
	flat(f, "PathWest", 3.6, 11, hex("d9c79a"), 74.5 + c.ox, 82.5 + c.oz, LAYER.detail)
	-- Apartment tombs, stacked like cabinets along three walls, and painted ground tombs
	at("Apartments1", 2.4, 4.8, 27, hex("dcd8cc"), 70.2, 2.4, 88)
	at("Apartments2", 30, 4.8, 2.4, hex("dcd8cc"), 89, 2.4, 72.2)
	at("Apartments3", 30, 4.8, 2.4, hex("dcd8cc"), 89, 2.4, 103.8)
	local paint = { hex("f1efe9"), hex("bcdff0"), hex("f4c6d0"), hex("c7e8c5"), hex("e9e3b8") }
	local n = 0
	for _, tz in { 77.5, 82, 94, 98.5 } do
		for tx = 79, 104, 4.5 do
			n += 1
			local h = 0.7 + (n % 3) * 0.6
			at("Tomb", 1.7, h, 2.6, paint[n % #paint + 1], tx, h / 2, tz)
			at("Cross", 0.2, 1.4, 0.2, Color3.new(1, 1, 1), tx, h + 0.7, tz - 1.1)
		end
	end
	-- The grave that takes parcels
	at("Grave", 1.7, 0.7, 2.6, hex("bcdff0"), 74.5, 0.35, 75.5)
	at("GraveCross", 0.2, 1.4, 0.2, Color3.new(1, 1, 1), 74.5, 1.5, 74.4)
	for _, t in { { 106, 104 }, { 106, 72 }, { 76, 97 } } do
		at("Tree", 0.7, 5, 0.7, hex("4a3a2c"), t[1], 2.5, t[2])
	end
end

-- A graybox tree: a trunk and a crown. Toolbox trees replace it through art("Tree").
local function tree(parent: Instance, x: number, z: number, s: number)
	if art("Tree", CFrame.new(WorldLayout.studs(x, z)) * CFrame.Angles(0, x % 6.28, 0), parent) then
		return
	end
	block(parent, "Trunk", 0.5 * s, 3 * s, 0.5 * s, hex("7a5a3c"), x, 1.5 * s, z)
	local crown = block(parent, "Crown", 3.2 * s, 2.6 * s, 3.2 * s, hex("3f9a52"), x, 3.8 * s, z)
	crown.Shape = Enum.PartType.Ball
	crown.CastShadow = true
end

-- The palengke: stalls with coloured canopies along the north spoke, bunting across the road.
local function buildMarket()
	local town = world.TownCenter
	local m = WorldLayout.MARKET
	local canopies = { "f06a6a", "ffd23f", "6cc6ff", "8fd16a", "e77fb3", "ff9a4a", "b79ae0" }
	local i = 0
	for z = m.z0, m.z1, m.step do
		for _, s in { -1, 1 } do
			i += 1
			local x = s * m.x
			if not art("Stall", CFrame.new(WorldLayout.studs(x, z)) * CFrame.Angles(0, s * math.pi / 2, 0), town) then
				block(town, "Counter", m.w - 1, 1, m.d - 1, hex("8a6a4a"), x, 0.5, z, Enum.Material.Wood)
				for _, c in { { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } } do
					block(town, "Pole", 0.12, 2.6, 0.12, hex("d6d9de"), x + c[1] * (m.w / 2 - 0.2), 1.3, z + c[2] * (m.d / 2 - 0.2))
				end
				block(town, "Canopy", m.w, 0.25, m.d, hex(canopies[i % #canopies + 1]), x, 2.7, z)
			end
		end
		-- A line of bunting across the road, flags in turn
		block(town, "Rope", m.x * 2, 0.05, 0.05, hex("a88a6a"), 0, 4.6, z)
		for f = -7, 7 do
			local flag = block(town, "Flag", 0.7, 0.7, 0.05, hex(canopies[(f + 8 + i) % #canopies + 1]), f * 1.1, 4.2, z)
			flag.CanCollide = false
		end
	end
	sign(town, "PALENGKE", 8, 1.6, 0, 6.2, m.z1 + 3, 0, hex("d6402b"), Color3.new(1, 1, 1))
end

local function buildScenery()
	local town, community = world.TownCenter, world.CommunityDistrict
	for i, t in WorldLayout.TOWERS do
		if not art("Tower", CFrame.new(WorldLayout.studs(t.x, t.z)), town) then
			block(town, `Tower{i}`, t.w, t.floors * 6, t.d, hex(t.color), t.x, t.floors * 3, t.z, Enum.Material.Concrete)
			block(town, `TowerRoof{i}`, t.w + 1, 0.6, t.d + 1, hex("6e7480"), t.x, t.floors * 6 + 0.3, t.z)
		end
	end
	-- The barangay hall, facing the inner ring, with a flag out front
	local b = WorldLayout.BARANGAY
	if not art("Barangay", CFrame.new(WorldLayout.studs(b.x, b.z)) * CFrame.Angles(0, -math.pi / 2, 0), community) then
		block(community, "BarangayHall", b.w, 6, b.d, hex("f4efe4"), b.x, 3, b.z, Enum.Material.Concrete)
		block(community, "BarangayRoof", b.w + 1, 0.6, b.d + 1, hex("2f6db5"), b.x, 6.3, b.z)
	end
	sign(community, "BARANGAY HALL", 9, 1.4, b.x - b.w / 2 - 0.1, 5, b.z, -math.pi / 2, hex("2f6db5"), Color3.new(1, 1, 1))
	block(community, "Flagpole", 0.2, 8, 0.2, hex("d6d9de"), b.x - b.w / 2 - 3, 4, b.z - 5)
	block(community, "FlagBlue", 2.4, 0.6, 0.05, hex("0038a8"), b.x - b.w / 2 - 1.7, 7.6, b.z - 5)
	block(community, "FlagRed", 2.4, 0.6, 0.05, hex("ce1126"), b.x - b.w / 2 - 1.7, 7.0, b.z - 5)
	buildMarket()
	local greenery = folder("Trees", world.RuralOutskirts)
	for _, t in WorldLayout.trees() do
		tree(greenery, t.x, t.z, t.s)
	end
	-- Sari-sari stores, facing the outer ring (the art direction's storefront)
	for i, s in WorldLayout.SARI_SARI do
		local yaw = if s.face > 0 then math.pi / 2 else -math.pi / 2
		if not art("SariSari", CFrame.new(WorldLayout.studs(s.x, s.z)) * CFrame.Angles(0, yaw, 0), town) then
			block(town, `SariSari{i}`, 9, 6, 14, hex("f2e3c4"), s.x, 3, s.z)
			block(town, `Awning{i}`, 3, 0.4, 15, hex("2f9e6e"), s.x + s.face * 6, 3.8, s.z)
		end
		sign(town, "SARI-SARI", 7, 1.6, s.x + s.face * 4.8, 5, s.z, yaw, hex("2f9e6e"), Color3.new(1, 1, 1))
	end
	local c = WorldLayout.COURT
	flat(community, "Court", 24, 14, hex("c96f3a"), c.x, c.z, LAYER.base)
	flat(community, "CourtInner", 21, 11, hex("d98a50"), c.x, c.z, LAYER.detail)
	for _, s in { -1, 1 } do
		block(community, "Hoop", 0.3, 4, 0.3, hex("444a55"), c.x + s * 11, 2, c.z)
		block(community, "Backboard", 0.2, 1.3, 2.2, Color3.new(1, 1, 1), c.x + s * 10.6, 3.8, c.z)
	end
	local p = WorldLayout.POND
	flat(community, "PondBank", 26, 18, hex("d9c79a"), p.x, p.z, LAYER.base)
	local water = flat(community, "Pond", 24, 16, hex("3f97d6"), p.x, p.z, LAYER.detail, Enum.Material.Glass)
	water.Transparency = 0.2
	local k = WorldLayout.PICKLEBALL
	flat(community, "Pickleball", 14, 26, hex("2f7d5b"), k.x, k.z, LAYER.base)
	flat(community, "PickleballInner", 10, 20, hex("3f8fc9"), k.x, k.z, LAYER.detail)
	block(community, "Net", 10.4, 0.8, 0.08, hex("f2f2ee"), k.x, 0.55, k.z)
end

local function buildLots()
	for _, lot in WorldLayout.LOTS do
		local model = Instance.new("Model")
		model.Name = lot.id
		model:SetAttribute("LotId", lot.id)
		model:SetAttribute("District", lot.district)
		model.Parent = gameplay.HomeLots
		flat(model, "Plot", lot.w, lot.d, hex("b9a27a"), lot.x, lot.z, LAYER.base)
		-- Owner sign beside the front; LotService writes the name on it
		local sx, sz = lot.x + lot.dx * 9 + lot.dz * 6, lot.z + lot.dz * 9 - lot.dx * 6
		block(model, "SignPost", 0.25, 2.4, 0.25, hex("7a5a3c"), sx, 1.2, sz)
		local board = sign(model, "FOR RENT", 3.2, 1.6, sx, 3.2, sz, yawFacing(lot.dx, lot.dz), Color3.new(1, 1, 1), hex("222222"))
		board.Name = "OwnerSign"
		local home = Instance.new("Model")
		home.Name = "Home"
		home.Parent = model
		local door = promptSpot(model, "HomePrompt", lot.step.x, lot.step.z, "Home", "Upgrades and rides")
		door:SetAttribute("LotId", lot.id)
	end
end

function WorldBuilder.build()
	world = folder("World", workspace)
	gameplay = folder("Gameplay", workspace)
	world:ClearAllChildren()
	gameplay:ClearAllChildren()
	for _, name in DISTRICTS do
		folder(name, world)
	end
	for _, name in SYSTEMS do
		folder(name, gameplay)
	end
	buildGround()
	buildRoads()
	buildHub()
	buildScenery()
	for _, h in WorldLayout.HOUSES do
		if h.id ~= "cemetery" then
			buildHouse(h)
		end
		deliveryPoint(h)
	end
	buildCemetery()
	buildLots()
end

return WorldBuilder

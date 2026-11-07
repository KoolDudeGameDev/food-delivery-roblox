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

local function buildGround()
	local edge = WorldLayout.EDGE
	block(world, "Ground", edge * 2 + 40, 1, edge * 2 + 40, hex("6fc46a"), 0, -0.5, 0, Enum.Material.Grass)
	-- A hedge round the map
	for _, s in { -1, 1 } do
		block(world, "Hedge", edge * 2 + 4, 4, 2, hex("3e8c4a"), 0, 2, s * (edge + 1), Enum.Material.Grass)
		block(world, "Hedge", 2, 4, edge * 2 + 4, hex("3e8c4a"), s * (edge + 1), 2, 0, Enum.Material.Grass)
	end
end

local function buildRoads()
	local roads = folder("Roads", world)
	for i, r in WorldLayout.ROADS do
		local w, d, x, z = r[1], r[2], r[3], r[4]
		block(roads, `Sidewalk{i}`, w + 3, 0.06, d + 3, hex("bfc3c9"), x, 0.03, z, Enum.Material.Concrete)
		-- East-west roads sit a touch lower, so crossings don't flicker
		local top = if w > d then 0.085 else 0.09
		block(roads, `Road{i}`, w, 0.03, d, hex("4a4f57"), x, top - 0.015, z, Enum.Material.Asphalt)
	end
end

local function buildHub()
	local logistics = world.LogisticsDistrict
	local hub = WorldLayout.HUB
	local plaza = block(logistics, "Plaza", 0.1, 30, 30, hex("cfd3da"), 0, 0.12, 0, Enum.Material.Concrete)
	plaza.Shape = Enum.PartType.Cylinder
	plaza.CFrame = CFrame.new(plaza.Position) * CFrame.Angles(0, 0, math.rad(90))

	-- The warehouse, open at the front, with the counter and the ORDERS sign
	local warehouse = folder("Warehouse", logistics)
	if not art("Warehouse", CFrame.new(WorldLayout.studs(0, -10)), warehouse) then
		local orange = hex("ff7a45")
		block(warehouse, "Back", 22, 7, 0.6, orange, 0, 3.5, -15)
		block(warehouse, "SideW", 0.6, 7, 10, orange, -11, 3.5, -10)
		block(warehouse, "SideE", 0.6, 7, 10, orange, 11, 3.5, -10)
		block(warehouse, "Roof", 23, 0.5, 11, hex("e06a38"), 0, 7.25, -10)
		block(warehouse, "Floor", 22, 0.06, 10, hex("9a9fa8"), 0, 0.2, -10)
		block(warehouse, "Lintel", 23, 0.8, 0.6, orange, 0, 6.6, -5.1)
		sign(warehouse, "ORDERS", 11, 2.8, 0, 8.9, -4.9, 0, hex("d6402b"), Color3.new(1, 1, 1))
	end
	block(warehouse, "Counter", 20.6, 1.1, 1.2, hex("6a6f78"), 0, 0.7, -5.6, Enum.Material.Metal)

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
	local ring = block(logistics, "HubRing", 0.05, Config.HUB_REACH * 2, Config.HUB_REACH * 2, hex("4dff88"), hub.x, 0.18, hub.z, Enum.Material.Neon)
	ring.Shape = Enum.PartType.Cylinder
	ring.CFrame = CFrame.new(ring.Position) * CFrame.Angles(0, 0, math.rad(90))
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
	local path = block(model, "Path", 5, 0.06, math.sqrt((p1x - p0x) ^ 2 + (p1z - p0z) ^ 2), hex("d9c79a"), (p0x + p1x) / 2, 0.04, (p0z + p1z) / 2)
	path.CFrame = CFrame.new(path.Position) * CFrame.Angles(0, yaw, 0)
	path.CanCollide = false
	local step = block(model, "Doorstep", 4, 0.12, 2.2, hex("bdb8aa"), h.step.x, 0.08, h.step.z)
	step.CFrame = CFrame.new(step.Position) * CFrame.Angles(0, yaw, 0)

	-- Gate parking pad on the road side: rides park here (milestone 4)
	local px, pz = at(0, V + 3)
	local pad = block(gameplay.VehicleSpawnPoints, `{h.id}Parking`, 0.1, 0.1, 0.1, hex("ffffff"), px, 0.1, pz)
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
	block(f, "Grass", c.x1 - c.x0, 0.04, c.z1 - c.z0, hex("6f8a62"), x, 0.03, z, Enum.Material.Grass)
	block(f, "WallN", c.x1 - c.x0 + 0.6, 1.6, 0.6, stone, x, 0.8, c.z0)
	block(f, "WallS", c.x1 - c.x0 + 0.6, 1.6, 0.6, stone, x, 0.8, c.z1)
	block(f, "WallW", 0.6, 1.6, c.z1 - c.z0, stone, c.x0, 0.8, z)
	block(f, "WallE1", 0.6, 1.6, side, stone, c.x1, 0.8, c.z0 + side / 2)
	block(f, "WallE2", 0.6, 1.6, side, stone, c.x1, 0.8, c.z1 - side / 2)
	block(f, "GateBar", 0.7, 0.5, c.gateGap * 2 + 0.9, hex("2b2f36"), c.x1, 3.6, z)
	sign(f, "CEMETERY", 6, 1.5, c.x1 + 0.4, 4.7, z, math.pi / 2, hex("2b2f36"), hex("e8e4d8"))
	block(f, "Path", 40.5, 0.04, 3.6, hex("d9c79a"), 92.75, 0.05, z)
	block(f, "PathWest", 3.6, 0.04, 11, hex("d9c79a"), 74.5, 0.05, 82.5)
	-- Apartment tombs along three walls, and painted ground tombs between
	block(f, "Apartments1", 2.4, 4.8, 27, hex("dcd8cc"), 70.2, 2.4, 88)
	block(f, "Apartments2", 30, 4.8, 2.4, hex("dcd8cc"), 89, 2.4, 72.2)
	block(f, "Apartments3", 30, 4.8, 2.4, hex("dcd8cc"), 89, 2.4, 103.8)
	local paint = { hex("f1efe9"), hex("bcdff0"), hex("f4c6d0"), hex("c7e8c5"), hex("e9e3b8") }
	local n = 0
	for _, tz in { 77.5, 82, 94, 98.5 } do
		for tx = 79, 104, 4.5 do
			n += 1
			block(f, "Tomb", 1.7, 0.7 + (n % 3) * 0.6, 2.6, paint[n % #paint + 1], tx, (0.7 + (n % 3) * 0.6) / 2, tz)
		end
	end
	-- The grave that takes parcels
	block(f, "Grave", 1.7, 0.7, 2.6, hex("bcdff0"), 74.5, 0.35, 75.5)
	block(f, "Cross", 0.2, 1.4, 0.2, Color3.new(1, 1, 1), 74.5, 1.5, 74.4)
end

local function buildScenery()
	local town, community = world.TownCenter, world.CommunityDistrict
	for i, t in WorldLayout.TOWERS do
		local x, z, w, d, floors, color = t[1], t[2], t[3], t[4], t[5], hex(t[6])
		if not art("Tower", CFrame.new(WorldLayout.studs(x, z)), town) then
			block(town, `Tower{i}`, w, floors * 6, d, color, x, floors * 3, z, Enum.Material.Concrete)
			block(town, `TowerRoof{i}`, w + 1, 0.6, d + 1, hex("6e7480"), x, floors * 6 + 0.3, z)
		end
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
	block(community, "Court", 24, 0.05, 14, hex("c96f3a"), c.x, 0.03, c.z)
	block(community, "CourtInner", 21, 0.06, 11, hex("d98a50"), c.x, 0.04, c.z)
	for _, s in { -1, 1 } do
		block(community, "Hoop", 0.3, 4, 0.3, hex("444a55"), c.x + s * 11, 2, c.z)
		block(community, "Backboard", 0.2, 1.3, 2.2, Color3.new(1, 1, 1), c.x + s * 10.6, 3.8, c.z)
	end
	local p = WorldLayout.POND
	block(community, "PondBank", 26, 0.03, 18, hex("d9c79a"), p.x, 0.02, p.z)
	local water = block(community, "Pond", 24, 0.05, 16, hex("3f97d6"), p.x, 0.03, p.z, Enum.Material.Glass)
	water.Transparency = 0.2
	local k = WorldLayout.PICKLEBALL
	block(community, "Pickleball", 14, 0.05, 26, hex("2f7d5b"), k.x, 0.03, k.z)
	block(community, "PickleballInner", 10, 0.06, 20, hex("3f8fc9"), k.x, 0.04, k.z)
	block(community, "Net", 10.4, 0.8, 0.08, hex("f2f2ee"), k.x, 0.55, k.z)
end

local function buildLots()
	for _, lot in WorldLayout.LOTS do
		local model = Instance.new("Model")
		model.Name = lot.id
		model:SetAttribute("LotId", lot.id)
		model:SetAttribute("District", lot.district)
		model.Parent = gameplay.HomeLots
		local w, d = if lot.dx ~= 0 then 28 else 40, if lot.dx ~= 0 then 40 else 28
		block(model, "Plot", w, 0.05, d, hex("b9a27a"), lot.x, 0.03, lot.z, Enum.Material.Ground)
		-- Owner sign beside the front; LotService writes the name on it
		local sx, sz = lot.x + lot.dx * 9 + lot.dz * 6, lot.z + lot.dz * 9 - lot.dx * 6
		block(model, "SignPost", 0.25, 2.4, 0.25, hex("7a5a3c"), sx, 1.2, sz)
		local board = sign(model, "FOR RENT", 3.2, 1.6, sx, 3.2, sz, yawFacing(lot.dx, lot.dz), Color3.new(1, 1, 1), hex("222222"))
		board.Name = "OwnerSign"
		local home = Instance.new("Model")
		home.Name = "Home"
		home.Parent = model
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

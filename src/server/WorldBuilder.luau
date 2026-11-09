-- Builds the graybox town from WorldLayout, in the Blueprint's hierarchy (§15):
-- Workspace.World/<District> for scenery, Workspace.Gameplay/<System> for what play depends on.
-- Art comes first from vetted Toolbox models in ServerStorage.Assets (by role name; see
-- CREDITS.md), then from the built-in kit (Data/Kit), then plain graybox blocks, so the town
-- always builds.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Kit = require(ReplicatedStorage.Shared.Data.Kit)
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

-- The built-in kit's model for this role (Data/Kit), placed at a pivot, or nil if it has none
local function kit(role: string, pivot: CFrame, parent: Instance, params: { [string]: any }?): Model?
	local make = (Kit :: any)[role]
	if not make then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = role
	for _, b in make(params or {}) do
		local o = b[9] or {}
		local part = block(model, b[1], b[2], b[3], b[4], hex(b[5]), 0, 0, 0, if o.m then (Enum.Material :: any)[o.m] else nil)
		if o.shape then
			part.Shape = (Enum.PartType :: any)[o.shape]
		end
		part.CFrame = pivot * CFrame.new(b[6] * S, b[7] * S, b[8] * S) * CFrame.Angles(o.rx or 0, o.ry or 0, o.rz or 0)
		part.Transparency = o.alpha or 0
		part.CanCollide = not o.ghost
		if o.tag then
			CollectionService:AddTag(part, o.tag)
		end
	end
	model.Parent = parent
	return model
end
WorldBuilder.kit = kit

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
		if r.foot then
			flat(roads, r.name, r.w, r.d, hex("d9c79a"), r.x, r.z, LAYER.detail) -- a trodden footpath
		elseif r.dirt then
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
		stripes.CFrame = CFrame.new(stripes.Position) * CFrame.Angles(0, e.yaw, 0)
		-- The sign faces back into town
		local facing = if e.z < -100 then 0 elseif e.z > 100 then math.pi else math.pi / 2
		sign(reserve, e.label, 8, 1.4, e.x, 2.4, e.z, facing, hex("ffd23f"), hex("222222"))
	end
	-- Direction signs at the main junctions (Blueprint §5.2 rule 5)
	for i, g in WorldLayout.SIGNS do
		block(roads, `SignPost{i}`, 0.2, 3.4, 0.2, hex("6a6f78"), g.x, 1.7, g.z)
		sign(roads, g.text, math.max(4, #g.text * 0.42), 1, g.x, 3.4, g.z, g.yaw, hex("2f6db5"), Color3.new(1, 1, 1))
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
		kit("Warehouse", CFrame.new(WorldLayout.studs(w.x, w.z)), warehouse, w)
		sign(warehouse, "ORDERS", 11, 2.8, w.x, 8.9, front + 0.1, 0, hex("d6402b"), Color3.new(1, 1, 1))
	end
	block(warehouse, "Counter", w.w - 1.4, 1.1, 1.2, hex("6a6f78"), w.x, 0.7, front - 0.6, Enum.Material.Metal)
	-- The conveyor belt along the counter top: packages ride it to the pickup point in the middle
	-- (client/Conveyor.luau moves them)
	block(warehouse, "Belt", w.w - 2, 0.06, 0.9, hex("2b2f36"), w.x, 1.28, front - 0.6)
	block(warehouse, "PickupMark", 1.2, 0.07, 1, hex("ffd23f"), w.x, 1.29, front - 0.6, Enum.Material.Neon)

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
		-- Turned so the model's front (+z) faces the doorstep to the north
		local pivot = CFrame.new(WorldLayout.studs(shop.x, shop.z)) * CFrame.Angles(0, math.pi, 0)
		local role = if key == "dealer" then "Dealer" else "Mechanic"
		if not art(role, pivot, f) then
			kit(role, pivot, f, { color = shop.color:ToHex() })
		end
		-- The shop's front faces north (-z), towards its doorstep
		sign(f, shop.label, 10, 2.4, shop.x, 7.8, shop.z - 5.2, math.pi, Color3.new(1, 1, 1), hex("222222"))
		local door = promptSpot(f, if key == "dealer" then "DealerPrompt" else "MechanicPrompt", shop.x, shop.z - 8.4, "Shop", shop.label)
		door:SetAttribute("Shop", key)
	end
end

-- Fence styles by house size (Blueprint §7.2)
local FENCES = {
	small = { height = 1.4, color = hex("c9a96b"), material = Enum.Material.Wood, leaves = 1, gate = hex("b08a52") },
	medium = { height = 2, color = hex("f3efe4"), material = Enum.Material.SmoothPlastic, leaves = 2, gate = hex("e8e2d0") },
	large = { height = 2.6, color = hex("b8b4aa"), material = Enum.Material.Concrete, leaves = 2, gate = hex("4a5058") },
}

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
	local function piece(name, u0, v0, u1, v1, height, color, material)
		local ax, az = at(u0, v0)
		local bx, bz = at(u1, v1)
		local w, d = math.max(math.abs(bx - ax), 0.4), math.max(math.abs(bz - az), 0.4)
		return block(model, name, w, height, d, color, (ax + bx) / 2, height / 2, (az + bz) / 2, material)
	end

	-- The fence says what kind of house it is (Blueprint §7.2): a low bamboo fence round a small
	-- house, a white picket round a medium one, a tall wall round a large one
	local style = FENCES[h.size]
	piece("FenceBack", -U, -V, U, -V, style.height, style.color, style.material)
	piece("FenceLeft", -U, -V, -U, V, style.height, style.color, style.material)
	piece("FenceRight", U, -V, U, V, style.height, style.color, style.material)
	piece("FenceFrontLeft", -U, V, -GATE, V, style.height, style.color, style.material)
	piece("FenceFrontRight", GATE, V, U, V, style.height, style.color, style.material)
	for _, s in { -1, 1 } do
		local x, z = at(s * GATE, V)
		block(model, "GatePost", 0.6, 4, 0.6, h.color, x, 2, z)
	end
	local gx, gz = at(0, V)
	local gate = block(model, "GateArch", GATE * 2 + 0.6, 0.5, 0.6, h.color, gx, 4, gz)
	gate.CFrame = CFrame.new(gate.Position) * CFrame.Angles(0, yaw, 0)
	sign(model, h.name:upper(), 3, 0.9, gx, 4.9, gz, yaw, Color3.new(1, 1, 1), hex("222222"))

	-- The gate itself: shut and solid until someone brings this house an order (GateService
	-- opens it; each client swings the leaves). A small house has one leaf, the others two.
	local gateModel = Instance.new("Model")
	gateModel.Name = "Gate"
	gateModel:SetAttribute("HouseId", h.id)
	gateModel:SetAttribute("Open", false)
	gateModel:SetAttribute("Inward", WorldLayout.studs(h.x, h.z)) -- the leaves swing towards the house
	gateModel.Parent = model
	local spans = if style.leaves == 1 then { { -GATE, GATE, -GATE } } else { { -GATE, 0, -GATE }, { 0, GATE, GATE } }
	for _, span in spans do
		local u0, u1, hingeU = span[1], span[2], span[3]
		local cx, cz = at((u0 + u1) / 2, V)
		local leaf = block(gateModel, "GateLeaf", u1 - u0 - 0.1, style.height * 0.9, 0.12, style.gate, cx, style.height * 0.45, cz)
		leaf.CFrame = CFrame.new(leaf.Position) * CFrame.Angles(0, yaw, 0)
		local hx, hz = at(hingeU, V)
		leaf:SetAttribute("Hinge", WorldLayout.studs(hx, hz))
		CollectionService:AddTag(leaf, "GateLeaf")
	end

	-- The house, near the back of the yard
	local hx, hz = at(0, geo.bodyV)
	local pivot = CFrame.new(WorldLayout.studs(hx, hz)) * CFrame.Angles(0, yaw, 0)
	local body = art(`House_{h.size}`, pivot, model)
	if body then
		-- Scaled about its base to fill the footprint's width; the box is in the house's own axes
		local _, box = body:GetBoundingBox()
		body:ScaleTo(body:GetScale() * size.w * S / box.X)
	elseif not kit(`House_{h.size}`, pivot, model, { color = h.color:ToHex() }) then
		local floors = size.h * size.floors
		local walls = block(model, "Body", size.w, floors, size.d, h.color, hx, floors / 2, hz)
		walls.CFrame = CFrame.new(walls.Position) * CFrame.Angles(0, yaw, 0)
		local roof = block(model, "Roof", size.w + 1.4, 1.2, size.d + 1.4, hex("8a4b38"), hx, floors + 0.6, hz)
		roof.CFrame = CFrame.new(roof.Position) * CFrame.Angles(0, yaw, 0)
		local dx, dz = at(0, geo.doorV)
		local door = block(model, "Door", 2, 3.4, 0.3, hex("5a3a28"), dx, 1.7, dz)
		door.CFrame = CFrame.new(door.Position) * CFrame.Angles(0, yaw, 0)
		-- Windows on the front, a row per floor: lit at night, dark in a brownout (WorldService)
		for f = 0, size.floors - 1 do
			for _, u in { -size.w / 4, size.w / 4 } do
				local wx, wz = at(u, geo.doorV + 0.05)
				local window = block(model, "Window", 1.8, 1.2, 0.1, hex("7fa6c9"), wx, f * size.h + size.h * 0.6, wz)
				window.CFrame = CFrame.new(window.Position) * CFrame.Angles(0, yaw, 0)
				window.CanCollide = false
				CollectionService:AddTag(window, "Window")
			end
		end
	end
	-- Flower beds either side of the front path, and a potted plant by the gate
	for _, u in { -4.5, 4.5 } do
		local fx, fz = at(u, geo.doorV + 1.4)
		local bed = block(model, "FlowerBed", 2.4, 0.4, 0.9, hex("5a3f2a"), fx, 0.2, fz)
		bed.CFrame = CFrame.new(bed.Position) * CFrame.Angles(0, yaw, 0)
		bed.CanCollide = false
		local bloom = block(model, "Flowers", 2.2, 0.3, 0.7, h.color:Lerp(Color3.new(1, 1, 1), 0.25), fx, 0.55, fz)
		bloom.CFrame = CFrame.new(bloom.Position) * CFrame.Angles(0, yaw, 0)
		bloom.CanCollide = false
	end
	local px, pz = at(U - 2, V - 2)
	block(model, "Pot", 0.7, 0.6, 0.7, hex("b5653d"), px, 0.3, pz).CanCollide = false
	local leaves = block(model, "PotPlant", 1, 1, 1, hex("3f9a52"), px, 1, pz)
	leaves.Shape, leaves.CanCollide = Enum.PartType.Ball, false

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
			-- Candles lit at night and all through Undas (WorldService), and flowers for the dead
			for _, ox in { -0.4, 0.4 } do
				local candle = at("Candle", 0.14, 0.32, 0.14, hex("fff4d8"), tx + ox, h + 0.16, tz + 0.9)
				candle.CanCollide = false
				CollectionService:AddTag(candle, "Candle")
			end
			if n % 2 == 0 then
				at("FlowerPot", 0.34, 0.3, 0.34, hex("b7b2a6"), tx + 1.1, 0.15, tz + 1)
				at("Flowers", 0.38, 0.3, 0.38, ({ hex("e0443a"), hex("ffd23f"), hex("e77fb3") })[n % 3 + 1], tx + 1.1, 0.45, tz + 1)
			end
		end
	end
	-- The grave that takes parcels
	at("Grave", 1.7, 0.7, 2.6, hex("bcdff0"), 74.5, 0.35, 75.5)
	at("GraveCross", 0.2, 1.4, 0.2, Color3.new(1, 1, 1), 74.5, 1.5, 74.4)
	for _, t in { { 106, 104 }, { 106, 72 }, { 76, 97 } } do
		at("Tree", 0.7, 5, 0.7, hex("4a3a2c"), t[1], 2.5, t[2])
	end
end

-- Graybox plants: a palm (town), a broadleaf tree (country) or a shrub. Toolbox models replace
-- them through art("Palm"), art("Tree") and art("Shrub").
local function tree(parent: Instance, x: number, z: number, s: number, kind: string)
	local role = if kind == "palm" then "Palm" elseif kind == "shrub" then "Shrub" else "Tree"
	if art(role, CFrame.new(WorldLayout.studs(x, z)) * CFrame.Angles(0, x % 6.28, 0), parent) then
		return
	end
	if kind == "shrub" then
		local bush = block(parent, "Shrub", 1.6 * s, 1.1 * s, 1.6 * s, hex("4a9e4f"), x, 0.5 * s, z)
		bush.Shape = Enum.PartType.Ball
		return
	elseif kind == "palm" then
		block(parent, "Trunk", 0.35 * s, 6 * s, 0.35 * s, hex("9a7a52"), x, 3 * s, z)
		for i = 0, 4 do
			local frond = block(parent, "Frond", 0.7 * s, 0.12, 3 * s, hex("4caf50"), x, 6 * s, z)
			frond.CFrame = CFrame.new(frond.Position) * CFrame.Angles(0, i * math.pi * 2 / 5, 0) * CFrame.new(0, 0, 1.2 * s * S) * CFrame.Angles(math.rad(-25), 0, 0)
			frond.CanCollide = false
		end
		return
	end
	block(parent, "Trunk", 0.5 * s, 3 * s, 0.5 * s, hex("7a5a3c"), x, 1.5 * s, z)
	local crown = block(parent, "Crown", 3.2 * s, 2.6 * s, 3.2 * s, hex("3f9a52"), x, 3.8 * s, z)
	crown.Shape = Enum.PartType.Ball
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
			kit("Tower", CFrame.new(WorldLayout.studs(t.x, t.z)), town, t).Name = `Tower{i}`
		end
	end
	-- The barangay hall, facing north onto the West Link, with a flag and a notice board out front
	local b = WorldLayout.BARANGAY
	local front = b.z - b.d / 2
	local hall = CFrame.new(WorldLayout.studs(b.x, b.z)) * CFrame.Angles(0, math.pi, 0)
	if not art("Barangay", hall, community) then
		kit("Barangay", hall, community, b)
	end
	sign(community, "BARANGAY HALL", 9, 1.4, b.x, 5, front - 0.1, math.pi, hex("2f6db5"), Color3.new(1, 1, 1))
	block(community, "Flagpole", 0.2, 8, 0.2, hex("d6d9de"), b.x - 4, 4, front - 2)
	block(community, "FlagBlue", 0.05, 0.6, 2.4, hex("0038a8"), b.x - 4, 7.6, front - 3.3)
	block(community, "FlagRed", 0.05, 0.6, 2.4, hex("ce1126"), b.x - 4, 7.0, front - 3.3)
	block(community, "NoticeBoardPost", 0.2, 2.2, 0.2, hex("7a5a3c"), b.x + 4, 1.1, front - 1.5)
	sign(community, "NOTICES", 2.4, 1.6, b.x + 4, 2, front - 1.5, math.pi, hex("8a6a4a"), hex("fff4d8"))
	buildMarket()
	local greenery = folder("Trees", world.RuralOutskirts)
	for _, t in WorldLayout.trees() do
		tree(greenery, t.x, t.z, t.s, t.kind)
	end
	-- Sari-sari stores (the art direction's storefront), the front 14 m across, facing the road
	for i, s in WorldLayout.SARI_SARI do
		local yaw = yawFacing(s.dx, s.dz)
		local base = CFrame.new(WorldLayout.studs(s.x, s.z)) * CFrame.Angles(0, yaw, 0)
		if not art("SariSari", base, town) then
			local body = block(town, `SariSari{i}`, 14, 6, 9, hex("f2e3c4"), s.x, 3, s.z)
			body.CFrame = base * CFrame.new(0, 3 * S, 0)
			local awning = block(town, `Awning{i}`, 15, 0.4, 3, hex("2f9e6e"), s.x, 3.8, s.z)
			awning.CFrame = base * CFrame.new(0, 3.8 * S, 6 * S)
		end
		sign(town, "SARI-SARI", 7, 1.6, s.x + s.dx * 4.6, 5, s.z + s.dz * 4.6, yaw, hex("2f9e6e"), Color3.new(1, 1, 1))
	end
	-- The court runs north-south: hoops at its ends
	local c = WorldLayout.COURT
	flat(community, "Court", c.w, c.d, hex("c96f3a"), c.x, c.z, LAYER.base)
	flat(community, "CourtInner", c.w - 3, c.d - 3, hex("d98a50"), c.x, c.z, LAYER.detail)
	for _, s in { -1, 1 } do
		block(community, "Hoop", 0.3, 4, 0.3, hex("444a55"), c.x, 2, c.z + s * (c.d / 2 - 1))
		block(community, "Backboard", 2.2, 1.3, 0.2, Color3.new(1, 1, 1), c.x, 3.8, c.z + s * (c.d / 2 - 1.4))
	end
	local p = WorldLayout.POND
	flat(community, "PondBank", p.w, p.d, hex("d9c79a"), p.x, p.z, LAYER.base)
	local water = flat(community, "Pond", p.w - 2, p.d - 2, hex("3f97d6"), p.x, p.z, LAYER.detail, Enum.Material.Glass)
	water.Transparency = 0.2
	-- Pickleball runs east-west: the net across the middle
	local k = WorldLayout.PICKLEBALL
	flat(community, "Pickleball", k.w, k.d, hex("2f7d5b"), k.x, k.z, LAYER.base)
	flat(community, "PickleballInner", k.w - 6, k.d - 4, hex("3f8fc9"), k.x, k.z, LAYER.detail)
	block(community, "Net", 0.08, 0.8, k.d - 3.6, hex("f2f2ee"), k.x, 0.55, k.z)
end

local function buildLots()
	for _, lot in WorldLayout.LOTS do
		local model = Instance.new("Model")
		model.Name = lot.id
		model:SetAttribute("LotId", lot.id)
		model:SetAttribute("District", lot.district)
		model.Parent = gameplay.HomeLots
		flat(model, "Plot", lot.w, lot.d, hex("b9a27a"), lot.x, lot.z, LAYER.base)
		-- A low border fence with a gap at the front, so a home lot reads as somebody's (Blueprint §8)
		local x0, x1, z0, z1 = lot.x - lot.w / 2, lot.x + lot.w / 2, lot.z - lot.d / 2, lot.z + lot.d / 2
		local edges = {
			{ x0, z0, x1, z0, lot.dz == -1 },
			{ x0, z1, x1, z1, lot.dz == 1 },
			{ x0, z0, x0, z1, lot.dx == -1 },
			{ x1, z0, x1, z1, lot.dx == 1 },
		}
		for _, e in edges do
			local ax, az, bx, bz, front = e[1], e[2], e[3], e[4], e[5]
			local spans = if front
				then { { 0, 0.5 - 4 / math.max(math.abs(bx - ax), math.abs(bz - az)) }, { 0.5 + 4 / math.max(math.abs(bx - ax), math.abs(bz - az)), 1 } }
				else { { 0, 1 } }
			for _, sp in spans do
				local sx, sz = ax + (bx - ax) * sp[1], az + (bz - az) * sp[1]
				local ex, ez = ax + (bx - ax) * sp[2], az + (bz - az) * sp[2]
				block(model, "LotFence", math.max(math.abs(ex - sx), 0.25), 0.9, math.max(math.abs(ez - sz), 0.25), hex("c9a96b"), (sx + ex) / 2, 0.45, (sz + ez) / 2, Enum.Material.Wood)
			end
		end
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

-- Studio's Baseplate template puts a grey Baseplate with its top at y = 0, exactly where our
-- ground's top is: the two fight and the grass flickers. The browser prototype had nothing under
-- its grass, so it never showed. Clear the template's pieces, and spawn in the hub yard.
local function clearTemplate()
	for _, child in workspace:GetChildren() do
		if child.Name == "Baseplate" or child:IsA("SpawnLocation") then
			child:Destroy()
		end
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0 -- no force field
	spawn.Size = Vector3.new(6 * S, 0.2, 6 * S)
	spawn.Position = Vector3.new(10 * S, LAYER.detail - 0.1, -9 * S)
	spawn.Transparency, spawn.CanCollide, spawn.CanQuery, spawn.CanTouch = 1, false, false, false
	spawn.Parent = workspace
end

-- Street lamps along both rings (the prototype's spots). WorldService lights them at night and
-- puts them out in a brownout.
local function buildStreetlights()
	local lamps = folder("Streetlights", world.TownCenter)
	for i, l in WorldLayout.lamps() do
		local x, z, ox, oz = l.x, l.z, l.ox, l.oz
		block(lamps, "Post", 0.25, 5.2, 0.25, hex("4a5058"), x, 2.6, z)
		block(lamps, "Arm", if ox ~= 0 then 1.4 else 0.16, 0.16, if oz ~= 0 then 1.4 else 0.16, hex("4a5058"), x + ox * 0.7, 5.2, z + oz * 0.7)
		local bulb = block(lamps, "Bulb", 0.4, 0.16, 0.4, hex("8a8f96"), x + ox * 1.3, 5.05, z + oz * 1.3)
		bulb.CanCollide = false
		-- Each lamp has its own switch-on moment, so the town lights up one by one at dusk
		bulb:SetAttribute("Order", i)
		local light = Instance.new("PointLight")
		light.Range = 12 * S -- a 12 m pool of light
		light.Brightness = 1.6
		light.Color = hex("ffd9a0")
		light.Shadows = false
		light.Enabled = false
		light.Parent = bulb
		CollectionService:AddTag(bulb, "Streetlight")
	end
end

-- Fiesta bunting round the hub yard, and Undas visitors by the graves: hidden until their event.
local function buildEventProps()
	local bunting = folder("FiestaBunting", world.LogisticsDistrict)
	local y = WorldLayout.HUB_YARD
	local colors = { hex("e0443a"), hex("ffd23f"), hex("4d8de0"), hex("3fae68") }
	local corners = {
		{ y.x - y.w / 2, y.z - y.d / 2 },
		{ y.x + y.w / 2, y.z - y.d / 2 },
		{ y.x + y.w / 2, y.z + y.d / 2 },
		{ y.x - y.w / 2, y.z + y.d / 2 },
	}
	local n = 0
	for i, a in corners do
		local b = corners[i % 4 + 1]
		local len = math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
		for t = 0.6, len - 0.6, 1.2 do
			n += 1
			local f = t / len
			local flag = block(bunting, "Flag", 0.55, 0.5, 0.1, colors[n % 4 + 1], a[1] + (b[1] - a[1]) * f, 4.6 + math.sin(n * 1.6) * 0.2, a[2] + (b[2] - a[2]) * f)
			flag.CanCollide, flag.Transparency = false, 1
			flag.CFrame = CFrame.new(flag.Position) * CFrame.Angles(0, math.atan2(b[1] - a[1], b[2] - a[2]) + math.pi / 2, 0)
		end
	end
	local c = WorldLayout.CEMETERY
	local visitors = folder("UndasVisitors", world.CemeteryDistrict)
	for _, v in { { 81, 80, "2b2f36" }, { 90, 84, "f1efe9" }, { 99, 96, "2b2f36" }, { 84, 92, "4d5563" } } do
		local x, z = v[1] + c.ox, v[2] + c.oz
		for _, piece in {
			block(visitors, "Shirt", 0.9, 1.1, 0.5, hex(v[3]), x, 1.55, z),
			block(visitors, "Head", 0.7, 0.7, 0.7, hex("c99a6b"), x, 2.45, z),
			block(visitors, "Legs", 0.8, 1, 0.46, hex("2b3a55"), x, 0.5, z),
		} do
			piece.CanCollide, piece.Transparency = false, 1
		end
	end
end

-- A part placed in a frame (metres): for props built round their own centre and turn.
local function placed(parent: Instance, name: string, frame: CFrame, w: number, h: number, d: number, color: Color3, ox: number, oy: number, oz: number): Part
	local p = block(parent, name, w, h, d, color, 0, 0, 0)
	p.CFrame = frame * CFrame.new(ox * S, oy * S, oz * S)
	return p
end

-- The roadside kit (Blueprint §10.1): waiting sheds, benches, bins, crop fields, and utility
-- poles with their wires. Each has an art() role for the Toolbox pass.
local function buildProps()
	local kit = folder("Props", world.TownCenter)
	for _, p in WorldLayout.PROPS do
		local frame = CFrame.new(WorldLayout.studs(p.x, p.z)) * CFrame.Angles(0, p.yaw, 0)
		local role = if p.kind == "shed" then "WaitingShed" elseif p.kind == "bench" then "Bench" else "Bin"
		if art(role, frame, kit) then
			continue
		end
		if p.kind == "shed" then
			for _, c in { { -1.8, -1 }, { 1.8, -1 }, { -1.8, 1 }, { 1.8, 1 } } do
				placed(kit, "ShedPost", frame, 0.15, 2.6, 0.15, hex("6a6f78"), c[1], 1.3, c[2])
			end
			placed(kit, "ShedRoof", frame, 4.4, 0.15, 2.9, hex("2f9e6e"), 0, 2.7, 0)
			placed(kit, "ShedBench", frame, 3.4, 0.12, 0.6, hex("8a6a4a"), 0, 0.5, -0.8)
			placed(kit, "ShedBack", frame, 4, 1.2, 0.1, hex("e8e2d0"), 0, 1.2, -1.2)
		elseif p.kind == "bench" then
			placed(kit, "BenchSeat", frame, 2, 0.12, 0.6, hex("8a6a4a"), 0, 0.5, 0)
			placed(kit, "BenchBack", frame, 2, 0.5, 0.1, hex("8a6a4a"), 0, 0.85, -0.28)
			for _, x in { -0.85, 0.85 } do
				placed(kit, "BenchLeg", frame, 0.1, 0.5, 0.5, hex("4a5058"), x, 0.25, 0)
			end
		else
			placed(kit, "Bin", frame, 0.6, 0.9, 0.6, hex("2f7d5b"), 0, 0.45, 0)
		end
	end
	local fields = folder("Fields", world.RuralOutskirts)
	for _, f in WorldLayout.FIELDS do
		flat(fields, "Earth", f.w, f.d, hex("8a6a48"), f.x, f.z, LAYER.base)
		for x = f.x - f.w / 2 + 1.5, f.x + f.w / 2 - 1, 2.5 do
			flat(fields, "CropRow", 1.2, f.d - 2, hex("6fbf4a"), x, f.z, LAYER.detail)
		end
	end
	local wires = folder("UtilityPoles", world.TownCenter)
	for _, run in WorldLayout.poles() do
		for i, pole in run do
			block(wires, "Pole", 0.3, 8, 0.3, hex("7a6a58"), pole.x, 4, pole.z, Enum.Material.Wood)
			block(wires, "CrossArm", 1.8, 0.15, 0.15, hex("7a6a58"), pole.x, 7.6, pole.z, Enum.Material.Wood)
			local nextPole = run[i + 1]
			if nextPole then
				local a, b = WorldLayout.studs(pole.x, pole.z, 7.5), WorldLayout.studs(nextPole.x, nextPole.z, 7.5)
				local wire = block(wires, "Wire", 0.04, 0.04, 0.04, hex("222222"), 0, 0, 0)
				wire.Size = Vector3.new(0.12, 0.12, (b - a).Magnitude)
				wire.CFrame = CFrame.lookAt((a + b) / 2 - Vector3.new(0, 0.6, 0), b - Vector3.new(0, 0.6, 0))
				wire.CanCollide = false
			end
		end
	end
end

function WorldBuilder.build()
	clearTemplate()
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
	buildStreetlights()
	buildEventProps()
	buildProps()
end

return WorldBuilder

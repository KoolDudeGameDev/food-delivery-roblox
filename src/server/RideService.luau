-- Your ride: built from the prototype's shapes (with the parts you've bought showing), welded
-- under your character as an arcade ride (GDD §6.1: no vehicle physics), and parked at the gate
-- whenever you walk into a yard, so the last stretch is always on foot (pillar 1). Walk back
-- out and you're riding again. Toolbox art replaces a shape through Assets/Ride_<key>.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Shop = require(ReplicatedStorage.Shared.Shop)
local Vehicles = require(ReplicatedStorage.Shared.Data.Vehicles)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local DataService = require(script.Parent.DataService)
local MoveService = require(script.Parent.MoveService)
local WorldBuilder = require(script.Parent.WorldBuilder)

local RideService = {}

local S = Config.STUDS
local TICK = 0.1
local hex = Color3.fromHex
local DARK, STEEL = hex("222222"), hex("b8bec6")

type Ride = { key: string, model: Model, parkedAt: string? }
local rides: { [Player]: Ride } = {}
local parkedFolder: Folder

-- Shapes in metres, facing +z, wheels on the ground at y = 0.
local function build(key: string, lv: { [string]: number }, paint: Color3): Model
	local model = Instance.new("Model")
	model.Name = Vehicles.byKey[key].name
	if WorldBuilder.art(`Ride_{key}`, CFrame.new(), model) then
		model.WorldPivot = CFrame.new() -- art is authored with its pivot on the ground
		return model
	end
	local function box(w, h, d, color, x, y, z)
		return WorldBuilder.block(model, "Part", w, h, d, color, x, y, z)
	end
	local function wheel(r, w, z, x)
		local p = box(w, r * 2, r * 2, DARK, x or 0, r, z)
		p.Shape = Enum.PartType.Cylinder -- a cylinder's axis is x, which is the axle
	end
	local function sidecar()
		box(0.95, 0.5, 1.6, hex("d6402b"), 1.25, 0.62, -0.05)
		box(0.6, 0.4, 0.6, hex("b98a56"), 1.25, 1.05, -0.3)
		wheel(0.32, 0.16, 0, 1.25)
	end
	local n = function(part)
		return lv[part] or 0
	end
	if key == "rollerblades" then
		for _, x in { -0.24, 0.24 } do
			box(0.44, 0.16, 0.78, paint, x, 0.14 + n("wheels") * 0.05, 0)
			box(0.12, 0.1, 0.7, DARK, x, 0.05, 0)
		end
		if n("pack") > 0 then
			box(0.8, 0.9, 0.36, paint, 0, 1.85, -0.42)
		end
	elseif key == "skateboard" then
		local r = 0.09 + n("wheels") * 0.05
		box(0.7, 0.08, 1.7, paint, 0, r * 2 + 0.06, 0)
		for _, z in { -0.55, 0.55 } do
			for _, x in { -0.3, 0.3 } do
				wheel(r, 0.16, z, x)
			end
		end
		if n("crate") > 0 then
			box(0.6, 0.5, 0.6, hex("3f7fd6"), 0, r * 2 + 0.35, -0.6)
		end
	elseif key == "bicycle" then
		local r = 0.48 + n("tires") * 0.08
		for _, z in { -0.85, 0.85 } do
			wheel(r, 0.1 + n("tires") * 0.05, z)
		end
		box(0.12, 0.12, 1.6, paint, 0, 0.9, 0)
		box(0.95, 0.1, 0.1, DARK, 0, 1.45, 0.7)
		if n("basket") > 0 then
			box(0.65, 0.35, 0.5, hex("8a6a3a"), 0, 1.25, 1.05)
		end
		if n("sidecar") > 0 then
			sidecar()
		end
	elseif key == "moped" or key == "tricycle" then
		local r = 0.38
		for _, z in { -0.8, 0.85 } do
			wheel(r, 0.24, z)
		end
		box(0.6, 0.4, 1.7, paint, 0, 0.62, 0)
		box(0.62, 0.95, 0.16, paint, 0, 1.05, 0.72)
		box(0.95, 0.1, 0.1, DARK, 0, 1.55, 0.68)
		for i = 1, n("engine") do
			box(0.14, 0.14, 0.8, STEEL, 0.34 - (i - 1) * 0.34, 0.32, -0.75)
		end
		if key == "tricycle" then
			wheel(0.36, 0.24, 0, 1.3)
			box(1.4, 1.2, 1.6, paint, 1.3, 1.2, 0) -- the cab beside you
			box(1.6, 0.12, 1.8, hex("f2f2ee"), 1.3, 2.4, 0)
			if n("rack") > 0 then
				box(1.2, 0.4, 1.2, hex("b98a56"), 1.3, 2.7, 0)
			end
		else
			if n("topBox") > 0 then
				box(0.75, 0.6, 0.6, hex("ffd23f"), 0, 1.3, -0.8)
			end
			if n("sidecar") > 0 then
				sidecar()
			end
		end
	elseif key == "motorcycle" then
		for _, z in { -0.95, 1.05 } do
			wheel(0.46, 0.3, z)
		end
		box(0.55, 0.5, 1.5, paint, 0, 0.85, 0.1)
		box(0.5, 0.35, 0.7, paint, 0, 1.2, 0.35)
		box(1, 0.1, 0.1, DARK, 0, 1.55, 0.75)
		for _, s in { -1, 1 } do
			box(0.14, 0.14, 0.9, STEEL, s * 0.36, 0.45, -0.5)
			if n("bags") > 0 then
				box(0.26, 0.5, 0.7, hex("5a4636"), s * 0.44, 0.85, -0.55)
			end
		end
		for i = 1, n("engine") do
			box(0.2, 0.2, 0.3, STEEL, 0, 0.5, 0.5 - i * 0.3)
		end
	end
	model.WorldPivot = CFrame.new() -- the ground under the rider, facing +z
	return model
end

local function rootOf(player: Player): BasePart?
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function setLoose(model: Model)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, true
		end
	end
end

-- Rides under the character, welded to the root.
local function mount(player: Player, ride: Ride)
	local root = rootOf(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not (root and humanoid) then
		return
	end
	-- A character faces -z and the ride faces +z, hence the half turn
	local feet = root.CFrame * CFrame.new(0, -(humanoid.HipHeight + root.Size.Y / 2), 0) * CFrame.Angles(0, math.pi, 0)
	ride.model:PivotTo(feet)
	for _, p in ride.model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = false
			local weld = Instance.new("WeldConstraint")
			weld.Name = "RideWeld"
			weld.Part0, weld.Part1 = root, p
			weld.Parent = p
		end
	end
	ride.model.Parent = player.Character
	ride.parkedAt = nil
	local data = DataService.get(player)
	MoveService.setRide(player, if data then Shop.stats(data, ride.key).speed else nil)
end

-- Waits outside the gate, facing the road.
local function park(player: Player, ride: Ride, house)
	for _, w in ride.model:GetDescendants() do
		if w:IsA("WeldConstraint") and w.Name == "RideWeld" then
			w:Destroy()
		elseif w:IsA("BasePart") then
			w.Anchored = true
		end
	end
	local spot = WorldLayout.parkingSpot(house)
	ride.model:PivotTo(CFrame.new(WorldLayout.studs(spot.x, spot.z)) * CFrame.Angles(0, math.atan2(house.dx, house.dz), 0))
	ride.model.Parent = parkedFolder
	ride.parkedAt = house.id
	MoveService.setRide(player, nil)
end

-- Builds (or clears) the player's ride from their data: after buying, fitting or choosing.
function RideService.refresh(player: Player)
	local old = rides[player]
	if old then
		old.model:Destroy()
		rides[player] = nil
	end
	local data = DataService.get(player)
	if not (data and data.equipped ~= "") then
		MoveService.setRide(player, nil)
		return
	end
	local v = Vehicles.byKey[data.equipped]
	local model = build(v.key, data.parts[v.key] or {}, v.color)
	model.Name = `{player.Name}_{v.key}`
	setLoose(model)
	local ride = { key = v.key, model = model }
	rides[player] = ride
	local root = rootOf(player)
	local house = root and WorldLayout.yardAt(root.Position.X / S, root.Position.Z / S)
	if house then
		park(player, ride, house)
	else
		mount(player, ride)
	end
end

local function tick()
	for player, ride in rides do
		local root = rootOf(player)
		if not root then
			continue
		end
		local house = WorldLayout.yardAt(root.Position.X / S, root.Position.Z / S)
		if house and not ride.parkedAt then
			park(player, ride, house)
			ReplicatedStorage.Remotes.Notify:FireClient(player, { kind = "toast", text = "Parked at the gate. On foot from here!" })
		elseif not house and ride.parkedAt then
			mount(player, ride)
		end
	end
end

function RideService.start()
	parkedFolder = Instance.new("Folder")
	parkedFolder.Name = "ParkedRides"
	parkedFolder.Parent = workspace.Gameplay
	DataService.onLoaded(function(player)
		RideService.refresh(player)
	end)
	local function watch(player: Player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart")
			task.defer(RideService.refresh, player)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		local ride = rides[player]
		if ride then
			ride.model:Destroy()
			rides[player] = nil
		end
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= TICK then
			acc = 0
			tick()
		end
	end)
end

return RideService

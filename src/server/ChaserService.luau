-- The yard chasers (milestone 2). The server runs every dog with ChaserRules and decides every
-- bite (GDD §5.3). It publishes each dog's position as attributes (X, Z in metres, Yaw,
-- Chasing), and each client moves its own copy of the model smoothly (client/Chasers.luau).
-- Models come from Toolbox art (ServerStorage.Assets/Dog_<breed>) when vetted, else graybox.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ChaserRules = require(ReplicatedStorage.Shared.ChaserRules)
local Config = require(ReplicatedStorage.Shared.Config)
local DogBreeds = require(ReplicatedStorage.Shared.Data.DogBreeds)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local MoveService = require(script.Parent.MoveService)
local OrderService = require(script.Parent.OrderService)
local WorldBuilder = require(script.Parent.WorldBuilder)

local Remotes = ReplicatedStorage.Remotes

local ChaserService = {}

local S = Config.STUDS
local TICK = 0.1

type Entry = { dog: ChaserRules.Dog, model: Model, breed: any }
local entries: { Entry } = {}
local rng = Random.new()

-- A blocky dog (or goose), the prototype's shapes, facing +z with its feet at y = 0.
local function buildModel(parent: Instance, breedKey: string, at: { x: number, z: number }): Model
	local breed = DogBreeds[breedKey]
	local s = Config.DOG_TYPES[breed.size].scale
	local model = Instance.new("Model")
	model.Name = breed.name
	local art = WorldBuilder.art(`Dog_{breedKey}`, CFrame.new(WorldLayout.studs(at.x, at.z)), model)
	local dark, coat = Color3.fromHex("333333"), breed.coat
	local head
	local function part(name, w, h, d, color, x, y, z)
		local p = WorldBuilder.block(model, name, w * s, h * s, d * s, color, at.x + x * s, y * s, at.z + z * s)
		p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
		return p
	end
	if not art then
		if breedKey == "goose" then
			part("Body", 0.7, 0.6, 1.2, coat, 0, 0.75, 0)
			part("Neck", 0.26, 1, 0.26, coat, 0, 1.5, 0.55)
			head = part("Head", 0.34, 0.3, 0.46, coat, 0, 2.05, 0.66)
			part("Beak", 0.22, 0.12, 0.34, Color3.fromHex("f0883a"), 0, 2, 1)
			for _, x in { -0.18, 0.18 } do
				part("Leg", 0.12, 0.46, 0.12, Color3.fromHex("f0883a"), x, 0.23, 0)
			end
		else
			local y = 0.75
			part("Body", 0.6, 0.6, 1.4, coat, 0, y, 0)
			head = part("Head", 0.55, 0.5, 0.55, coat, 0, y + 0.4, 0.8)
			part("Muzzle", 0.3, 0.22, 0.3, dark, 0, y + 0.3, 1.15)
			for _, x in { -0.2, 0.2 } do
				part("Ear", 0.14, 0.28, 0.14, coat, x, y + 0.72, 0.75)
				for _, z in { -0.5, 0.5 } do
					part("Leg", 0.18, 0.5, 0.18, coat, x, 0.25, z)
				end
			end
			part("Tail", 0.12, 0.45, 0.12, coat, 0, y + 0.35, -0.75)
		end
		model.PrimaryPart = model:FindFirstChild("Body") :: BasePart
	end
	model.WorldPivot = CFrame.new(WorldLayout.studs(at.x, at.z))
	-- A red "!" over its head while it chases; the client shows it
	local alert = Instance.new("BillboardGui")
	alert.Name = "Alert"
	alert.Size = UDim2.fromOffset(90, 40) -- wide enough for "WOOF!" or "HONK!"
	alert.StudsOffsetWorldSpace = Vector3.new(0, (2.6 * s + 1) * S, 0)
	alert.AlwaysOnTop = true
	alert.Enabled = false
	local mark = Instance.new("TextLabel")
	mark.Size = UDim2.fromScale(1, 1)
	mark.BackgroundTransparency = 1
	mark.Text = "!"
	mark.TextScaled = true
	mark.Font = Enum.Font.FredokaOne
	mark.TextColor3 = Color3.fromHex("ff3b30")
	mark.Parent = alert
	alert.Adornee = head or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	alert.Parent = model
	model.Parent = parent
	return model
end

-- The house body as a rectangle, so dogs run round it.
local function bodyRect(h): ChaserRules.Rect
	local geo = WorldLayout.houseGeometry(h)
	local cx, cz = WorldLayout.frame(h)(0, geo.bodyV)
	local across, deep = geo.size.w / 2, geo.size.d / 2
	local hx = math.abs(h.dz) * across + math.abs(h.dx) * deep
	local hz = math.abs(h.dx) * across + math.abs(h.dz) * deep
	return { x0 = cx - hx, x1 = cx + hx, z0 = cz - hz, z1 = cz + hz }
end

local function runners(): ({ ChaserRules.Runner }, { [string]: Player })
	local list, byId = {}, {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			local id = tostring(player.UserId)
			local feet = (root.Position.Y - humanoid.HipHeight - root.Size.Y / 2) / S
			table.insert(list, { id = id, x = root.Position.X / S, z = root.Position.Z / S, feet = feet })
			byId[id] = player
		end
	end
	return list, byId
end

local function bite(player: Player, entry: Entry)
	local kind = Config.DOG_TYPES[entry.breed.size]
	local carrying = OrderService.carrying(player) > 0
	OrderService.hurt(player, kind.damage)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local away = Vector3.new(0, 0, 1)
	if root then
		local flat = Vector3.new(root.Position.X - entry.dog.x * S, 0, root.Position.Z - entry.dog.z * S)
		away = if flat.Magnitude > 0.01 then flat.Unit else away
	end
	Remotes.Notify:FireClient(player, {
		kind = "bite",
		text = if carrying then `{entry.breed.name} bit you! -{kind.damage}%` else `{entry.breed.name} bit you!`,
		knock = away * kind.knock * S + Vector3.new(0, 4 * S, 0),
	})
	MoveService.stun(player, kind.stun)
end

local function tick()
	local list, byId = runners()
	for _, entry in entries do
		local dog = entry.dog
		local awake = false
		for _, r in list do
			if (r.x - dog.x) ^ 2 + (r.z - dog.z) ^ 2 < Config.DOG_WAKE ^ 2 then
				awake = true
				break
			end
		end
		if not awake then
			if dog.chasing then
				dog.chasing, dog.alert = nil, 0
				entry.model:SetAttribute("Chasing", false)
				entry.model:SetAttribute("State", "idle")
			end
			continue
		end
		local result = ChaserRules.step(dog, list, TICK, rng)
		entry.model:SetAttribute("X", dog.x)
		entry.model:SetAttribute("Z", dog.z)
		entry.model:SetAttribute("Yaw", dog.yaw)
		entry.model:SetAttribute("Chasing", dog.chasing ~= nil)
		entry.model:SetAttribute("State", ChaserRules.state(dog)) -- the client's posture: idle, alert or chase
		if result.started and byId[result.started] then
			Remotes.Notify:FireClient(byId[result.started], { kind = "toast", text = `{entry.breed.call or "WOOF!"} Run!` })
		end
		if result.bite and byId[result.bite] then
			entry.model:SetAttribute("BiteAt", workspace:GetServerTimeNow()) -- clients play the lunge
			bite(byId[result.bite], entry)
		end
	end
end

function ChaserService.start()
	local folder = Instance.new("Folder")
	folder.Name = "Chasers"
	folder.Parent = workspace.Gameplay
	for _, h in WorldLayout.HOUSES do
		if h.dog then
			local breed = DogBreeds[h.dog]
			local dog = ChaserRules.new(h, breed.size, bodyRect(h))
			local model = buildModel(folder, h.dog, dog.home)
			model:SetAttribute("HouseId", h.id)
			model:SetAttribute("X", dog.x)
			model:SetAttribute("Z", dog.z)
			model:SetAttribute("Yaw", 0)
			model:SetAttribute("Chasing", false)
			model:SetAttribute("State", "idle")
			model:SetAttribute("Call", breed.call or "WOOF!")
			model:SetAttribute("Sound", breed.sound or "bark") -- a key in Data/Sounds
			table.insert(entries, { dog = dog, model = model, breed = breed })
		end
	end
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= TICK then
			acc = 0
			tick()
		end
	end)
end

return ChaserService

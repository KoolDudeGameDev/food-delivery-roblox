-- Police (GDD Appendix A; prototype `police.js`). Two cars patrol the ring roads, one each way.
-- They ignore you unless you carry a shady package (NightJobService); then a car that sees you
-- comes for you. A yard hides you, and a car never drives in through a gate. An arrest takes a
-- share of your cash and every order you carry, and puts you back at the hub. The server runs the
-- cars with PoliceRules at 10 Hz and publishes X, Z, Yaw and Mode; each client smooths its copy
-- and flashes the lights (client/Police.luau).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local PoliceRules = require(ReplicatedStorage.Shared.PoliceRules)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local ChaserService = require(script.Parent.ChaserService)
local DataService = require(script.Parent.DataService)
local MoveService = require(script.Parent.MoveService)
local OrderService = require(script.Parent.OrderService)
local WorldBuilder = require(script.Parent.WorldBuilder)

local PoliceService = {}

local S = Config.STUDS
local TICK = 0.1
local ARREST_STUN = 1 -- s

-- The prototype's car, facing +z: w, h, d, colour, centre x, y, z, name (metres)
local BODY = {
	{ 2.2, 0.75, 4.6, "f1f2f4", 0, 0.75, 0, "Body" },
	{ 2.24, 0.3, 2, "1c2c52", 0, 0.8, 0, "Stripe" },
	{ 1.95, 0.7, 2.3, "24303f", 0, 1.45, -0.2, "Cabin" },
	{ 2.35, 0.6, 0.75, "151515", 0, 0.32, -1.5, "Wheels" },
	{ 2.35, 0.6, 0.75, "151515", 0, 0.32, 1.5, "Wheels" },
	{ 0.8, 0.24, 0.4, "e0352b", -0.45, 1.92, -0.2, "Red" },
	{ 0.8, 0.24, 0.4, "2f7de0", 0.45, 1.92, -0.2, "Blue" },
}

local function build(parent: Instance, name: string, car): Model
	local model = Instance.new("Model")
	model.Name = name
	for _, b in BODY do
		local part = WorldBuilder.block(model, b[8], b[1], b[2], b[3], Color3.fromHex(b[4]), car.x + b[5], b[6], car.z + b[7])
		part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
	end
	model.WorldPivot = CFrame.new(WorldLayout.studs(car.x, car.z))
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Parent = parent
	return model
end

function PoliceService.start()
	local folder = Instance.new("Folder")
	folder.Name = "Police"
	folder.Parent = workspace.Gameplay
	local rng = Random.new()
	local cars = {}
	for i, spec in { { WorldLayout.RING, 1 }, { WorldLayout.OUTER, -1 } } do
		local car = PoliceRules.new(spec[1], spec[2], rng:NextNumber(0, (spec[1] - Config.POLICE_LANE) * 8))
		table.insert(cars, { car = car, model = build(folder, `PoliceCar{i}`, car) })
	end
	local graceUntil: { [Player]: number } = {}
	local Notify = ReplicatedStorage.Remotes.Notify

	local function arrest(player: Player)
		local data = DataService.get(player)
		if not data then
			return
		end
		local lost = math.floor(data.cash * Config.ARREST_COST)
		data.cash -= lost
		DataService.changed(player)
		OrderService.clearAll(player)
		graceUntil[player] = os.clock() + Config.POLICE_GRACE
		for _, c in cars do
			if c.car.target == tostring(player.UserId) then
				c.car.mode, c.car.target = "back", nil
			end
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			root.CFrame = CFrame.new(WorldLayout.studs(WorldLayout.HUB.x, WorldLayout.HUB.z + 3, 1.5))
			root.AssemblyLinearVelocity = Vector3.zero
		end
		MoveService.stun(player, ARREST_STUN)
		Notify:FireClient(player, { kind = "bite", text = `Arrested! -₱{lost}` })
	end

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < TICK then
			return
		end
		acc = 0
		local list, byId = ChaserService.runners()
		local now = os.clock()
		local runners = {}
		for _, r in list do
			local player = byId[r.id]
			table.insert(runners, {
				id = r.id,
				x = r.x,
				z = r.z,
				wanted = OrderService.wanted(player) and now >= (graceUntil[player] or 0),
				hidden = WorldLayout.yardAt(r.x, r.z) ~= nil,
			})
		end
		for _, c in cars do
			local result = PoliceRules.step(c.car, runners, TICK)
			c.model:SetAttribute("X", c.car.x)
			c.model:SetAttribute("Z", c.car.z)
			c.model:SetAttribute("Yaw", c.car.yaw)
			c.model:SetAttribute("Mode", c.car.mode)
			if result.spotted and byId[result.spotted] then
				Notify:FireClient(byId[result.spotted], { kind = "toast", text = "Police! Run for it!" })
			elseif result.escaped and byId[result.escaped] then
				Notify:FireClient(byId[result.escaped], { kind = "toast", text = "You lost them" })
			elseif result.arrested and byId[result.arrested] then
				arrest(byId[result.arrested])
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		graceUntil[player] = nil
	end)
end

return PoliceService

-- Customer gates that open for the delivery (Blueprint §7.3, §13). A gate opens while someone
-- carrying an order for that house is close, or while anyone is inside the yard (so nobody is
-- ever shut in), and closes a moment after. Walk up to the wrong gate with orders in hand and it
-- stays shut and tells you so. The server owns open and shut (the leaves stop colliding); each
-- client swings the leaves (client/Gates.luau).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local OrderService = require(script.Parent.OrderService)

local GateService = {}

local S = Config.STUDS
local TICK = 0.2
local OPEN_REACH = 10 -- m from the gate at which it opens for the right order
local TELL_REACH = 4 -- m: walking right up to the wrong gate
local HOLD = 2 -- s it stays open after the last reason to be open
local TELL_GAP = 8 -- s between "wrong house" notes for one player at one gate

type Gate = { model: Model, house: any, x: number, z: number, openUntil: number }
local gates: { Gate } = {}
local told: { [Player]: { [string]: number } } = {}

local function setOpen(gate: Gate, open: boolean)
	if gate.model:GetAttribute("Open") == open then
		return
	end
	gate.model:SetAttribute("Open", open)
	for _, leaf in gate.model:GetChildren() do
		if leaf:IsA("BasePart") then
			leaf.CanCollide = not open
		end
	end
end

local function tick()
	local now = os.clock()
	local here = {}
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			table.insert(here, { player = player, x = root.Position.X / S, z = root.Position.Z / S })
		end
	end
	for _, gate in gates do
		local y = gate.house.yard
		for _, p in here do
			local d2 = (p.x - gate.x) ^ 2 + (p.z - gate.z) ^ 2
			local inside = p.x > y.x0 and p.x < y.x1 and p.z > y.z0 and p.z < y.z1
			local theirs = OrderService.carriesFor(p.player, gate.house.id)
			if inside or (theirs and d2 < OPEN_REACH ^ 2) then
				gate.openUntil = now + HOLD
			elseif d2 < TELL_REACH ^ 2 and OrderService.carrying(p.player) > 0 then
				local notes = told[p.player] or {}
				told[p.player] = notes
				if now - (notes[gate.house.id] or -math.huge) > TELL_GAP then
					notes[gate.house.id] = now
					ReplicatedStorage.Remotes.Notify:FireClient(p.player, { kind = "toast", text = `No order for the {gate.house.name} house` })
				end
			end
		end
		setOpen(gate, now < gate.openUntil)
	end
end

function GateService.start()
	local seen = {}
	for _, leaf in CollectionService:GetTagged("GateLeaf") do
		local model = leaf.Parent :: Model
		local id = model:GetAttribute("HouseId")
		local house = id and WorldLayout.byId[id]
		if house and not seen[model] then
			seen[model] = true
			local x, z = WorldLayout.frame(house)(0, WorldLayout.HOUSE_SIZES[house.size].yardV)
			table.insert(gates, { model = model, house = house, x = x, z = z, openUntil = 0 })
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		told[player] = nil
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

return GateService

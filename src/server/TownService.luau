-- The living town's bumps and fines (prototype `traffic.js`, `citizens.js`). Vehicles and walkers
-- follow TownRules from the server clock, so nobody needs their positions sent; the server checks
-- every frame who ran into what. A jeepney or tricycle bumps you (orders lose TRAFFIC_DAMAGE, a
-- knock and a short stun). Running into a walker fast sends them flying: a fine, and your orders
-- lose HIT_DAMAGE. Every client is told, so they all see that walker fly (client/Town).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local TownRules = require(ReplicatedStorage.Shared.TownRules)
local DataService = require(script.Parent.DataService)
local MoveService = require(script.Parent.MoveService)
local OrderService = require(script.Parent.OrderService)
local WorldService = require(script.Parent.WorldService)

local TownService = {}

local S = Config.STUDS
local bumpedAt: { [Player]: number } = {}
local downUntil: { [number]: number } = {} -- walker index: fallen until (server time)

local function step()
	local t = workspace:GetServerTimeNow()
	local night = WorldService.isNight()
	local Notify = ReplicatedStorage.Remotes.Notify
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not (root and humanoid and humanoid.Health > 0) then
			continue
		end
		local v = root.AssemblyLinearVelocity / S
		local runner = {
			x = root.Position.X / S,
			z = root.Position.Z / S,
			vx = v.X,
			vz = v.Z,
			feet = (root.Position.Y - humanoid.HipHeight - root.Size.Y / 2) / S,
		}
		if os.clock() - (bumpedAt[player] or -math.huge) > Config.TRAFFIC_COOLDOWN then
			for i, vehicle in TownRules.VEHICLES do
				local x, z = TownRules.vehicleAt(i, t)
				if TownRules.bumps(vehicle, x, z, runner) then
					bumpedAt[player] = os.clock()
					OrderService.hurt(player, Config.TRAFFIC_DAMAGE)
					local away = Vector3.new(runner.x - x, 0, runner.z - z)
					away = if away.Magnitude > 0.01 then away.Unit else Vector3.new(0, 0, 1)
					Notify:FireClient(player, {
						kind = "bite",
						text = "Watch the road!",
						knock = away * Config.TRAFFIC_KNOCK * S + Vector3.new(0, 5 * S, 0),
					})
					MoveService.stun(player, Config.TRAFFIC_STUN)
					break
				end
			end
		end
		for i in TownRules.WALKERS do
			if not TownRules.walkerOut(i, night) or t < (downUntil[i] or 0) then
				continue
			end
			local wx, wz = TownRules.walkerAt(i, t)
			if TownRules.hitsWalker(runner, wx, wz) then
				downUntil[i] = t + Config.WALKER_FALL
				local data = DataService.get(player)
				local fine = if data then TownRules.fine(data.cash) else 0
				if data and fine > 0 then
					data.cash -= fine
					DataService.changed(player)
				end
				OrderService.hurt(player, Config.HIT_DAMAGE) -- also pushes the new cash
				local pace = math.sqrt(runner.vx ^ 2 + runner.vz ^ 2)
				Notify:FireAllClients({
					kind = "walkerHit",
					index = i,
					fling = Vector3.new(runner.vx * 0.8, 5 + pace * 0.15, runner.vz * 0.8) * S,
					down = Config.WALKER_FALL,
				})
				Notify:FireClient(player, { kind = "bite", text = `Hoy! Watch it! -₱{fine}` })
			end
		end
	end
end

function TownService.start()
	RunService.Heartbeat:Connect(step)
	Players.PlayerRemoving:Connect(function(player)
		bumpedAt[player] = nil
	end)
end

return TownService

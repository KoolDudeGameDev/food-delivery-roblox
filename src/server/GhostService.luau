-- The White Lady (GDD §5.1; prototype `ghost.js`). The server runs her with GhostRules at 10 Hz and
-- decides every scare, like a dog's bite: orders lose GHOST_DAMAGE of their condition, and you're
-- knocked back and stunned for a moment. She publishes X, Z, Yaw and Shown as attributes; each
-- client floats its copy of her (client/Ghost.luau).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local GhostRules = require(ReplicatedStorage.Shared.GhostRules)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local ChaserService = require(script.Parent.ChaserService)
local MoveService = require(script.Parent.MoveService)
local OrderService = require(script.Parent.OrderService)
local WorldBuilder = require(script.Parent.WorldBuilder)
local WorldService = require(script.Parent.WorldService)

local GhostService = {}

local S = Config.STUDS
local TICK = 0.1

-- The prototype's figure: a pale dress in three tiers, a head, and long black hair, facing +z,
-- in metres: w, h, d, colour, centre y, centre z.
local PIECES = {
	{ 1.5, 0.9, 1.1, "e9edf2", 0.75, 0 },
	{ 1.2, 0.9, 0.85, "f1f4f7", 1.5, 0 },
	{ 0.95, 0.9, 0.6, "f7f9fb", 2.3, 0 },
	{ 0.68, 0.68, 0.68, "d6dee4", 3, 0 },
	{ 0.76, 1.7, 0.3, "0b0d10", 2.5, -0.36 },
	{ 0.76, 0.3, 0.76, "0b0d10", 3.4, 0 },
}

local function build(parent: Instance, at: { x: number, z: number }): Model
	local model = Instance.new("Model")
	model.Name = "WhiteLady"
	for _, p in PIECES do
		local part = WorldBuilder.block(model, "Piece", p[1], p[2], p[3], Color3.fromHex(p[4]), at.x, p[5], at.z + p[6])
		part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
		part.CastShadow = false
		part.Transparency = 1 -- the client shows her
		-- The dress glows faintly in the dark; the hair stays black
		part.Material = if p[4] == "0b0d10" then Enum.Material.SmoothPlastic else Enum.Material.Neon
	end
	model.WorldPivot = CFrame.new(WorldLayout.studs(at.x, at.z))
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Parent = parent
	return model
end

function GhostService.start()
	local cem = WorldLayout.CEMETERY
	local yard = { x0 = cem.x0, x1 = cem.x1, z0 = cem.z0, z1 = cem.z1 }
	local start = { x = 74.5 + cem.ox, z = 83 + cem.oz } -- the prototype's spot, just inside the gate
	local lady = GhostRules.new(yard, start)
	local folder = Instance.new("Folder")
	folder.Name = "Ghosts"
	folder.Parent = workspace.Gameplay
	local model = build(folder, start)
	local function publish()
		model:SetAttribute("X", lady.x)
		model:SetAttribute("Z", lady.z)
		model:SetAttribute("Yaw", lady.yaw)
		model:SetAttribute("Shown", GhostRules.shown(lady))
	end
	publish()
	local Notify = ReplicatedStorage.Remotes.Notify
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < TICK then
			return
		end
		acc = 0
		local list, byId = ChaserService.runners()
		local touchX, touchZ = lady.x, lady.z -- where she is before a scare sends her away
		local result = GhostRules.step(lady, list, WorldService.isNight(), TICK)
		publish()
		if result.appeared then
			for _, r in list do
				if r.x > yard.x0 and r.x < yard.x1 and r.z > yard.z0 and r.z < yard.z1 then
					Notify:FireClient(byId[r.id], { kind = "toast", text = "Someone is standing by the graves..." })
				end
			end
		end
		local player = result.scared and byId[result.scared]
		if player then
			local carrying = OrderService.carrying(player) > 0
			OrderService.hurt(player, Config.GHOST_DAMAGE)
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local away = Vector3.new(0, 0, 1)
			if root then
				-- Away from where she touched them (she has already gone to the far corner)
				local flat = Vector3.new(root.Position.X - touchX * S, 0, root.Position.Z - touchZ * S)
				away = if flat.Magnitude > 0.01 then flat.Unit else away
			end
			Notify:FireClient(player, {
				kind = "bite", -- the same red toast and knockback as a bite
				text = if carrying then `The White Lady! -{Config.GHOST_DAMAGE}%` else "The White Lady!",
				knock = away * Config.GHOST_KNOCK * S + Vector3.new(0, Config.GHOST_LIFT * S, 0),
			})
			MoveService.stun(player, Config.GHOST_STUN)
		end
	end)
end

return GhostService

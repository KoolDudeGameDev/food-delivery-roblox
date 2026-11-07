-- Moves this client's copy of each chaser smoothly to where the server says it is (the X, Z,
-- Yaw and Chasing attributes ChaserService sets), with a bounce while it chases. Moving a
-- server-built model here is local only; the server never moves the models itself.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Chasers = {}

local S = Config.STUDS
local shown: { [Model]: CFrame } = {}
local folder: Instance?

function Chasers.start()
	task.spawn(function()
		folder = workspace:WaitForChild("Gameplay"):WaitForChild("Chasers")
	end)
end

function Chasers.step(dt: number, clock: number)
	if not folder then
		return
	end
	local blend = math.min(1, dt * 10)
	for _, model in folder:GetChildren() do
		if not model:IsA("Model") then
			continue
		end
		local x, z, yaw = model:GetAttribute("X"), model:GetAttribute("Z"), model:GetAttribute("Yaw")
		if not (x and z and yaw) then
			continue
		end
		local chasing = model:GetAttribute("Chasing") == true
		local hop = if chasing then math.abs(math.sin(clock * 14)) * 0.25 * S else 0
		local target = CFrame.new(x * S, hop, z * S) * CFrame.Angles(0, yaw, 0)
		local from = shown[model] or target
		local now = from:Lerp(target, blend)
		shown[model] = now
		model:PivotTo(now)
		local alert = model:FindFirstChild("Alert")
		if alert then
			(alert :: BillboardGui).Enabled = chasing
		end
	end
	for model in shown do
		if not model.Parent then
			shown[model] = nil -- streamed out
		end
	end
end

return Chasers

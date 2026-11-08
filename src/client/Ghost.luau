-- Floats this client's copy of the White Lady (GhostService): she glides after her server
-- position, bobs gently, and fades in and out with the server's Shown. Local only.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Ghost = {}

local S = Config.STUDS
local SEEN = 0.4 -- transparency when she's out: her Neon dress still glows, and the tombs show through
local folder: Instance?
local shown: { [Model]: CFrame } = {}
local fade: { [Model]: number } = {}

function Ghost.start()
	task.spawn(function()
		folder = workspace:WaitForChild("Gameplay"):WaitForChild("Ghosts")
	end)
end

function Ghost.step(dt: number, clock: number)
	if not folder then
		return
	end
	for _, model in folder:GetChildren() do
		if not model:IsA("Model") then
			continue
		end
		local x, z, yaw = model:GetAttribute("X"), model:GetAttribute("Z"), model:GetAttribute("Yaw")
		if not (x and z and yaw) then
			continue
		end
		local bob = (0.35 + math.sin(clock * 2) * 0.18) * S
		local target = CFrame.new(x * S, bob, z * S) * CFrame.Angles(0, yaw, 0)
		local was = shown[model]
		-- Glide between the server's steps; jump straight there when she reappears elsewhere
		local now = if was and (was.Position - target.Position).Magnitude < 4 * S then was:Lerp(target, math.min(1, dt * 10)) else target
		shown[model] = now
		model:PivotTo(now)
		local goal = if model:GetAttribute("Shown") then SEEN else 1
		local t = fade[model] or 1
		t += math.clamp(goal - t, -dt * 3, dt * 3)
		fade[model] = t
		for _, part in model:GetChildren() do
			if part:IsA("BasePart") then
				part.Transparency = t
			end
		end
	end
	for model in shown do
		if not model.Parent then
			shown[model], fade[model] = nil, nil
		end
	end
end

return Ghost

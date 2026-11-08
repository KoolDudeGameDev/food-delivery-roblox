-- Drives this client's copy of each police car (PoliceService): it glides after the server's
-- position, and the light bar flashes red and blue, fast in a chase. Local only.
local Police = {}

local S = 3
local RED, BLUE, DIM = Color3.fromHex("ff2015"), Color3.fromHex("1d6dff"), Color3.fromHex("3a3f48")

local folder: Instance?
local shown: { [Model]: CFrame } = {}

function Police.start()
	task.spawn(function()
		folder = workspace:WaitForChild("Gameplay"):WaitForChild("Police")
	end)
end

function Police.step(dt: number, clock: number)
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
		local target = CFrame.new(x * S, 0, z * S) * CFrame.Angles(0, yaw, 0)
		local was = shown[model]
		local now = if was and (was.Position - target.Position).Magnitude < 12 * S then was:Lerp(target, math.min(1, dt * 10)) else target
		shown[model] = now
		model:PivotTo(now)
		local chase = model:GetAttribute("Mode") == "chase"
		local flash = math.floor(clock / (if chase then 0.11 else 0.32)) % 2 == 0
		local red, blue = model:FindFirstChild("Red") :: BasePart?, model:FindFirstChild("Blue") :: BasePart?
		if red and blue then
			red.Material, blue.Material = Enum.Material.Neon, Enum.Material.Neon
			red.Color = if flash then RED else DIM
			blue.Color = if flash then DIM else BLUE
		end
	end
	for model in shown do
		if not model.Parent then
			shown[model] = nil
		end
	end
end

return Police

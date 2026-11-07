-- Moves and animates this client's copy of each chaser: the model glides to where the server
-- says the dog is (the X, Z, Yaw and Chasing attributes ChaserService sets), legs swing as it
-- runs (the prototype's walk cycle), its tail wags, faster while chasing, and it bounds when it
-- chases. Moving a server-built model here is local only; the server never moves them itself.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Chasers = {}

local S = Config.STUDS

type Rig = {
	parts: { BasePart },
	offsets: { CFrame }, -- each part relative to the model's pivot
	joints: { CFrame? }, -- where a leg or tail turns, relative to the pivot
	kinds: { string },
	shown: CFrame,
	phase: number,
}
local rigs: { [Model]: Rig } = {}
local folder: Instance?

function Chasers.start()
	task.spawn(function()
		folder = workspace:WaitForChild("Gameplay"):WaitForChild("Chasers")
	end)
end

local function rigOf(model: Model): Rig
	local rig = rigs[model]
	if rig then
		return rig
	end
	local pivot = model:GetPivot()
	rig = { parts = {}, offsets = {}, joints = {}, kinds = {}, shown = pivot, phase = 0 }
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			local offset = pivot:ToObjectSpace(p.CFrame)
			local kind, joint = "body", nil
			if p.Name == "Leg" then
				kind, joint = "leg", offset * CFrame.new(0, p.Size.Y / 2, 0) -- the hip
			elseif p.Name == "Tail" then
				kind, joint = "tail", offset * CFrame.new(0, -p.Size.Y / 2, 0) -- the root
			end
			table.insert(rig.parts, p)
			table.insert(rig.offsets, offset)
			table.insert(rig.joints, joint)
			table.insert(rig.kinds, kind)
		end
	end
	rigs[model] = rig
	return rig
end

function Chasers.step(dt: number, clock: number)
	if not folder then
		return
	end
	local blend = math.min(1, dt * 10)
	local parts, frames = {}, {}
	for _, model in folder:GetChildren() do
		if not model:IsA("Model") then
			continue
		end
		local x, z, yaw = model:GetAttribute("X"), model:GetAttribute("Z"), model:GetAttribute("Yaw")
		if not (x and z and yaw) then
			continue
		end
		local rig = rigOf(model)
		local chasing = model:GetAttribute("Chasing") == true
		local target = CFrame.new(x * S, 0, z * S) * CFrame.Angles(0, yaw, 0)
		local before = rig.shown.Position
		rig.shown = rig.shown:Lerp(target, blend)
		local moved = (rig.shown.Position - before).Magnitude / S
		rig.phase += moved * 2.4 -- the prototype's 2.4 radians of stride per metre
		local swing = if moved > 0.002 then math.sin(rig.phase) * 0.9 else 0
		local hop = if chasing then math.abs(math.sin(rig.phase)) * 0.25 * S else 0
		local wag = math.sin(clock * (if chasing then 20 else 6)) * 0.6
		local base = rig.shown * CFrame.new(0, hop, 0)
		for i, part in rig.parts do
			local offset, joint = rig.offsets[i], rig.joints[i]
			local frame
			if rig.kinds[i] == "leg" and joint then
				local turn = if i % 2 == 0 then swing else -swing
				frame = base * joint * CFrame.Angles(turn, 0, 0) * joint:Inverse() * offset
			elseif rig.kinds[i] == "tail" and joint then
				frame = base * joint * CFrame.Angles(0, wag, 0) * joint:Inverse() * offset
			else
				frame = base * offset
			end
			table.insert(parts, part)
			table.insert(frames, frame)
		end
		local alert = model:FindFirstChild("Alert")
		if alert then
			(alert :: BillboardGui).Enabled = chasing
		end
	end
	if #parts > 0 then
		workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
	end
	for model in rigs do
		if not model.Parent then
			rigs[model] = nil -- streamed out; rebuilt from its pivot when it streams back
		end
	end
end

return Chasers

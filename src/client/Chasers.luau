-- Moves and animates this client's copy of each chaser, so its body says what it's about to do
-- (Blueprint §9.2 rule 2, §13): idle, it wanders with a lazy wag; alert, it freezes facing you,
-- head and tail up, barking ("WOOF!" over its head); chasing, it bounds with its legs going and a
-- "!" overhead; and it lunges when it bites. Positions come from ChaserService's attributes;
-- moving a server-built model here is local only.
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

-- Paths and doorsteps sit a little above the grass, so each dog stands on whatever flat ground
-- is under it. The ray starts below the fences, so it only finds the ground layers.
local ground = RaycastParams.new()
ground.FilterType = Enum.RaycastFilterType.Include
ground.RespectCanCollide = true

local function groundAt(x: number, z: number): number
	local hit = workspace:Raycast(Vector3.new(x, 2, z), Vector3.new(0, -4, 0), ground)
	return if hit then hit.Position.Y else 0
end

function Chasers.start()
	task.spawn(function()
		local gameplay = workspace:WaitForChild("Gameplay")
		ground.FilterDescendantsInstances = { workspace:WaitForChild("World"), gameplay:WaitForChild("CustomerHouses") }
		folder = gameplay:WaitForChild("Chasers")
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
			elseif p.Name == "Head" or p.Name == "Ear" or p.Name == "Muzzle" or p.Name == "Neck" or p.Name == "Beak" then
				kind = "head"
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
		local state = model:GetAttribute("State") or "idle"
		local chasing = state == "chase"
		local alert = state == "alert"
		-- A lunge for a quarter second after a bite
		local biteAt = model:GetAttribute("BiteAt")
		local since = if biteAt then workspace:GetServerTimeNow() - biteAt else math.huge
		local lunge = if since < 0.25 then math.sin(since / 0.25 * math.pi) * 0.6 * S else 0
		local target = CFrame.new(x * S, groundAt(x * S, z * S), z * S) * CFrame.Angles(0, yaw, 0) * CFrame.new(0, 0, lunge)
		local before = rig.shown.Position
		rig.shown = rig.shown:Lerp(target, blend)
		local moved = (rig.shown.Position - before).Magnitude / S
		rig.phase += moved * 2.4 -- the prototype's 2.4 radians of stride per metre
		local swing = if moved > 0.002 then math.sin(rig.phase) * 0.9 else 0
		local hop = if chasing then math.abs(math.sin(rig.phase)) * 0.25 * S else 0
		local wag = math.sin(clock * (if chasing or alert then 20 else 6)) * 0.6
		local base = rig.shown * CFrame.new(0, hop, 0)
		-- Alert: head up and a little bark bob; the tail stands up
		local raise = if alert then CFrame.new(0, (0.18 + math.abs(math.sin(clock * 14)) * 0.08) * S, 0) else CFrame.new()
		for i, part in rig.parts do
			local offset, joint = rig.offsets[i], rig.joints[i]
			local frame
			if rig.kinds[i] == "leg" and joint then
				local turn = if i % 2 == 0 then swing else -swing
				frame = base * joint * CFrame.Angles(turn, 0, 0) * joint:Inverse() * offset
			elseif rig.kinds[i] == "tail" and joint then
				local up = if alert then CFrame.Angles(-0.8, 0, 0) else CFrame.new()
				frame = base * joint * up * CFrame.Angles(0, wag, 0) * joint:Inverse() * offset
			elseif rig.kinds[i] == "head" then
				frame = base * raise * offset
			else
				frame = base * offset
			end
			table.insert(parts, part)
			table.insert(frames, frame)
		end
		local bubble = model:FindFirstChild("Alert") :: BillboardGui?
		if bubble then
			bubble.Enabled = alert or chasing
			local label = bubble:FindFirstChildOfClass("TextLabel")
			if label then
				label.Text = if alert then model:GetAttribute("Call") or "WOOF!" else "!"
			end
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

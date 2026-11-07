-- A column of light over where you're going, and a beam to it from your feet: the doorstep of
-- each order you carry, or the order board when you carry none. Local parts, seen only by you.
local Players = game:GetService("Players")

local Waypoint = {}

local YELLOW = Color3.fromHex("ffd23f")
local GREEN = Color3.fromHex("4dff88")

local markers: { Instance } = {}

local function column(at: Vector3, color: Color3)
	local part = Instance.new("Part")
	part.Name = "Waypoint"
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(48, 8, 8)
	part.CFrame = CFrame.new(at + Vector3.new(0, 24, 0)) * CFrame.Angles(0, 0, math.rad(90))
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Transparency = 0.6
	part.Parent = workspace.CurrentCamera
	table.insert(markers, part)

	local root = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if root then
		local from = Instance.new("Attachment")
		from.Name = "WaypointFrom"
		from.Position = Vector3.new(0, -2.5, 0)
		from.Parent = root
		local to = Instance.new("Attachment")
		to.Position = Vector3.new(-24, 0, 0) -- the column's foot, in its turned frame
		to.Parent = part
		local beam = Instance.new("Beam")
		beam.Attachment0, beam.Attachment1 = from, to
		beam.Color = ColorSequence.new(color)
		beam.Width0, beam.Width1 = 0.6, 0.6
		beam.Transparency = NumberSequence.new(0.45)
		beam.FaceCamera = true
		beam.Parent = part
		table.insert(markers, from)
	end
end

function Waypoint.onState(state)
	for _, m in markers do
		m:Destroy()
	end
	markers = {}
	if #state.orders == 0 then
		column(state.hub, GREEN)
	end
	for _, order in state.orders do
		column(order.target, YELLOW)
	end
end

return Waypoint

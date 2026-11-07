-- The warehouse conveyor (Blueprint §13): boxes ride the belt along the counter to the yellow
-- pickup point, all the time, so the warehouse reads as the place orders come from. When you
-- take an order, your red food bag or brown parcel comes down the belt, then hops to you; the
-- server has already put it in your arms. Local only.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)

local Conveyor = {}

local S = Config.STUDS
local SPEED = 2.5 -- m/s along the belt
local EVERY = 1.4 -- s between boxes
local COLORS = { Color3.fromHex("b98a56"), Color3.fromHex("c99a5e"), Color3.fromHex("a87b4a") }

local w = WorldLayout.WAREHOUSE
local beltZ = w.z + w.d / 2 - 0.6
local startX, pickupX = w.x - w.w / 2 + 1.5, w.x
local boxes: { { part: Part, x: number } } = {}
local sinceLast = 0
local folder: Folder

local function makeBox(color: Color3, size: number): Part
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Size = Vector3.new(size, size * 0.75, size) * S
	p.Color = color
	p.Parent = folder
	return p
end

local function at(x: number, size: number): CFrame
	return CFrame.new(WorldLayout.studs(x, beltZ, 1.31 + size * 0.375))
end

function Conveyor.start()
	folder = Instance.new("Folder")
	folder.Name = "Conveyor"
	folder.Parent = workspace.CurrentCamera
end

function Conveyor.step(dt: number)
	-- Only worth animating when you're near the warehouse
	local root = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local near = root and (root.Position - WorldLayout.studs(w.x, w.z)).Magnitude < 90 * S
	if not near then
		return
	end
	sinceLast += dt
	if sinceLast >= EVERY then
		sinceLast = 0
		table.insert(boxes, { part = makeBox(COLORS[math.random(#COLORS)], 0.6), x = startX })
	end
	for i = #boxes, 1, -1 do
		local b = boxes[i]
		b.x += SPEED * dt
		if b.x >= pickupX then
			b.part:Destroy() -- taken off at the pickup point
			table.remove(boxes, i)
		else
			b.part.CFrame = at(b.x, 0.6)
		end
	end
end

-- Your order comes down the belt to the pickup point, then hops into your arms.
function Conveyor.accepted(food: boolean)
	local size = if food then 0.7 else 0.8
	local box = makeBox(if food then Color3.fromHex("d6402b") else Color3.fromHex("b98a56"), size)
	box.Material = Enum.Material.Neon -- it stands out from the background boxes
	box.CFrame = at(pickupX - 3, size)
	local slide = TweenService:Create(box, TweenInfo.new(0.5), { CFrame = at(pickupX, size) })
	slide:Play()
	slide.Completed:Wait()
	local root = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		local hop = TweenService:Create(box, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			CFrame = root.CFrame * CFrame.new(0, 0.5 * S, -0.85 * S),
			Size = box.Size * 0.8,
		})
		hop:Play()
		hop.Completed:Wait()
	end
	box:Destroy()
end

return Conveyor

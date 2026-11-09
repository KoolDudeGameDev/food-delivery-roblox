-- Swings gate leaves open and shut as the server's Open attribute changes, and, after a
-- delivery, opens the customer's front door and pops the pay over the doorstep. Local only:
-- the server decides who may pass (GateService) and what was paid (OrderService).
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)

local Gates = {}

local SWING = math.rad(100)
local closed: { [BasePart]: CFrame } = {}

-- The open position: turned about its hinge, whichever way swings it into the yard.
local function openFrame(leaf: BasePart, shut: CFrame, inward: Vector3): CFrame
	local hinge = leaf:GetAttribute("Hinge") :: Vector3
	local pivot = CFrame.new(hinge.X, shut.Position.Y, hinge.Z)
	local best, bestD
	for _, sign in { 1, -1 } do
		local frame = pivot * CFrame.Angles(0, sign * SWING, 0) * pivot:Inverse() * shut
		local d = (frame.Position - inward).Magnitude
		if not bestD or d < bestD then
			best, bestD = frame, d
		end
	end
	return best
end

local function swing(gate: Model)
	local open = gate:GetAttribute("Open") == true
	local inward = gate:GetAttribute("Inward") :: Vector3?
	for _, leaf in gate:GetChildren() do
		if leaf:IsA("BasePart") and leaf:GetAttribute("Hinge") and inward then
			local shut = closed[leaf] or leaf.CFrame
			closed[leaf] = shut
			local goal = if open then openFrame(leaf, shut, inward) else shut
			TweenService:Create(leaf, TweenInfo.new(0.45, Enum.EasingStyle.Quad), { CFrame = goal }):Play()
		end
	end
end

local function watch(leaf: Instance)
	local gate = leaf.Parent
	if gate and gate:IsA("Model") and not gate:GetAttribute("Watched") then
		gate:SetAttribute("Watched", true) -- local only
		gate:GetAttributeChangedSignal("Open"):Connect(function()
			swing(gate)
		end)
		if gate:GetAttribute("Open") then
			swing(gate)
		end
	end
end

function Gates.start()
	for _, leaf in CollectionService:GetTagged("GateLeaf") do
		watch(leaf)
	end
	CollectionService:GetInstanceAddedSignal("GateLeaf"):Connect(watch) -- leaves streaming in
end

-- After a paid delivery: the door swings open, and "+₱74" rises from the doorstep.
function Gates.delivered(houseId: string, total: number)
	local house = WorldLayout.byId[houseId]
	if not house then
		return
	end
	local houses = workspace:FindFirstChild("Gameplay") and workspace.Gameplay:FindFirstChild("CustomerHouses")
	for _, model in if houses then houses:GetChildren() else {} do
		local door = model:GetAttribute("HouseId") == houseId and model:FindFirstChild("Door", true) :: BasePart?
		if door then
			local shut = door.CFrame
			local hinge = shut * CFrame.new(-door.Size.X / 2, 0, 0)
			local open = hinge * CFrame.Angles(0, math.rad(-85), 0) * hinge:Inverse() * shut
			TweenService:Create(door, TweenInfo.new(0.3), { CFrame = open }):Play()
			task.delay(1.6, function()
				TweenService:Create(door, TweenInfo.new(0.4), { CFrame = shut }):Play()
			end)
		end
	end
	local anchor = Instance.new("Part")
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = WorldLayout.studs(house.step.x, house.step.z, 2.5)
	anchor.Parent = workspace.CurrentCamera
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(140, 50)
	gui.AlwaysOnTop = true
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromHex("ffd23f")
	label.TextStrokeTransparency = 0.2
	label.Text = `+₱{total}`
	label.Parent = gui
	TweenService:Create(anchor, TweenInfo.new(1.4, Enum.EasingStyle.Quad), { Position = anchor.Position + Vector3.new(0, 9, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(1.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1.5, function()
		anchor:Destroy()
	end)
end

return Gates

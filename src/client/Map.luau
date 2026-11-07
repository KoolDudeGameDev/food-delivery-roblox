-- The town map, drawn from WorldLayout: a north-up minimap in the top-right corner that follows
-- you, and a full town map with district names (tap the minimap or press M). Both show you,
-- your house, every delivery you carry, the order board, the shops and the cemetery.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local Ui = require(script.Parent.Ui)

local Map = {}

local S = Config.STUDS
local EDGE = WorldLayout.EDGE
local hex = Color3.fromHex

export type Pin = { x: number, z: number, icon: string, color: Color3, key: string }

local DISTRICT_NAMES = {
	{ "Town Center", 0, -78 },
	{ "Residential East", 78, 0 },
	{ "Residential West", -78, 0 },
	{ "Rural Outskirts", 0, -195 },
	{ "Rural Outskirts", 0, 195 },
	{ "Cemetery", -148, 236 },
}

local View = {}
View.__index = View

local function rectFrame(parent, x0, z0, x1, z1, ppm, color, z)
	return Ui.make("Frame", {
		Parent = parent,
		Position = UDim2.fromOffset((x0 + EDGE) * ppm, (z0 + EDGE) * ppm),
		Size = UDim2.fromOffset(math.max(1, (x1 - x0) * ppm), math.max(1, (z1 - z0) * ppm)),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = z,
	})
end

local function newView(holder: GuiObject, follow: boolean, range: number?)
	local self = setmetatable({ holder = holder, follow = follow, range = range or 90, pins = {}, ppm = 1 }, View)
	self.canvas = Ui.make("Frame", { Parent = holder, BackgroundColor3 = hex("7dc777"), BorderSizePixel = 0, ZIndex = 1 })
	self.overlay = Ui.make("Frame", { Parent = holder, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 10 })
	self.me = Ui.label("▲", 18, hex("1f2329"), {
		Parent = self.overlay,
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutomaticSize = Enum.AutomaticSize.None,
		Size = UDim2.fromOffset(20, 20),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.2,
		TextStrokeColor3 = Color3.new(1, 1, 1),
		ZIndex = 13,
	})
	holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:draw()
	end)
	self:draw()
	return self
end

function View:draw()
	local size = self.holder.AbsoluteSize
	if size.X < 1 then
		return
	end
	self.ppm = if self.follow then size.X / (2 * self.range) else math.min(size.X, size.Y) / (2 * EDGE)
	local ppm, canvas = self.ppm, self.canvas
	canvas:ClearAllChildren()
	canvas.Size = UDim2.fromOffset(2 * EDGE * ppm, 2 * EDGE * ppm)
	for _, r in WorldLayout.ROADS do
		local color = if r.dirt then hex("c9a878") else hex("5a5f6a")
		rectFrame(canvas, r.x - r.w / 2, r.z - r.d / 2, r.x + r.w / 2, r.z + r.d / 2, ppm, color, 2)
	end
	local plaza = rectFrame(canvas, -15, -15, 15, 15, ppm, hex("cfd3da"), 3)
	Ui.corner(1000).Parent = plaza
	for _, h in WorldLayout.HOUSES do
		local y = h.yard
		local color = if h.id == "cemetery" then hex("8fa08a") else h.color:Lerp(Color3.new(1, 1, 1), 0.45)
		rectFrame(canvas, y.x0, y.z0, y.x1, y.z1, ppm, color, 3)
	end
	for _, p in WorldLayout.footprints() do
		if p.kind == "lot" then
			rectFrame(canvas, p.x0, p.z0, p.x1, p.z1, ppm, hex("b9a27a"), 3)
		elseif p.kind == "building" or p.kind == "stall" or p.kind == "hub" and p.name ~= "Plaza" then
			rectFrame(canvas, p.x0, p.z0, p.x1, p.z1, ppm, hex("9aa0aa"), 4)
		elseif p.name == "Pond" then
			rectFrame(canvas, p.x0, p.z0, p.x1, p.z1, ppm, hex("3f97d6"), 4)
		elseif p.kind == "ground" then
			rectFrame(canvas, p.x0, p.z0, p.x1, p.z1, ppm, hex("c96f3a"), 4)
		end
	end
	if not self.follow then
		for _, d in DISTRICT_NAMES do
			Ui.label(d[1]:upper(), 12, hex("1f2329"), {
				Parent = canvas,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset((d[2] + EDGE) * ppm, (d[3] + EDGE) * ppm),
				TextTransparency = 0.25,
				ZIndex = 6,
			})
		end
	end
end

-- Where a point in metres is on the holder, before any clamping.
function View:toScreen(x: number, z: number): Vector2
	local pos = self.canvas.AbsolutePosition - self.holder.AbsolutePosition
	return Vector2.new(pos.X + (x + EDGE) * self.ppm, pos.Y + (z + EDGE) * self.ppm)
end

function View:update(meX: number, meZ: number, heading: number, pins: { Pin })
	local size = self.holder.AbsoluteSize
	local span = 2 * EDGE * self.ppm
	if self.follow then
		self.canvas.Position = UDim2.fromOffset(size.X / 2 - (meX + EDGE) * self.ppm, size.Y / 2 - (meZ + EDGE) * self.ppm)
	else
		self.canvas.Position = UDim2.fromOffset((size.X - span) / 2, (size.Y - span) / 2)
	end
	local seen = {}
	for _, pin in pins do
		seen[pin.key] = true
		local label = self.pins[pin.key]
		if not label then
			label = Ui.make("TextLabel", {
				Parent = self.overlay,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(22, 22),
				BackgroundColor3 = pin.color,
				Text = pin.icon,
				TextSize = 13,
				Font = Enum.Font.GothamBold,
				TextColor3 = Color3.new(1, 1, 1),
				ZIndex = 12,
			}, { Ui.corner(11), Ui.make("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1.5 }) })
			self.pins[pin.key] = label
		end
		local at = self:toScreen(pin.x, pin.z)
		if self.follow then
			-- Off the minimap: held at its edge, so you can still see which way to go
			at = Vector2.new(math.clamp(at.X, 11, size.X - 11), math.clamp(at.Y, 11, size.Y - 11))
		end
		label.Position = UDim2.fromOffset(at.X, at.Y)
	end
	for key, label in self.pins do
		if not seen[key] then
			label:Destroy()
			self.pins[key] = nil
		end
	end
	local me = self:toScreen(meX, meZ)
	self.me.Position = UDim2.fromOffset(me.X, me.Y)
	self.me.Rotation = math.deg(heading)
end

local mini, full, fullPanel
local orders = {}

local function fixedPins(): { Pin }
	local list = {
		{ key = "hub", x = WorldLayout.HUB.x, z = WorldLayout.HUB.z, icon = "📋", color = hex("2f9e6e") },
		{ key = "dealer", x = WorldLayout.SHOPS.dealer.x, z = WorldLayout.SHOPS.dealer.z, icon = "🛵", color = hex("ff9a3f") },
		{ key = "mechanic", x = WorldLayout.SHOPS.mechanic.x, z = WorldLayout.SHOPS.mechanic.z, icon = "🔧", color = hex("35b8a8") },
	}
	local c = WorldLayout.CEMETERY
	table.insert(list, { key = "cemetery", x = (c.x0 + c.x1) / 2, z = (c.z0 + c.z1) / 2, icon = "✝", color = hex("6a6f78") })
	local lotId = Players.LocalPlayer:GetAttribute("LotId")
	for _, lot in WorldLayout.LOTS do
		if lot.id == lotId then
			table.insert(list, { key = "home", x = lot.x, z = lot.z, icon = "🏠", color = hex("3f7fd6") })
		end
	end
	for _, o in orders do
		table.insert(list, { key = o.id, x = o.target.X / S, z = o.target.Z / S, icon = if o.food then "🍲" else "📦", color = hex("e8a400") })
	end
	return list
end

function Map.open()
	fullPanel.Visible = true
end

function Map.close()
	fullPanel.Visible = false
end

function Map.toggle()
	fullPanel.Visible = not fullPanel.Visible
end

function Map.mount(screen: ScreenGui)
	local miniHolder = Ui.make("Frame", {
		Name = "Minimap",
		Parent = screen,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.fromOffset(150, 150),
		BackgroundColor3 = hex("7dc777"),
		ClipsDescendants = true,
	}, { Ui.corner(14), Ui.make("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 3 }) })
	mini = newView(miniHolder, true, 90)
	local tap = Ui.make("TextButton", {
		Parent = miniHolder,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 20,
	})
	tap.Activated:Connect(Map.open)
	Ui.label("MAP (M)", 11, Color3.new(1, 1, 1), {
		Parent = miniHolder,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -3),
		TextStrokeTransparency = 0.3,
		ZIndex = 15,
	})

	fullPanel = Ui.make("Frame", {
		Name = "TownMap",
		Parent = screen,
		Visible = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.94, 0.9),
		BackgroundColor3 = Ui.PANEL,
		ZIndex = 30,
	}, { Ui.corner(16), Ui.pad(10), Ui.make("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }) })
	local fullHolder = Ui.make("Frame", {
		Parent = fullPanel,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = hex("7dc777"),
		ClipsDescendants = true,
	}, { Ui.corner(10) })
	full = newView(fullHolder, false)
	local close = Ui.make("TextButton", {
		Parent = fullPanel,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -4, 0, 4),
		Size = UDim2.fromOffset(44, 44),
		Text = "✕",
		TextSize = 22,
		Font = Enum.Font.GothamBold,
		TextColor3 = Ui.INK,
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 40,
	}, { Ui.corner(22) })
	close.Activated:Connect(Map.close)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.M then
			Map.toggle()
		end
	end)
end

function Map.onState(state)
	orders = state.orders
end

function Map.step()
	local root = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local look = root.CFrame.LookVector
	local heading = math.atan2(look.X, -look.Z) -- 0 is north (up), clockwise like the UI
	local x, z = root.Position.X / S, root.Position.Z / S
	local pins = fixedPins()
	mini:update(x, z, heading, pins)
	if fullPanel.Visible then
		full:update(x, z, heading, pins)
	end
end

return Map

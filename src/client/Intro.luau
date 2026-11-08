-- The intro, every time you join (prototype `intro.js`): a rider name and a look, then Play. You
-- keep your own Roblox avatar unless you pick the rider outfit. Each change goes to the server
-- (LookService), which checks it, saves it and dresses you, so what you see is what others see.
-- While it's open the camera faces your rider from the front, beside the panel.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Homes = require(ReplicatedStorage.Shared.Data.Homes)
local Looks = require(ReplicatedStorage.Shared.Data.Looks)
local Ui = require(script.Parent.Ui)

local Intro = {}

local player = Players.LocalPlayer
local SWAY, FAR, SIDE = 0.45, 11, 4 -- radians either way, studs out front, studs aside for the panel

local PLAY_H = 52 -- px, the Play button under the panel

local panel: ScrollingFrame
local playButton: TextButton
local note: TextLabel
local nameBox: TextBox
local styleRows: Frame
local choice: { [string]: TextButton } = {}
local look: Looks.Look = Looks.default()
local opened = false
local onPlay: ((string) -> ())? = nil
local hidden: { GuiObject } = {} -- the HUD, map and hints, out of the way while the intro is up

local function send()
	ReplicatedStorage.Remotes.Intro:FireServer(nameBox.Text, look)
end

local function setControls(enabled: boolean)
	task.spawn(function()
		local module = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 5)
		local ok, controls = pcall(function()
			return require(module :: ModuleScript):GetControls()
		end)
		if ok and controls then
			if enabled then
				controls:Enable()
			else
				controls:Disable()
			end
		end
	end)
end

local function button(text: string, color: Color3, textColor: Color3, props: { [string]: any }): TextButton
	local base = {
		Text = text,
		TextSize = 17,
		Font = Enum.Font.GothamBold,
		TextColor3 = textColor,
		BackgroundColor3 = color,
		AutoButtonColor = true,
	}
	for k, v in props do
		base[k] = v
	end
	return Ui.make("TextButton", base, { Ui.corner(10) })
end

local function renderChoice()
	for key, b in choice do
		local on = (key == "outfit") == look.outfit
		b.BackgroundColor3 = if on then Ui.ACCENT else Color3.fromHex("e6e1d6")
		b.TextColor3 = if on then Color3.new(1, 1, 1) else Ui.INK
	end
	styleRows.Visible = look.outfit
end

-- One row of swatches: Skin, Shirt, Pants or Cap
local function swatchRow(order: number, label: string, field: string, colors: { Color3 })
	local row = Ui.make("Frame", {
		Parent = styleRows,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, { Ui.make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })
	Ui.label(label, 14, Ui.MUTED, { Parent = row, LayoutOrder = 0 })
	local strip = Ui.make("Frame", {
		Parent = row,
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, { Ui.make("UIGridLayout", { CellSize = UDim2.fromOffset(36, 36), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local swatches = {}
	local function render()
		for i, s in swatches do
			local stroke = s:FindFirstChildOfClass("UIStroke") :: UIStroke
			stroke.Thickness = if look[field] == i then 3 else 1
			stroke.Color = if look[field] == i then Ui.INK else Color3.fromHex("c9c3b6")
		end
	end
	for i, color in colors do
		local s = Ui.make("TextButton", {
			Parent = strip,
			LayoutOrder = i,
			Text = "",
			BackgroundColor3 = color,
			AutoButtonColor = true,
		}, { Ui.corner(18), Ui.make("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) })
		s.Activated:Connect(function()
			look[field] = i
			render()
			send()
		end)
		swatches[i] = s
	end
	render()
end

function Intro.mount(screen: ScreenGui)
	panel = Ui.make("ScrollingFrame", {
		Name = "Intro",
		Parent = screen,
		Visible = false,
		Position = UDim2.new(0, 16, 0, 16),
		Size = UDim2.new(0.46, 0, 0, 0), -- its height follows the content, up to the screen (fit below)
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		BorderSizePixel = 0,
		BackgroundColor3 = Ui.PANEL,
	}, {
		Ui.corner(16),
		Ui.pad(16),
		Ui.make("UISizeConstraint", { MaxSize = Vector2.new(400, math.huge) }),
	})
	-- As tall as its content, but never taller than the screen: on a short phone screen it scrolls
	local layout = Ui.make("UIListLayout", { Parent = panel, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
	local function refit()
		local tall = layout.AbsoluteContentSize.Y + 32 -- the padding, top and bottom
		panel.Size = UDim2.new(0.46, 0, 0, math.min(tall, math.max(160, screen.AbsoluteSize.Y - 42 - PLAY_H)))
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refit)
	screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(refit)
	refit()
	Ui.label("Deliver a Parcel", 28, Ui.INK, { Parent = panel, LayoutOrder = 0, Font = Enum.Font.FredokaOne })
	note = Ui.label("", 15, Ui.MUTED, {
		Parent = panel,
		LayoutOrder = 1,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		Font = Enum.Font.Gotham,
	})
	Ui.label("Your name", 14, Ui.MUTED, { Parent = panel, LayoutOrder = 2 })
	nameBox = Ui.make("TextBox", {
		Parent = panel,
		LayoutOrder = 3,
		Size = UDim2.new(1, -8, 0, 44),
		Text = "",
		PlaceholderText = player.DisplayName,
		ClearTextOnFocus = false,
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		TextColor3 = Ui.INK,
		PlaceholderColor3 = Ui.MUTED,
		BackgroundColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, { Ui.corner(10), Ui.make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })
	-- At most 12 characters, as the server allows
	nameBox:GetPropertyChangedSignal("Text"):Connect(function()
		local text = nameBox.Text
		local length = utf8.len(text)
		if length and length > Looks.NAME_MAX then
			nameBox.Text = text:sub(1, (utf8.offset(text, Looks.NAME_MAX + 1) :: number) - 1)
		end
	end)
	nameBox.FocusLost:Connect(send)

	Ui.label("Your look", 14, Ui.MUTED, { Parent = panel, LayoutOrder = 4 })
	local switch = Ui.make("Frame", {
		Parent = panel,
		LayoutOrder = 5,
		Size = UDim2.new(1, -8, 0, 44),
		BackgroundTransparency = 1,
	}, { Ui.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }) })
	for _, key in { "avatar", "outfit" } do
		local b = button(if key == "avatar" then "My avatar" else "Rider outfit", Ui.PANEL, Ui.INK, {
			Parent = switch,
			LayoutOrder = if key == "avatar" then 1 else 2,
			Size = UDim2.new(0.5, -3, 1, 0),
		})
		b.Activated:Connect(function()
			look.outfit = key == "outfit"
			renderChoice()
			send()
		end)
		choice[key] = b
	end
	styleRows = Ui.make("Frame", {
		Parent = panel,
		LayoutOrder = 6,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, { Ui.make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })

	-- Play sits under the panel, never scrolled out of sight
	playButton = button("Play", Ui.GOOD, Color3.new(1, 1, 1), {
		Name = "IntroPlay",
		Parent = screen,
		Visible = false,
		Position = UDim2.new(0, 16, 0, 16),
		Size = UDim2.new(0.46, 0, 0, PLAY_H),
		TextSize = 22,
	})
	Ui.make("UISizeConstraint", { Parent = playButton, MaxSize = Vector2.new(400, PLAY_H) })
	local function underPanel()
		playButton.Position = UDim2.new(0, 16, 0, 16 + panel.AbsoluteSize.Y + 10)
	end
	panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(underPanel)
	underPanel()
	playButton.Activated:Connect(function()
		send()
		Intro.close()
	end)
end

-- The camera stands in front of the rider, a little aside so the rider shows beside the panel
local function frame()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local turn = math.sin(os.clock() * 0.4) * SWAY
	local facing = root.CFrame * CFrame.Angles(0, turn, 0)
	local eye = facing.Position + facing.LookVector * FAR + Vector3.new(0, 2.5, 0)
	workspace.CurrentCamera.CFrame = CFrame.lookAt(eye, root.Position + Vector3.new(0, 1.5, 0)) * CFrame.new(-SIDE, 0, 0)
end

function Intro.open(state)
	opened = true
	look = Looks.clean(state.look) or Looks.default()
	nameBox.Text = state.name or ""
	note.Text = if (state.delivered or 0) == 0 and (state.homeTier or 1) == 1
		then "You start with a cardboard box somewhere in town. Deliver food and parcels, dodge the dogs, and build it into a mansion."
		else `₱{state.cash} · {state.delivered} deliveries · {Homes[state.homeTier].name}`
	renderChoice()
	local paints = {}
	for i, p in Looks.PAINTS do
		paints[i] = p.color
	end
	swatchRow(1, "Skin", "skin", Looks.SKINS)
	swatchRow(2, "Shirt", "shirt", paints)
	swatchRow(3, "Pants", "pants", paints)
	swatchRow(4, "Cap", "hat", paints)
	for _, other in (panel.Parent :: Instance):GetChildren() do
		if other ~= panel and other:IsA("GuiObject") and other.Visible then
			other.Visible = false
			table.insert(hidden, other)
		end
	end
	panel.Visible, playButton.Visible = true, true
	setControls(false)
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	RunService:BindToRenderStep("Intro", Enum.RenderPriority.Camera.Value + 1, frame)
end

function Intro.close()
	panel.Visible, playButton.Visible = false, false
	for _, other in hidden do
		other.Visible = true
	end
	table.clear(hidden)
	RunService:UnbindFromRenderStep("Intro")
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	setControls(true)
	local name = nameBox.Text:match("^%s*(.-)%s*$")
	if onPlay then
		onPlay(if name == "" then player.DisplayName else name)
	end
end

-- The first state after joining opens the intro, with what you picked last time
function Intro.onState(state, then_: (string) -> ())
	if not opened then
		onPlay = then_
		Intro.open(state)
	end
end

return Intro

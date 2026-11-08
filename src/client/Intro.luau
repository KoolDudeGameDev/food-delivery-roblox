-- The intro, every time you join (prototype `intro.js`): a rider name, then Play. Players keep
-- their own Roblox avatar. The name goes to the server (NameService), which checks it, saves it
-- and shows it, filtered, over your head. While it's open the camera faces your rider from the
-- front, beside the panel, and the HUD waits.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Homes = require(ReplicatedStorage.Shared.Data.Homes)
local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
local Ui = require(script.Parent.Ui)

local Intro = {}

local player = Players.LocalPlayer
local SWAY, FAR, SIDE = 0.45, 11, 4 -- radians either way, studs out front, studs aside for the panel

local panel: Frame
local note: TextLabel
local nameBox: TextBox
local opened = false
local onPlay: ((string) -> ())? = nil
local hidden: { GuiObject } = {} -- the HUD, map and hints, out of the way while the intro is up

local function send()
	ReplicatedStorage.Remotes.Intro:FireServer(nameBox.Text)
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

function Intro.mount(screen: ScreenGui)
	panel = Ui.make("Frame", {
		Name = "Intro",
		Parent = screen,
		Visible = false,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
		Size = UDim2.new(0.46, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Ui.PANEL,
	}, {
		Ui.corner(16),
		Ui.pad(16),
		Ui.make("UISizeConstraint", { MaxSize = Vector2.new(400, math.huge) }),
		Ui.make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	Ui.label("Deliver a Parcel", 28, Ui.INK, { Parent = panel, LayoutOrder = 0, Font = Enum.Font.FredokaOne })
	note = Ui.label("", 15, Ui.MUTED, {
		Parent = panel,
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		Font = Enum.Font.Gotham,
	})
	Ui.label("Your name", 14, Ui.MUTED, { Parent = panel, LayoutOrder = 2 })
	nameBox = Ui.make("TextBox", {
		Parent = panel,
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 44),
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
		if length and length > PlayerData.NAME_MAX then
			nameBox.Text = text:sub(1, (utf8.offset(text, PlayerData.NAME_MAX + 1) :: number) - 1)
		end
	end)
	nameBox.FocusLost:Connect(send)
	local play = Ui.make("TextButton", {
		Parent = panel,
		LayoutOrder = 4,
		Size = UDim2.new(1, 0, 0, 52),
		Text = "Play",
		TextSize = 22,
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = Ui.GOOD,
	}, { Ui.corner(10) })
	play.Activated:Connect(function()
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
	nameBox.Text = state.name or ""
	note.Text = if (state.delivered or 0) == 0 and (state.homeTier or 1) == 1
		then "You start with a cardboard box somewhere in town. Deliver food and parcels, dodge the dogs, and build it into a mansion."
		else `₱{state.cash} · {state.delivered} deliveries · {Homes[state.homeTier].name}`
	for _, other in (panel.Parent :: Instance):GetChildren() do
		if other ~= panel and other:IsA("GuiObject") and other.Visible then
			other.Visible = false
			table.insert(hidden, other)
		end
	end
	panel.Visible = true
	setControls(false)
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	RunService:BindToRenderStep("Intro", Enum.RenderPriority.Camera.Value + 1, frame)
end

function Intro.close()
	panel.Visible = false
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

-- The first state after joining opens the intro, with the name you picked last time
function Intro.onState(state, then_: (string) -> ())
	if not opened then
		onPlay = then_
		Intro.open(state)
	end
end

return Intro

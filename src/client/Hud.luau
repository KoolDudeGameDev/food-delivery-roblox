-- The HUD, laid out like the prototype: a small stats card top left (cash, stamina, rating,
-- streak), the job card top centre (an arrow to the next door, distance, the order, its time
-- and freshness bars), toasts in the middle, and a hint line at the bottom.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Ui = require(script.Parent.Ui)

local Hud = {}

local PANEL = Color3.fromRGB(12, 20, 34) -- the prototype's --panel, at 62% opacity
local PANEL_T = 0.38
local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromHex("ffd23f")
local S = Config.STUDS

local cashLabel: TextLabel
local staminaFill: Frame
local ratingTag: TextLabel
local streakTag: TextLabel
local job: Frame
local arrow: TextLabel
local distLabel: TextLabel
local orderName: TextLabel
local timeLeft: TextLabel
local timeFill: Frame
local freshFill: Frame
local moreLabel: TextLabel
local hint: TextLabel
local toastFrame: Frame
local current = { orders = {} }

local function text(parent, value: string, size: number, color: Color3?, order: number?, props: { [string]: any }?)
	local base = { Parent = parent, LayoutOrder = order or 0, TextStrokeTransparency = 0.6, TextStrokeColor3 = Color3.new(0, 0, 0) }
	for k, v in props or {} do
		base[k] = v
	end
	return Ui.label(value, size, color or WHITE, base)
end

-- A thin bar with a dark track, as in the prototype; returns the fill.
local function bar(parent, color: Color3, order: number, width: number): Frame
	local track = Ui.make("Frame", {
		Parent = parent,
		LayoutOrder = order,
		Size = UDim2.fromOffset(width, 9),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.55,
		ClipsDescendants = true,
	}, { Ui.corner(5) })
	return Ui.make("Frame", { Parent = track, Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BorderSizePixel = 0 }, { Ui.corner(5) })
end

local function card(parent, name: string, props: { [string]: any }): Frame
	local base = {
		Name = name,
		Parent = parent,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = PANEL,
		BackgroundTransparency = PANEL_T,
	}
	for k, v in props do
		base[k] = v
	end
	return Ui.make("Frame", base, {
		Ui.corner(14),
		Ui.make("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}),
	})
end

local function list(parent, padding: number, horizontal: boolean?)
	Ui.make("UIListLayout", {
		Parent = parent,
		Padding = UDim.new(0, padding),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		VerticalAlignment = if horizontal then Enum.VerticalAlignment.Center else Enum.VerticalAlignment.Top,
	})
end

function Hud.mount(screen: ScreenGui)
	-- Stats, top left
	local stats = card(screen, "Stats", { Position = UDim2.fromOffset(12, 10) })
	Ui.make("UISizeConstraint", { Parent = stats, MinSize = Vector2.new(154, 0), MaxSize = Vector2.new(200, math.huge) })
	list(stats, 2)
	cashLabel = text(stats, "₱0", 26, WHITE, 1, { Font = Enum.Font.GothamBold })
	text(stats, "Stamina", 12, WHITE, 2, { Font = Enum.Font.Gotham })
	staminaFill = bar(stats, Color3.fromHex("6cc6ff"), 3, 130)
	ratingTag = text(stats, "", 12, GOLD, 4, { Font = Enum.Font.Gotham })
	streakTag = text(stats, "", 12, GOLD, 5, { Font = Enum.Font.Gotham })

	-- The job card, top centre
	job = card(screen, "Job", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Visible = false })
	list(job, 12, true)
	local nav = Ui.make("Frame", { Parent = job, LayoutOrder = 1, AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1 })
	list(nav, 0)
	arrow = text(nav, "▲", 34, GOLD, 1, { TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromOffset(40, 36), AutomaticSize = Enum.AutomaticSize.None })
	distLabel = text(nav, "", 13, WHITE, 2, { TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromOffset(40, 16), AutomaticSize = Enum.AutomaticSize.None })
	local info = Ui.make("Frame", { Parent = job, LayoutOrder = 2, AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1 })
	list(info, 2)
	orderName = text(info, "", 15, WHITE, 1)
	timeLeft = text(info, "", 12, WHITE, 2, { Font = Enum.Font.Gotham })
	timeFill = bar(info, GOLD, 3, 150)
	text(info, "Freshness", 12, WHITE, 4, { Font = Enum.Font.Gotham })
	freshFill = bar(info, Color3.fromHex("5ee07a"), 5, 150)
	moreLabel = text(info, "", 12, Color3.fromHex("a7b3c2"), 6, { Font = Enum.Font.Gotham })

	-- Toasts in the middle, a hint at the bottom
	toastFrame = Ui.make("Frame", {
		Name = "Toasts",
		Parent = screen,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.3, 0),
		Size = UDim2.new(0.6, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	})
	Ui.make("UIListLayout", { Parent = toastFrame, Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center })
	hint = text(screen, "", 15, WHITE, 0, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Enum.Font.GothamMedium,
	})
end

function Hud.toast(message: string, color: Color3?)
	local toast = Ui.make("Frame", {
		Parent = toastFrame,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = color or PANEL,
		BackgroundTransparency = if color then 0.1 else PANEL_T,
	}, { Ui.corner(12), Ui.pad(8) })
	local label = Ui.label(message, 17, WHITE, { Parent = toast, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center })
	Ui.make("UISizeConstraint", { Parent = label, MaxSize = Vector2.new(400, math.huge) })
	task.delay(3, function()
		toast:Destroy()
	end)
end

function Hud.onNotify(message)
	if message.kind == "toast" then
		Hud.toast(message.text)
	elseif message.kind == "bite" then
		Hud.toast(message.text, Color3.fromHex("d6402b"))
	elseif message.kind == "paid" then
		local extra = if message.night then " night pay" else ""
		Hud.toast(`{Ui.stars(message.rating)}  +₱{message.total}{extra}`, Ui.GOOD)
		if message.regularNow then
			Hud.toast(`{message.regularNow} is a regular now! +10% there`, Ui.ACCENT)
		end
	end
end

function Hud.onState(state)
	current = state
	cashLabel.Text = `₱{state.cash}`
	ratingTag.Text = if state.rating then `★ {string.format("%.1f", state.rating)} rating` else ""
	ratingTag.Visible = state.rating ~= nil
	streakTag.Text = if state.streak > 0 then `Streak {state.streak}` else ""
	streakTag.Visible = state.streak > 0
	job.Visible = #state.orders > 0
	hint.Text = if #state.orders == 0 then "Pick up an order at the board (green on the map)" else ""
end

-- The order the job card follows: the nearest door.
local function nearest(root: BasePart)
	local best, bestD
	for _, o in current.orders do
		local d = (Vector3.new(o.target.X, root.Position.Y, o.target.Z) - root.Position).Magnitude
		if not bestD or d < bestD then
			best, bestD = o, d
		end
	end
	return best, bestD
end

-- Every frame: the stamina bar and the job card.
function Hud.step(serverNow: number)
	local player = Players.LocalPlayer
	local stamina = (player:GetAttribute("Stamina") or 100) / 100
	staminaFill.Size = UDim2.fromScale(math.clamp(stamina, 0, 1), 1)
	staminaFill.BackgroundColor3 = if player:GetAttribute("Winded") then Ui.ACCENT else Color3.fromHex("6cc6ff")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (job.Visible and root) then
		return
	end
	local order, dist = nearest(root)
	if not order then
		return
	end
	-- The arrow turns with the camera: straight up means straight ahead
	local look = workspace.CurrentCamera.CFrame.LookVector
	local to = order.target - root.Position
	local angle = math.atan2(look.X * to.Z - look.Z * to.X, look.X * to.X + look.Z * to.Z)
	arrow.Rotation = math.deg(angle)
	distLabel.Text = `{math.round(dist / S)} m`
	local left = order.deadline - serverNow
	orderName.Text = order.title
	timeLeft.Text = `{Ui.clock(left)} left`
	timeLeft.TextColor3 = if left < 5 then Color3.fromHex("ff6b5b") else WHITE
	timeFill.Size = UDim2.fromScale(math.clamp(left / order.max, 0, 1), 1)
	freshFill.Size = UDim2.fromScale(math.clamp(order.fresh / 100, 0, 1), 1)
	moreLabel.Text = if #current.orders > 1 then `+{#current.orders - 1} more` else ""
	moreLabel.Visible = #current.orders > 1
end

return Hud

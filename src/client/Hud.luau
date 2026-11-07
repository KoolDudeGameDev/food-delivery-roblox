-- Cash, the orders you carry with their countdown, and toasts from the server.
local Ui = require(script.Parent.Ui)

local Hud = {}

local gui: ScreenGui
local cashLabel: TextLabel
local streakLabel: TextLabel
local staminaFill: Frame
local ordersFrame: Frame
local toastFrame: Frame
local rows: { [string]: TextLabel } = {}
local current = { orders = {} }

function Hud.mount(screen: ScreenGui)
	gui = screen
	local top = Ui.make("Frame", {
		Name = "Top",
		Parent = gui,
		Position = UDim2.new(0, 12, 0, 56),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Ui.PANEL,
		BackgroundTransparency = 0.08,
	}, { Ui.corner(), Ui.pad(10), Ui.make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })
	cashLabel = Ui.label("₱0", 28, Ui.GOOD, { Parent = top, Font = Enum.Font.FredokaOne, LayoutOrder = 1 })
	streakLabel = Ui.label("", 14, Ui.MUTED, { Parent = top, LayoutOrder = 2 })
	-- Sprint stamina: the server runs it and publishes the player's Stamina attribute
	local bar = Ui.make("Frame", {
		Name = "Stamina",
		Parent = top,
		LayoutOrder = 2,
		Size = UDim2.fromOffset(150, 8),
		BackgroundColor3 = Color3.fromHex("e6e1d6"),
	}, { Ui.corner(4) })
	staminaFill = Ui.make("Frame", { Parent = bar, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromHex("3f7fd6") }, { Ui.corner(4) })
	ordersFrame = Ui.make("Frame", {
		Name = "Orders",
		Parent = top,
		LayoutOrder = 3,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
	}, { Ui.make("UIListLayout", { Padding = UDim.new(0, 2) }) })
	toastFrame = Ui.make("Frame", {
		Name = "Toasts",
		Parent = gui,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.new(1, -2 * 180, 0, 0), -- between the HUD on the left and the minimap
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, {
		Ui.make("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center }),
	})
end

function Hud.toast(text: string, color: Color3?)
	local toast = Ui.make("Frame", {
		Parent = toastFrame,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = color or Ui.INK,
		BackgroundTransparency = 0.1,
	}, { Ui.corner(10), Ui.pad(8) })
	Ui.label(text, 16, Color3.new(1, 1, 1), {
		Parent = toast,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	task.delay(3.5, function()
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
		Hud.toast(`₱{message.pay} pay + ₱{message.tip} tip, x{string.format("%.2f", message.bonus)} bonus`, Ui.MUTED)
		if message.regularNow then
			Hud.toast(`{message.regularNow} is a regular now! +10% there`, Ui.ACCENT)
		end
	end
end

function Hud.onState(state)
	current = state
	cashLabel.Text = `₱{state.cash}`
	streakLabel.Text = if state.streak > 0 then `Streak {state.streak} · {state.delivered} delivered` else `{state.delivered} delivered`
	for _, row in rows do
		row:Destroy()
	end
	rows = {}
	if #state.orders == 0 then
		rows.none = Ui.label("Pick up an order at the board (green)", 14, Ui.MUTED, { Parent = ordersFrame })
	end
	for i, order in state.orders do
		rows[order.id] = Ui.label("", 16, Ui.INK, { Parent = ordersFrame, LayoutOrder = i })
	end
end

-- Every frame: the countdowns and the stamina bar.
function Hud.step(serverNow: number)
	local player = game:GetService("Players").LocalPlayer
	local stamina = (player:GetAttribute("Stamina") or 100) / 100
	staminaFill.Size = UDim2.fromScale(math.clamp(stamina, 0, 1), 1)
	staminaFill.BackgroundColor3 = if player:GetAttribute("Winded") then Ui.ACCENT else Color3.fromHex("3f7fd6")
	for _, order in current.orders do
		local row = rows[order.id]
		if row then
			local left = order.deadline - serverNow
			row.Text = `{order.title}  {Ui.clock(left)}`
			row.TextColor3 = if left < 5 then Color3.fromHex("d6402b") else Ui.INK
		end
	end
end

return Hud

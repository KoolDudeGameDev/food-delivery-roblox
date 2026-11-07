-- One panel behind three places, as in the prototype: the dealer (rides), the mechanic (parts
-- for the ride you're on) and your home (house upgrades, and which ride to use). Every button
-- asks the server through Buy; what you see comes from the server's State.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Homes = require(ReplicatedStorage.Shared.Data.Homes)
local Shop = require(ReplicatedStorage.Shared.Shop)
local Vehicles = require(ReplicatedStorage.Shared.Data.Vehicles)
local Ui = require(script.Parent.Ui)

local ShopPanel = {}

local TITLES = { dealer = "Vehicle dealer", mechanic = "Mechanic", home = "Your home" }

local panel: Frame
local title: TextLabel
local note: TextLabel
local list: ScrollingFrame
local current
local place: string? = nil
local busy = false

local function clear()
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function heading(text: string, order: number)
	Ui.label(text, 15, Ui.MUTED, { Parent = list, LayoutOrder = order })
end

local function row(order: number, name: string, detail: string, button: string, enabled: boolean, item: string?)
	local frame = Ui.make("Frame", {
		Parent = list,
		LayoutOrder = order,
		Size = UDim2.new(1, -6, 0, 58),
		BackgroundColor3 = Color3.new(1, 1, 1),
	}, { Ui.corner(10), Ui.pad(8) })
	local none, cut = Enum.AutomaticSize.None, Enum.TextTruncate.AtEnd
	Ui.label(name, 16, Ui.INK, { Parent = frame, Size = UDim2.new(1, -100, 0, 20), AutomaticSize = none, TextTruncate = cut })
	Ui.label(detail, 13, Ui.MUTED, {
		Parent = frame,
		Position = UDim2.fromOffset(0, 22),
		Size = UDim2.new(1, -100, 0, 18),
		AutomaticSize = none,
		TextTruncate = cut,
	})
	local b = Ui.make("TextButton", {
		Parent = frame,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(92, 42),
		Text = button,
		TextSize = 15,
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = if enabled then Ui.GOOD else Ui.MUTED,
		AutoButtonColor = enabled,
	}, { Ui.corner(10) })
	b.Activated:Connect(function()
		if busy or not enabled or not item then
			return
		end
		busy = true
		local result = ReplicatedStorage.Remotes.Buy:InvokeServer(item)
		busy = false
		if result and not result.ok then
			note.Text = result.message
		end
	end)
end

local function statsLine(data, key: string?): string
	local s = Shop.stats(data, key)
	return `{s.speed} m/s · carries {s.carry}`
end

local function render()
	clear()
	if not (current and place) then
		return
	end
	local data = current
	title.Text = TITLES[place]
	note.Text = `₱{data.cash}`
	local order = 0
	local function nextOrder()
		order += 1
		return order
	end
	if place == "dealer" then
		local nextRide = Shop.nextRide(data)
		for _, v in Vehicles.list do
			local owned = data.owned[v.key] == true
			local label = if owned then (if data.equipped == v.key then "Riding" else "Use") else `₱{v.price}`
			local enabled = if owned then data.equipped ~= v.key else (v == nextRide and data.cash >= v.price)
			local detail = if owned or v == nextRide then statsLine(data, v.key) else "Buy the rides before it first"
			row(nextOrder(), v.name, detail, label, enabled, if owned then `use:{v.key}` else `ride:{v.key}`)
		end
	elseif place == "mechanic" then
		local v = Vehicles.byKey[data.equipped]
		if not v then
			heading("Get on a ride to upgrade it.", nextOrder())
		else
			heading(`{v.name}: {statsLine(data, v.key)}`, nextOrder())
			local levels = data.parts[v.key] or {}
			for _, p in v.parts do
				local lv = levels[p.key] or 0
				local price = p.prices[lv + 1]
				local adds = if p.speed then `+{p.speed} m/s` elseif p.accel then `+{p.accel} pickup` else `+{p.carry} carry`
				row(nextOrder(), p.name, `Level {lv} of {#p.prices} · {adds} each`, if price then `₱{price}` else "Max", price ~= nil and data.cash >= price, `part:{v.key}:{p.key}`)
			end
		end
	else
		local home, nextHome = Homes[data.homeTier], Homes[data.homeTier + 1]
		heading("House", nextOrder())
		local detail = `+{math.round(home.bonus * 100)}% pay` .. (if nextHome then ` · next: {nextHome.name}` else "")
		row(nextOrder(), home.name, detail, if nextHome then `₱{nextHome.price}` else "Max", nextHome ~= nil and data.cash >= nextHome.price, "home")
		heading("Your rides", nextOrder())
		row(nextOrder(), "On foot", statsLine(data, nil), if data.equipped == "" then "Using" else "Use", data.equipped ~= "", "use:foot")
		for _, v in Vehicles.list do
			if data.owned[v.key] then
				row(nextOrder(), v.name, statsLine(data, v.key), if data.equipped == v.key then "Riding" else "Use", data.equipped ~= v.key, `use:{v.key}`)
			end
		end
	end
end

function ShopPanel.mount(screen: ScreenGui)
	panel = Ui.make("Frame", {
		Name = "Shop",
		Parent = screen,
		Visible = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.92, 0, 0.8, 0),
		BackgroundColor3 = Ui.PANEL,
		ZIndex = 20,
	}, {
		Ui.corner(16),
		Ui.pad(14),
		Ui.make("UISizeConstraint", { MaxSize = Vector2.new(480, 560) }),
	})
	title = Ui.label("", 24, Ui.INK, { Parent = panel, Font = Enum.Font.FredokaOne })
	note = Ui.label("", 15, Ui.GOOD, { Parent = panel, Position = UDim2.fromOffset(0, 32) })
	list = Ui.make("ScrollingFrame", {
		Parent = panel,
		Position = UDim2.fromOffset(0, 58),
		Size = UDim2.new(1, 0, 1, -112),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, { Ui.make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local close = Ui.make("TextButton", {
		Parent = panel,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 44),
		Text = "Close",
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		TextColor3 = Ui.INK,
		BackgroundColor3 = Color3.fromHex("e6e1d6"),
	}, { Ui.corner(10) })
	close.Activated:Connect(ShopPanel.close)
end

-- From a prompt: "dealer", "mechanic", or a lot id for a home.
function ShopPanel.openFrom(prompt: ProximityPrompt): string?
	local spot = prompt.Parent
	if prompt.Name == "DealerPrompt" then
		place = "dealer"
	elseif prompt.Name == "MechanicPrompt" then
		place = "mechanic"
	elseif prompt.Name == "HomePrompt" then
		if spot and spot:GetAttribute("LotId") ~= Players.LocalPlayer:GetAttribute("LotId") then
			return "This is someone else's home."
		end
		place = "home"
	else
		return nil
	end
	panel.Visible = true
	render()
	return nil
end

function ShopPanel.close()
	panel.Visible = false
	place = nil
end

function ShopPanel.isOpen(): boolean
	return panel.Visible
end

function ShopPanel.onState(state)
	current = state
	if panel.Visible then
		render()
	end
end

return ShopPanel

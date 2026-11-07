-- The order board panel: the server's offers for you, and a Take button that asks the server.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ui = require(script.Parent.Ui)

local Board = {}

local panel: Frame
local list: Frame
local note: TextLabel
local current = { offers = {}, offersDeadline = 0, orders = {}, carry = 1 }
local busy = false

local function render()
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for i, offer in current.offers do
		local row = Ui.make("Frame", {
			Parent = list,
			LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, 64),
			BackgroundColor3 = Color3.new(1, 1, 1),
		}, { Ui.corner(10), Ui.pad(8) })
		-- Text leaves room for the button; anything longer ends in "…"
		local none, cut = Enum.AutomaticSize.None, Enum.TextTruncate.AtEnd
		Ui.label(offer.title, 17, Ui.INK, { Parent = row, Size = UDim2.new(1, -92, 0, 22), AutomaticSize = none, TextTruncate = cut })
		local regular = if offer.regular then " · Regular" else ""
		local problem = if offer.problem then ` · {offer.problem}` else ""
		Ui.label(`{Ui.stars(offer.stars)} · ₱{offer.pay} · {Ui.clock(offer.max)}{regular}{problem}`, 14, Ui.MUTED, {
			Parent = row,
			Position = UDim2.new(0, 0, 0, 26),
			Size = UDim2.new(1, -92, 0, 20),
			AutomaticSize = none,
			TextTruncate = cut,
		})
		local take = Ui.make("TextButton", {
			Parent = row,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.new(0, 84, 0, 44),
			Text = "Take",
			TextSize = 18,
			Font = Enum.Font.GothamBold,
			TextColor3 = Color3.new(1, 1, 1),
			BackgroundColor3 = if offer.problem then Ui.MUTED else Ui.GOOD,
			AutoButtonColor = offer.problem == nil,
		}, { Ui.corner(10) })
		take.Activated:Connect(function()
			if busy or offer.problem then
				return
			end
			busy = true
			local result = ReplicatedStorage.Remotes.AcceptOrder:InvokeServer(offer.id)
			busy = false
			if result and result.ok then
				Board.close()
			elseif result then
				note.Text = result.reason
			end
		end)
	end
end

function Board.mount(screen: ScreenGui)
	panel = Ui.make("Frame", {
		Name = "Board",
		Parent = screen,
		Visible = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.92, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Ui.PANEL,
	}, {
		Ui.corner(16),
		Ui.pad(14),
		Ui.make("UISizeConstraint", { MaxSize = Vector2.new(460, math.huge) }),
		Ui.make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	Ui.label("Order board", 24, Ui.INK, { Parent = panel, Font = Enum.Font.FredokaOne, LayoutOrder = 0 })
	note = Ui.label("", 14, Ui.MUTED, { Parent = panel, LayoutOrder = 1 })
	list = Ui.make("Frame", {
		Parent = panel,
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, { Ui.make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local close = Ui.make("TextButton", {
		Parent = panel,
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 44),
		Text = "Close",
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		TextColor3 = Ui.INK,
		BackgroundColor3 = Color3.fromHex("e6e1d6"),
	}, { Ui.corner(10) })
	close.Activated:Connect(Board.close)
end

function Board.open()
	panel.Visible = true
	render()
end

function Board.close()
	panel.Visible = false
end

function Board.isOpen(): boolean
	return panel.Visible
end

function Board.onState(state)
	current = state
	if panel.Visible then
		render()
	end
end

function Board.step(serverNow: number)
	if panel.Visible then
		note.Text = `Carrying {#current.orders} of {current.carry} · new offers in {Ui.clock(current.offersDeadline - serverNow)}`
	end
end

return Board

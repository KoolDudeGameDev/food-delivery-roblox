-- The order board, carried orders, timers, delivery and pay. The server owns all of it
-- (GDD §13.2): the client only asks to accept an offer, and never says what it earned.
-- Each player has their own board of offers, as in the prototype.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Goals = require(ReplicatedStorage.Shared.Goals)
local Homes = require(ReplicatedStorage.Shared.Data.Homes)
local Offers = require(ReplicatedStorage.Shared.Offers)
local OrderTypes = require(ReplicatedStorage.Shared.Data.OrderTypes)
local Pay = require(ReplicatedStorage.Shared.Pay)
local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local Shop = require(ReplicatedStorage.Shared.Shop)
local WorldClock = require(ReplicatedStorage.Shared.WorldClock)
local DataService = require(script.Parent.DataService)
local MoveService = require(script.Parent.MoveService)
local WorldService = require(script.Parent.WorldService)

local Remotes = ReplicatedStorage.Remotes

local OrderService = {}

local S = Config.STUDS
local ACCEPT_GAP = 0.25 -- s between one player's accept requests
local REACH_SLACK = 2 -- m of slack on the hub reach, for lag

type Order = Offers.Offer & { id: string, deadline: number, fresh: number }
type State = {
	offers: { Offers.Offer & { id: string } },
	offersDeadline: number,
	orders: { Order },
	lastHouse: string?,
	lastAccept: number,
}

local states: { [Player]: State } = {}
local rng = Random.new()
local nextId = 0

local function now(): number
	return workspace:GetServerTimeNow()
end

local isNight = WorldService.isNight

-- Today's date on the server's clock, the same in every server, so goals match for everyone.
local function today(): string
	return os.date("!%Y-%m-%d") :: string
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function newId(): string
	nextId += 1
	return `o{nextId}`
end

local function notify(player: Player, message)
	Remotes.Notify:FireClient(player, message)
end

local function renew(player: Player, state: State, data)
	local exclude = {}
	for _, order in state.orders do
		exclude[order.houseId] = true
	end
	if state.lastHouse then
		exclude[state.lastHouse] = true
	end
	state.offers = {}
	for _, offer in Offers.renew({ rng = rng, maxStars = PlayerData.maxStars(data), exclude = exclude, night = isNight() }) do
		local withId = table.clone(offer) :: any
		withId.id = newId()
		table.insert(state.offers, withId)
	end
	state.offersDeadline = now() + Config.OFFER_LIFE
end

-- Today's goals as the board shows them.
local function goalLines(data)
	data.goals = Goals.current(data.goals, today())
	local lines = {}
	for _, g in data.goals.list do
		local t = Goals.TYPES[g.type]
		table.insert(lines, { text = t.text, progress = g.progress, count = t.count, reward = t.reward, done = g.done })
	end
	return lines
end

-- Sends the player everything their HUD and board show. Positions are in studs.
local function push(player: Player)
	local state, data = states[player], DataService.get(player)
	if not (state and data) then
		return
	end
	local carry = Shop.stats(data).carry
	local offers = {}
	for _, o in state.offers do
		table.insert(offers, {
			id = o.id,
			title = o.title,
			stars = o.stars,
			pay = o.pay,
			max = o.max,
			food = o.food,
			regular = (data.regulars[o.houseId] or 0) >= Config.REGULAR_VISITS,
			problem = Offers.problem(carry, #state.orders, o),
		})
	end
	local orders = {}
	for _, o in state.orders do
		local step = WorldLayout.byId[o.houseId].step
		table.insert(orders, {
			id = o.id,
			title = o.title,
			food = o.food,
			stars = o.stars,
			max = o.max,
			deadline = o.deadline,
			fresh = o.fresh,
			target = WorldLayout.studs(step.x, step.z),
		})
	end
	Remotes.State:FireClient(player, {
		cash = data.cash,
		delivered = data.delivered,
		streak = data.streak,
		carry = carry,
		rating = if data.ratingCount > 0 then data.ratingSum / data.ratingCount else nil,
		goals = goalLines(data),
		homeTier = data.homeTier,
		owned = data.owned,
		parts = data.parts,
		equipped = data.equipped,
		name = data.name,
		offers = offers,
		offersDeadline = state.offersDeadline,
		orders = orders,
		hub = WorldLayout.studs(WorldLayout.HUB.x, WorldLayout.HUB.z),
	})
end

-- Parcels are heavy: carrying one slows you down.
-- What you carry, in your arms where everyone can see it (Blueprint §13, package handling): a
-- red insulated bag for food, a brown box for a parcel, stacked, darker and more crooked the
-- more it's been knocked about.
local FOOD_BAG, PARCEL_BOX, WRECKED = Color3.fromHex("d6402b"), Color3.fromHex("b98a56"), Color3.fromHex("4a4038")

local function syncCarry(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local old = character:FindFirstChild("CarriedOrders")
	if old then
		old:Destroy()
	end
	local state = states[player]
	if not (state and #state.orders > 0) then
		return
	end
	local stack = Instance.new("Model")
	stack.Name = "CarriedOrders"
	local y = 0.05
	for i, o in state.orders do
		local wear = 1 - o.fresh / 100
		local size = if o.food then Vector3.new(0.7, 0.5, 0.5) else Vector3.new(0.8, 0.6, 0.6)
		local box = Instance.new("Part")
		box.Name = if o.food then "FoodBag" else "Parcel"
		box.Size = size * S
		box.Color = (if o.food then FOOD_BAG else PARCEL_BOX):Lerp(WRECKED, wear * 0.7)
		box.CanCollide, box.CanQuery, box.CanTouch, box.Massless = false, false, false, true
		-- In front of the chest (a character faces -z), each one on the last, tilted by its damage
		box.CFrame = root.CFrame * CFrame.new(0, (y + size.Y / 2) * S, -0.85 * S) * CFrame.Angles(wear * 0.35, (i % 2 - 0.5) * wear * 0.6, 0)
		y += size.Y
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1 = root, box
		weld.Parent = box
		box.Parent = stack
	end
	stack.Parent = character
end

-- Parcels are heavy: carrying one slows you down. Also refreshes what you're seen carrying.
local function updateSpeed(player: Player)
	local state = states[player]
	local parcel = false
	for _, o in if state then state.orders else {} do
		parcel = parcel or not o.food
	end
	MoveService.setParcel(player, parcel)
	syncCarry(player)
end

local function rate(data, stars: number)
	data.ratingSum += stars
	data.ratingCount += 1
end

local function removeOrder(state: State, order: Order): boolean
	local i = table.find(state.orders, order)
	if not i then
		return false
	end
	table.remove(state.orders, i)
	return true
end

local function timeout(player: Player, state: State, order: Order)
	local data = DataService.get(player)
	if not (data and removeOrder(state, order)) then
		return
	end
	rate(data, 1)
	if data.streak >= 3 then
		notify(player, { kind = "toast", text = `Streak of {data.streak} lost!` })
	end
	data.streak = 0
	DataService.changed(player)
	notify(player, { kind = "toast", text = "Too late! Order cancelled, 1 star" })
	updateSpeed(player)
	push(player)
end

local function deliver(player: Player, state: State, order: Order)
	local data = DataService.get(player)
	-- Removed before paying, so the same order can never pay twice
	if not (data and removeOrder(state, order)) then
		return
	end
	local visits = data.regulars[order.houseId] or 0
	local night = isNight()
	local result = Pay.delivery(order, {
		left = math.max(0, order.deadline - now()),
		fresh = order.fresh,
		homeBonus = Homes[data.homeTier].bonus,
		regular = visits >= Config.REGULAR_VISITS,
		streak = data.streak,
		eventBonus = WorldClock.eventBonus(WorldService.weather(), order.food, order.houseId),
		night = night,
	})
	data.cash += result.total
	data.delivered += 1
	rate(data, result.rating)
	data.regulars[order.houseId] = visits + 1
	data.streak += 1
	local house = WorldLayout.byId[order.houseId]
	-- Daily goals, counted from the server's own events (GDD §10.2)
	local goals = Goals.current(data.goals, today())
	data.goals = goals
	local reward = Goals.count(goals, "delivered", 1)
		+ (if house.dog then Goals.count(goals, "dogYard", 1) else 0)
		+ (if result.rating == 5 then Goals.count(goals, "fiveStar", 1) else 0)
		+ (if order.stars >= 4 then Goals.count(goals, "hardOrder", 1) else 0)
		+ (if order.houseId == "cemetery" and night then Goals.count(goals, "cemeteryNight", 1) else 0)
		+ Goals.count(goals, "streak", data.streak)
	data.cash += reward
	DataService.changed(player)
	if reward > 0 then
		notify(player, { kind = "toast", text = `Goal done! +₱{reward}` })
	end
	notify(player, {
		kind = "paid",
		houseId = order.houseId, -- the client opens that front door and pops the pay over it
		title = order.title,
		pay = order.pay,
		tip = result.tip,
		bonus = result.bonus,
		night = night,
		total = result.total,
		rating = result.rating,
		regularNow = visits + 1 == Config.REGULAR_VISITS and house.name or nil,
	})
	updateSpeed(player)
	push(player)
end

local function accept(player: Player, offerId: unknown)
	local state, data = states[player], DataService.get(player)
	if not (state and data) then
		return { ok = false, reason = "Still loading" }
	end
	if typeof(offerId) ~= "string" or #offerId > 32 then
		return { ok = false, reason = "Bad request" }
	end
	local t = os.clock()
	if t - state.lastAccept < ACCEPT_GAP then
		return { ok = false, reason = "Too fast" }
	end
	state.lastAccept = t
	local root = rootOf(player)
	local hub = WorldLayout.studs(WorldLayout.HUB.x, WorldLayout.HUB.z)
	if not root or flatDistance(root.Position, hub) > (Config.HUB_REACH + REACH_SLACK) * S then
		return { ok = false, reason = "Go to the order board" }
	end
	local offer
	for _, o in state.offers do
		if o.id == offerId then
			offer = o
		end
	end
	if not offer then
		return { ok = false, reason = "That offer is gone" }
	end
	local problem = Offers.problem(Shop.stats(data).carry, #state.orders, offer)
	if problem then
		return { ok = false, reason = problem }
	end
	local order = table.clone(offer) :: any
	order.deadline = now() + offer.max
	order.fresh = 100
	table.insert(state.orders, order)
	state.lastHouse = offer.houseId
	renew(player, state, data)
	notify(player, { kind = "toast", text = if offer.food then "Hot food! Go go go!" else "Parcel: heavy, so you move slower" })
	notify(player, { kind = "accepted", food = offer.food }) -- the conveyor brings it out
	updateSpeed(player)
	push(player)
	return { ok = true }
end

local function tick()
	local t = now()
	for player, state in states do
		for _, order in table.clone(state.orders) do
			local root = rootOf(player)
			local step = WorldLayout.byId[order.houseId].step
			if t >= order.deadline then
				timeout(player, state, order)
			elseif root and flatDistance(root.Position, WorldLayout.studs(step.x, step.z)) < Config.DELIVER_REACH * S then
				deliver(player, state, order)
			end
		end
		if t >= state.offersDeadline or #state.offers == 0 then
			local data = DataService.get(player)
			if data then
				renew(player, state, data)
				push(player)
			end
		end
	end
end

function OrderService.start()
	DataService.onLoaded(function(player, data)
		local state: State = { offers = {}, offersDeadline = 0, orders = {}, lastAccept = 0 }
		states[player] = state
		renew(player, state, data)
		push(player)
		updateSpeed(player)
	end)
	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			task.defer(updateSpeed, player)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
	Remotes.AcceptOrder.OnServerInvoke = accept
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 0.1 then
			acc = 0
			tick()
		end
	end)
end

-- Bites (and later crashes) hurt everything a player carries: fragile orders twice as much.
-- Any hurt ends the streak, as in the prototype.
function OrderService.hurt(player: Player, amount: number)
	local state, data = states[player], DataService.get(player)
	if not (state and data) then
		return
	end
	for _, order in state.orders do
		order.fresh = math.max(0, order.fresh - amount * OrderTypes[order.typeKey].damage)
	end
	if data.streak >= 3 then
		notify(player, { kind = "toast", text = `Streak of {data.streak} lost!` })
	end
	if data.streak > 0 then
		data.streak = 0
		DataService.changed(player)
	end
	syncCarry(player) -- the box looks the worse for it
	push(player)
end

function OrderService.carrying(player: Player): number
	local state = states[player]
	return if state then #state.orders else 0
end

-- Whether the player carries an order for this house (GateService opens its gate).
function OrderService.carriesFor(player: Player, houseId: string): boolean
	local state = states[player]
	for _, o in if state then state.orders else {} do
		if o.houseId == houseId then
			return true
		end
	end
	return false
end

OrderService.updateSpeed = updateSpeed
OrderService.push = push

-- For tests and probes: the server's view of a player's carried orders and board.
function OrderService.stateOf(player: Player)
	return states[player]
end

return OrderService

-- The economy check (GDD §16, MVP-Tracker "Economy check"): a fresh player's first hour, played
-- many times with the real rules (Offers, Pay, Shop, PlayerData.maxStars). Not a spec, so the
-- test runner skips it. Run it in Studio's command bar:
--   print(require(game.ServerStorage.Tests.EconomySim).run())
-- The ASSUMPTIONS are guesses about how people play, to check against a real stopwatch.
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local DogBreeds = require(Shared.Data.DogBreeds)
local Homes = require(Shared.Data.Homes)
local Offers = require(Shared.Offers)
local Pay = require(Shared.Pay)
local PlayerData = require(Shared.PlayerData)
local Shop = require(Shared.Shop)
local Vehicles = require(Shared.Data.Vehicles)
local WorldClock = require(Shared.WorldClock)
local WorldLayout = require(Shared.WorldLayout)

local EconomySim = {}

local ASSUMPTIONS = {
	road = 1.3, -- the route is this much longer than a straight line
	board = 6, -- s at the board: read, take, the conveyor
	door = 3, -- s at each door
	yardWalk = 4, -- s from the parked ride to the door and back
	biteShare = 0.4, -- share of dog-yard visits that end in one bite
	startClock = 8, -- the world clock when they join
	minutes = 60,
	runs = 200,
}

local function hub()
	return WorldLayout.HUB
end

local function dist(a, b): number
	return math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2) * ASSUMPTIONS.road
end

-- One player's hour. policy "rides": the next ride as soon as it's affordable, else a home
-- upgrade; "homes": the other way round.
local function play(rng: Random, policy: string)
	local data = PlayerData.template()
	local t, clock = 0, ASSUMPTIONS.startClock
	local log = {}
	local deliveries = 0
	local function spend()
		local nextRide, nextHome = Shop.nextRide(data), Homes[data.homeTier + 1]
		local order = if policy == "rides" then { "ride", "home" } else { "home", "ride" }
		for _, kind in order do
			if kind == "ride" and nextRide and data.cash >= nextRide.price then
				Shop.buy(data, `ride:{nextRide.key}`)
				table.insert(log, { t = t, what = nextRide.name })
				return true
			elseif kind == "home" and nextHome and data.cash >= nextHome.price then
				Shop.buy(data, "home")
				table.insert(log, { t = t, what = nextHome.name })
				return true
			end
		end
		return false
	end
	local function wait(seconds: number)
		t += seconds
		clock = WorldClock.advance(clock, seconds)
	end
	while t < ASSUMPTIONS.minutes * 60 do
		while spend() do
		end
		local stats = Shop.stats(data)
		local riding = data.equipped ~= ""
		local offers = Offers.renew({ rng = rng, maxStars = PlayerData.maxStars(data), night = WorldClock.isNight(clock) })
		-- Take the best-paying offers you can carry, nearest first
		table.sort(offers, function(a, b)
			return a.pay > b.pay
		end)
		local trip = {}
		for _, offer in offers do
			if #trip < stats.carry and not Offers.problem(stats.carry, #trip, offer) then
				table.insert(trip, offer)
			end
		end
		wait(ASSUMPTIONS.board)
		local at = hub()
		local started = t
		while #trip > 0 do
			table.sort(trip, function(a, b)
				return dist(at, WorldLayout.byId[a.houseId].step) < dist(at, WorldLayout.byId[b.houseId].step)
			end)
			local offer = table.remove(trip, 1) :: any
			local house = WorldLayout.byId[offer.houseId]
			local speed = if riding then stats.speed else Config.RUN * (if offer.food then 1 else Config.PARCEL_SLOW)
			wait(dist(at, house.step) / speed + ASSUMPTIONS.door + (if riding then ASSUMPTIONS.yardWalk else 0))
			at = house.step
			local fresh = 100
			if house.dog and rng:NextNumber() < ASSUMPTIONS.biteShare then
				fresh -= Config.DOG_TYPES[DogBreeds[house.dog].size].damage
			end
			local left = offer.max - (t - started)
			if left <= 0 then
				data.streak = 0
				data.ratingSum += 1
				data.ratingCount += 1
			else
				local visits = data.regulars[offer.houseId] or 0
				local result = Pay.delivery(offer, {
					left = left,
					fresh = fresh,
					homeBonus = Homes[data.homeTier].bonus,
					regular = visits >= Config.REGULAR_VISITS,
					streak = data.streak,
					night = WorldClock.isNight(clock),
				})
				data.cash += result.total
				data.ratingSum += result.rating
				data.ratingCount += 1
				data.regulars[offer.houseId] = visits + 1
				data.streak += 1
				deliveries += 1
			end
		end
		wait(dist(at, hub()) / (if riding then stats.speed else Config.RUN))
	end
	return { log = log, deliveries = deliveries, cash = data.cash, ride = Shop.stats(data).name, home = Homes[data.homeTier].name }
end

local function median(list: { number }): number?
	if #list == 0 then
		return nil
	end
	table.sort(list)
	return list[math.ceil(#list / 2)]
end

local function percentile(list: { number }, p: number): number?
	if #list == 0 then
		return nil
	end
	table.sort(list)
	return list[math.clamp(math.ceil(#list * p), 1, #list)]
end

local function minutes(seconds: number?): string
	return if seconds then string.format("%.1f", seconds / 60) else "—"
end

function EconomySim.run(seed: number?): string
	local lines = {
		`Economy check: {ASSUMPTIONS.runs} fresh players, {ASSUMPTIONS.minutes} minutes each, with the real rules.`,
		`Assumptions: route x{ASSUMPTIONS.road} straight line, {ASSUMPTIONS.board} s at the board, {ASSUMPTIONS.door} s per door, {ASSUMPTIONS.yardWalk} s yard walk when riding, a bite in {ASSUMPTIONS.biteShare * 100}% of dog yards, no events or goals.`,
	}
	for _, policy in { "rides", "homes" } do
		local rng = Random.new(seed or 1)
		local at: { [string]: { number } } = {}
		local deliveries, cash = {}, {}
		for _ = 1, ASSUMPTIONS.runs do
			local result = play(rng, policy)
			for _, entry in result.log do
				at[entry.what] = at[entry.what] or {}
				table.insert(at[entry.what], entry.t)
			end
			table.insert(deliveries, result.deliveries)
			table.insert(cash, result.cash)
		end
		table.insert(lines, "")
		table.insert(lines, `Spending: {if policy == "rides" then "next ride first, then the home" else "next home first, then the ride"}`)
		table.insert(lines, "Bought | players who got there | minute (median, 10%–90%)")
		local order = {}
		for _, v in Vehicles.list do
			table.insert(order, v.name)
		end
		for i = 2, #Homes do
			table.insert(order, Homes[i].name)
		end
		for _, name in order do
			local times = at[name]
			if times then
				table.insert(lines, `{name} | {#times} of {ASSUMPTIONS.runs} | {minutes(median(table.clone(times)))} ({minutes(percentile(table.clone(times), 0.1))}–{minutes(percentile(table.clone(times), 0.9))})`)
			end
		end
		table.insert(lines, `Deliveries in the hour: median {median(table.clone(deliveries))}; cash left: median ₱{median(table.clone(cash))}`)
	end
	return table.concat(lines, "\n")
end

return EconomySim

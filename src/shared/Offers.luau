-- Making the order board's offers (the prototype's makeOffer and renewOffers), pure so the
-- server and the tests share it. Randomness comes in as a Random, so tests can seed it.
local Config = require(script.Parent.Config)
local DogBreeds = require(script.Parent.Data.DogBreeds)
local OrderTypes = require(script.Parent.Data.OrderTypes)
local Pay = require(script.Parent.Pay)
local WorldLayout = require(script.Parent.WorldLayout)

local Offers = {}

export type Offer = {
	houseId: string,
	typeKey: string,
	food: boolean,
	stars: number,
	pay: number,
	max: number,
	title: string,
}

local TYPE_POOL = {}
for _, key in { "normal", "fragile", "rush", "bulky" } do
	for _ = 1, OrderTypes[key].weight do
		table.insert(TYPE_POOL, key)
	end
end

function Offers.distance(house): number
	local hub = WorldLayout.HUB
	return math.sqrt((house.step.x - hub.x) ^ 2 + (house.step.z - hub.z) ^ 2)
end

function Offers.make(house, typeKey: string, rng: Random, night: boolean?): Offer
	local orderType = OrderTypes[typeKey]
	local distance = Offers.distance(house)
	local dog = if house.dog then Config.DOG_TYPES[DogBreeds[house.dog].size].danger else 0
	local risk = (house.risk or 0) + (if night then house.nightRisk or 0 else 0)
	local stars = Pay.difficulty(distance, dog, risk, orderType.stars)
	local food = not orderType.parcelOnly and not house.parcelOnly and rng:NextNumber() < Config.FOOD_CHANCE
	local thing = if food then "food" else "parcel"
	local place = house.place or `{house.name} house`
	local label = if orderType.label ~= "" then `{orderType.label} {thing}` else (if food then "Food" else "Parcel")
	return {
		houseId = house.id,
		typeKey = typeKey,
		food = food,
		stars = stars,
		pay = Pay.offerPay(distance, stars, food, orderType),
		max = Pay.timeLimit(distance, food, orderType, house.extraTime),
		title = `{label} to {place}`,
	}
end

export type RenewOptions = {
	rng: Random,
	maxStars: number,
	exclude: { [string]: boolean }?, -- houses the player is already delivering to, or just did
	night: boolean?,
}

-- A fresh board: up to OFFER_COUNT offers to different houses, easiest first. Chaser yards come
-- up about twice as often, because they're the fun part. The first offer made is always a plain
-- one, so there's always something you can take.
function Offers.renew(opts: RenewOptions): { Offer }
	local pool = {}
	for _, house in WorldLayout.HOUSES do
		for _ = 1, house.weight or (if house.dog then 2 else 1) do
			table.insert(pool, house)
		end
	end
	local exclude = opts.exclude or {}
	local offers, used = {}, {}
	for _ = 1, 80 do
		if #offers >= Config.OFFER_COUNT then
			break
		end
		local house = pool[opts.rng:NextInteger(1, #pool)]
		if exclude[house.id] or used[house.id] then
			continue
		end
		local typeKey = if #offers == 0 then "normal" else TYPE_POOL[opts.rng:NextInteger(1, #TYPE_POOL)]
		local offer = Offers.make(house, typeKey, opts.rng, opts.night)
		if offer.stars <= opts.maxStars then
			used[house.id] = true
			table.insert(offers, offer)
		end
	end
	table.sort(offers, function(a, b)
		return a.stars < b.stars
	end)
	return offers
end

-- Why a player can't take an offer right now, or nil if they can.
function Offers.problem(carry: number, carried: number, offer: Offer): string?
	if carried >= carry then
		return "You can't carry any more"
	end
	local minCarry = OrderTypes[offer.typeKey].minCarry
	if minCarry and carry < minCarry then
		return "Needs a sidecar"
	end
	return nil
end

-- The teleport check on delivery (MVP criterion 3): could anyone have covered this many metres in
-- this many seconds at this top speed (m/s)? Straight lines are already shorter than the roads,
-- and the slack and slop cover a fling, a knockback and lag. A teleport fails it until enough
-- time has passed, so it never pays sooner than riding would (and the tip shrinks meanwhile).
function Offers.tooFast(metres: number, seconds: number, topSpeed: number): boolean
	return metres > topSpeed * Config.TRAVEL_SLACK * math.max(0, seconds) + Config.TRAVEL_SLOP
end

return Offers

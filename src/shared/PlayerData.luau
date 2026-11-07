-- What a player's save holds, its defaults, and the check every save gets when it loads
-- (GDD §13.4). A new saved field needs a default here and a check in sanitize.
local Homes = require(script.Parent.Data.Homes)
local WorldLayout = require(script.Parent.WorldLayout)

local PlayerData = {}

PlayerData.VERSION = 1

export type Data = {
	version: number,
	cash: number,
	delivered: number,
	homeTier: number,
	ratingSum: number, -- customer ratings add up here; the average unlocks harder orders
	ratingCount: number,
	streak: number,
	regulars: { [string]: number }, -- deliveries per house id
}

function PlayerData.template(): Data
	return {
		version = PlayerData.VERSION,
		cash = 0,
		delivered = 0,
		homeTier = 1,
		ratingSum = 0,
		ratingCount = 0,
		streak = 0,
		regulars = {},
	}
end

-- A whole number from 0 up, or 0 for anything else (NaN, infinity, negatives, wrong types).
local function count(value: any): number
	if type(value) ~= "number" or value ~= value or value == math.huge or value < 0 then
		return 0
	end
	return math.floor(value)
end

function PlayerData.sanitize(data: Data): Data
	for _, field in { "cash", "delivered", "ratingSum", "ratingCount", "streak" } do
		data[field] = count(data[field])
	end
	local tier = count(data.homeTier)
	data.homeTier = if tier >= 1 and tier <= #Homes then tier else 1
	local regulars = {}
	if type(data.regulars) == "table" then
		for id, visits in data.regulars do
			if WorldLayout.byId[id] and count(visits) > 0 then
				regulars[id] = count(visits)
			end
		end
	end
	data.regulars = regulars
	data.version = PlayerData.VERSION
	return data
end

-- The hardest orders a player is trusted with, from their ratings (the prototype's maxStars).
function PlayerData.maxStars(data: Data): number
	local n = data.ratingCount
	local average = if n > 0 then data.ratingSum / n else 0
	if n >= 15 and average >= 4 then
		return 5
	elseif n >= 5 and average >= 3.5 then
		return 4
	end
	return 3
end

return PlayerData

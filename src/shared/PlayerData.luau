-- What a player's save holds, its defaults, and the check every save gets when it loads
-- (GDD §13.4). A new saved field needs a default here and a check in sanitize.
local Goals = require(script.Parent.Goals)
local Cosmetics = require(script.Parent.Data.Cosmetics)
local Homes = require(script.Parent.Data.Homes)
local Vehicles = require(script.Parent.Data.Vehicles)
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
	owned: { [string]: boolean }, -- rides by key
	parts: { [string]: { [string]: number } }, -- part levels, by ride then part
	equipped: string, -- a ride key, or "" on foot
	goals: { day: string, list: { { type: number, progress: number, done: boolean } } },
	name: string, -- the rider name from the intro, unfiltered; "" uses their Roblox display name
	paint: { house: number, rides: { [string]: number } }, -- Cosmetics.PAINTS index; 0 = as built
	decor: { [string]: boolean }, -- Cosmetics.DECOR keys in the yard
}

PlayerData.NAME_MAX = 12 -- characters, as in the prototype

-- The name trimmed, or nil if it isn't allowed. It still goes through TextService before anyone
-- sees it (NameService).
function PlayerData.cleanName(name: any): string?
	if type(name) ~= "string" or name:find("%c") then
		return nil
	end
	local trimmed = name:match("^%s*(.-)%s*$") :: string
	local length = utf8.len(trimmed)
	if not length or length > PlayerData.NAME_MAX then
		return nil
	end
	return trimmed
end

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
		owned = {},
		parts = {},
		equipped = "",
		goals = { day = "", list = {} },
		name = "",
		paint = { house = 0, rides = {} },
		decor = {},
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
	-- Rides: only real ones, part levels within their price list, and the ride in use owned
	local owned, parts = {}, {}
	for _, v in Vehicles.list do
		if type(data.owned) == "table" and data.owned[v.key] == true then
			owned[v.key] = true
			local saved = type(data.parts) == "table" and type(data.parts[v.key]) == "table" and data.parts[v.key] or {}
			local levels = {}
			for _, p in v.parts do
				local lv = math.min(count(saved[p.key]), #p.prices)
				if lv > 0 then
					levels[p.key] = lv
				end
			end
			parts[v.key] = levels
		end
	end
	data.owned, data.parts = owned, parts
	data.equipped = if type(data.equipped) == "string" and owned[data.equipped] then data.equipped else ""
	-- Goals: a day string and three known goals, or nothing (a fresh set comes on use)
	local goals = { day = "", list = {} }
	local saved = data.goals
	if type(saved) == "table" and type(saved.day) == "string" and type(saved.list) == "table" and #saved.list == Goals.COUNT then
		local ok = true
		for _, g in saved.list do
			local t = type(g) == "table" and Goals.TYPES[g.type]
			ok = ok and t ~= nil and t ~= false
		end
		if ok then
			goals.day = saved.day
			for _, g in saved.list do
				local t = Goals.TYPES[g.type]
				table.insert(goals.list, { type = g.type, progress = math.min(count(g.progress), t.count), done = g.done == true })
			end
		end
	end
	data.goals = goals
	data.name = PlayerData.cleanName(data.name) or ""
	data.look = nil -- the rider outfit, dropped 2026-11-08: players keep their own avatar
	-- Paint: a known colour or none; ride paint only on rides they own
	local function colour(value: any): number?
		local n = count(value)
		return if n == value and n >= 1 and n <= #Cosmetics.PAINTS then n else nil
	end
	local savedPaint = if type(data.paint) == "table" then data.paint else {}
	local paint = { house = colour(savedPaint.house) or 0, rides = {} }
	if type(savedPaint.rides) == "table" then
		for key in owned do
			paint.rides[key] = colour(savedPaint.rides[key])
		end
	end
	data.paint = paint
	local decor = {}
	for _, d in Cosmetics.DECOR do
		if type(data.decor) == "table" and data.decor[d.key] == true then
			decor[d.key] = true
		end
	end
	data.decor = decor
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

-- Buying rides, parts and homes, and choosing a ride: pure rules on a player's data, so the
-- server and the tests share them. The server checks where the player is first (ShopService).
-- Items are strings: "ride:<key>", "part:<ride>:<part>", "home", "use:<ride>" or "use:foot".
local Config = require(script.Parent.Config)
local Homes = require(script.Parent.Data.Homes)
local Vehicles = require(script.Parent.Data.Vehicles)

local Shop = {}

local function partOf(v, partKey: string)
	for _, p in v.parts do
		if p.key == partKey then
			return p
		end
	end
	return nil
end

-- The first ride you don't own yet: rides are bought in order.
function Shop.nextRide(data)
	for _, v in Vehicles.list do
		if not data.owned[v.key] then
			return v
		end
	end
	return nil
end

-- Speed (m/s) and carry for a ride with its parts, or running if key is nil.
function Shop.stats(data, key: string?)
	key = key or (if data.equipped ~= "" then data.equipped else nil)
	local v = key and Vehicles.byKey[key]
	if not v then
		return { key = nil, name = "On foot", speed = Config.RUN, carry = 1 }
	end
	local levels = data.parts[v.key] or {}
	local speed, carry = v.speed, v.carry
	for _, p in v.parts do
		local lv = levels[p.key] or 0
		speed += (p.speed or 0) * lv
		carry += (p.carry or 0) * lv
	end
	return { key = v.key, name = v.name, speed = speed, carry = math.min(carry, Config.MAX_CARRY) }
end

-- Tries to buy or use an item. Changes data only on success. Returns ok, a message, and the
-- kind of change ("ride", "part", "home" or "use") so the server knows what to rebuild.
function Shop.buy(data, item: string): (boolean, string, string?)
	local kind, a, b = string.match(item, "^(%a+):?([%w]*):?([%w]*)$")
	if kind == "ride" and a ~= "" and b == "" then
		local v = Vehicles.byKey[a]
		if not v or data.owned[a] then
			return false, "You can't buy that"
		elseif Shop.nextRide(data) ~= v then
			return false, `Buy the {Shop.nextRide(data).name} first`
		elseif data.cash < v.price then
			return false, `You need ₱{v.price}`
		end
		data.cash -= v.price
		data.owned[a] = true
		data.parts[a] = data.parts[a] or {}
		data.equipped = a
		return true, `{v.name} bought!`, "ride"
	elseif kind == "part" and a ~= "" and b ~= "" then
		local v = Vehicles.byKey[a]
		local p = v and partOf(v, b)
		if not (p and data.owned[a]) then
			return false, "You can't buy that"
		end
		data.parts[a] = data.parts[a] or {}
		local lv = data.parts[a][b] or 0
		local price = p.prices[lv + 1]
		if not price then
			return false, "Already the best"
		elseif data.cash < price then
			return false, `You need ₱{price}`
		end
		data.cash -= price
		data.parts[a][b] = lv + 1
		return true, `{p.name} fitted!`, "part"
	elseif kind == "home" and a == "" and b == "" then
		local next = Homes[data.homeTier + 1]
		if not next then
			return false, "It's already a mansion"
		elseif data.cash < next.price then
			return false, `You need ₱{next.price}`
		end
		data.cash -= next.price
		data.homeTier += 1
		return true, `{next.name} built!`, "home"
	elseif kind == "use" and a ~= "" and b == "" then
		if a == "foot" then
			data.equipped = ""
			return true, "On foot", "use"
		elseif data.owned[a] and Vehicles.byKey[a] then
			data.equipped = a
			return true, `Riding the {Vehicles.byKey[a].name}`, "use"
		end
		return false, "You don't own that"
	end
	return false, "You can't buy that"
end

return Shop

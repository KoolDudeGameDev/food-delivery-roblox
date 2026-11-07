-- The Buy remote: rides at the dealer, parts at the mechanic, home upgrades at your own lot,
-- and choosing a ride at your lot or the dealer. The server checks where you are, then Shop
-- decides the rest (GDD §8.5: valid item, price, ownership, range, prerequisites).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Shop = require(ReplicatedStorage.Shared.Shop)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local DataService = require(script.Parent.DataService)
local LotService = require(script.Parent.LotService)
local OrderService = require(script.Parent.OrderService)
local RideService = require(script.Parent.RideService)

local ShopService = {}

local S = Config.STUDS
local GAP = 0.3 -- s between one player's requests
local lastAt: { [Player]: number } = {}

-- Where each kind of purchase happens, in metres.
local function shopDoor(key: string)
	local s = WorldLayout.SHOPS[key]
	return { x = s.x, z = s.z - 8.4 }
end
ShopService.shopDoor = shopDoor

local function near(player: Player, x: number, z: number, reach: number): boolean
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end
	local dx, dz = root.Position.X / S - x, root.Position.Z / S - z
	return dx * dx + dz * dz <= reach * reach
end

local function atHome(player: Player): boolean
	local lot = LotService.lotOf(player)
	return lot ~= nil and near(player, lot.x, lot.z, math.max(lot.w, lot.d) / 2 + Config.SHOP_REACH)
end

local function atShop(player: Player, key: string): boolean
	local door = shopDoor(key)
	return near(player, door.x, door.z, Config.SHOP_REACH)
end

local function inRange(player: Player, item: string): boolean
	local kind = string.match(item, "^(%a+)")
	if kind == "ride" then
		return atShop(player, "dealer")
	elseif kind == "part" then
		return atShop(player, "mechanic")
	elseif kind == "home" then
		return atHome(player)
	elseif kind == "use" then
		return atHome(player) or atShop(player, "dealer")
	end
	return false
end

local function buy(player: Player, item: unknown)
	if typeof(item) ~= "string" or #item > 40 then
		return { ok = false, message = "Bad request" }
	end
	local t = os.clock()
	if t - (lastAt[player] or 0) < GAP then
		return { ok = false, message = "Too fast" }
	end
	lastAt[player] = t
	local data = DataService.get(player)
	if not data then
		return { ok = false, message = "Still loading" }
	end
	if not inRange(player, item) then
		return { ok = false, message = "Go to the shop first" }
	end
	local ok, message, kind = Shop.buy(data, item)
	if ok then
		DataService.changed(player)
		if kind == "home" then
			local lot = LotService.lotOf(player)
			if lot then
				LotService.showHome(lot, data.homeTier)
			end
		else
			RideService.refresh(player)
		end
		OrderService.push(player)
		ReplicatedStorage.Remotes.Notify:FireClient(player, { kind = "toast", text = message })
	end
	return { ok = ok, message = message }
end

function ShopService.start()
	ReplicatedStorage.Remotes.Buy.OnServerInvoke = buy
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastAt[player] = nil
	end)
end

return ShopService

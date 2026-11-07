-- Buying rides, parts and homes, and choosing a ride (prototype `home.js`). Money: every rule
-- here is a way cash could go wrong.
local function load()
	local Shared = script.Parent.Parent.Shared
	return require(Shared.Shop), require(Shared.PlayerData)
end

local function rich(PlayerData, cash)
	local d = PlayerData.template()
	d.cash = cash
	return d
end

return {
	onFootRunsAndCarriesOne = function()
		local Shop, PlayerData = load()
		local s = Shop.stats(PlayerData.template())
		assert(s.speed == 6 and s.carry == 1 and s.key == nil and s.accel == 30)
	end,
	accelPartsQuickenARide = function()
		local Shop, PlayerData = load()
		local d = rich(PlayerData, 1000)
		Shop.buy(d, "ride:rollerblades")
		assert(Shop.stats(d).accel == 8)
		assert(Shop.buy(d, "part:rollerblades:laces"))
		assert(Shop.stats(d).accel == 11, `accel {Shop.stats(d).accel}`)
		assert(Shop.stats(d).speed == 7.8, "laces don't add speed")
	end,
	ridesAreBoughtInOrder = function()
		local Shop, PlayerData = load()
		local d = rich(PlayerData, 100000)
		local ok = Shop.buy(d, "ride:bicycle")
		assert(not ok, "skipped ahead to the bicycle")
		assert(Shop.buy(d, "ride:rollerblades"))
		assert(d.cash == 100000 - 300 and d.owned.rollerblades and d.equipped == "rollerblades")
		assert(not Shop.buy(d, "ride:rollerblades"), "bought the same ride twice")
		assert(Shop.buy(d, "ride:skateboard"))
	end,
	cantBuyWhatYouCantAfford = function()
		local Shop, PlayerData = load()
		local d = rich(PlayerData, 299)
		assert(not Shop.buy(d, "ride:rollerblades"))
		assert(d.cash == 299 and not d.owned.rollerblades)
		assert(not Shop.buy(d, "home"), "a 400 shack on 299")
		assert(d.homeTier == 1)
	end,
	partsLevelUpToTheirLastPrice = function()
		local Shop, PlayerData = load()
		local d = rich(PlayerData, 100000)
		Shop.buy(d, "ride:rollerblades")
		assert(not Shop.buy(d, "part:skateboard:wheels"), "part for a ride not owned")
		assert(Shop.buy(d, "part:rollerblades:wheels"))
		assert(Shop.buy(d, "part:rollerblades:wheels"))
		assert(not Shop.buy(d, "part:rollerblades:wheels"), "past the last level")
		assert(d.parts.rollerblades.wheels == 2)
		assert(d.cash == 100000 - 300 - 80 - 200, `cash {d.cash}`)
		local s = Shop.stats(d)
		assert(math.abs(s.speed - (7.8 + 1.6)) < 1e-9, `speed {s.speed}`)
	end,
	carryAddsUpButCapsAtFour = function()
		local Shop, PlayerData = load()
		local d = rich(PlayerData, 100000)
		for _, item in { "ride:rollerblades", "ride:skateboard", "ride:bicycle", "part:bicycle:basket", "part:bicycle:sidecar" } do
			assert(Shop.buy(d, item), item)
		end
		assert(Shop.stats(d).carry == 4)
		d.equipped = "tricycle"
		d.owned.tricycle = true
		d.parts.tricycle = { rack = 1 }
		assert(Shop.stats(d).carry == 4, "tricycle 3 + rack 1")
	end,
	homeClimbsTheLadder = function()
		local Shop, PlayerData = load()
		local d = rich(PlayerData, 14900)
		for _ = 1, 4 do
			assert(Shop.buy(d, "home"))
		end
		assert(d.homeTier == 5 and d.cash == 0)
		assert(not Shop.buy(d, "home"), "past the mansion")
	end,
	useOnlyWhatYouOwn = function()
		local Shop, PlayerData = load()
		local d = rich(PlayerData, 1000)
		assert(not Shop.buy(d, "use:moped"))
		Shop.buy(d, "ride:rollerblades")
		assert(Shop.buy(d, "use:foot") and d.equipped == "")
		assert(Shop.buy(d, "use:rollerblades") and d.equipped == "rollerblades")
	end,
	junkRequestsAreRefused = function()
		local Shop, PlayerData = load()
		local d = rich(PlayerData, 1000)
		for _, item in { "", "ride:", "ride:spaceship", "part:rollerblades", "part::", "home:9", "use:", "free money" } do
			assert(not Shop.buy(d, item), item)
		end
		assert(d.cash == 1000)
	end,
}

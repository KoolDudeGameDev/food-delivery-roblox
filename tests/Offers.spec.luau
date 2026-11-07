local function load()
	local Shared = script.Parent.Parent.Shared
	return require(Shared.Offers), require(Shared.WorldLayout), require(Shared.Pay), require(Shared.Data.OrderTypes)
end

return {
	offerUsesThePayFormulas = function()
		local Offers, WorldLayout, Pay, Types = load()
		local red = WorldLayout.byId.red
		local offer = Offers.make(red, "rush", Random.new(1))
		local d = Offers.distance(red)
		-- Red's chaser is a Chihuahua (tiny, danger 0.5); rush adds a star
		assert(offer.stars == Pay.difficulty(d, 0.5, 0, 1), `stars {offer.stars}`)
		assert(offer.pay == Pay.offerPay(d, offer.stars, offer.food, Types.rush))
		assert(math.abs(offer.max - Pay.timeLimit(d, offer.food, Types.rush, 0)) < 1e-6)
		assert(offer.houseId == "red")
	end,
	parcelOnlyPlacesNeverGetFood = function()
		local Offers, WorldLayout = load()
		local rng = Random.new(7)
		for _ = 1, 50 do
			assert(not Offers.make(WorldLayout.byId.cemetery, "normal", rng).food)
			assert(not Offers.make(WorldLayout.byId.red, "fragile", rng).food)
		end
	end,
	boardHasThreeDifferentAllowedHouses = function()
		local Offers = load()
		for seed = 1, 30 do
			local offers = Offers.renew({ rng = Random.new(seed), maxStars = 3, exclude = { red = true } })
			assert(#offers == 3, `seed {seed}: {#offers} offers`)
			local seen = {}
			for i, o in offers do
				assert(o.houseId ~= "red", "excluded house offered")
				assert(not seen[o.houseId], "same house twice")
				assert(o.stars <= 3, "too hard for the player")
				seen[o.houseId] = true
				if i > 1 then
					assert(offers[i - 1].stars <= o.stars, "not easiest first")
				end
			end
		end
	end,
	boardAlwaysHasAPlainOffer = function()
		local Offers = load()
		for seed = 1, 30 do
			local plain = false
			for _, o in Offers.renew({ rng = Random.new(seed), maxStars = 5 }) do
				plain = plain or o.typeKey == "normal"
			end
			assert(plain, `seed {seed} has no plain offer`)
		end
	end,
	problemChecksCarryAndBulky = function()
		local Offers = load()
		local plain = { typeKey = "normal" }
		local bulky = { typeKey = "bulky" }
		assert(Offers.problem(1, 0, plain) == nil)
		assert(Offers.problem(1, 1, plain) ~= nil, "full")
		assert(Offers.problem(1, 0, bulky) ~= nil, "bulky needs carry 3")
		assert(Offers.problem(3, 0, bulky) == nil)
	end,
}

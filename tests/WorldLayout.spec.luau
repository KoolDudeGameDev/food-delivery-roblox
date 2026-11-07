-- The Blueprint's graybox checks (§7.3, §8, §16) that can run without playing.
local function load()
	return require(script.Parent.Parent.Shared.WorldLayout)
end

local function onRoad(L, x, z, margin)
	for _, r in L.ROADS do
		if math.abs(x - r[3]) < r[1] / 2 + margin and math.abs(z - r[4]) < r[2] / 2 + margin then
			return true
		end
	end
	return false
end

return {
	twentyOneCustomersPlusTheCemeteryWithUniqueIds = function()
		local L = load()
		assert(#L.HOUSES == 22, `{#L.HOUSES} delivery places`)
		local ids = {}
		for _, h in L.HOUSES do
			assert(not ids[h.id], `duplicate id {h.id}`)
			ids[h.id] = true
			assert(L.byId[h.id] == h)
			assert(L.HOUSE_SIZES[h.size], `{h.id} has an unknown size`)
			assert(h.district ~= "", `{h.id} has no district`)
		end
	end,
	sevenLotsAtLeast72mApart = function()
		local L = load()
		assert(#L.LOTS == 7)
		for i, a in L.LOTS do
			for j = i + 1, #L.LOTS do
				local b = L.LOTS[j]
				local d = math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2)
				assert(d >= 72, `{a.id} and {b.id} are {d} m apart`)
			end
		end
	end,
	lotsAreOffTheRoads = function()
		local L = load()
		for _, lot in L.LOTS do
			assert(not onRoad(L, lot.x, lot.z, 12), `{lot.id} is on a road`)
		end
	end,
	everyDoorstepIsInsideItsYardAndOffTheRoad = function()
		local L = load()
		for _, h in L.HOUSES do
			if h.id == "cemetery" then
				continue
			end
			local size = L.HOUSE_SIZES[h.size]
			local reach = math.max(size.yardU, size.yardV)
			local d = math.sqrt((h.step.x - h.x) ^ 2 + (h.step.z - h.z) ^ 2)
			assert(d < reach, `{h.id}'s doorstep is {d} m from the house`)
			assert(not onRoad(L, h.step.x, h.step.z, 0), `{h.id}'s doorstep is on a road`)
		end
		local c, g = L.CEMETERY, L.byId.cemetery.step
		assert(g.x > c.x0 and g.x < c.x1 and g.z > c.z0 and g.z < c.z1, "the grave is outside the cemetery")
	end,
	everythingIsOnTheMap = function()
		local L = load()
		for _, p in L.HOUSES do
			assert(math.abs(p.x) < L.EDGE and math.abs(p.z) < L.EDGE, `{p.id} is off the map`)
		end
		for _, p in L.LOTS do
			assert(math.abs(p.x) < L.EDGE - 10 and math.abs(p.z) < L.EDGE - 10, `{p.id} is off the map`)
		end
	end,
}

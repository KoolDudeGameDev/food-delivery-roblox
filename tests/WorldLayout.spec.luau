-- The Blueprint's graybox checks (§7.3, §8, §16) that can run without playing.
local function load()
	return require(script.Parent.Parent.Shared.WorldLayout)
end

local SIDEWALK = 1.5

local function overlaps(a, b, margin)
	return a.x0 < b.x1 + margin and b.x0 < a.x1 + margin and a.z0 < b.z1 + margin and b.z0 < a.z1 + margin
end

local function roadRect(r)
	return { x0 = r.x - r.w / 2, x1 = r.x + r.w / 2, z0 = r.z - r.d / 2, z1 = r.z + r.d / 2 }
end

return {
	twentyOneCustomersSplitSevenSevenSevenPlusTheCemetery = function()
		local L = load()
		assert(#L.HOUSES == 22, `{#L.HOUSES} delivery places`)
		local ids, rings = {}, { inner = 0, outer = 0, rural = 0 }
		for _, h in L.HOUSES do
			assert(not ids[h.id], `duplicate id {h.id}`)
			ids[h.id] = true
			assert(L.byId[h.id] == h)
			assert(L.HOUSE_SIZES[h.size], `{h.id} has an unknown size`)
			assert(h.district ~= "", `{h.id} has no district`)
			if h.id ~= "cemetery" then
				rings[h.ring] += 1
			end
		end
		assert(rings.inner == 7 and rings.outer == 7 and rings.rural == 7, `rings {rings.inner}/{rings.outer}/{rings.rural}`)
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
	nothingOverlaps = function()
		local L = load()
		local prints = L.footprints()
		for i, a in prints do
			for j = i + 1, #prints do
				local b = prints[j]
				if a.kind ~= "hub" and b.kind ~= "hub" then
					assert(not overlaps(a, b, 0), `{a.name} overlaps {b.name}`)
				end
			end
		end
	end,
	nothingSitsOnARoadOrSidewalk = function()
		local L = load()
		for _, p in L.footprints() do
			if p.kind ~= "hub" then
				for _, r in L.ROADS do
					assert(not overlaps(p, roadRect(r), SIDEWALK), `{p.name} is on {r.name}`)
				end
			end
		end
	end,
	everyDoorstepIsInsideItsYard = function()
		local L = load()
		for _, h in L.HOUSES do
			local y = h.yard
			assert(h.step.x > y.x0 and h.step.x < y.x1 and h.step.z > y.z0 and h.step.z < y.z1, `{h.id}'s doorstep is outside its yard`)
			assert(not L.onRoad(h.step.x, h.step.z, 0), `{h.id}'s doorstep is on a road`)
		end
	end,
	everyGateReachesARoad = function()
		local L = load()
		for _, h in L.HOUSES do
			if h.id ~= "cemetery" then
				local x, z = L.frame(h)(0, L.ROAD_REACH)
				assert(L.onRoad(x, z, 0), `{h.id}'s path doesn't reach a road`)
			end
		end
		-- The cemetery's gate opens onto its lane
		local c = L.CEMETERY
		assert(L.onRoad(c.x1 + 6, (c.z0 + c.z1) / 2, 0), "the cemetery gate doesn't reach its lane")
	end,
	everythingIsOnTheMap = function()
		local L = load()
		for _, p in L.footprints() do
			assert(p.x0 > -L.EDGE and p.x1 < L.EDGE and p.z0 > -L.EDGE and p.z1 < L.EDGE, `{p.name} is off the map`)
		end
	end,
	treesStayOffEverything = function()
		local L = load()
		local trees = L.trees()
		assert(#trees > 50, `only {#trees} trees`)
		for _, t in trees do
			assert(not L.blocked(t.x, t.z, 3), "a tree is in the way")
		end
	end,
}

-- The built-in art kit (Data/Kit): every role builds from its real footprint, with sane boxes,
-- and the parts that gameplay looks for are there (a Door to swing, Windows to light, Paint).
local function load()
	local Shared = script.Parent.Parent.Shared
	return require(Shared.Data.Kit), require(Shared.WorldLayout), require(Shared.Data.Homes)
end

local function roles()
	local Kit, WorldLayout, Homes = load()
	local list = {
		Warehouse = WorldLayout.WAREHOUSE,
		Dealer = { color = "3f7fd6" },
		Mechanic = { color = "6a6f78" },
		Barangay = WorldLayout.BARANGAY,
		House_large = { color = "d6402b" },
	}
	for i, t in WorldLayout.TOWERS do
		list[`Tower{i}`] = t
	end
	for i, def in Homes do
		list[`Home_{i}`] = { w = def.size[1] * 2 * def.scale, d = def.size[2] * 2 * def.scale, h = def.height * def.scale }
	end
	local built = {}
	for role, params in list do
		built[role] = (Kit :: any)[role:gsub("^Tower%d+$", "Tower")](params)
	end
	return built
end

local function has(boxes, test): boolean
	for _, b in boxes do
		if test(b) then
			return true
		end
	end
	return false
end

return {
	everyRoleBuildsSaneBoxes = function()
		for role, boxes in roles() do
			assert(#boxes > 3, `{role} has {#boxes} boxes`)
			for _, b in boxes do
				assert(type(b[1]) == "string" and #b[5] == 6, `{role}: {b[1]} name and colour`)
				for i = 2, 4 do
					assert(b[i] > 0 and b[i] < 60, `{role}: {b[1]} size {b[i]}`)
				end
				for i = 6, 8 do
					assert(b[i] == b[i], `{role}: {b[1]} position is NaN`)
				end
			end
		end
	end,
	housesKeepWhatGameplayNeeds = function()
		local built = roles()
		assert(has(built.House_large, function(b)
			return b[1] == "Door"
		end), "the large house has a Door to swing")
		for role, boxes in built do
			if role:match("^Home_") then
				assert(has(boxes, function(b)
					return b[9] and b[9].tag == "Paint"
				end), `{role} takes paint`)
			end
		end
		for _, role in { "House_large", "Barangay", "Tower1", "Warehouse", "Home_3" } do
			assert(has(built[role], function(b)
				return b[9] and b[9].tag == "Window"
			end), `{role} lights up at night`)
		end
	end,
	homesStayClearOfTheGardenDecor = function()
		local Cosmetics = require(script.Parent.Parent.Shared.Data.Cosmetics)
		local function overlap(a0, a1, b0, b1)
			return a0 < b1 and b0 < a1
		end
		for role, boxes in roles() do
			if role:match("^Home_") then
				for _, b in boxes do
					if not (b[9] and (b[9].rx or b[9].rz)) then -- tilted flaps and roofs stay above the decor
						for _, decor in Cosmetics.DECOR do
							for _, c in decor.boxes do
								local hit = overlap(b[6] - b[2] / 2, b[6] + b[2] / 2, c[5] - c[1] / 2, c[5] + c[1] / 2)
									and overlap(b[8] - b[4] / 2, b[8] + b[4] / 2, c[7] - c[3] / 2, c[7] + c[3] / 2)
								assert(not hit, `{role}: {b[1]} overlaps the {decor.key}`)
							end
						end
					end
				end
			end
		end
	end,
}

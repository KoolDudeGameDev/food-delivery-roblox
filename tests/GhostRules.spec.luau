-- The White Lady (GDD §5.1; prototype `ghost.js`): only in the cemetery after dark, drifting
-- straight at you through the tombs. Slower than you, but she never stops. Metres and seconds.
local function load()
	local Shared = script.Parent.Parent.Shared
	return require(Shared.GhostRules), require(Shared.Config)
end

local YARD = { x0 = 0, x1 = 40, z0 = 0, z1 = 36 }
local START = { x = 35, z = 13 }

local function runner(id, x, z, feet)
	return { id = id, x = x, z = z, feet = feet or 0 }
end

return {
	sheWaitsForNightAndSomeoneInside = function()
		local Ghost = load()
		local lady = Ghost.new(YARD, START)
		local r = Ghost.step(lady, { runner("a", 20, 18) }, false, 0.1)
		assert(not lady.active and not r.appeared, "not by day")
		r = Ghost.step(lady, { runner("a", 60, 18) }, true, 0.1)
		assert(not lady.active, "not with nobody in the cemetery")
		r = Ghost.step(lady, { runner("a", 20, 18) }, true, 0.1)
		assert(lady.active and r.appeared and Ghost.shown(lady), "night, and someone among the graves")
	end,
	sheDriftsStraightAtTheNearestOneInside = function()
		local Ghost, Config = load()
		local lady = Ghost.new(YARD, START)
		Ghost.step(lady, { runner("far", 5, 13), runner("near", 30, 13), runner("outside", 36, 40) }, true, 0)
		local before = lady.x
		Ghost.step(lady, { runner("far", 5, 13), runner("near", 30, 13), runner("outside", 36, 40) }, true, 1)
		assert(math.abs((before - lady.x) - Config.GHOST_SPEED) < 1e-6, `moved {before - lady.x} m towards the nearest`)
		assert(math.abs(lady.z - 13) < 1e-6, "straight at them")
	end,
	sheStaysInTheCemetery = function()
		local Ghost = load()
		local lady = Ghost.new(YARD, { x = 39.5, z = 35.5 })
		Ghost.step(lady, { runner("a", 20, 20) }, true, 0)
		assert(lady.x == YARD.x1 - 1 and lady.z == YARD.z1 - 1, `a metre in from the wall, not {lady.x},{lady.z}`)
	end,
	herTouchScaresThenSheComesBackFromTheFarCorner = function()
		local Ghost, Config = load()
		local lady = Ghost.new(YARD, START)
		local r = Ghost.step(lady, { runner("a", 35, 13.5) }, true, 0.1)
		assert(r.scared == "a", "close enough to touch")
		assert(not Ghost.shown(lady), "she fades out")
		-- They're east of the middle and south of it, so she comes back from the west and the north
		assert(lady.x == YARD.x0 + 6 and lady.z == YARD.z1 - 8, `from the corner away from them, not {lady.x},{lady.z}`)
		r = Ghost.step(lady, { runner("a", lady.x, lady.z) }, true, Config.GHOST_COOLDOWN / 2)
		assert(r.scared == nil and not Ghost.shown(lady), "a moment to run")
		Ghost.step(lady, { runner("a", 35, 13.5) }, true, Config.GHOST_COOLDOWN)
		assert(Ghost.shown(lady), "then she's back")
	end,
	jumpingOverHerIsSafe = function()
		local Ghost = load()
		local lady = Ghost.new(YARD, START)
		local r = Ghost.step(lady, { runner("a", 35, 13.5, 1.5) }, true, 0.1)
		assert(r.scared == nil)
	end,
	sheGoesBackToHerSpotByDay = function()
		local Ghost = load()
		local lady = Ghost.new(YARD, START)
		Ghost.step(lady, { runner("a", 10, 10) }, true, 2)
		Ghost.step(lady, { runner("a", 10, 10) }, false, 0.1)
		assert(not lady.active and lady.x == START.x and lady.z == START.z)
	end,
}

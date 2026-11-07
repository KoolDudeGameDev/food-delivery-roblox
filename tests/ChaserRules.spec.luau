-- The chase (milestone 2): the prototype's dog behaviour, run on the server.
local function load()
	local Shared = script.Parent.Parent.Shared
	return require(Shared.ChaserRules), require(Shared.Config)
end

-- A long test yard, so only speed decides whether the dog catches up.
local YARD = { x0 = 0, x1 = 60, z0 = -10, z1 = 10 }

local function dogOf(Rules, size, x)
	local dog = Rules.new({ id = "test", dog = "aspin", yard = YARD }, size)
	dog.x, dog.z = x, 0
	return dog
end

-- A runner starts at x = 5 and runs east at RUN; the dog starts behind them at x = 1.
local function chase(size): boolean
	local Rules, Config = load()
	local dog = dogOf(Rules, size, 1)
	local runner = { id = "p", x = 5, z = 0, feet = 0 }
	local dt = 0.05
	for _ = 1, math.floor(50 / Config.RUN / dt) do -- until the runner is near the far fence
		runner.x += Config.RUN * dt
		if Rules.step(dog, { runner }, dt, Random.new(1)).bite then
			return true
		end
	end
	return false
end

return {
	aChihuahuaCatchesARunner = function()
		assert(chase("tiny"), "a tiny dog should catch a runner")
	end,
	aGreatDaneDoesNot = function()
		assert(not chase("giant"), "a giant dog shouldn't catch a runner")
	end,
	dogsStayInTheirYard = function()
		local Rules = load()
		local dog = dogOf(Rules, "tiny", 55)
		local outside = { id = "p", x = 80, z = 0, feet = 0 }
		for _ = 1, 200 do
			Rules.step(dog, { outside }, 0.1, Random.new(2))
			assert(dog.x >= YARD.x0 and dog.x <= YARD.x1 and dog.z >= YARD.z0 and dog.z <= YARD.z1, "the dog left its yard")
		end
		assert(dog.chasing == nil, "a dog chases only people in its yard")
	end,
	itChasesTheNearestPersonInTheYard = function()
		local Rules = load()
		local dog = dogOf(Rules, "medium", 30)
		local near = { id = "near", x = 34, z = 0, feet = 0 }
		local far = { id = "far", x = 50, z = 0, feet = 0 }
		local result = Rules.step(dog, { far, near }, 0.05, Random.new(3))
		assert(dog.chasing == "near" and result.started == "near")
	end,
	bitesWaitBetweenEachOther = function()
		local Rules, Config = load()
		local dog = dogOf(Rules, "medium", 10)
		local still = { id = "p", x = 10.5, z = 0, feet = 0 }
		Rules.step(dog, { still }, Config.DOG_ALERT + 0.01, Random.new(4)) -- notices, barks, warning over
		assert(Rules.step(dog, { still }, 0.05, Random.new(4)).bite == "p", "first bite")
		assert(Rules.step(dog, { still }, 0.05, Random.new(4)).bite == nil, "bit again too soon")
		local waited
		for _ = 1, math.ceil(Config.BITE_GAP / 0.05) do
			waited = Rules.step(dog, { still }, 0.05, Random.new(4)).bite or waited
		end
		assert(waited == "p", "never bit again")
	end,
	jumpingClearsASmallDogButNotABigOne = function()
		local Rules, Config = load()
		local function afterAlert(size, runner)
			local dog = dogOf(Rules, size, 10)
			Rules.step(dog, { runner }, Config.DOG_ALERT + 0.01, Random.new(5)) -- the warning
			return Rules.step(dog, { runner }, 0.05, Random.new(5)).bite
		end
		assert(afterAlert("tiny", { id = "p", x = 10.3, z = 0, feet = 1 }) == nil)
		assert(afterAlert("giant", { id = "p", x = 10.3, z = 0, feet = 0.8 }) == "p")
	end,
	aDogBarksBeforeItChases = function()
		local Rules, Config = load()
		local dog = dogOf(Rules, "tiny", 10)
		local runner = { id = "p", x = 11, z = 0, feet = 0 }
		local first = Rules.step(dog, { runner }, 0.05, Random.new(6))
		assert(first.started == "p" and first.bite == nil, "noticed, no bite")
		assert(Rules.state(dog) == "alert")
		local x = dog.x
		for _ = 1, math.floor(Config.DOG_ALERT / 0.05) - 2 do
			assert(Rules.step(dog, { runner }, 0.05, Random.new(6)).bite == nil, "bit during the warning")
		end
		assert(dog.x == x, "moved during the warning")
		for _ = 1, 4 do
			Rules.step(dog, { runner }, 0.05, Random.new(6))
		end
		assert(Rules.state(dog) == "chase", "never gave chase")
	end,
	aDogTrotsHomeWhenYouLeave = function()
		local Rules, Config = load()
		local dog = dogOf(Rules, "medium", 30)
		local home = { x = dog.home.x, z = dog.home.z }
		local runner = { id = "p", x = 50, z = 0, feet = 0 }
		Rules.step(dog, { runner }, Config.DOG_ALERT + 0.01, Random.new(7))
		for _ = 1, 40 do
			Rules.step(dog, { runner }, 0.05, Random.new(7))
		end
		runner.x = 80 -- out of the yard
		local closest = math.huge
		for _ = 1, 400 do
			Rules.step(dog, { runner }, 0.05, Random.new(7))
			closest = math.min(closest, (dog.x - home.x) ^ 2 + (dog.z - home.z) ^ 2)
		end
		assert(closest < 1, "didn't go home")
		assert(Rules.state(dog) == "idle")
	end,
}

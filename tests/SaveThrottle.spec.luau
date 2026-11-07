-- Garage changes save straight away, but a burst of them must not become a burst of
-- DataStore writes: at most one save per gap, plus one at the end of the gap.
local GAP = 0.3

local function counter()
	local n = { count = 0 }
	return n, function()
		n.count += 1
	end
end

return {
	firstRequestSavesAtOnce = function()
		local SaveThrottle = require(script.Parent.Parent.Server.SaveThrottle)
		local n, save = counter()
		SaveThrottle.new(GAP, save):request()
		assert(n.count == 1, `saved {n.count} times`)
	end,
	burstSavesOnceNowAndOnceAtTheEndOfTheGap = function()
		local SaveThrottle = require(script.Parent.Parent.Server.SaveThrottle)
		local n, save = counter()
		local throttle = SaveThrottle.new(GAP, save)
		for _ = 1, 10 do
			throttle:request()
		end
		assert(n.count == 1, `saved {n.count} times during the burst`)
		task.wait(GAP + 0.15)
		assert(n.count == 2, `saved {n.count} times after the gap`)
		task.wait(GAP + 0.15)
		assert(n.count == 2, `saved {n.count} times with nothing new to save`)
	end,
	requestAfterTheGapSavesAtOnce = function()
		local SaveThrottle = require(script.Parent.Parent.Server.SaveThrottle)
		local n, save = counter()
		local throttle = SaveThrottle.new(GAP, save)
		throttle:request()
		task.wait(GAP + 0.05)
		throttle:request()
		assert(n.count == 2, `saved {n.count} times`)
	end,
}

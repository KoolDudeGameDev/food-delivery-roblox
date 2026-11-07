-- Coalesces saves: the first request saves at once, and any requests inside the next
-- `gap` seconds become one save when the gap ends. ProfileStore's Save() is an
-- immediate UpdateAsync, and the whole server shares about 60 + 10 per player writes
-- a minute, so one player spamming the garage must not spend it.
local SaveThrottle = {}
SaveThrottle.__index = SaveThrottle

function SaveThrottle.new(gap: number, save: () -> ())
	return setmetatable({ gap = gap, save = save, lastAt = -math.huge, pending = false }, SaveThrottle)
end

function SaveThrottle:request()
	if self.pending then
		return
	end
	local wait = self.lastAt + self.gap - os.clock()
	if wait <= 0 then
		self.lastAt = os.clock()
		self.save()
		return
	end
	self.pending = true
	task.delay(wait, function()
		self.pending = false
		self.lastAt = os.clock()
		self.save()
	end)
end

return SaveThrottle

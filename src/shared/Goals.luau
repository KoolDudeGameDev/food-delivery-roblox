-- Daily goals (prototype `goals.js`, GDD §10.2): three a day, the same for everyone on the same
-- date, each paid once. A new goal is one more row. The prototype's "finish a shady job" goal
-- waits for night jobs.
local Goals = {}

export type Goal = { type: number, progress: number, done: boolean }
export type State = { day: string, list: { Goal } }

Goals.COUNT = 3
Goals.TYPES = {
	{ event = "delivered", count = 8, reward = 250, text = "Make 8 deliveries" },
	{ event = "dogYard", count = 4, reward = 300, text = "Deliver to 4 yards with a chaser" },
	{ event = "fiveStar", count = 3, reward = 350, text = "Earn 5 stars 3 times" },
	{ event = "hardOrder", count = 2, reward = 400, text = "Finish 2 orders of 4 stars or more" },
	{ event = "cemeteryNight", count = 1, reward = 350, text = "Deliver to the cemetery at night" },
	{ event = "streak", count = 5, reward = 300, text = "Reach a streak of 5" },
}

function Goals.indexOf(event: string): number?
	for i, t in Goals.TYPES do
		if t.event == event then
			return i
		end
	end
	return nil
end

-- The prototype's string hash (h * 31 + byte, kept to 32 bits).
local function hash(text: string): number
	local h = 7
	for i = 1, #text do
		h = (h * 31 + string.byte(text, i)) % 4294967296
	end
	return h
end

-- The three goals for a date, picked from the date so every server agrees.
function Goals.forDay(day: string): { Goal }
	-- Walk the list from a date-picked start, a few apart. The prototype stepped 3 through 7
	-- types; with 6, a step of 3 would only ever reach 2 of them, so the walk takes every type
	-- once (i from 0 to #TYPES - 1) and can never loop forever.
	local start, list = hash(day), {}
	local total = #Goals.TYPES
	for i = 0, total - 1 do
		if #list >= Goals.COUNT then
			break
		end
		table.insert(list, { type = (start + i * 5) % total + 1, progress = 0, done = false })
	end
	return list
end

-- The player's goals for today, starting fresh on a new day.
function Goals.current(state: State?, day: string): State
	if not state or state.day ~= day or type(state.list) ~= "table" or #state.list ~= Goals.COUNT then
		return { day = day, list = Goals.forDay(day) }
	end
	return state
end

-- Counts an event towards today's goals. Returns the pesos earned by goals it finished. A streak
-- goal measures the best streak rather than adding up.
function Goals.count(state: State, event: string, by: number): number
	local reward = 0
	for _, g in state.list do
		local t = Goals.TYPES[g.type]
		if t and not g.done and t.event == event then
			g.progress = if event == "streak" then math.max(g.progress, by) else g.progress + by
			if g.progress >= t.count then
				g.progress = t.count
				g.done = true
				reward += t.reward
			end
		end
	end
	return reward
end

return Goals

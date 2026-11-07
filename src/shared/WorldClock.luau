-- Time of day and world events as pure rules (prototype `daynight.js`, `events.js`; GDD §10.1).
-- The server runs the clock and the events (WorldService); both sides read these.
local Config = require(script.Parent.Config)

local WorldClock = {}

-- Night in the prototype: the sun is less than an eighth of the way up (about 6:30 to 17:30 is day).
function WorldClock.isNight(clockTime: number): boolean
	return clockTime < 6.5 or clockTime > 17.5
end

-- The clock (0 to 24) after dt seconds.
function WorldClock.advance(clockTime: number, dt: number): number
	return (clockTime + dt / Config.DAY_LENGTH * 24) % 24
end

export type Weather = { rain: boolean, festival: string } -- festival is "", "fiesta" or "undas"

-- The extra pay share events add to a delivery (the prototype's eventBonus).
function WorldClock.eventBonus(weather: Weather, food: boolean, houseId: string): number
	return (if weather.rain then Config.RAIN_PAY else 0)
		+ (if weather.festival == "fiesta" and food then Config.FIESTA_PAY else 0)
		+ (if weather.festival == "undas" and houseId == "cemetery" then Config.UNDAS_PAY else 0)
end

return WorldClock

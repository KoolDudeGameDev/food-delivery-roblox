-- The shared world (GDD §10.1, Blueprint §11): the day and night clock, rain, brownouts, and the
-- odd fiesta or Undas, run on the server so everyone in the server sees the same town. Timings
-- are the prototype's (`events.js`), except the day length, which follows the Blueprint.
-- Clients read Lighting.ClockTime and workspace attributes Rain, Brownout and Festival.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldClock = require(ReplicatedStorage.Shared.WorldClock)

local WorldService = {}

local weather = { rain = false, brownout = false, festival = "" }
local timers = { rain = 0, brownout = 0, festival = 0 }
local left = { rain = 0, brownout = 0, festival = 0 }
local sinceLights = 0
local clock = Config.START_TIME
local sinceWrite = 0
local rng = Random.new()

local function between(range: { number }): number
	return rng:NextNumber(range[1], range[2])
end

local function announce(text: string)
	ReplicatedStorage.Remotes.Notify:FireAllClients({ kind = "toast", text = text })
end

function WorldService.isNight(): boolean
	return WorldClock.isNight(clock)
end

function WorldService.weather(): WorldClock.Weather
	return { rain = weather.rain, festival = weather.festival }
end

-- Lights that tell the time (Blueprint §11). Each lamp and window has its own moment, so the
-- town lights up one by one through the half hour after 17:30 and goes out the same way after
-- dawn. A brownout flickers the lamps three times, then cuts them and the windows. Candles burn
-- at night and all through Undas, brownout or not.
local LAMP_ON, LAMP_OFF = Color3.fromHex("ffe2a8"), Color3.fromHex("8a8f96")
local WINDOW_ON, WINDOW_OFF = Color3.fromHex("ffd98a"), Color3.fromHex("7fa6c9")
local CANDLE_ON, CANDLE_OFF = Color3.fromHex("ffcf6b"), Color3.fromHex("fff4d8")
local shown: { [Instance]: boolean } = {}
local flickerUntil = 0

-- Lit at this clock time, for a light switched on `offset` hours after dusk begins.
local function litAt(t: number, offset: number): boolean
	return t >= 17.5 + offset or t < 6.5 - offset
end

local function show(part: BasePart, on: boolean, onColor: Color3, offColor: Color3)
	if shown[part] == on then
		return
	end
	shown[part] = on
	part.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
	part.Color = if on then onColor else offColor
	local light = part:FindFirstChildOfClass("PointLight")
	if light then
		light.Enabled = on
	end
end

local function updateLights()
	local t = clock
	local flicker = os.clock() < flickerUntil
	for i, bulb in CollectionService:GetTagged("Streetlight") do
		local offset = ((bulb:GetAttribute("Order") or i) * 7 % 30) / 60 -- up to half an hour
		local on = litAt(t, offset) and not weather.brownout
		if flicker then
			on = math.floor(os.clock() * 4) % 2 == 0 -- the lights stutter before they die
		end
		show(bulb, on, LAMP_ON, LAMP_OFF)
	end
	for i, window in CollectionService:GetTagged("Window") do
		local offset = (i * 11 % 40) / 60
		show(window, litAt(t, offset) and not weather.brownout, WINDOW_ON, WINDOW_OFF)
	end
	local candles = WorldClock.isNight(t) or weather.festival == "undas"
	for _, candle in CollectionService:GetTagged("Candle") do
		show(candle, candles, CANDLE_ON, CANDLE_OFF)
	end
	-- The town's own light: darker at night, much darker in a brownout
	local night = WorldClock.isNight(t)
	local ambient = if night and weather.brownout then 25 elseif night then 70 else 128
	local now = Lighting.OutdoorAmbient.R * 255
	local level = now + (ambient - now) * 0.25 -- eased, a quarter of the way each update
	Lighting.OutdoorAmbient = Color3.fromRGB(level, level, level)
	Lighting.Ambient = Color3.fromRGB(level * 0.3, level * 0.3, level * 0.35)
end

local function showFolder(path: { string }, visible: boolean)
	local node: Instance? = workspace:FindFirstChild("World")
	for _, name in path do
		node = node and node:FindFirstChild(name)
	end
	if node then
		for _, p in node:GetDescendants() do
			if p:IsA("BasePart") then
				p.Transparency = if visible then 0 else 1
			end
		end
	end
end

local function setRain(on: boolean)
	weather.rain = on
	workspace:SetAttribute("Rain", on)
	-- Rain closes in the view: thicker, greyer air and a duller sky (Blueprint §11)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Density = if on then 0.5 else 0.28
		atmosphere.Haze = if on then 2.6 else 1
		atmosphere.Color = if on then Color3.fromHex("9aa4ad") else Color3.fromHex("c7d4e0")
	end
	Lighting.Brightness = if on then 1.4 else 2.5
end

local function setFestival(name: string)
	weather.festival = name
	workspace:SetAttribute("Festival", name)
	showFolder({ "LogisticsDistrict", "FiestaBunting" }, name == "fiesta")
	showFolder({ "CemeteryDistrict", "UndasVisitors" }, name == "undas")
end

local function step(dt: number)
	-- The sky moves about a minute of game time a second, so twice a second is smooth enough
	-- and keeps the clock from replicating every frame
	clock = WorldClock.advance(clock, dt)
	sinceWrite += dt
	sinceLights += dt
	if sinceWrite >= 0.5 then
		sinceWrite = 0
		Lighting.ClockTime = clock
	end
	local night = WorldService.isNight()

	if left.rain > 0 then
		left.rain -= dt
		if left.rain <= 0 then
			setRain(false)
			timers.rain = between(Config.RAIN_EVERY)
		end
	else
		timers.rain -= dt
		if timers.rain <= 0 then
			left.rain = between(Config.RAIN_LASTS)
			setRain(true)
			announce("Rain! Better pay while it lasts")
		end
	end

	if left.brownout > 0 then
		left.brownout -= dt
		if left.brownout <= 0 then
			weather.brownout = false
			workspace:SetAttribute("Brownout", false)
			announce("Power is back")
			timers.brownout = between(Config.BROWNOUT_EVERY)
		end
	elseif night then
		timers.brownout -= dt
		if timers.brownout <= 0 then
			left.brownout = between(Config.BROWNOUT_LASTS)
			weather.brownout = true
			workspace:SetAttribute("Brownout", true)
			flickerUntil = os.clock() + 1.5
			announce("Brownout! The whole town went dark")
		end
	end

	if left.festival > 0 then
		left.festival -= dt
		if left.festival <= 0 then
			setFestival("")
			timers.festival = between(Config.FESTIVAL_EVERY)
		end
	else
		timers.festival -= dt
		if timers.festival <= 0 then
			left.festival = between(Config.FESTIVAL_LASTS)
			local name = if rng:NextNumber() < 0.5 then "fiesta" else "undas"
			setFestival(name)
			announce(if name == "fiesta" then "Barangay fiesta! Food pays more" else "Undas! The cemetery pays more")
		end
	end

	if sinceLights >= 0.5 or os.clock() < flickerUntil then
		sinceLights = 0
		updateLights()
	end
end

-- For tests and playtests: start an event now ("rain", "brownout", "fiesta", "undas").
function WorldService.startEvent(name: string)
	if name == "rain" then
		timers.rain = 0
	elseif name == "brownout" then
		timers.brownout = 0
	elseif name == "fiesta" or name == "undas" then
		left.festival = Config.FESTIVAL_LASTS[1]
		setFestival(name)
	end
end

function WorldService.start()
	Lighting.ClockTime = Config.START_TIME
	timers.rain = between({ 90, 180 }) -- the prototype's first waits are a little shorter
	timers.brownout = between({ 40, 90 })
	timers.festival = between({ 120, 240 })
	setRain(false)
	setFestival("")
	workspace:SetAttribute("Brownout", false)
	-- Playtest helper: set workspace attribute StartEvent to an event name to start it
	workspace:GetAttributeChangedSignal("StartEvent"):Connect(function()
		local name = workspace:GetAttribute("StartEvent")
		if type(name) == "string" and name ~= "" then
			WorldService.startEvent(name)
			workspace:SetAttribute("StartEvent", "")
		end
	end)
	RunService.Heartbeat:Connect(step)
end

return WorldService

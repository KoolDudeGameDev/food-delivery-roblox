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
local lit: boolean? = nil
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

local function setLamps(on: boolean)
	if lit == on then
		return
	end
	lit = on
	for _, bulb in CollectionService:GetTagged("Streetlight") do
		bulb.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
		bulb.Color = if on then Color3.fromHex("ffe2a8") else Color3.fromHex("8a8f96")
		local light = bulb:FindFirstChildOfClass("PointLight")
		if light then
			light.Enabled = on
		end
	end
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
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Density = if on then 0.42 else 0.28
	end
	Lighting.Brightness = if on then 1.6 else 2.5
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

	setLamps(night and not weather.brownout)
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

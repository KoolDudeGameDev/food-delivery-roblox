-- The soundscape (Blueprint §12), all local. Beds play everywhere and crossfade with where you
-- are and the world's state: birds in town, the outskirts' wind and frogs, crickets at night,
-- rain with the odd thunderclap. Placed sounds sit in the world: street walla at the towers and
-- the market, the warehouse belt, wind at the cemetery, fiesta music at the market. A dog barks
-- from its own body as it turns to chase, so you hear it behind a gate before you see it, and
-- the till rings when you're paid. Ids and volumes are in Data/Sounds.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage.Shared.Config)
local Sounds = require(ReplicatedStorage.Shared.Data.Sounds)
local WorldClock = require(ReplicatedStorage.Shared.WorldClock)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)

local Audio = {}

local S = Config.STUDS
local FADE = 1.5 -- how fast volumes follow their targets (per second)
local rng = Random.new()

type Faded = { sound: Sound, full: number, level: number, target: number }
local faded: { [string]: Faded } = {}
local thunder: Sound
local pay: Sound
local nextThunder = 0
local chasers: Instance?
local lastState: { [Model]: string } = {}
local nextBark: { [Model]: number } = {}

local function make(key: string, parent: Instance, looped: boolean): Sound
	local def = Sounds[key]
	local s = Instance.new("Sound")
	s.Name = key
	s.SoundId = `rbxassetid://{def.id}`
	s.Volume = def.volume
	s.Looped = looped
	s.Parent = parent
	return s
end

-- Heard at full volume within `near` m, fading out to nothing at `far` m.
local function spread(s: Sound, near: number, far: number)
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = near * S
	s.RollOffMaxDistance = far * S
end

local function fade(name: string, s: Sound)
	faded[name] = { sound = s, full = s.Volume, level = 0, target = 0 }
	s.Volume = 0
end

-- A looped sound placed at (x, z), in metres.
local function emitter(key: string, x: number, z: number, near: number, far: number): Sound
	local spot = Instance.new("Attachment")
	spot.Name = `Sound_{key}`
	spot.Position = WorldLayout.studs(x, z, 2) -- the terrain sits at the origin
	spot.Parent = workspace.Terrain
	local s = make(key, spot, true)
	spread(s, near, far)
	return s
end

function Audio.start()
	for _, key in { "birds", "rural", "crickets", "rain" } do
		fade(key, make(key, SoundService, true))
	end
	thunder = make("thunder", SoundService, false)
	pay = make("pay", SoundService, false)

	-- The town centre: the towers on the inner ring, and the market on the north spoke
	local market = WorldLayout.MARKET
	local marketZ = (market.z0 + market.z1) / 2
	for _, t in WorldLayout.TOWERS do
		emitter("street", t.x, t.z, 15, 70).Playing = true
	end
	emitter("street", 0, marketZ, 15, 70).Playing = true
	local w = WorldLayout.WAREHOUSE
	emitter("conveyor", w.x, w.z + w.d / 2 - 0.6, 4, 30).Playing = true
	local cem = WorldLayout.CEMETERY
	emitter("cemeteryWind", (cem.x0 + cem.x1) / 2, (cem.z0 + cem.z1) / 2, 10, 50).Playing = true
	fade("fiesta", emitter("fiesta", 0, marketZ, 25, 120))

	task.spawn(function()
		chasers = workspace:WaitForChild("Gameplay"):WaitForChild("Chasers")
	end)
end

-- A dog's call, from its body: a bark, a honk or a hiss.
local function call(model: Model)
	local body = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not body then
		return
	end
	local s = body:FindFirstChild("Call") :: Sound?
	if not s then
		local made = make(model:GetAttribute("Sound") or "bark", body, false)
		made.Name = "Call"
		spread(made, 6, 60)
		s = made
	end
	s.PlaybackSpeed = rng:NextNumber(0.9, 1.1)
	s:Play()
end

local function stepChasers(now: number)
	if not chasers then
		return
	end
	for _, model in chasers:GetChildren() do
		if not model:IsA("Model") then
			continue
		end
		local state = model:GetAttribute("State") or "idle"
		local was = lastState[model]
		lastState[model] = state
		-- One call as it turns on you, then every second or two while it chases
		if (state == "alert" and was ~= "alert") or (state == "chase" and now >= (nextBark[model] or 0)) then
			call(model)
			nextBark[model] = now + rng:NextNumber(1.2, 2.2)
		end
	end
	for model in lastState do
		if not model.Parent then
			lastState[model], nextBark[model] = nil, nil -- streamed out
		end
	end
end

function Audio.step(dt: number, now: number)
	local root = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local at = (if root then root.Position else workspace.CurrentCamera.CFrame.Position) / S
	local out = math.max(math.abs(at.X), math.abs(at.Z))
	local rural = math.clamp((out - WorldLayout.OUTER) / 30, 0, 1) -- 0 in town, 1 well out
	local night = WorldClock.isNight(Lighting.ClockTime)
	local rain = workspace:GetAttribute("Rain") == true
	local hush = if rain then 0.4 else 1 -- rain drowns out the rest

	faded.birds.target = (if night then 0 else 1 - rural) * hush
	faded.rural.target = (if night then 0 else rural) * hush
	faded.crickets.target = (if night then 0.6 + 0.4 * rural else 0) * hush
	faded.rain.target = if rain then 1 else 0
	faded.fiesta.target = if workspace:GetAttribute("Festival") == "fiesta" then 1 else 0
	local k = math.min(1, dt * FADE)
	for _, f in faded do
		f.level += (f.target - f.level) * k
		f.sound.Volume = f.full * f.level
		local on = f.level > 0.01
		if f.sound.Playing ~= on then
			f.sound.Playing = on
		end
	end

	if rain and now >= nextThunder then
		if nextThunder > 0 then
			thunder:Play()
		end
		nextThunder = now + rng:NextNumber(20, 45)
	elseif not rain then
		nextThunder = 0
	end

	stepChasers(now)
end

function Audio.paid()
	pay:Play()
end

return Audio

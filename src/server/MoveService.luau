-- The one place that sets a player's walking speed (the server caps it; GDD §13.2). Other
-- services report what affects it: the ride under you, a parcel in your arms, a bite's stun.
-- Sprint is a request from the client (hold Shift or SPRINT) spent from a stamina bar the
-- server runs, published as the player's "Stamina" attribute (0 to 100).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local MoveService = {}

local S = Config.STUDS
local TICK = 0.1

type Move = { ride: number?, parcel: boolean, wantSprint: boolean, stamina: number, winded: boolean, stunUntil: number }
local moves: { [Player]: Move } = {}

local function moveOf(player: Player): Move
	local m = moves[player]
	if not m then
		m = { ride = nil, parcel = false, wantSprint = false, stamina = 100, winded = false, stunUntil = 0 }
		moves[player] = m
	end
	return m
end

local function humanoidOf(player: Player): Humanoid?
	return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end

local function sprinting(player: Player, m: Move): boolean
	local humanoid = humanoidOf(player)
	return m.wantSprint and not m.winded and humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0.05
end

local function apply(player: Player)
	local m, humanoid = moveOf(player), humanoidOf(player)
	if not humanoid then
		return
	end
	if os.clock() < m.stunUntil then
		humanoid.WalkSpeed = 0
		return
	end
	local fast = sprinting(player, m)
	local speed = if m.ride then m.ride * (if fast then Config.RIDE_SPRINT else 1) else (if fast then Config.SPRINT else Config.RUN)
	humanoid.WalkSpeed = speed * (if m.parcel then Config.PARCEL_SLOW else 1) * S
end

-- The ride's speed in m/s while you're on it, or nil on foot (or parked at a gate).
function MoveService.setRide(player: Player, speed: number?)
	moveOf(player).ride = speed
	apply(player)
end

function MoveService.setParcel(player: Player, parcel: boolean)
	moveOf(player).parcel = parcel
	apply(player)
end

function MoveService.stun(player: Player, seconds: number)
	moveOf(player).stunUntil = os.clock() + seconds
	apply(player)
	task.delay(seconds, apply, player)
end

local function tick()
	for player, m in moves do
		local fast = sprinting(player, m)
		m.stamina = math.clamp(m.stamina + (if fast then -Config.STAMINA_DRAIN else Config.STAMINA_REGEN) * TICK, 0, 100)
		-- Run out and you're winded for a bit, or the sprint would restart straight away
		if m.stamina <= 0 then
			m.winded = true
		elseif m.stamina >= Config.WINDED_UNTIL then
			m.winded = false
		end
		player:SetAttribute("Stamina", math.floor(m.stamina))
		player:SetAttribute("Winded", m.winded)
		apply(player)
	end
end

function MoveService.start()
	ReplicatedStorage.Remotes.Sprint.OnServerEvent:Connect(function(player, want)
		if typeof(want) == "boolean" then
			moveOf(player).wantSprint = want
			apply(player)
		end
	end)
	local function watch(player: Player)
		moveOf(player)
		player.CharacterAdded:Connect(function()
			task.defer(apply, player)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		moves[player] = nil
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= TICK then
			acc = 0
			tick()
		end
	end)
end

return MoveService

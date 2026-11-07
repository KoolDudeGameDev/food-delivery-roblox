-- Getting up to speed, turning and stopping take time on a ride, and longer in the rain (the
-- prototype's movement blend: velocity eases towards what you steer, at accel x grip per second).
-- On foot it's near enough instant. This runs after the PlayerModule's controls each frame and
-- moves the character with the eased direction instead; the server still caps the speed.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Shop = require(ReplicatedStorage.Shared.Shop)

local Grip = {}

local player = Players.LocalPlayer
local controls
local latest
local eased = Vector3.zero

local function riding(character: Model): boolean
	for _, child in character:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("Ride") then
			return true
		end
	end
	return false
end

-- The way the player is steering, in world space, length 0 to 1.
local function steering(): Vector3
	local move = controls and controls:GetMoveVector() or Vector3.zero
	if move.Magnitude < 0.01 then
		return Vector3.zero
	end
	local camera = workspace.CurrentCamera.CFrame
	local forward = Vector3.new(camera.LookVector.X, 0, camera.LookVector.Z)
	local right = Vector3.new(camera.RightVector.X, 0, camera.RightVector.Z)
	if forward.Magnitude < 0.01 then
		return Vector3.zero
	end
	local world = right.Unit * move.X + forward.Unit * -move.Z
	return if world.Magnitude > 1 then world.Unit else world
end

function Grip.start()
	task.spawn(function()
		local module = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
		controls = module:GetControls()
	end)
	RunService:BindToRenderStep("Grip", Enum.RenderPriority.Character.Value + 1, function(dt)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not (humanoid and controls) then
			return
		end
		local onRide = riding(character)
		local accel = if onRide and latest then Shop.stats(latest).accel else Config.FOOT_ACCEL
		local grip = if onRide and workspace:GetAttribute("Rain") then Config.RAIN_GRIP else 1
		local want = steering()
		eased += (want - eased) * math.min(1, accel * grip * dt)
		if eased.Magnitude < 0.02 and want.Magnitude < 0.01 then
			eased = Vector3.zero
		end
		humanoid:Move(eased, false)
	end)
end

function Grip.onState(state)
	latest = state
end

return Grip

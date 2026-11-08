-- Ride hits (Gregory, 2026-11-08). The server decides every hit with RamRules, checked each frame
-- so a fast motorcycle can't skip past someone between checks. Whoever is hit flies off as a
-- ragdoll, now and then minus an arm or a leg, and pulls themselves together where they land.
-- Orders, their condition and freshness, and pay are never touched.
--
-- The pattern (as in Brawldude2/RagdollService, MIT): the server swaps the body's Motor6Ds for
-- ball sockets, since joints changed on a client don't replicate; the hit player's own client,
-- which owns its character's physics, goes limp and takes the fling (client/Ragdoll.luau).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local RamRules = require(ReplicatedStorage.Shared.RamRules)
local RideService = require(script.Parent.RideService)

local RamService = {}

local S = Config.STUDS
local rng = Random.new()
local immuneUntil: { [Player]: number } = {}

local function partsOf(player: Player): (BasePart?, Humanoid?)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root and humanoid and humanoid.Health > 0 then
		return root, humanoid
	end
	return nil, nil
end

local function socketBetween(part0: BasePart, part1: BasePart, c0: CFrame, c1: CFrame, made: { Instance })
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.CFrame, a1.CFrame = c0, c1
	a0.Parent, a1.Parent = part0, part1
	local socket = Instance.new("BallSocketConstraint")
	socket.Attachment0, socket.Attachment1 = a0, a1
	socket.LimitsEnabled, socket.TwistLimitsEnabled = true, true
	socket.UpperAngle, socket.TwistLowerAngle, socket.TwistUpperAngle = 60, -45, 45
	socket.Parent = part0
	table.insert(made, a0)
	table.insert(made, a1)
	table.insert(made, socket)
end

-- Lets the body go loose on ball sockets, except the limbs that come off, which just let go.
-- Two kinds of avatar: the current one, whose joints are AnimationConstraints with ball sockets
-- already built in beside them ("LeftShoulder" and "LeftShoulderBallSocket"), and the classic
-- one, whose joints are Motor6Ds and gets sockets made here. Returns how to put the body back.
local function fallApart(character: Model, humanoid: Humanoid, off: { string }): () -> ()
	local made: { Instance } = {}
	local disabled: { Instance } = {} -- joints, and built-in sockets of limbs that came off
	local collide: { [BasePart]: boolean } = {}
	local requiresNeck = humanoid.RequiresNeck
	humanoid.RequiresNeck = false
	for _, joint in character:GetDescendants() do
		local part0, part1
		if joint:IsA("Motor6D") then
			part0, part1 = joint.Part0, joint.Part1
		elseif joint:IsA("AnimationConstraint") then
			local a0, a1 = joint.Attachment0, joint.Attachment1
			part0 = a0 and a0.Parent :: BasePart?
			part1 = a1 and a1.Parent :: BasePart?
		else
			continue
		end
		if not (part0 and part1) or joint.Name == "Root" or joint.Name == "RootJoint" then
			continue -- the root stays with the body, so the camera and the ride follow it
		end
		local comesOff = table.find(off, (joint.Name:gsub(" ", ""))) ~= nil
		;(joint :: any).Enabled = false
		table.insert(disabled, joint)
		if joint:IsA("Motor6D") then
			if not comesOff then
				socketBetween(part0, part1, joint.C0, joint.C1, made)
			end
		elseif comesOff then
			local socket = joint.Parent and joint.Parent:FindFirstChild(joint.Name .. "BallSocket")
			if socket and socket:IsA("BallSocketConstraint") and socket.Enabled then
				socket.Enabled = false
				table.insert(disabled, socket)
			end
		end
		-- Limbs collide while loose, so they land on the ground and not through it
		for _, part in { part0, part1 } do
			if collide[part] == nil and part.Name ~= "HumanoidRootPart" then
				collide[part] = part.CanCollide
				part.CanCollide = true
			end
		end
	end
	return function()
		for _, instance in made do
			instance:Destroy()
		end
		for _, instance in disabled do
			(instance :: any).Enabled = true -- a limb that flew off pulls back on
		end
		for part, was in collide do
			part.CanCollide = was
		end
		humanoid.RequiresNeck = requiresNeck
	end
end

-- Public so a one-player playtest can send itself flying
function RamService.hit(rider: Player, other: Player, vx: number, vz: number)
	local root, humanoid = partsOf(other)
	if not (root and humanoid) then
		return
	end
	immuneUntil[other] = os.clock() + Config.RAM_IMMUNE
	local fx, fy, fz = RamRules.fling(vx, vz)
	local off = RamRules.detach(rng)
	local character = other.Character :: Model
	local mend = fallApart(character, humanoid, off)
	local Notify = ReplicatedStorage.Remotes.Notify
	Notify:FireClient(other, {
		kind = "rammed",
		text = if #off > 0 then `{rider.DisplayName} sent you flying… in pieces!` else `{rider.DisplayName} sent you flying!`,
		fling = Vector3.new(fx, fy, fz) * S,
		down = Config.RAM_DOWN,
	})
	Notify:FireClient(rider, { kind = "toast", text = `BONK! {other.DisplayName} goes flying` })
	task.delay(Config.RAM_DOWN, function()
		if other.Character == character then
			mend()
		end
	end)
end

local function step()
	local now = os.clock()
	local here = {}
	for _, player in Players:GetPlayers() do
		local root = partsOf(player)
		if root then
			table.insert(here, { player = player, x = root.Position.X / S, z = root.Position.Z / S, v = root.AssemblyLinearVelocity / S })
		end
	end
	for _, rider in here do
		if not RideService.riding(rider.player) or now < (immuneUntil[rider.player] or 0) then
			continue -- on foot, or in pieces themselves
		end
		local mover = { x = rider.x, z = rider.z, vx = rider.v.X, vz = rider.v.Z }
		for _, other in here do
			if other ~= rider and now >= (immuneUntil[other.player] or 0) and RamRules.hits(mover, other) then
				RamService.hit(rider.player, other.player, mover.vx, mover.vz)
			end
		end
	end
end

function RamService.start()
	RunService.Heartbeat:Connect(step)
	Players.PlayerRemoving:Connect(function(player)
		immuneUntil[player] = nil
	end)
end

return RamService

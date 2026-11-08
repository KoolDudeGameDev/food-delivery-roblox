local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Audio = require(script.Parent.Audio)
local Board = require(script.Parent.Board)
local Chasers = require(script.Parent.Chasers)
local Conveyor = require(script.Parent.Conveyor)
local Gates = require(script.Parent.Gates)
local Grip = require(script.Parent.Grip)
local Hud = require(script.Parent.Hud)
local Intro = require(script.Parent.Intro)
local Lights = require(script.Parent.Lights)
local Map = require(script.Parent.Map)
local Ragdoll = require(script.Parent.Ragdoll)
local Riding = require(script.Parent.Riding)
local ShopPanel = require(script.Parent.ShopPanel)
local Waypoint = require(script.Parent.Waypoint)
local Weather = require(script.Parent.Weather)

local Remotes = ReplicatedStorage.Remotes
local player = Players.LocalPlayer

local screen = Instance.new("ScreenGui")
screen.Name = "DeliveryUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
-- Children always draw over their parent. A script-made ScreenGui defaults to Global, where a
-- panel with a high ZIndex hides its own buttons (the empty shop panel)
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = player:WaitForChild("PlayerGui")

Hud.mount(screen)
Board.mount(screen)
Map.mount(screen)
ShopPanel.mount(screen)
Intro.mount(screen)
Chasers.start()
Gates.start()
Conveyor.start()
Grip.start()
Weather.start()
Audio.start()

local latest
Remotes.State.OnClientEvent:Connect(function(state)
	latest = state
	Hud.onState(state)
	Board.onState(state)
	Map.onState(state)
	ShopPanel.onState(state)
	Grip.onState(state)
	Waypoint.onState(state)
	Intro.onState(state, function(name)
		Hud.toast(if state.delivered == 0 then `Welcome home, {name}!` else `Welcome back, {name}!`)
	end)
end)
Remotes.Notify.OnClientEvent:Connect(function(message)
	Hud.onNotify(message)
	if message.kind == "accepted" then
		task.spawn(Conveyor.accepted, message.food == true)
	end
	if message.kind == "paid" then
		Audio.paid()
	end
	if message.kind == "paid" and message.houseId then
		Gates.delivered(message.houseId, message.total)
	end
	-- A bite knocks you back; the server already decided it and took its toll
	if message.kind == "bite" and typeof(message.knock) == "Vector3" then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			root.AssemblyLinearVelocity = message.knock
		end
	end
	-- A ride hit you: fly, in pieces now and then, and get back up where you land
	if message.kind == "rammed" and typeof(message.fling) == "Vector3" and type(message.down) == "number" then
		Ragdoll.fling(message.fling, message.down)
	end
end)

-- The waypoint's beam hangs off the character, so a new character needs it again
player.CharacterAdded:Connect(function(character)
	character:WaitForChild("HumanoidRootPart")
	if latest then
		Waypoint.onState(latest)
	end
end)

-- Sprint: hold Shift (or L3), or the SPRINT button on a phone. The server spends the stamina.
ContextActionService:BindAction("Sprint", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		Remotes.Sprint:FireServer(true)
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		Remotes.Sprint:FireServer(false)
	end
	return Enum.ContextActionResult.Pass
end, true, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift, Enum.KeyCode.ButtonL3)
ContextActionService:SetTitle("Sprint", "SPRINT")
ContextActionService:SetPosition("Sprint", UDim2.new(1, -170, 1, -90))

-- Panels close when you walk away from where you opened them
local openedAt: Vector3? = nil
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local spot = prompt.Parent
	if prompt.Name == "BoardPrompt" then
		Board.open()
	else
		local problem = ShopPanel.openFrom(prompt)
		if problem then
			Hud.toast(problem)
		end
	end
	openedAt = if spot and spot:IsA("BasePart") then spot.Position else nil
end)

RunService.RenderStepped:Connect(function(dt)
	local now = workspace:GetServerTimeNow()
	Hud.step(now)
	Board.step(now)
	Map.step()
	Chasers.step(dt, os.clock())
	Riding.step()
	Conveyor.step(dt)
	Lights.step()
	Weather.step()
	Waypoint.step(os.clock())
	Audio.step(dt, os.clock())
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root and openedAt and (root.Position - openedAt).Magnitude > 40 then
		Board.close()
		ShopPanel.close()
		openedAt = nil
	end
end)

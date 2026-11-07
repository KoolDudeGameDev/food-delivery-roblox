local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Board = require(script.Parent.Board)
local Hud = require(script.Parent.Hud)
local Waypoint = require(script.Parent.Waypoint)

local Remotes = ReplicatedStorage.Remotes
local player = Players.LocalPlayer

local screen = Instance.new("ScreenGui")
screen.Name = "DeliveryUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.Parent = player:WaitForChild("PlayerGui")

Hud.mount(screen)
Board.mount(screen)

local latest
Remotes.State.OnClientEvent:Connect(function(state)
	latest = state
	Hud.onState(state)
	Board.onState(state)
	Waypoint.onState(state)
end)
Remotes.Notify.OnClientEvent:Connect(Hud.onNotify)

-- The waypoint's beam hangs off the character, so a new character needs it again
player.CharacterAdded:Connect(function(character)
	character:WaitForChild("HumanoidRootPart")
	if latest then
		Waypoint.onState(latest)
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt.Name == "BoardPrompt" then
		Board.open()
	end
end)

RunService.RenderStepped:Connect(function()
	local now = workspace:GetServerTimeNow()
	Hud.step(now)
	Board.step(now)
	-- Walking away from the board closes it
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if Board.isOpen() and latest and root and (root.Position - latest.hub).Magnitude > 30 then
		Board.close()
	end
end)

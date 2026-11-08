-- The rider name from the intro (GDD §13.3 `Intro` remote). Players keep their own Roblox avatar;
-- the name they pick shows over their head once TextService has filtered it for everyone. Blank
-- uses their Roblox display name.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local PlayerData = require(ReplicatedStorage.Shared.PlayerData)
local DataService = require(script.Parent.DataService)
local OrderService = require(script.Parent.OrderService)

local NameService = {}

local GAP = 0.5 -- s between one player's name changes

local lastAt: { [Player]: number } = {}
local shown: { [Player]: { from: string, name: string } } = {} -- the filtered name, and what it came from

local function shownName(player: Player, name: string): string
	local cached = shown[player]
	if cached and cached.from == name then
		return cached.name
	end
	local result = player.DisplayName
	if name ~= "" then
		local ok, filtered = pcall(function()
			return TextService:FilterStringAsync(name, player.UserId):GetNonChatStringForBroadcastAsync()
		end)
		if ok and filtered ~= "" then
			result = filtered
		end
	end
	shown[player] = { from = name, name = result }
	return result
end

local function show(player: Player)
	local data = DataService.get(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if data and humanoid then
		humanoid.DisplayName = shownName(player, data.name)
	end
end

local function watch(player: Player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid", 10)
		show(player)
	end)
end

function NameService.start()
	ReplicatedStorage.Remotes.Intro.OnServerEvent:Connect(function(player, name)
		local clean, data = PlayerData.cleanName(name), DataService.get(player)
		local t = os.clock()
		if not (clean and data) or t - (lastAt[player] or 0) < GAP then
			return
		end
		lastAt[player] = t
		data.name = clean
		DataService.changed(player)
		show(player)
		OrderService.push(player)
	end)
	DataService.onLoaded(show)
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastAt[player], shown[player] = nil, nil
	end)
end

return NameService

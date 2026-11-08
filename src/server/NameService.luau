-- The rider name from the intro (GDD §13.3 `Intro` remote). Players keep their own Roblox avatar;
-- the name they pick shows over their head once TextService has filtered it for everyone. Blank
-- uses their Roblox display name.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Config = require(ReplicatedStorage.Shared.Config)
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

-- Still on the intro: from joining until they press Play, so ride hits leave them alone. The
-- server doesn't take the client's word for long: walking or riding off counts as playing.
local INTRO_ROAM = 10 -- m from where the intro started
local played: { [Player]: boolean } = {}
local introAt: { [Player]: Vector3 } = {}

function NameService.inIntro(player: Player): boolean
	if played[player] then
		return false
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return true
	end
	local at = introAt[player]
	if not at then
		introAt[player] = root.Position
	elseif (root.Position - at).Magnitude > INTRO_ROAM * Config.STUDS then
		played[player] = true
		player:SetAttribute("Playing", true)
		return false
	end
	return true
end

function NameService.start()
	ReplicatedStorage.Remotes.Intro.OnServerEvent:Connect(function(player, name, play)
		if play == true then
			played[player] = true -- before the rate limit, so Play right after typing still counts
			player:SetAttribute("Playing", true) -- the server's say, visible to playtests and clients
		end
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
		lastAt[player], shown[player], played[player], introAt[player] = nil, nil, nil, nil
	end)
end

return NameService

-- Loads and saves each player's data with ProfileStore: session-locked, so two servers never
-- write the same player and progress can't be duplicated (GDD §13.4). In Studio without API
-- access it uses a mock store, so data resets each playtest. Every save is checked on load.
-- Other services read data through get/waitFor and call changed() after every change.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileStore = require(script.Parent.Packages.ProfileStore)
local SaveThrottle = require(script.Parent.SaveThrottle)
local PlayerData = require(ReplicatedStorage.Shared.PlayerData)

local DataService = {}

local STORE_NAME = "PlayerData_v1"
local LOAD_TIMEOUT = 20
local SAVE_GAP = 6 -- at most one save per player per gap; leaving always saves

local store
local profiles: { [Player]: any } = {}
local saves: { [Player]: any } = {}
local loaded = Instance.new("BindableEvent")
local onLoaded: { (Player, PlayerData.Data) -> () } = {}

function DataService.get(player: Player): PlayerData.Data?
	local profile = profiles[player]
	return profile and profile.Data
end

-- Yields until the player's data is loaded (or they leave, or it times out).
function DataService.waitFor(player: Player): PlayerData.Data?
	local started = os.clock()
	while not profiles[player] and player.Parent == Players and os.clock() - started < LOAD_TIMEOUT do
		loaded.Event:Wait()
	end
	return DataService.get(player)
end

-- Runs for every player once their data is ready.
function DataService.onLoaded(callback: (Player, PlayerData.Data) -> ())
	table.insert(onLoaded, callback)
end

-- Call after every change: saves straight away, or at the end of the save gap.
function DataService.changed(player: Player)
	local save = saves[player]
	if save then
		save:request()
	end
end

local function onPlayerAdded(player: Player)
	local profile = store:StartSessionAsync(`Player_{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if not profile then
		if player.Parent == Players then
			player:Kick("We couldn't load your save. Please rejoin.")
		end
		return
	end
	profile:AddUserId(player.UserId)
	profile:Reconcile()
	PlayerData.sanitize(profile.Data)
	profile.OnSessionEnd:Connect(function()
		profiles[player], saves[player] = nil, nil
		player:Kick("Your save was opened on another server. Please rejoin.")
	end)
	if player.Parent ~= Players then
		profile:EndSession()
		return
	end
	saves[player] = SaveThrottle.new(SAVE_GAP, function()
		if profile:IsActive() then -- a delayed save after leaving: EndSession already saved
			profile:Save()
		end
	end)
	profiles[player] = profile
	loaded:Fire()
	for _, callback in onLoaded do
		task.spawn(callback, player, profile.Data)
	end
end

function DataService.start()
	store = ProfileStore.New(STORE_NAME, PlayerData.template())
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		local profile = profiles[player]
		if profile then
			profile:EndSession() -- saves; ProfileStore also saves everyone on shutdown
		end
		loaded:Fire()
	end)
end

return DataService

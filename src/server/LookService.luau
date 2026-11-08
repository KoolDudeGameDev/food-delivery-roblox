-- The rider's name and look from the intro (GDD §6.3, §13.3 `Intro` remote). The client sends a
-- name and a look; the server keeps them only if Looks allows them, saves them, shows the name
-- over the rider's head once TextService has filtered it, and dresses the character. Players keep
-- their own Roblox avatar unless they put on the rider outfit.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Looks = require(ReplicatedStorage.Shared.Data.Looks)
local DataService = require(script.Parent.DataService)
local OrderService = require(script.Parent.OrderService)

local LookService = {}

local GAP = 0.15 -- s between applying one player's changes; clicks in between merge into one
local APPEARANCE_WAIT = 5 -- s to wait for the avatar to load before dressing anyway

local wanted: { [Player]: { name: string, look: Looks.Look } } = {}
local busy: { [Player]: boolean } = {}
local shown: { [Player]: { from: string, name: string } } = {} -- the filtered name, and what it came from
local originals: { [Model]: HumanoidDescription } = {} -- each character's own avatar

-- The name others see: filtered for everyone, or their Roblox display name
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

local function cap(character: Model, look: Looks.Look)
	local old = character:FindFirstChild("RiderCap")
	if old then
		old:Destroy()
	end
	local head = character:FindFirstChild("Head") :: BasePart?
	if not (look.outfit and head) then
		return
	end
	local color = Looks.PAINTS[look.hat].color
	local crown = Instance.new("Part")
	crown.Name = "RiderCap"
	crown.Size = Vector3.new(head.Size.X * 1.05, head.Size.Y * 0.3, head.Size.Z * 1.05)
	crown.Color = color
	crown.CanCollide, crown.CanQuery, crown.CanTouch, crown.Massless = false, false, false, true
	local brim = crown:Clone()
	brim.Name = "Brim"
	brim.Size = Vector3.new(head.Size.X * 0.8, 0.12, head.Size.Z * 0.5)
	brim.Parent = crown
	for _, piece in { { crown, CFrame.new(0, head.Size.Y * 0.45, 0) }, { brim, CFrame.new(0, head.Size.Y * 0.32, -head.Size.Z * 0.65) } } do
		local weld = Instance.new("Weld")
		weld.Part0, weld.Part1, weld.C0 = head, piece[1], piece[2]
		weld.Parent = piece[1]
	end
	crown.CFrame = head.CFrame * CFrame.new(0, head.Size.Y * 0.45, 0)
	crown.Parent = character
end

local function dress(player: Player)
	local data = DataService.get(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (data and character and humanoid) then
		return
	end
	humanoid.DisplayName = shownName(player, data.name)
	local original = originals[character]
	if not original then
		return -- still loading; dressed when the avatar arrives
	end
	local look = data.look
	local description = original:Clone()
	if look.outfit then
		local skin = Looks.SKINS[look.skin]
		local pants = Looks.PAINTS[look.pants].color
		description.HeadColor, description.LeftArmColor, description.RightArmColor = skin, skin, skin
		description.TorsoColor = Looks.PAINTS[look.shirt].color
		description.LeftLegColor, description.RightLegColor = pants, pants
		description.Shirt, description.Pants, description.GraphicTShirt = 0, 0, 0
		-- Layered jackets, pants and shoes come off too; hair and hats stay
		local kept = {}
		for _, accessory in description:GetAccessories(true) do
			if not accessory.IsLayered then
				table.insert(kept, accessory)
			end
		end
		description:SetAccessories(kept, true)
	end
	local ok, err = pcall(humanoid.ApplyDescription, humanoid, description)
	if not ok then
		warn(`[LookService] couldn't dress {player.Name}: {err}`)
	end
	cap(character, look)
end

-- One change at a time per player; a burst of clicks becomes the latest one
local function apply(player: Player)
	if busy[player] then
		return
	end
	busy[player] = true
	while wanted[player] and player.Parent == Players do
		local want = wanted[player]
		wanted[player] = nil
		local data = DataService.get(player)
		if data then
			data.name, data.look = want.name, want.look
			DataService.changed(player)
			dress(player)
			OrderService.push(player)
		end
		task.wait(GAP)
	end
	busy[player] = nil
end

-- Each new character arrives in the player's own avatar: remember it, then dress it
local function onCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
	end
	local started = os.clock()
	while not player:HasAppearanceLoaded() and os.clock() - started < APPEARANCE_WAIT and character.Parent do
		task.wait(0.1)
	end
	if not character.Parent then
		return
	end
	originals[character] = humanoid:GetAppliedDescription()
	character.AncestryChanged:Connect(function()
		if not character.Parent then
			originals[character] = nil
		end
	end)
	dress(player)
end

local function watch(player: Player)
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
end

function LookService.start()
	ReplicatedStorage.Remotes.Intro.OnServerEvent:Connect(function(player, name, look)
		local cleanName, cleanLook = Looks.name(name), Looks.clean(look)
		if cleanName and cleanLook then
			wanted[player] = { name = cleanName, look = cleanLook }
			apply(player)
		end
	end)
	DataService.onLoaded(function(player)
		dress(player)
	end)
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		wanted[player], busy[player], shown[player] = nil, nil, nil
	end)
end

return LookService

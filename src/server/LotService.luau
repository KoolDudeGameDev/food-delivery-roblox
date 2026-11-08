-- Gives each player one of the seven home lots while they're in the server, builds their saved
-- home tier on it, and spawns them in front of it. Ownership of the home (tier, and later
-- decoration) persists in their save; the physical lot is assigned per session (GDD §6.4).
-- Visitors can walk onto any lot; nobody but the server changes one.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cosmetics = require(ReplicatedStorage.Shared.Data.Cosmetics)
local Homes = require(ReplicatedStorage.Shared.Data.Homes)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local DataService = require(script.Parent.DataService)
local WorldBuilder = require(script.Parent.WorldBuilder)

local LotService = {}

local owners: { [string]: Player } = {}

local function lotModel(lotId: string): Model
	return workspace.Gameplay.HomeLots[lotId]
end

local function setSign(lotId: string, text: string)
	lotModel(lotId).OwnerSign.SurfaceGui.TextLabel.Text = text
end

function LotService.lotOf(player: Player)
	local id = player:GetAttribute("LotId")
	for _, lot in WorldLayout.LOTS do
		if lot.id == id then
			return lot
		end
	end
	return nil
end

-- The garden things in the yard, in the lot's frame (Cosmetics boxes)
local function showDecor(lot, decor: { [string]: boolean })
	local folder = lotModel(lot.id):FindFirstChild("Decor")
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Model")
	folder.Name = "Decor"
	local at = WorldLayout.frame(lot)
	local yaw = math.atan2(lot.dx, lot.dz)
	for _, d in Cosmetics.DECOR do
		if decor[d.key] then
			for _, b in d.boxes do
				local x, z = at(b[5] :: number, b[7] :: number)
				local part = WorldBuilder.block(folder, d.name, b[1] :: number, b[2] :: number, b[3] :: number, Color3.fromHex(b[4] :: string), x, b[6] :: number, z)
				part.CFrame = CFrame.new(part.Position) * CFrame.Angles(0, yaw, 0)
				part.CanCollide = false
			end
		end
	end
	folder.Parent = lotModel(lot.id)
end

-- Rebuilds the home on a lot from a player's save: the tier, from Toolbox art if there is any,
-- else graybox; its paint (on art, the parts tagged "Paint"); and the garden things.
function LotService.showHome(lot, data)
	local home = lotModel(lot.id).Home
	home:ClearAllChildren()
	local def = Homes[data.homeTier]
	local paint = Cosmetics.PAINTS[data.paint.house]
	local yaw = math.atan2(lot.dx, lot.dz)
	local art = WorldBuilder.art(`Home_{data.homeTier}`, CFrame.new(WorldLayout.studs(lot.x, lot.z)) * CFrame.Angles(0, yaw, 0), home)
	if art then
		if paint then
			for _, part in art:GetDescendants() do
				if part:IsA("BasePart") and CollectionService:HasTag(part, "Paint") then
					part.Color = paint.color
				end
			end
		end
	else
		local w, d, h = def.size[1] * 2 * def.scale, def.size[2] * 2 * def.scale, def.height * def.scale
		local color = if paint then paint.color else Color3.fromHex("b98a56")
		local body = WorldBuilder.block(home, def.name, w, h, d, color, lot.x, h / 2, lot.z)
		body.CFrame = CFrame.new(body.Position) * CFrame.Angles(0, yaw, 0)
	end
	showDecor(lot, data.decor)
end

local function spawnAt(player: Player, character: Model)
	local lot = LotService.lotOf(player)
	if not lot then
		return -- no free lot: the default spawn by the hub
	end
	local at = WorldLayout.studs(lot.step.x, lot.step.z) + Vector3.new(0, 3, 0)
	local facing = at + Vector3.new(lot.dx, 0, lot.dz)
	task.defer(function()
		if character.Parent then
			character:PivotTo(CFrame.lookAt(at, facing))
		end
	end)
end

local function assign(player: Player, data)
	local free = {}
	for _, lot in WorldLayout.LOTS do
		if not owners[lot.id] then
			table.insert(free, lot)
		end
	end
	if #free == 0 or player.Parent ~= Players then
		return
	end
	local lot = free[math.random(1, #free)]
	owners[lot.id] = player
	player:SetAttribute("LotId", lot.id)
	setSign(lot.id, `{player.DisplayName:upper()}'S HOME`)
	LotService.showHome(lot, data)
	if player.Character then
		spawnAt(player, player.Character)
	end
end

function LotService.start()
	DataService.onLoaded(assign)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			spawnAt(player, character)
		end)
	end)
	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function(character)
			spawnAt(player, character)
		end)
	end
	Players.PlayerRemoving:Connect(function(player)
		local lot = LotService.lotOf(player)
		if lot and owners[lot.id] == player then
			owners[lot.id] = nil
			setSign(lot.id, "FOR RENT")
			lotModel(lot.id).Home:ClearAllChildren()
			local decor = lotModel(lot.id):FindFirstChild("Decor")
			if decor then
				decor:Destroy()
			end
		end
	end)
end

return LotService

-- Riding poses (the prototype's poses: blades, board, pedal, motor). On a bicycle, moped,
-- motorcycle or tricycle you sit; on a skateboard you stand still on the deck; on roller blades
-- you keep skating (the run). The poses reuse the character's own Animate script animations,
-- played over the walk cycle, so no new animation assets are needed.
local Players = game:GetService("Players")

local Riding = {}

local SIT = { bicycle = true, moped = true, motorcycle = true, tricycle = true }
local STAND = { skateboard = true }

local track: AnimationTrack?
local playingFor: string? = nil

local function stop()
	if track then
		track:Stop(0.2)
		track = nil
	end
	playingFor = nil
end

local function animationFrom(character: Model, folderName: string): Animation?
	local animate = character:FindFirstChild("Animate")
	local folder = animate and animate:FindFirstChild(folderName)
	return folder and folder:FindFirstChildOfClass("Animation")
end

function Riding.step()
	local character = Players.LocalPlayer.Character
	if not character then
		stop()
		return
	end
	local key: string? = nil
	for _, child in character:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("Ride") then
			key = child:GetAttribute("Ride")
			break
		end
	end
	local pose = if key and SIT[key] then "sit" elseif key and STAND[key] then "idle" else nil
	if pose == playingFor then
		return
	end
	stop()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	local animation = pose and animationFrom(character, pose)
	if animator and animation then
		track = animator:LoadAnimation(animation)
		track.Priority = Enum.AnimationPriority.Action
		track.Looped = true
		track:Play(0.2)
	end
	playingFor = pose
end

Players.LocalPlayer.CharacterAdded:Connect(function()
	track, playingFor = nil, nil
end)

return Riding

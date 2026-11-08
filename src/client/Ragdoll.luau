-- When a ride hits you (RamService): go limp and fly, then get back up where you land. The server
-- has already loosened your joints; your client owns your character's physics, so the fling and
-- the limp happen here.
local Players = game:GetService("Players")

local Ragdoll = {}

local player = Players.LocalPlayer
local downUntil = 0

function Ragdoll.fling(fling: Vector3, down: number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (humanoid and root) then
		return
	end
	humanoid.AutoRotate = false
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	root.AssemblyLinearVelocity = fling
	root.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 12 -- a tumble
	local until_ = os.clock() + down
	downUntil = until_
	task.delay(down, function()
		if downUntil == until_ and humanoid.Parent and humanoid.Health > 0 then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			humanoid.AutoRotate = true
		end
	end)
end

return Ragdoll

-- Rain you can see: a box of falling streaks that travels with the camera (the prototype's
-- trick), on while the server's Rain attribute is set. Local only.
local Weather = {}

local box: Part
local emitter: ParticleEmitter

function Weather.start()
	box = Instance.new("Part")
	box.Name = "RainBox"
	box.Anchored, box.CanCollide, box.CanQuery, box.CanTouch, box.CastShadow = true, false, false, false, false
	box.Transparency = 1
	box.Size = Vector3.new(120, 1, 120)
	box.Parent = workspace.CurrentCamera
	emitter = Instance.new("ParticleEmitter")
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.EmissionDirection = Enum.NormalId.Bottom
	emitter.Speed = NumberRange.new(90, 110)
	emitter.Lifetime = NumberRange.new(0.8, 1)
	emitter.Rate = 500
	emitter.Size = NumberSequence.new(0.12)
	emitter.Squash = NumberSequence.new(-3) -- long, thin streaks
	emitter.Orientation = Enum.ParticleOrientation.VelocityParallel
	emitter.Color = ColorSequence.new(Color3.fromHex("bfd8f0"))
	emitter.Transparency = NumberSequence.new(0.35)
	emitter.LightInfluence = 1
	emitter.Enabled = false
	emitter.Parent = box
end

function Weather.step()
	local camera = workspace.CurrentCamera
	box.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 40, 0))
	emitter.Enabled = workspace:GetAttribute("Rain") == true
end

return Weather

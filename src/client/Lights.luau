-- Ride headlights: on after dark (and off in daylight), on every ride this client can see.
-- The town's own lights are the server's (WorldService); headlights are cheap to run locally.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldClock = require(ReplicatedStorage.Shared.WorldClock)

local Lights = {}

function Lights.step()
	local night = WorldClock.isNight(Lighting.ClockTime)
	for _, lamp in CollectionService:GetTagged("Headlight") do
		local beam = lamp:FindFirstChildOfClass("SpotLight")
		if beam and beam.Enabled ~= night then
			beam.Enabled = night
			lamp.Material = if night then Enum.Material.Neon else Enum.Material.SmoothPlastic
		end
	end
end

return Lights

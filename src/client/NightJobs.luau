-- Your night job, drawn only for you (prototype `contraband.js`): the dealer the server put out
-- for you, and the buyer of the shady package you carry, each a figure in a coat and shades in
-- a purple ring. The server decides where they are and when you're close (NightJobService).
local NightJobs = {}

local RING = Color3.fromHex("b14dff")
local S = 3

local dealer: Model
local buyer: Model
local dealerAt: Vector3? = nil

-- The prototype's figure, feet at the model's pivot, facing +z (metres)
local function figure(name: string, coat: Color3): Model
	local model = Instance.new("Model")
	model.Name = name
	local function box(w, h, d, color, x, y, z, shape)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		p.Size = Vector3.new(w, h, d) * S
		p.Position = Vector3.new(x, y, z) * S
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		if shape then
			p.Shape = shape
		end
		p.Parent = model
		return p
	end
	box(0.95, 1.6, 0.55, coat, 0, 1.2, 0)
	box(0.85, 0.85, 0.8, coat, 0, 2.4, 0)
	box(0.5, 0.4, 0.1, Color3.fromHex("171717"), 0, 2.35, 0.4)
	local ring = box(0.1, 6.2, 6.2, RING, 0, 0.15, 0, Enum.PartType.Cylinder)
	ring.CFrame = CFrame.new(ring.Position) * CFrame.Angles(0, 0, math.rad(90))
	ring.Material, ring.Transparency = Enum.Material.Neon, 0.55
	model.WorldPivot = CFrame.new()
	return model
end

local function place(model: Model, at: Vector3?)
	if at then
		model:PivotTo(CFrame.new(at.X, 0, at.Z) * CFrame.Angles(0, (at.X + at.Z) % 6.28, 0))
		model.Parent = workspace.CurrentCamera
	else
		model.Parent = nil
	end
end

function NightJobs.start()
	dealer = figure("Dealer", Color3.fromHex("2c2238"))
	buyer = figure("Buyer", Color3.fromHex("3a2a22"))
end

-- From the server: where your dealer stands, or nil when there's none
function NightJobs.onDealer(at: Vector3?)
	dealerAt = at
	place(dealer, at)
end

-- The buyer waits at your shady package's drop
function NightJobs.onState(state)
	local at = nil
	for _, o in state.orders do
		if o.contraband then
			at = o.target
		end
	end
	place(buyer, at)
end

-- For the map: your dealer, if one is out
function NightJobs.dealer(): Vector3?
	return dealerAt
end

NightJobs.RING = RING

return NightJobs

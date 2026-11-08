-- Draws the living town (prototype `traffic.js`, `citizens.js`): jeepneys and tricycles on the
-- ring roads and walkers on their sidewalks, each placed from the server clock by TownRules, so
-- every player sees them in the same spots without anything being sent. A walker someone hit
-- (TownService's "walkerHit") tumbles through the air, lies there, then gets up and walks on.
-- Local parts only, moved together each frame.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TownRules = require(ReplicatedStorage.Shared.TownRules)
local WorldClock = require(ReplicatedStorage.Shared.WorldClock)

local Town = {}

local S = 3
local GRAVITY = 25 -- m/s², a little floaty, as in the prototype
local WALK_STRIDE = 3.2

-- [w, h, d, colour (nil: the paint), x, y, z] in metres, facing +z (the prototype's shapes)
local SHAPES = {
	jeepney = {
		{ 2.2, 1.4, 5, nil, 0, 1.3, -0.3 },
		{ 2.3, 0.2, 5.3, "f1efe9", 0, 2.1, -0.3 },
		{ 2, 0.8, 1.3, "c8ccd2", 0, 1, 2.8 },
		{ 2.24, 0.3, 5.04, "ffd23f", 0, 1.1, -0.3 },
		{ 2.3, 0.55, 0.7, "151515", 0, 0.3, 1.9 },
		{ 2.3, 0.55, 0.7, "151515", 0, 0.3, -1.9 },
	},
	tricycle = {
		{ 0.6, 0.5, 1.8, nil, -0.5, 0.75, 0 },
		{ 1.3, 0.9, 1.7, nil, 0.55, 1, 0.1 },
		{ 1.4, 0.14, 2, "f1efe9", 0.55, 1.85, 0.1 },
		{ 0.1, 0.7, 0.1, "333333", 1.15, 1.5, -0.7 },
		{ 0.3, 0.6, 0.6, "151515", -0.5, 0.3, -0.8 },
		{ 0.3, 0.6, 0.6, "151515", -0.5, 0.3, 0.8 },
		{ 0.3, 0.5, 0.5, "151515", 0.9, 0.25, 0.3 },
	},
}

-- A walker's body: [w, h, d, which colour, x, y, z, swing] where swing marks a limb that hangs
-- from (x, y + h/2): 1 swings with the phase, -1 against it.
local BODY = {
	{ 0.95, 1, 0.5, "shirt", 0, 1.5, 0, 0 },
	{ 0.72, 0.72, 0.72, "skin", 0, 2.38, 0, 0 },
	{ 0.76, 0.2, 0.76, "hair", 0, 2.76, 0, 0 },
	{ 0.42, 1, 0.45, "pants", -0.24, 0.5, 0, 1 },
	{ 0.42, 1, 0.45, "pants", 0.24, 0.5, 0, -1 },
	{ 0.3, 1, 0.38, "skin", -0.64, 1.5, 0, -1 },
	{ 0.3, 1, 0.38, "skin", 0.64, 1.5, 0, 1 },
}

type Piece = { part: BasePart, offset: CFrame, hinge: CFrame?, swing: number }
local vehicles: { { pieces: { Piece } } } = {}
local walkers: { { pieces: { Piece }, fall: { at: Vector3, v: Vector3, roll: number, untilT: number }? } } = {}

local function newPart(size: Vector3, color: Color3, parent: Instance): BasePart
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Size = size * S
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

function Town.start()
	local folder = Instance.new("Folder")
	folder.Name = "Town"
	folder.Parent = workspace.CurrentCamera
	for _, v in TownRules.VEHICLES do
		local pieces = {}
		for _, b in SHAPES[v.kind] do
			local color = if b[4] then Color3.fromHex(b[4] :: string) else v.paint
			local part = newPart(Vector3.new(b[1], b[2], b[3]), color, folder)
			table.insert(pieces, { part = part, offset = CFrame.new(b[5] * S, (b[6] + 0.1) * S, b[7] * S), swing = 0 })
		end
		table.insert(vehicles, { pieces = pieces })
	end
	for _, w in TownRules.WALKERS do
		local pieces = {}
		for _, b in BODY do
			local size = Vector3.new(b[1], b[2], b[3]) * w.scale
			local part = newPart(size, (w :: any)[b[4]], folder)
			local x, y, z = b[5] * w.scale, b[6] * w.scale, b[7] * w.scale
			local hinge = if b[8] ~= 0 then CFrame.new(x * S, (y + size.Y / 2) * S, z * S) else nil
			table.insert(pieces, { part = part, offset = CFrame.new(x * S, y * S, z * S), hinge = hinge, swing = b[8] })
		end
		table.insert(walkers, { pieces = pieces })
	end
end

-- From the server: walker i was hit and flies off with this velocity (studs/s)
function Town.walkerHit(i: number, fling: Vector3, down: number)
	local w = walkers[i]
	if not w then
		return
	end
	local x, z = TownRules.walkerAt(i, workspace:GetServerTimeNow())
	w.fall = { at = Vector3.new(x * S, 0.1 * S, z * S), v = fling, roll = 0, untilT = os.clock() + down }
end

local HIDDEN = CFrame.new(0, -500, 0)

function Town.step(dt: number)
	local t = workspace:GetServerTimeNow()
	local night = WorldClock.isNight(Lighting.ClockTime)
	local parts, frames = {}, {}
	for i, v in vehicles do
		local x, z, yaw = TownRules.vehicleAt(i, t)
		local base = CFrame.new(x * S, 0, z * S) * CFrame.Angles(0, yaw, 0)
		for _, p in v.pieces do
			table.insert(parts, p.part)
			table.insert(frames, base * p.offset)
		end
	end
	for i, w in walkers do
		local spec = TownRules.WALKERS[i]
		local base
		local swing = 0
		local f = w.fall
		if f and os.clock() < f.untilT then
			-- Tumble through the air, then lie where they land
			if f.at.Y > 0.1 * S or f.v.Y > 0 then
				f.v -= Vector3.new(0, GRAVITY * S * dt, 0)
				f.at += f.v * dt
				f.roll += dt * 8
				if f.at.Y <= 0.1 * S then
					f.at = Vector3.new(f.at.X, 0.1 * S, f.at.Z)
					f.v = Vector3.zero
				end
			end
			base = CFrame.new(f.at) * CFrame.Angles(math.min(f.roll, math.pi / 2), 0, 0) * CFrame.new(0, 0.3 * S, 0)
		elseif TownRules.walkerOut(i, night) then
			w.fall = nil
			local x, z, yaw = TownRules.walkerAt(i, t)
			base = CFrame.new(x * S, 0, z * S) * CFrame.Angles(0, yaw, 0)
			swing = math.sin(spec.phase + spec.speed * t * WALK_STRIDE) * 0.6
		else
			base = HIDDEN -- gone home for the night
		end
		for _, p in w.pieces do
			local frame = base * p.offset
			if p.hinge and swing ~= 0 then
				frame = base * p.hinge * CFrame.Angles(swing * p.swing, 0, 0) * p.hinge:Inverse() * p.offset
			end
			table.insert(parts, p.part)
			table.insert(frames, frame)
		end
	end
	workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
end

return Town

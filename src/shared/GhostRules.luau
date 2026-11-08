-- The White Lady as pure rules (GDD §5.1; prototype `ghost.js`). She only appears in the cemetery
-- after dark, while someone is among the graves, and drifts straight at the nearest of them
-- through the tombs: slower than you, but she never stops. Her touch is a scare; then she fades
-- out and comes back from the far corner, so you get a moment to run. GhostService runs her on
-- the server. Metres and seconds.
local Config = require(script.Parent.Config)

local GhostRules = {}

local JUMP_CLEAR = 1.2 -- m: feet this high pass over her

export type Rect = { x0: number, x1: number, z0: number, z1: number }
export type Runner = { id: string, x: number, z: number, feet: number }
export type Lady = {
	yard: Rect,
	start: { x: number, z: number },
	x: number,
	z: number,
	yaw: number,
	active: boolean,
	cooldown: number,
}

function GhostRules.new(yard: Rect, start: { x: number, z: number }): Lady
	return { yard = yard, start = start, x = start.x, z = start.z, yaw = 0, active = false, cooldown = 0 }
end

-- Visible: out, and not faded after a scare
function GhostRules.shown(lady: Lady): boolean
	return lady.active and lady.cooldown <= 0
end

local function inside(r: Runner, y: Rect): boolean
	return r.x > y.x0 and r.x < y.x1 and r.z > y.z0 and r.z < y.z1
end

-- appeared: she has just come out; scared: the runner she touched
function GhostRules.step(lady: Lady, runners: { Runner }, night: boolean, dt: number): { appeared: boolean, scared: string? }
	local y = lady.yard
	local nearest, best = nil, math.huge
	if night then
		for _, r in runners do
			local d = (r.x - lady.x) ^ 2 + (r.z - lady.z) ^ 2
			if inside(r, y) and d < best then
				nearest, best = r, d
			end
		end
	end
	if not nearest then
		lady.active, lady.cooldown = false, 0
		lady.x, lady.z = lady.start.x, lady.start.z
		return { appeared = false }
	end
	local appeared = not lady.active
	if appeared then
		lady.active = true
		lady.x, lady.z = lady.start.x, lady.start.z
	end
	lady.cooldown -= dt
	if lady.cooldown > 0 then
		return { appeared = appeared }
	end
	local dx, dz = nearest.x - lady.x, nearest.z - lady.z
	local d = math.sqrt(dx * dx + dz * dz)
	if d > 0.1 then
		local move = math.min(Config.GHOST_SPEED * dt, d)
		lady.x += dx / d * move
		lady.z += dz / d * move
		lady.yaw = math.atan2(dx, dz)
	end
	lady.x = math.clamp(lady.x, y.x0 + 1, y.x1 - 1)
	lady.z = math.clamp(lady.z, y.z0 + 1, y.z1 - 1)
	local left = math.sqrt((nearest.x - lady.x) ^ 2 + (nearest.z - lady.z) ^ 2)
	if left < Config.GHOST_REACH and nearest.feet < JUMP_CLEAR then
		lady.cooldown = Config.GHOST_COOLDOWN
		lady.x = if nearest.x < (y.x0 + y.x1) / 2 then y.x1 - 6 else y.x0 + 6
		lady.z = if nearest.z < (y.z0 + y.z1) / 2 then y.z1 - 8 else y.z0 + 8
		return { appeared = appeared, scared = nearest.id }
	end
	return { appeared = appeared }
end

return GhostRules

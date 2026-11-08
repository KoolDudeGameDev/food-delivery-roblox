-- The rider's name and look, picked free on the intro (GDD §6.3; prototype `intro.js` and
-- `data/cosmetics.js`). Players keep their own Roblox avatar unless they put on the rider outfit:
-- a skin tone and plain shirt, pants and cap colours. The server keeps only what clean() allows.
local Looks = {}

Looks.NAME_MAX = 12 -- characters, as in the prototype

-- The first is the prototype's classic blocky yellow
Looks.SKINS = {
	Color3.fromHex("f6c945"),
	Color3.fromHex("f3d2b3"),
	Color3.fromHex("e0ac7e"),
	Color3.fromHex("c68a5c"),
	Color3.fromHex("9a6440"),
	Color3.fromHex("6b4428"),
}

-- The prototype's paints, shared with house and ride paint later (GDD §6.3)
Looks.PAINTS = {
	{ name = "Red", color = Color3.fromHex("e0524d") },
	{ name = "Orange", color = Color3.fromHex("f0883a") },
	{ name = "Yellow", color = Color3.fromHex("e8c23c") },
	{ name = "Green", color = Color3.fromHex("3fae68") },
	{ name = "Teal", color = Color3.fromHex("2fb5a8") },
	{ name = "Blue", color = Color3.fromHex("4d8de0") },
	{ name = "Purple", color = Color3.fromHex("8d63d6") },
	{ name = "Pink", color = Color3.fromHex("e77fb3") },
	{ name = "White", color = Color3.fromHex("f1efe9") },
	{ name = "Black", color = Color3.fromHex("2b2f36") },
}

export type Look = { outfit: boolean, skin: number, shirt: number, pants: number, hat: number }

-- The prototype's colours: yellow skin, blue shirt, black pants, red cap
function Looks.default(): Look
	return { outfit = false, skin = 1, shirt = 6, pants = 10, hat = 1 }
end

local function pick(value: any, count: number): boolean
	return type(value) == "number" and value == math.floor(value) and value >= 1 and value <= count
end

-- A copy of an allowed look, or nil
function Looks.clean(look: any): Look?
	if type(look) ~= "table" or type(look.outfit) ~= "boolean" then
		return nil
	end
	local n = #Looks.PAINTS
	if not (pick(look.skin, #Looks.SKINS) and pick(look.shirt, n) and pick(look.pants, n) and pick(look.hat, n)) then
		return nil
	end
	return { outfit = look.outfit, skin = look.skin, shirt = look.shirt, pants = look.pants, hat = look.hat }
end

-- The name trimmed, or nil if it isn't allowed. "" means their Roblox display name. It still goes
-- through TextService before anyone sees it.
function Looks.name(name: any): string?
	if type(name) ~= "string" or name:find("%c") then
		return nil
	end
	local trimmed = name:match("^%s*(.-)%s*$") :: string
	local length = utf8.len(trimmed)
	if not length or length > Looks.NAME_MAX then
		return nil
	end
	return trimmed
end

return Looks

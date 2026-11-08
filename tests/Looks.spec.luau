-- The intro's rider name and look (GDD §6.3, §13.3): the server keeps only allowed values.
local function load()
	return require(script.Parent.Parent.Shared.Data.Looks)
end

return {
	palettesMatchThePrototype = function()
		local Looks = load()
		assert(#Looks.SKINS == 6, `{#Looks.SKINS} skins`)
		assert(#Looks.PAINTS == 10, `{#Looks.PAINTS} paints`)
		assert(Looks.SKINS[1] == Color3.fromHex("f6c945"), "skin 1 is the classic yellow")
		assert(Looks.PAINTS[6].name == "Blue" and Looks.PAINTS[10].name == "Black")
	end,
	defaultIsTheirOwnAvatarWithThePrototypeColours = function()
		local Looks = load()
		local d = Looks.default()
		assert(d.outfit == false, "players keep their own avatar until they pick the outfit")
		assert(d.skin == 1 and d.shirt == 6 and d.pants == 10 and d.hat == 1)
		d.skin = 3
		assert(Looks.default().skin == 1, "a fresh table each time")
	end,
	cleanKeepsAValidLook = function()
		local Looks = load()
		local look = Looks.clean({ outfit = true, skin = 6, shirt = 1, pants = 10, hat = 5 })
		assert(look and look.outfit == true and look.skin == 6 and look.shirt == 1 and look.pants == 10 and look.hat == 5)
	end,
	cleanRejectsOutOfRangeOrWrongTypes = function()
		local Looks = load()
		assert(Looks.clean(nil) == nil)
		assert(Looks.clean("look") == nil)
		assert(Looks.clean({ outfit = true, skin = 7, shirt = 1, pants = 1, hat = 1 }) == nil, "skin 7")
		assert(Looks.clean({ outfit = true, skin = 1, shirt = 0, pants = 1, hat = 1 }) == nil, "shirt 0")
		assert(Looks.clean({ outfit = true, skin = 1, shirt = 1.5, pants = 1, hat = 1 }) == nil, "fractions")
		assert(Looks.clean({ outfit = true, skin = 1, shirt = 1, pants = 0 / 0, hat = 1 }) == nil, "NaN")
		assert(Looks.clean({ outfit = "yes", skin = 1, shirt = 1, pants = 1, hat = 1 }) == nil, "outfit must be a boolean")
	end,
	nameIsTrimmedAndAtMostTwelveCharacters = function()
		local Looks = load()
		assert(Looks.name("  Juan  ") == "Juan")
		assert(Looks.name("") == "", "empty means their Roblox display name")
		assert(Looks.name("   ") == "")
		assert(Looks.name("Mang Kanor the Great") == nil, "too long")
		assert(Looks.name("Ñiño Pañero") == "Ñiño Pañero", "counted in characters, not bytes")
		assert(Looks.name("a\nb") == nil, "no control characters")
		assert(Looks.name(42) == nil)
	end,
}

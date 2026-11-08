-- Paint and garden things (GDD §6.3; prototype `data/cosmetics.js`). They change only how
-- things look, and they're all on sale from the start. A new colour or decoration is one more row.

local Cosmetics = {}

Cosmetics.PAINTS = {
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

Cosmetics.PAINT_PRICES = { house = 250, ride = 120 }

-- A box: w, h, d, colour, then its centre x, y, z, all in metres in the lot's frame: x across,
-- z towards the road (the doorstep is at z = 10), y up.
export type Box = { number | string }
export type Decor = { key: string, name: string, price: number, boxes: { Box } }

local function flowers(): { Box }
	local list: { Box } = { { 5, 0.3, 1.6, "6b4a2e", -9, 0.25, 9 } }
	local colors = { "e0443a", "ffd23f", "e77fb3" }
	for i = 0, 7 do
		table.insert(list, { 0.4, 0.55, 0.4, colors[i % 3 + 1], -11.1 + i * 0.6, 0.6, 8.6 + i % 2 * 0.8 })
	end
	return list
end

local function lights(): { Box }
	local list: { Box } = {}
	local colors = { "ffd23f", "e0443a", "4d8de0" }
	for i = 0, 8 do
		table.insert(list, { 0.22, 0.22, 0.22, colors[i % 3 + 1], -14 + i * 3.5, 4 - math.sin(i * 0.78) * 0.5, 13 })
	end
	for _, x in { -14.5, 14.5 } do
		table.insert(list, { 0.15, 4.4, 0.15, "4a5058", x, 2.2, 13 })
	end
	return list
end

local function pet(): { Box }
	local list: { Box } = {
		{ 0.5, 0.5, 1.1, "b98a56", 4, 0.65, 12 },
		{ 0.48, 0.45, 0.48, "b98a56", 4, 1, 12.7 },
		{ 0.26, 0.2, 0.26, "333333", 4, 0.92, 13 },
	}
	for _, x in { 3.8, 4.2 } do
		for _, z in { 11.6, 12.4 } do
			table.insert(list, { 0.14, 0.42, 0.14, "a87b4a", x, 0.2, z })
		end
	end
	return list
end

Cosmetics.DECOR = {
	{ key = "flowers", name = "Flower bed", price = 120, boxes = flowers() },
	{
		key = "flag",
		name = "Philippine flag",
		price = 150,
		boxes = {
			{ 0.2, 7, 0.2, "d6d9de", 12, 3.5, 11 },
			{ 0.06, 0.9, 2.4, "d6402b", 12, 5.95, 12.3 },
			{ 0.06, 0.9, 2.4, "2f5fc0", 12, 6.85, 12.3 },
			{ 0.08, 1.8, 0.9, "f4f1ea", 12, 6.4, 11.5 },
		},
	},
	{
		key = "gnome",
		name = "Garden gnome",
		price = 200,
		boxes = {
			{ 0.6, 0.8, 0.5, "3f7fd6", -5, 0.55, 12 },
			{ 0.45, 0.4, 0.45, "f0c9a0", -5, 1.15, 12 },
			{ 0.5, 0.6, 0.5, "d6402b", -5, 1.65, 12 },
		},
	},
	{
		key = "fountain",
		name = "Fountain",
		price = 400,
		boxes = {
			{ 3.6, 0.6, 3.6, "bfc3c9", 8, 0.35, 11 },
			{ 3, 0.1, 3, "3f97d6", 8, 0.68, 11 },
			{ 0.5, 1.6, 0.5, "d6d9de", 8, 1.2, 11 },
			{ 1.2, 0.25, 1.2, "d6d9de", 8, 2, 11 },
		},
	},
	{ key = "pet", name = "Pet dog", price = 350, boxes = pet() },
	{ key = "lights", name = "String lights", price = 180, boxes = lights() },
}

Cosmetics.decorByKey = {}
for _, d in Cosmetics.DECOR do
	Cosmetics.decorByKey[d.key] = d
end

return Cosmetics

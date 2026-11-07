-- What you can ride, in the order it's bought (prototype `data/vehicles.js`). speed is m/s,
-- carry is how many orders it holds. Each part is levels of one upgrade, one price per level,
-- and what each level adds. The prototype's acceleration-only parts (tighter laces, bigger
-- deck, wider tyres) are left out: Roblox walking has no acceleration to change, and a part
-- that does nothing shouldn't be sold.

export type Part = { key: string, name: string, prices: { number }, speed: number?, carry: number? }
export type Vehicle = { key: string, name: string, price: number, speed: number, carry: number, color: Color3, parts: { Part } }

local hex = Color3.fromHex

local Vehicles: { Vehicle } = {
	{
		key = "rollerblades",
		name = "Roller blades",
		price = 300,
		speed = 7.8,
		carry = 1,
		color = hex("4d8de0"),
		parts = {
			{ key = "wheels", name = "Faster wheels", prices = { 80, 200 }, speed = 0.8 },
			{ key = "pack", name = "Backpack", prices = { 220 }, carry = 1 },
		},
	},
	{
		key = "skateboard",
		name = "Skateboard",
		price = 900,
		speed = 9.5,
		carry = 1,
		color = hex("d6402b"),
		parts = {
			{ key = "wheels", name = "Bigger wheels", prices = { 100, 250, 500 }, speed = 1 },
			{ key = "crate", name = "Milk crate", prices = { 350 }, carry = 1 },
		},
	},
	{
		key = "bicycle",
		name = "Bicycle",
		price = 2500,
		speed = 12.5,
		carry = 1,
		color = hex("2fae57"),
		parts = {
			{ key = "tires", name = "Bigger tyres", prices = { 250, 600, 1100 }, speed = 1 },
			{ key = "basket", name = "Front basket", prices = { 450 }, carry = 1 },
			{ key = "sidecar", name = "Sidecar", prices = { 900 }, carry = 2 },
		},
	},
	{
		key = "moped",
		name = "Moped",
		price = 7000,
		speed = 17,
		carry = 1,
		color = hex("e0443a"),
		parts = {
			{ key = "engine", name = "Bigger engine", prices = { 700, 1500, 2800 }, speed = 1.5 },
			{ key = "topBox", name = "Top box", prices = { 1100 }, carry = 1 },
			{ key = "sidecar", name = "Sidecar", prices = { 2000 }, carry = 2 },
		},
	},
	{
		key = "motorcycle",
		name = "Motorcycle",
		price = 12000,
		speed = 20,
		carry = 1,
		color = hex("2b2f36"),
		parts = {
			{ key = "engine", name = "Racing engine", prices = { 2000, 3500 }, speed = 1.5 },
			{ key = "bags", name = "Saddlebags", prices = { 1800 }, carry = 1 },
		},
	},
	{
		key = "tricycle",
		name = "Tricycle",
		price = 18000,
		speed = 17.5,
		carry = 3,
		color = hex("2fb5a8"),
		parts = {
			{ key = "engine", name = "Stronger engine", prices = { 2500 }, speed = 1.5 },
			{ key = "rack", name = "Roof rack", prices = { 2200 }, carry = 1 },
		},
	},
}

local byKey = {}
for _, v in Vehicles do
	byKey[v.key] = v
end

return { list = Vehicles, byKey = byKey }

-- The home ladder (prototype `data/homes.js`). size is the half footprint in metres before
-- scale; tier 1 is where everyone starts.

export type Home = { name: string, price: number, bonus: number, scale: number, size: { number }, height: number }

local Homes: { Home } = {
	{ name = "Cardboard box", price = 0, bonus = 0, scale = 1.25, size = { 2, 1.8 }, height = 2.8 },
	{ name = "Wooden shack", price = 400, bonus = 0.03, scale = 1.45, size = { 3.2, 2.7 }, height = 3.5 },
	{ name = "Bungalow", price = 1500, bonus = 0.06, scale = 1.7, size = { 4.2, 3.4 }, height = 6.6 },
	{ name = "Two-storey house", price = 4000, bonus = 0.09, scale = 1.55, size = { 7.5, 4 }, height = 9.8 },
	{ name = "Mansion", price = 9000, bonus = 0.12, scale = 1.5, size = { 11, 4.2 }, height = 11.4 },
}

return Homes

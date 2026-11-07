-- What kinds of order the board can offer (prototype `data/orderTypes.js`). A new type is one
-- more row. stars adds to difficulty, pay and time multiply, damage multiplies anything that
-- hurts the order, parcelOnly rules out food, minCarry is the carry a ride needs to take it.

export type OrderType = {
	key: string,
	label: string,
	weight: number,
	stars: number,
	pay: number,
	time: number,
	damage: number,
	parcelOnly: boolean?,
	minCarry: number?,
}

local OrderTypes: { [string]: OrderType } = {
	normal = { key = "normal", label = "", weight = 5, stars = 0, pay = 1, time = 1, damage = 1 },
	fragile = { key = "fragile", label = "Fragile", weight = 2, stars = 1, pay = 1.25, time = 1, damage = 2, parcelOnly = true },
	rush = { key = "rush", label = "Rush", weight = 2, stars = 1, pay = 1.5, time = 0.55, damage = 1 },
	bulky = { key = "bulky", label = "Bulky", weight = 1, stars = 1, pay = 1.4, time = 1.2, damage = 1, parcelOnly = true, minCarry = 3 },
}

return OrderTypes

-- Every sound in the game: a Creator Store asset id and its volume (Blueprint §12). Volumes are
-- first guesses, to tune by ear. Sources and licences are in CREDITS.md: ProSoundEffects, APM
-- and DistroKid audio is licensed by Roblox for any experience; the three animal calls are short
-- public uploads, to replace if a licensed one turns up.
export type Sound = { id: number, volume: number }

local Sounds: { [string]: Sound } = {
	-- Beds: heard everywhere, faded by where you are and what the world is doing
	birds = { id = 9112835068, volume = 0.35 }, -- Neighborhood Birds 2: residential streets by day
	rural = { id = 9112806209, volume = 0.45 }, -- Jungle Dawn 2: wind, birds, frogs in the outskirts
	crickets = { id = 9112764891, volume = 0.4 }, -- Crickets Night 3: night everywhere
	rain = { id = 9112853563, volume = 0.6 }, -- Rain on grass and a wooden roof, Malaysia
	thunder = { id = 9120015808, volume = 0.5 }, -- Thunder And Rain 1: now and then while it rains

	-- Placed in the world: loud close up, gone a block or two away
	street = { id = 9112786939, volume = 0.5 }, -- Gas Town 4: walla and the odd car, town centre
	conveyor = { id = 9113910299, volume = 0.35 }, -- Conveyor Belt 1: the warehouse belt
	cemeteryWind = { id = 9113286969, volume = 0.5 }, -- Barstow Wind: quiet wind at the cemetery
	fiesta = { id = 120005535141518, volume = 0.5 }, -- Fiesta de Colores: at the market in a fiesta

	-- One-shots
	pay = { id = 9113728042, volume = 0.6 }, -- Cash Register 1: the drawer, when you're paid
	bark = { id = 99723552215501, volume = 0.8 }, -- "Dog bark" (public upload)
	honk = { id = 138096010, volume = 0.8 }, -- "Goose Honk" (public upload)
	hiss = { id = 134699420140804, volume = 0.8 }, -- "cat-meow short" (public upload)
}

return Sounds

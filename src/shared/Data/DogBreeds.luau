-- A breed sets how a chaser looks, and its size (Config.DOG_TYPES) how it plays
-- (prototype `config.js`). Chasers arrive in milestone 2; houses already name theirs.

export type Breed = { name: string, size: string, coat: Color3, call: string?, sign: string? }

local hex = Color3.fromHex

local DogBreeds: { [string]: Breed } = {
	chihuahua = { name = "Chihuahua", size = "tiny", coat = hex("e8d0a9") },
	pomeranian = { name = "Pomeranian", size = "tiny", coat = hex("e89a4a") },
	shihTzu = { name = "Shih Tzu", size = "small", coat = hex("f1ece0") },
	dachshund = { name = "Dachshund", size = "small", coat = hex("7a3f22") },
	aspin = { name = "Aspin", size = "medium", coat = hex("b98a56") },
	beagle = { name = "Beagle", size = "medium", coat = hex("f1ece0") },
	germanShepherd = { name = "German Shepherd", size = "big", coat = hex("b9803f") },
	husky = { name = "Husky", size = "big", coat = hex("dfe4ea") },
	greatDane = { name = "Great Dane", size = "giant", coat = hex("8f7f6e") },
	saintBernard = { name = "Saint Bernard", size = "giant", coat = hex("f1ece0") },
	mastiff = { name = "Mastiff", size = "giant", coat = hex("4a4038") },
	cat = { name = "Angry cat", size = "tiny", coat = hex("6b6f78"), call = "HISS!", sign = "BEWARE OF CAT" },
	goose = { name = "Goose", size = "small", coat = hex("f4f2ea"), call = "HONK!", sign = "BEWARE OF GOOSE" },
}

return DogBreeds

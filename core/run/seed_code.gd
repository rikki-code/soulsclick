## Short shareable run seed ("ASH-7F3K") <-> integer. 4 bits pick the word, 20 bits the four base-32 characters.
class_name SeedCode
extends RefCounted

const WORDS: Array[String] = ["ASH", "EMB", "CIN", "DUS", "FOG", "HEX", "ICE", "MOR", "ORE", "PYR", "RUE", "SOT", "TAR", "VEX", "WAN", "YEW"]
const ALPHABET := "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
const CHAR_BITS := 5
const CHAR_COUNT := 4
const SEED_BITS := 24
const SEED_MAX := (1 << SEED_BITS) - 1
const INVALID := -1
const _LOOKALIKES := {"O": "0", "I": "1", "L": "1"}

static func encode(run_seed: int) -> String:
	var value := run_seed & SEED_MAX
	var tail_bits := CHAR_BITS * CHAR_COUNT
	var text := ""
	for i in CHAR_COUNT:
		var shift := CHAR_BITS * (CHAR_COUNT - 1 - i)
		text += ALPHABET[(value >> shift) & ((1 << CHAR_BITS) - 1)]
	return "%s-%s" % [WORDS[value >> tail_bits], text]

## Returns INVALID for text that is not a seed code. Case, spaces and the hyphen are ignored.
static func decode(code: String) -> int:
	var clean := code.to_upper().replace("-", "").replace(" ", "")
	if clean.length() != 3 + CHAR_COUNT:
		return INVALID
	var word := WORDS.find(clean.substr(0, 3))
	if word < 0:
		return INVALID
	var value := 0
	for i in CHAR_COUNT:
		var character := clean[3 + i]
		character = _LOOKALIKES.get(character, character)
		var digit := ALPHABET.find(character)
		if digit < 0:
			return INVALID
		value = (value << CHAR_BITS) | digit
	return (word << (CHAR_BITS * CHAR_COUNT)) | value

static func random_seed(rng: RandomNumberGenerator) -> int:
	return rng.randi() & SEED_MAX

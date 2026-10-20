## Inputs fixed at run start. Meta upgrades (bank rate, start souls, HP) arrive here from the profile.
class_name RunConfig
extends RefCounted

var seed := 0
var max_hp := 100
var start_souls := 0
## Share of souls converted to Embers on death or abandon (victory is always 1.0).
var death_bank_rate := 0.5

func _init(p_seed := 0, p_max_hp := 100) -> void:
	seed = p_seed & SeedCode.SEED_MAX
	max_hp = p_max_hp

func to_dict() -> Dictionary:
	return {"seed": seed, "max_hp": max_hp, "start_souls": start_souls, "death_bank_rate": death_bank_rate}

static func from_dict(data: Dictionary) -> RunConfig:
	var config := RunConfig.new(int(data.get("seed", 0)), maxi(int(data.get("max_hp", 100)), 1))
	config.start_souls = maxi(int(data.get("start_souls", 0)), 0)
	config.death_bank_rate = clampf(float(data.get("death_bank_rate", 0.5)), 0.0, 1.0)
	return config

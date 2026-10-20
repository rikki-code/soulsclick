## The single curve object that turns base numbers into level-scaled ones (NG+ cycles, later bosses).
class_name CombatScaling
extends RefCounted

var level: int
var _tuning: CombatTuning

func _init(p_tuning: CombatTuning, p_level: int = 1) -> void:
	_tuning = p_tuning
	level = maxi(p_level, 1)

func enemy_hp(base: int) -> int:
	return _grow(base, _tuning.enemy_hp_growth)

func enemy_damage(base: int) -> int:
	return _grow(base, _tuning.enemy_damage_growth)

func souls(base: int) -> int:
	return _grow(base, _tuning.enemy_souls_growth)

func _grow(base: int, growth: float) -> int:
	return roundi(base * (1.0 + growth * (level - 1)))

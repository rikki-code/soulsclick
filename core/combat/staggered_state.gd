## Helpless for stagger_time; takes extra damage from the opponent.
class_name StaggeredState
extends FighterState

const ID := &"staggered"

var _duration: float

func _init(p_duration: float) -> void:
	_duration = p_duration

func id() -> StringName:
	return ID

func duration() -> float:
	return _duration

func damage_taken_multiplier(attacker_stats: CombatStats) -> float:
	return attacker_stats.value(CombatStats.PUNISH_MULT)

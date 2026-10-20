## Every parry in a row raises attack damage; taking a hit resets the streak.
class_name DuelistsPride
extends Modifier

const ID := &"duelists_pride"
const STREAK := &"streak"

func _init() -> void:
	stage = Stage.MUL
	params = {&"per_parry": 0.1, &"max_streak": 5.0}

func id() -> StringName:
	return ID

func modify_stat(stat_id: StringName, value: float, _ctx: HookCtx) -> float:
	if stat_id != CombatStats.ATTACK_DAMAGE:
		return value
	return value * (1.0 + params[&"per_parry"] * fight_data.get(STREAK, 0))

func on_parry(_ctx: StrikeCtx) -> void:
	fight_data[STREAK] = mini(fight_data.get(STREAK, 0) + 1, int(params[&"max_streak"]))
	mark_dirty()

func on_damage_taken(_ctx: DamageCtx) -> void:
	fight_data[STREAK] = 0
	mark_dirty()

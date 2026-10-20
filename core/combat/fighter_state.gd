## Base of the fighter state objects (idle, attacking, blocking, staggered). A new state is a new file
## overriding the hooks it cares about.
class_name FighterState
extends RefCounted

func id() -> StringName:
	return &""

## Seconds until on_finished; INF = until replaced.
func duration() -> float:
	return INF

func enter(_duel: Duel, _fighter: Fighter) -> void:
	pass

func advance(_duel: Duel, _fighter: Fighter, _dt: float) -> void:
	pass

func on_finished(duel: Duel, fighter: Fighter) -> void:
	duel.enter_state(fighter, IdleState.new())

## Whether the fighter may start an attack or a block.
func can_act() -> bool:
	return false

func stamina_regen_factor() -> float:
	return 0.0

func damage_taken_multiplier(_tuning: CombatTuning) -> float:
	return 1.0

## Routes an incoming strike to the kind hook that matches this state's defence.
func receive_strike(duel: Duel, _fighter: Fighter, kind: AttackKind, result: StrikeResult) -> void:
	kind.on_hit(duel, result)

## Called after the strike result was applied and announced.
func after_strike(_duel: Duel, _fighter: Fighter, _result: StrikeResult) -> void:
	pass

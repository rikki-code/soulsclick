## Guard raised by a press. It stays up while the button is held and at least block_min_duration after the
## press. Strikes landing within parry_window of the press (after block_startup) are parried; a strike before
## the guard is up hits. Plain blocks cost stamina by damage; running out of stamina breaks the guard.
class_name BlockingState
extends FighterState

const ID := &"blocking"

var _min_duration: float
var _held := true

func _init(p_min_duration: float) -> void:
	_min_duration = p_min_duration

func id() -> StringName:
	return ID

## INF while held; once released, the remaining guard time counts from the press.
func duration() -> float:
	return INF if _held else _min_duration

func is_held() -> bool:
	return _held

func release() -> void:
	_held = false

func remaining(fighter: Fighter) -> float:
	return maxf(_min_duration - fighter.state_elapsed, 0.0)

func enter(_duel: Duel, fighter: Fighter) -> void:
	fighter.holding_block = true

func on_finished(duel: Duel, fighter: Fighter) -> void:
	fighter.holding_block = false
	fighter.block_cooldown = fighter.stats.value(CombatStats.BLOCK_COOLDOWN)
	super.on_finished(duel, fighter)

func receive_strike(duel: Duel, fighter: Fighter, kind: AttackKind, result: StrikeResult) -> void:
	var stats := fighter.stats
	var into_guard := fighter.state_elapsed - stats.value(CombatStats.BLOCK_STARTUP)
	if into_guard < 0.0:
		kind.on_hit(duel, result)
		return
	var window := stats.value(CombatStats.PARRY_WINDOW)
	if into_guard <= window:
		result.precision = clampf(into_guard / maxf(window, 0.001), 0.0, 1.0)
		result.perfect = result.precision >= stats.value(CombatStats.PERFECT_THRESHOLD)
		kind.on_parried(duel, result)
		return
	kind.on_blocked(duel, result)

## A parry frees the defender at once so the punish window is not spent finishing the block; a broken guard
## drops with the usual cooldown.
func after_strike(duel: Duel, fighter: Fighter, result: StrikeResult) -> void:
	if result.outcome == StrikeResult.PARRIED:
		fighter.holding_block = false
		duel.enter_state(fighter, IdleState.new())
	elif result.guard_broken:
		on_finished(duel, fighter)

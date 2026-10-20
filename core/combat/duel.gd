## One player-vs-enemy duel. Pure model: advance(dt) moves time, events leave through signals that carry
## everything a view needs. Same seed and same inputs at the same times give the same result.
class_name Duel
extends RefCounted

signal telegraph_started(attack_kind_id: StringName, duration: float, index_in_combo: int)
signal strike_resolved(result: StrikeResult)
signal player_attacked(damage: int, enemy_hp: int)
signal stamina_changed(value: float, max_value: float)
signal fighter_state_changed(side: StringName, state_id: StringName)
## Extra: emitted right after fighter_state_changed; duration is INF for idle.
signal fighter_state_timed(side: StringName, state_id: StringName, duration: float)
## Extra: a press that was refused, so the view can shake the button.
signal action_rejected(action_id: StringName, reason: StringName)
signal duel_finished(winner_side: StringName)

const ACTION_ATTACK := &"attack"
const ACTION_BLOCK := &"block"
const REJECT_DISABLED := &"disabled"
const REJECT_FINISHED := &"finished"
const REJECT_BUSY := &"busy"
const REJECT_STAMINA := &"stamina"
const REJECT_COOLDOWN := &"cooldown"
## Longest slice advance() simulates at once, so timing does not depend on the caller's frame rate.
const MAX_SUBSTEP := 0.02

var tuning: CombatTuning
var definition: EnemyDefinition
var scaling: CombatScaling
var player: Fighter
var enemy: Fighter
var pattern: AttackPattern
var rng := RandomNumberGenerator.new()
var time := 0.0
## Human-input gate for try_attack / try_block. perform_* ignores it.
var input_enabled := true
var finished := false
var winner: StringName = &""

var _enemy_wait: float
var _kind: AttackKind
var _strike_index := 0
var _last_stamina: float

func _init(p_tuning: CombatTuning, p_definition: EnemyDefinition, p_seed: int = 0, p_level: int = 1, p_player: Fighter = null) -> void:
	tuning = p_tuning
	definition = p_definition
	scaling = CombatScaling.new(tuning, p_level)
	player = p_player if p_player != null else Fighter.make_player(tuning)
	enemy = Fighter.make_enemy(definition, scaling)
	pattern = AttackPattern.new(definition.pattern)
	rng.seed = p_seed
	_enemy_wait = definition.opening_delay
	_last_stamina = player.stamina

func advance(dt: float) -> void:
	var remaining := dt
	while remaining > 0.0 and not finished:
		var slice := minf(remaining, MAX_SUBSTEP)
		remaining -= slice
		_tick(slice)
	_sync_stamina()

func try_attack() -> bool:
	if not input_enabled:
		action_rejected.emit(ACTION_ATTACK, REJECT_DISABLED)
		return false
	return perform_attack()

func try_block() -> bool:
	if not input_enabled:
		action_rejected.emit(ACTION_BLOCK, REJECT_DISABLED)
		return false
	return perform_block()

func perform_attack() -> bool:
	var reason := _attack_refusal()
	if reason != &"":
		action_rejected.emit(ACTION_ATTACK, reason)
		return false
	player.spend_stamina(tuning.attack_stamina_cost)
	enter_state(player, AttackingState.new(tuning.attack_duration))
	var amount := roundi(player.damage * enemy.state.damage_taken_multiplier(tuning))
	enemy.take_damage(amount)
	player_attacked.emit(amount, enemy.hp)
	_sync_stamina()
	if not enemy.is_alive():
		_finish(Fighter.PLAYER)
	return true

func perform_block() -> bool:
	var reason := _block_refusal()
	if reason != &"":
		action_rejected.emit(ACTION_BLOCK, reason)
		return false
	enter_state(player, BlockingState.new(tuning.block_duration))
	return true

func enter_state(fighter: Fighter, state: FighterState) -> void:
	fighter.state = state
	fighter.state_elapsed = 0.0
	state.enter(self, fighter)
	fighter_state_changed.emit(fighter.side, state.id())
	fighter_state_timed.emit(fighter.side, state.id(), state.duration())

func _attack_refusal() -> StringName:
	if finished:
		return REJECT_FINISHED
	if not player.state.can_act():
		return REJECT_BUSY
	if player.stamina < tuning.attack_stamina_cost:
		return REJECT_STAMINA
	return &""

func _block_refusal() -> StringName:
	if finished:
		return REJECT_FINISHED
	if not player.state.can_act():
		return REJECT_BUSY
	if player.block_cooldown > 0.0:
		return REJECT_COOLDOWN
	return &""

func _tick(slice: float) -> void:
	time += slice
	player.advance(self, slice)
	enemy.advance(self, slice)
	if not finished:
		_tick_enemy_wait(slice)

func _tick_enemy_wait(slice: float) -> void:
	if not enemy.state.can_act():
		return
	_enemy_wait -= slice
	if _enemy_wait > 0.0:
		return
	if _kind == null:
		_kind = AttackKindCatalog.create(pattern.next_step(rng))
		_strike_index = 0
	_begin_telegraph()

func _begin_telegraph() -> void:
	var duration := _kind.telegraph_time(_strike_index)
	enter_state(enemy, AttackingState.new(duration, _on_telegraph_done))
	telegraph_started.emit(_kind.telegraph_id(), duration, _strike_index)

func _on_telegraph_done() -> void:
	var result := _kind.resolve(self, _strike_index)
	result.damage = roundi(result.damage * player.state.damage_taken_multiplier(tuning))
	player.take_damage(result.damage)
	player.spend_stamina(result.stamina_cost)
	result.target_hp = player.hp
	strike_resolved.emit(result)
	player.state.after_strike(self, player, result)
	_sync_stamina()
	if not player.is_alive():
		_finish(Fighter.ENEMY)
		return
	if result.staggers_attacker:
		_stagger_enemy()
		return
	_strike_index += 1
	if _strike_index < _kind.strike_count():
		_enemy_wait = _kind.strike_gap()
		if _enemy_wait <= 0.0:
			_begin_telegraph()
			return
		enter_state(enemy, IdleState.new())
		return
	_enemy_wait = _kind.step.recovery_time
	_kind = null
	enter_state(enemy, IdleState.new())

func _stagger_enemy() -> void:
	_kind = null
	_enemy_wait = definition.post_stagger_delay
	enter_state(enemy, StaggeredState.new(tuning.stagger_time))

func _sync_stamina() -> void:
	if is_equal_approx(player.stamina, _last_stamina):
		return
	_last_stamina = player.stamina
	stamina_changed.emit(player.stamina, player.max_stamina)

func _finish(winner_side: StringName) -> void:
	finished = true
	winner = winner_side
	duel_finished.emit(winner_side)

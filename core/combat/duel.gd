## One player-vs-enemy duel. Pure model: advance(dt) moves time, events leave through signals that carry
## everything a view needs. Same seed and same inputs at the same times give the same result.
class_name Duel
extends RefCounted

signal telegraph_started(attack_kind_id: StringName, duration: float, index_in_combo: int)
signal strike_resolved(result: StrikeResult)
signal player_attacked(damage: int, enemy_hp: int)
## Extra, right after player_attacked: crit = the enemy was staggered (punish window); combo = hits counted
## including this one (a crit counts combo_crit_weight).
signal player_hit(damage: int, enemy_hp: int, crit: bool, combo: int)
## Combo counter or its damage multiplier changed (also on reset to 0 / x1.0).
signal combo_changed(count: int, multiplier: float)
signal stamina_changed(value: float, max_value: float)
signal fighter_state_changed(side: StringName, state_id: StringName)
## Extra: emitted right after fighter_state_changed; duration is INF for idle.
signal fighter_state_timed(side: StringName, state_id: StringName, duration: float)
## Extra: a press that was refused, so the view can shake the button.
signal action_rejected(action_id: StringName, reason: StringName)
signal duel_finished(winner_side: StringName)
## Emitted with every telegraph (and every combo strike): seconds until the strike lands and the player's
## parry window, so the view can draw the timing cue.
signal strike_timing(strike_in: float, parry_window: float, attack_kind_id: StringName, index_in_combo: int)
signal player_hp_changed(hp: int, max_hp: int)
signal enemy_hp_changed(hp: int, max_hp: int)
## A modifier effect fired; the view flashes the relic icon.
signal modifier_triggered(mod_id: StringName, side: StringName)
## The same duel continues after revive_player.
signal player_revived(hp: int)
## A consumable was spent (charges_left in the bag; -1 when no bag tracks charges).
## Clicker income: whole Souls earned by a hit (source "hit") or a parry ("parry").
signal souls_earned(amount: int, source: StringName)
signal item_used(item_id: StringName, charges_left: int)

const ACTION_ATTACK := &"attack"
const ACTION_BLOCK := &"block"
const ACTION_ITEM := &"item"
const REJECT_DISABLED := &"disabled"
const REJECT_FINISHED := &"finished"
const REJECT_BUSY := &"busy"
const REJECT_STAMINA := &"stamina"
const REJECT_COOLDOWN := &"cooldown"
const REJECT_NO_ITEM := &"no_item"
const TAG_STRIKE := &"strike"
## Longest slice advance() simulates at once, so timing does not depend on the caller's frame rate.
const MAX_SUBSTEP := 0.02
## The enemy never stands idle longer than this before its first swing (the road flow has no intro to hide it).
const OPENING_DELAY_CAP := 0.6

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
## Consecutive player hits without taking damage; scales player attack damage (see combo_multiplier).
var combo := 0
## Where use_item takes consumable charges from (set by Inventory.begin_fight).
var items: ItemBag
## Souls earned in this duel (whole units); the fraction carries to the next award.
var souls_earned_total := 0

var _enemy_wait: float
var _kind: AttackKind
var _strike_index := 0
var _last_stamina: float
var _started := false
var _pending_death: DeathCtx
var _souls_fraction := 0.0

func _init(p_tuning: CombatTuning, p_definition: EnemyDefinition, p_seed: int = 0, p_level: int = 1, p_player: Fighter = null) -> void:
	tuning = p_tuning
	definition = p_definition
	scaling = CombatScaling.new(tuning, p_level)
	player = p_player if p_player != null else Fighter.make_player(tuning)
	enemy = Fighter.make_enemy(definition, scaling, tuning)
	pattern = AttackPattern.new(definition.pattern)
	rng.seed = p_seed
	_enemy_wait = minf(definition.opening_delay, OPENING_DELAY_CAP)
	_last_stamina = player.stamina
	player.mods.reseed(p_seed)
	enemy.mods.reseed(p_seed + 1)

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

## Item slot tap: `item` is a consumable id (charge taken from `items`) or a ConsumableItem (free use when
## there is no bag). Allowed while idle or guarding.
func use_item(item: Variant) -> bool:
	if not input_enabled:
		action_rejected.emit(ACTION_ITEM, REJECT_DISABLED)
		return false
	return perform_use_item(item)

func perform_use_item(item: Variant) -> bool:
	if finished:
		action_rejected.emit(ACTION_ITEM, REJECT_FINISHED)
		return false
	if not (player.state is IdleState or player.state is BlockingState):
		action_rejected.emit(ACTION_ITEM, REJECT_BUSY)
		return false
	var def: ConsumableItem = item if item is ConsumableItem else null
	if def != null:
		if items != null and items.take_charge(def.id) == null:
			def = null
	elif items != null and (item is StringName or item is String):
		def = items.take_charge(StringName(item))
	if def == null:
		action_rejected.emit(ACTION_ITEM, REJECT_NO_ITEM)
		return false
	var left := items.charges(def.id) if items != null else -1
	var ctx := HookCtx.new(self, player)
	ctx.rng = rng
	ctx.mod = ItemUseMod.new(def.id)
	ctx.fx = HookApi.new(self, ctx.mod, Fighter.PLAYER, 0)
	def.use(ctx)
	_sync_stamina()
	item_used.emit(def.id, left)
	_resolve_deaths()
	return true

func try_block_release() -> bool:
	return perform_block_release()

func perform_attack() -> bool:
	var ctx := AttackCtx.new(self, player)
	ctx.stamina_cost = player.stats.value(CombatStats.ATTACK_COST)
	ctx.lock_time = player.stats.value(CombatStats.ATTACK_LOCK)
	ctx.damage = player.stats.value(CombatStats.ATTACK_DAMAGE)
	player.mods.fire(&"modify_attack", ctx, self)
	if player.state is BlockingState and not finished and player.stamina >= ctx.stamina_cost:
		(player.state as BlockingState).on_finished(self, player)
	var reason := _attack_refusal(ctx.stamina_cost)
	if reason != &"":
		action_rejected.emit(ACTION_ATTACK, reason)
		return false
	player.spend_stamina(ctx.stamina_cost)
	enter_state(player, AttackingState.new(ctx.lock_time))
	var crit := enemy.state is StaggeredState
	var mult := combo_multiplier()
	var amount := outgoing_damage(player, enemy, ctx.damage * mult)
	deal_damage(enemy, amount, [HookApi.TAG_ATTACK], 0)
	_add_combo(tuning.combo_crit_weight if crit else 1)
	_award_souls(tuning.souls_per_hit * mult, &"hit")
	player_attacked.emit(amount, enemy.hp)
	player_hit.emit(amount, enemy.hp, crit, combo)
	_sync_stamina()
	_resolve_deaths()
	return true

## Damage multiplier of the current combo: 1 + combo_step per counted hit, capped at combo_max_multiplier.
func combo_multiplier() -> float:
	return minf(1.0 + tuning.combo_step * combo, tuning.combo_max_multiplier)

func perform_block() -> bool:
	var reason := _block_refusal()
	if reason != &"":
		action_rejected.emit(ACTION_BLOCK, reason)
		return false
	enter_state(player, BlockingState.new(player.stats.value(CombatStats.BLOCK_MIN_DURATION)))
	return true

## The button was released: the guard ends at max(release, press + block_min_duration). Never gated by
## input_enabled, so a held guard cannot get stuck.
func perform_block_release() -> bool:
	var blocking := player.state as BlockingState
	if blocking == null or not blocking.is_held():
		return false
	blocking.release()
	var left := blocking.remaining(player)
	if left <= 0.0:
		blocking.on_finished(self, player)
		return true
	fighter_state_timed.emit(player.side, BlockingState.ID, left)
	return true

## Continues the same duel after a player death: the enemy goes idle and waits revive_grace seconds.
func revive_player(hp_fraction: float) -> bool:
	if not finished or winner != Fighter.ENEMY:
		return false
	finished = false
	winner = &""
	player.hp = clampi(ceili(player.max_hp * hp_fraction), 1, player.max_hp)
	player.stamina = player.max_stamina
	player.block_cooldown = 0.0
	player.holding_block = false
	_kind = null
	_strike_index = 0
	_reset_combo()
	_enemy_wait = tuning.revive_grace
	enter_state(player, IdleState.new())
	enter_state(enemy, IdleState.new())
	player_hp_changed.emit(player.hp, player.max_hp)
	player_revived.emit(player.hp)
	_sync_stamina()
	return true

func foe_of(fighter: Fighter) -> Fighter:
	return enemy if fighter == player else player

func fighter_on(side: StringName) -> Fighter:
	return player if side == Fighter.PLAYER else enemy

func outgoing_damage(attacker: Fighter, target: Fighter, base: float) -> int:
	var scale := target.state.damage_taken_multiplier(attacker.stats)
	scale *= attacker.stats.value(CombatStats.DAMAGE_DEALT_MULT) * target.stats.value(CombatStats.DAMAGE_TAKEN_MULT)
	return roundi(base * scale)

## Applies damage and runs the damage and death hooks. Returns the amount applied.
func deal_damage(target: Fighter, amount: int, tags: Array[StringName], depth: int) -> int:
	if amount <= 0 or not target.is_alive():
		return 0
	target.take_damage(amount)
	_emit_hp(target)
	var source := foe_of(target)
	var is_proc := tags.has(HookApi.TAG_PROC)
	source.mods.fire(&"on_damage_dealt", _damage_ctx(source, target, amount, tags, depth, is_proc), self)
	target.mods.fire(&"on_damage_taken", _damage_ctx(target, target, amount, tags, depth, is_proc), self)
	if not target.is_alive():
		_would_die(target, amount, depth, is_proc)
	return amount

func heal_fighter(side: StringName, amount: int) -> bool:
	var fighter := fighter_on(side)
	var before := fighter.hp
	fighter.heal(amount)
	if fighter.hp == before:
		return false
	_emit_hp(fighter)
	return true

func add_stamina(side: StringName, amount: float) -> void:
	var fighter := fighter_on(side)
	fighter.stamina = clampf(fighter.stamina + amount, 0.0, fighter.max_stamina)
	_sync_stamina()

func free_attack(damage_mult: float, depth: int) -> int:
	var amount := outgoing_damage(player, enemy, player.stats.value(CombatStats.ATTACK_DAMAGE) * damage_mult)
	var applied := deal_damage(enemy, amount, [HookApi.TAG_PROC, HookApi.TAG_ATTACK], depth)
	if applied > 0:
		player_attacked.emit(applied, enemy.hp)
	return applied

func prevent_death(survive_hp: int) -> bool:
	if _pending_death == null:
		return false
	_pending_death.survive_hp = maxi(survive_hp, 1)
	return true

func stagger_enemy(seconds: float) -> void:
	_kind = null
	_enemy_wait = definition.post_stagger_delay
	enter_state(enemy, StaggeredState.new(seconds))

func enter_state(fighter: Fighter, state: FighterState) -> void:
	fighter.state = state
	fighter.state_elapsed = 0.0
	state.enter(self, fighter)
	fighter_state_changed.emit(fighter.side, state.id())
	fighter_state_timed.emit(fighter.side, state.id(), state.duration())

func _attack_refusal(cost: float) -> StringName:
	if finished:
		return REJECT_FINISHED
	if not player.state.can_act():
		return REJECT_BUSY
	if player.stamina < cost:
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
	if not _started:
		_started = true
		_fire_fight_start()
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
	var duration := _kind.telegraph_time(_strike_index) * enemy.stats.value(CombatStats.TELEGRAPH_SCALE)
	enter_state(enemy, AttackingState.new(duration, _on_telegraph_done))
	telegraph_started.emit(_kind.telegraph_id(), duration, _strike_index)
	strike_timing.emit(duration, player.stats.value(CombatStats.PARRY_WINDOW), _kind.telegraph_id(), _strike_index)

func _on_telegraph_done() -> void:
	var result := _kind.resolve(self, _strike_index)
	result.damage = mini(outgoing_damage(enemy, player, result.damage), _hit_cap())
	deal_damage(player, result.damage, [TAG_STRIKE], 0)
	player.spend_stamina(result.stamina_cost)
	_fire_strike_hooks(result)
	if result.outcome == StrikeResult.PARRIED:
		_award_souls(tuning.souls_per_parry, &"parry")
	result.target_hp = player.hp
	if result.outcome == StrikeResult.HIT and result.damage > 0:
		_reset_combo()
	strike_resolved.emit(result)
	player.state.after_strike(self, player, result)
	_sync_stamina()
	_resolve_deaths()
	if finished:
		return
	if result.staggers_attacker:
		stagger_enemy(enemy.stats.value(CombatStats.STAGGER_TIME))
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

## Largest damage one enemy hit may deal to the player: max_hit_share of max hp, at least 1.
func _hit_cap() -> int:
	return maxi(ceili(player.max_hp * player.stats.value(CombatStats.MAX_HIT_SHARE)), 1)

func _fire_fight_start() -> void:
	player.mods.reset_fight()
	enemy.mods.reset_fight()
	player.mods.fire(&"on_fight_start", HookCtx.new(self, player), self)
	enemy.mods.fire(&"on_fight_start", HookCtx.new(self, enemy), self)

func _fire_strike_hooks(result: StrikeResult) -> void:
	var hook := &""
	if result.outcome == StrikeResult.PARRIED:
		hook = &"on_parry"
	elif result.outcome == StrikeResult.BLOCKED:
		hook = &"on_block"
	if hook != &"":
		player.mods.fire(hook, _strike_ctx(player, result), self)
	enemy.mods.fire(&"on_strike_result", _strike_ctx(enemy, result), self)

func _strike_ctx(owner: Fighter, result: StrikeResult) -> StrikeCtx:
	var ctx := StrikeCtx.new(self, owner)
	ctx.result = result
	ctx.precision = result.precision
	ctx.perfect = result.perfect
	return ctx

func _damage_ctx(owner: Fighter, target: Fighter, amount: int, tags: Array[StringName], depth: int, is_proc: bool) -> DamageCtx:
	var ctx := DamageCtx.new(self, owner)
	ctx.source_side = foe_of(target).side
	ctx.target_side = target.side
	ctx.amount = amount
	ctx.tags = tags
	ctx.depth = depth
	ctx.is_proc = is_proc
	return ctx

func _would_die(target: Fighter, amount: int, depth: int, is_proc: bool) -> void:
	var ctx := DeathCtx.new(self, target)
	ctx.amount = amount
	ctx.depth = depth
	ctx.is_proc = is_proc
	_pending_death = ctx
	target.mods.fire(&"on_would_die", ctx, self)
	_pending_death = null
	if ctx.survive_hp > 0:
		target.hp = mini(ctx.survive_hp, target.max_hp)
		_emit_hp(target)
		return
	var foe_ctx := DeathCtx.new(self, foe_of(target))
	foe_ctx.amount = amount
	foe_ctx.depth = depth
	foe_ctx.is_proc = is_proc
	target.mods.fire(&"on_death", ctx, self)
	foe_of(target).mods.fire(&"on_death", foe_ctx, self)

func _emit_hp(fighter: Fighter) -> void:
	if fighter == player:
		player_hp_changed.emit(fighter.hp, fighter.max_hp)
	else:
		enemy_hp_changed.emit(fighter.hp, fighter.max_hp)

func _resolve_deaths() -> void:
	if finished:
		return
	if not enemy.is_alive():
		_finish(Fighter.PLAYER)
	elif not player.is_alive():
		_finish(Fighter.ENEMY)

func _award_souls(amount: float, source: StringName) -> void:
	_souls_fraction += amount
	var whole := floori(_souls_fraction)
	if whole <= 0:
		return
	_souls_fraction -= whole
	souls_earned_total += whole
	souls_earned.emit(whole, source)

func _add_combo(count: int) -> void:
	combo += count
	combo_changed.emit(combo, combo_multiplier())

func _reset_combo() -> void:
	if combo == 0:
		return
	combo = 0
	combo_changed.emit(0, 1.0)

func _sync_stamina() -> void:
	if is_equal_approx(player.stamina, _last_stamina):
		return
	_last_stamina = player.stamina
	stamina_changed.emit(player.stamina, player.max_stamina)

func _finish(winner_side: StringName) -> void:
	finished = true
	winner = winner_side
	duel_finished.emit(winner_side)

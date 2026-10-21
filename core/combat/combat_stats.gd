## Resolved numbers of one fighter: base values (from CombatTuning or an enemy definition), then the owner's
## modifiers. Cached; any change of the modifier stack invalidates it. Duel and attack kinds read only this.
class_name CombatStats
extends RefCounted

const MAX_HP := &"max_hp"
const MAX_STAMINA := &"max_stamina"
const STAMINA_REGEN := &"stamina_regen"
const ATTACK_DAMAGE := &"attack_damage"
const ATTACK_COST := &"attack_cost"
const ATTACK_LOCK := &"attack_lock"
const BLOCK_STARTUP := &"block_startup"
## Seconds the guard stays up after the press even if released earlier.
const BLOCK_MIN_DURATION := &"block_min_duration"
const BLOCK_COOLDOWN := &"block_cooldown"
## Stamina per point of incoming strike damage held by the guard.
const BLOCK_COST := &"block_cost"
const PARRY_WINDOW := &"parry_window"
const PERFECT_THRESHOLD := &"perfect_threshold"
const CHIP_SHARE := &"chip_share"
const GUARD_BREAK_SHARE := &"guard_break_damage_share"
const GUARD_BREAK_RESIST := &"guard_break_resist"
const STAGGER_TIME := &"stagger_time"
const PUNISH_MULT := &"punish_mult"
const TELEGRAPH_SCALE := &"telegraph_scale"
const DAMAGE_TAKEN_MULT := &"damage_taken_mult"
const DAMAGE_DEALT_MULT := &"damage_dealt_mult"
## One enemy hit never takes more than this share of the target's max hp (applied after armor and block).
const MAX_HIT_SHARE := &"max_hit_share"

var _base := {}
var _cache := {}
var _stack: ModifierStack
var _ctx: HookCtx

func _init(p_owner: Fighter, p_stack: ModifierStack) -> void:
	_stack = p_stack
	_ctx = HookCtx.new(null, p_owner)

static func tuning_base(tuning: CombatTuning) -> Dictionary:
	return {
		MAX_HP: float(tuning.player_hp),
		MAX_STAMINA: tuning.player_stamina,
		STAMINA_REGEN: tuning.stamina_regen,
		ATTACK_DAMAGE: float(tuning.player_damage),
		ATTACK_COST: tuning.attack_stamina_cost,
		ATTACK_LOCK: tuning.attack_duration,
		BLOCK_STARTUP: tuning.block_startup,
		BLOCK_MIN_DURATION: tuning.block_duration,
		BLOCK_COOLDOWN: tuning.block_cooldown,
		BLOCK_COST: tuning.block_stamina_cost,
		PARRY_WINDOW: tuning.parry_window,
		PERFECT_THRESHOLD: tuning.perfect_threshold,
		CHIP_SHARE: tuning.chip_damage_share,
		GUARD_BREAK_SHARE: tuning.guard_break_damage_share,
		GUARD_BREAK_RESIST: 0.0,
		STAGGER_TIME: tuning.stagger_time,
		PUNISH_MULT: tuning.punish_multiplier,
		TELEGRAPH_SCALE: 1.0,
		DAMAGE_TAKEN_MULT: 1.0,
		DAMAGE_DEALT_MULT: 1.0,
		MAX_HIT_SHARE: tuning.max_hit_share,
	}

func set_base(stat_id: StringName, value: float) -> void:
	_base[stat_id] = value
	invalidate()

func base(stat_id: StringName) -> float:
	return float(_base.get(stat_id, 0.0))

func load_base(values: Dictionary) -> void:
	_base = values.duplicate()
	invalidate()

func invalidate() -> void:
	_cache.clear()

func value(stat_id: StringName) -> float:
	if _cache.has(stat_id):
		return _cache[stat_id]
	var resolved := _stack.resolve(stat_id, base(stat_id), _ctx)
	_cache[stat_id] = resolved
	return resolved

func int_value(stat_id: StringName) -> int:
	return roundi(value(stat_id))

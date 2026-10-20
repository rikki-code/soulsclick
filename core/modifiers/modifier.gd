## Base of everything that changes combat numbers or reacts to combat events: equipment, relics, affixes.
## All hooks are no-op virtuals; a new effect is one file overriding only what it needs.
class_name Modifier
extends RefCounted

enum Stage { ADD, MUL, SET }

var params := {}
var stacks := 1
var stage := Stage.ADD
## Within a stage, lower priority runs first; ties keep acquire order.
var priority := 0
## Whether the modifier also sees events produced by modifier effects.
var reacts_to_proc := false
## Acquire index, set by the stack; makes the order stable.
var order := 0
var run_data := {}
var fight_data := {}
var owner: Fighter
var rng := RandomNumberGenerator.new()

func id() -> StringName:
	return &""

func param(key: StringName, fallback := 0.0) -> float:
	return float(params.get(key, fallback)) * stacks

func mark_dirty() -> void:
	if owner != null:
		owner.stats.invalidate()

func on_added(_fighter: Fighter) -> void:
	pass

func modify_stat(_stat_id: StringName, value: float, _ctx: HookCtx) -> float:
	return value

func on_fight_start(_ctx: HookCtx) -> void:
	pass

func modify_attack(_ctx: AttackCtx) -> void:
	pass

func on_parry(_ctx: StrikeCtx) -> void:
	pass

func on_block(_ctx: StrikeCtx) -> void:
	pass

func on_strike_result(_ctx: StrikeCtx) -> void:
	pass

func on_damage_dealt(_ctx: DamageCtx) -> void:
	pass

func on_damage_taken(_ctx: DamageCtx) -> void:
	pass

func on_would_die(_ctx: DeathCtx) -> void:
	pass

func on_death(_ctx: DeathCtx) -> void:
	pass

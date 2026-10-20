## Base context handed to every modifier hook. The only way to change the world is `fx`.
class_name HookCtx
extends RefCounted

var owner: Fighter
var foe: Fighter
var side: StringName
var fx: HookApi
var mod: Modifier
var rng: RandomNumberGenerator
## Proc chain depth: 0 for a player or enemy action, +1 for every effect started through `fx`.
var depth := 0
## True when the event was produced by a modifier effect (tag `proc`).
var is_proc := false
var _duel: Duel

func _init(p_duel: Duel = null, p_owner: Fighter = null) -> void:
	_duel = p_duel
	owner = p_owner
	if p_owner != null:
		side = p_owner.side
	if p_duel != null and p_owner != null:
		foe = p_duel.foe_of(p_owner)

func time() -> float:
	return _duel.time if _duel != null else 0.0

func hp_ratio(of_side: StringName) -> float:
	var fighter := owner if of_side == side else foe
	return float(fighter.hp) / maxf(fighter.max_hp, 1.0)

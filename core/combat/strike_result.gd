## Outcome of one enemy strike, carried by Duel.strike_resolved so the view never inspects state.
class_name StrikeResult
extends RefCounted

const HIT := &"hit"
const BLOCKED := &"blocked"
const PARRIED := &"parried"
const FEINT := &"feint"

var kind_id: StringName
var outcome: StringName = HIT
var strike_index: int
var strike_count: int
## Final damage dealt to the target.
var damage: int
var target_side: StringName = Fighter.PLAYER
## Target hp after the strike (filled by Duel).
var target_hp: int
var stamina_cost := 0.0
var staggers_attacker := false
## Heavy strike that went through a plain block.
var guard_broken := false

func _init(p_kind_id: StringName, p_index: int, p_count: int, p_damage: int) -> void:
	kind_id = p_kind_id
	strike_index = p_index
	strike_count = p_count
	damage = p_damage

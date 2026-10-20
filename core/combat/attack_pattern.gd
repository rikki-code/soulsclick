## Order in which an enemy plays its steps. Default: in order, looping. Override _pick_index for
## random or weighted patterns.
class_name AttackPattern
extends RefCounted

var steps: Array[AttackStepDefinition]
var cursor := 0

func _init(p_steps: Array[AttackStepDefinition]) -> void:
	steps = p_steps

func next_step(rng: RandomNumberGenerator) -> AttackStepDefinition:
	var index := _pick_index(rng)
	cursor = index + 1
	return steps[index]

func _pick_index(_rng: RandomNumberGenerator) -> int:
	return cursor % steps.size()

## One step of an enemy pattern: which attack kind to use and its numbers. Kinds read only the fields they need.
class_name AttackStepDefinition
extends Resource

@export var kind_id: StringName = &"quick"
## Windup before the strike (quick, heavy, feint).
@export var telegraph_time := 0.7
## Combo only: one windup per strike, the size is the strike count.
@export var telegraph_times := PackedFloat32Array()
## Multiplier of the enemy's damage for each strike of this step.
@export var damage_scale := 1.0
## Combo only: pause between a resolved strike and the next windup.
@export var strike_gap := 0.0
## Idle time of the enemy after the step, before the next one starts.
@export var recovery_time := 1.2
## Feint only: kind id the telegraph reports, so the view cannot tell it apart from the real attack.
@export var imitates: StringName = &"quick"

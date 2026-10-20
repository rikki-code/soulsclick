## An enemy as data: stats and an attack pattern. Name is a translation key.
class_name EnemyDefinition
extends Resource

@export var id: StringName = &""
@export var name_key := ""
@export var hp := 50
@export var damage := 8
@export var pattern: Array[AttackStepDefinition] = []
## Tag the view maps to a look; core never holds visuals.
@export var palette_tag: StringName = &""
@export var souls_reward := 10
## Idle time before the first step.
@export var opening_delay := 1.2
## Idle time after a stagger ends before the next step.
@export var post_stagger_delay := 0.6

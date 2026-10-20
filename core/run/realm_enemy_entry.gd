## One weighted enemy in a realm pool; `affixes` lists the elite affix ids it may roll (placeholders until affixes exist).
class_name RealmEnemyEntry
extends Resource

@export var enemy: EnemyDefinition
@export var weight := 1.0
@export var affixes: Array[StringName] = []

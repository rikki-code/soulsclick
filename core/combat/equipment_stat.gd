## One stat change of a piece of equipment, as data.
class_name EquipmentStat
extends Resource

@export var stat: StringName
@export var stage: Modifier.Stage = Modifier.Stage.ADD
@export var amount := 0.0

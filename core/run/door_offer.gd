## The doors of one step with the map position, everything a map view needs.
class_name DoorOffer
extends RefCounted

var realm_index := 0
var depth := 0
var realm_id: StringName = &""
var step_index := 0
var step_count := 0
var doors: Array[Door] = []

func to_dict() -> Dictionary:
	var list: Array[Dictionary] = []
	for door in doors:
		list.append(door.to_dict())
	return {"realm_index": realm_index, "depth": depth, "realm_id": realm_id, "step_index": step_index, "step_count": step_count, "doors": list}

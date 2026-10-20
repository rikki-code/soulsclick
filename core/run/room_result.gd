## What the game layer reports back when a room is done.
class_name RoomResult
extends RefCounted

var won := true
## Player hp at the end of the room; -1 keeps the current value.
var hp_after := -1
var souls_bonus := 0
var souls_spent := 0
## Choice made in the room (bonfire option, shop purchase summary); kind specific.
var choice: StringName = &""
var flawless := false

static func victory(p_hp_after := -1) -> RoomResult:
	var result := RoomResult.new()
	result.hp_after = p_hp_after
	return result

static func defeat() -> RoomResult:
	var result := RoomResult.new()
	result.won = false
	result.hp_after = 0
	return result

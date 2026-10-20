## First-person hands: tap the left half to block, the right half to attack. No button UI; the hands (shield
## left, weapon right) react to the player's state and to strikes.
class_name HandsScheme
extends InputScheme

const RESERVED_SHARE := 0.19

var _rig := PlayerRig.new()

func _init() -> void:
	add_child(_rig)

func reserved_height(view_size: Vector2) -> float:
	return view_size.y * RESERVED_SHARE

func on_action_rejected(_action_id: StringName, _reason: StringName) -> void:
	_rig.on_rejected()

func on_strike_resolved(result: StrikeResult) -> void:
	_rig.on_strike(result)

func on_player_state(state_id: StringName, _duration: float) -> void:
	_rig.on_state(state_id)

func _layout(view_size: Vector2) -> void:
	_rig.layout(view_size)

func _pointer_down(_pointer: int, at: Vector2) -> void:
	if at.x < size.x * 0.5:
		block_requested.emit()
	else:
		attack_requested.emit()

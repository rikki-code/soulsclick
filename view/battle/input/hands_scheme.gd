## First-person hands: tap the left half to block, the right half to attack. No button UI.
class_name HandsScheme
extends InputScheme

func _init(loadout: PlayerLoadoutView = null) -> void:
	super(loadout)

func _pointer_down(pointer: int, at: Vector2) -> void:
	if at.x < size.x * 0.5:
		_hold_block(pointer)
	else:
		attack_requested.emit()

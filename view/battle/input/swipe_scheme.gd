## Swipe up = attack, swipe down = block. Fires as soon as a finger has travelled the threshold (not on release);
## one action per touch. No extra UI: the hands are the only thing shown.
class_name SwipeScheme
extends InputScheme

const THRESHOLD := 40.0

var _starts: Dictionary = {}
var _fired: Dictionary = {}

func _init(loadout: PlayerLoadoutView = null) -> void:
	super(loadout)

func _on_enabled_changed(_enabled: bool) -> void:
	_starts.clear()
	_fired.clear()

func _pointer_down(pointer: int, at: Vector2) -> void:
	_starts[pointer] = at
	_fired.erase(pointer)

func _pointer_moved(pointer: int, at: Vector2) -> void:
	if not _starts.has(pointer) or _fired.has(pointer):
		return
	var travel: Vector2 = at - _starts[pointer]
	if absf(travel.y) < THRESHOLD or absf(travel.y) <= absf(travel.x):
		return
	_fired[pointer] = true
	if travel.y < 0.0:
		attack_requested.emit()
	else:
		_hold_block(pointer)

func _pointer_up(pointer: int) -> void:
	_starts.erase(pointer)
	_fired.erase(pointer)

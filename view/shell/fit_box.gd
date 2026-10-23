## Centers its children and shrinks them (never enlarges) until they fit the box, whatever the window aspect.
## It reports no minimum size, so a tall page can never push its parent or start a layout feedback loop.
class_name FitBox
extends Container

## Free border kept around the content, in canvas pixels.
@export var margin := 16.0

func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		for child in get_children():
			var control := child as Control
			if control != null and control.visible and not control.top_level:
				_fit(control)

func _fit(control: Control) -> void:
	var need := control.get_combined_minimum_size()
	var room := (size - Vector2.ONE * margin * 2.0).max(Vector2.ONE)
	var factor := 1.0
	if need.x > 0.0 and need.y > 0.0:
		factor = minf(1.0, minf(room.x / need.x, room.y / need.y))
	control.pivot_offset = Vector2.ZERO
	control.scale = Vector2.ONE * factor
	control.size = need
	control.position = (size - need * factor) * 0.5

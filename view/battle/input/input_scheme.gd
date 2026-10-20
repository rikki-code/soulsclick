## Base of the battle input schemes. Turns pointer events (one id per touch finger, one for the mouse) into
## attack_requested / block_requested; subclasses decide what a pointer means and how the zone looks.
class_name InputScheme
extends Control

signal attack_requested
signal block_requested

const MOUSE_POINTER := -1

var input_enabled := true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(event: InputEvent) -> void:
	handle_event(event)

## Raw events are read here (not through Control GUI routing) so every finger arrives, even with several buttons
## or halves pressed at once. Mouse events synthesized from touch are skipped: the touch itself is handled.
func handle_event(event: InputEvent) -> void:
	if not input_enabled:
		return
	var touch := event as InputEventScreenTouch
	if touch != null:
		_route_button(touch.index, touch.position, touch.pressed and not touch.canceled)
		return
	var drag := event as InputEventScreenDrag
	if drag != null:
		_pointer_moved(drag.index, drag.position)
		return
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	var click := event as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_LEFT:
		_route_button(MOUSE_POINTER, click.position, click.pressed)
		return
	var motion := event as InputEventMouseMotion
	if motion != null and motion.button_mask & MOUSE_BUTTON_MASK_LEFT != 0:
		_pointer_moved(MOUSE_POINTER, motion.position)

func set_input_enabled(enabled: bool) -> void:
	if enabled == input_enabled:
		return
	input_enabled = enabled
	_on_enabled_changed(enabled)

func layout(size_in_view: Vector2) -> void:
	position = Vector2.ZERO
	size = size_in_view
	_layout(size_in_view)

## Height of the bottom strip the scheme occupies; the HUD bars and the enemy stay above it.
func reserved_height(_view_size: Vector2) -> float:
	return 0.0

func on_action_accepted(_action_id: StringName) -> void:
	pass

func on_action_rejected(_action_id: StringName, _reason: StringName) -> void:
	pass

func on_strike_resolved(_result: StrikeResult) -> void:
	pass

func on_player_state(_state_id: StringName, _duration: float) -> void:
	pass

func _layout(_view_size: Vector2) -> void:
	pass

func _on_enabled_changed(_enabled: bool) -> void:
	pass

func _pointer_down(_pointer: int, _at: Vector2) -> void:
	pass

func _pointer_moved(_pointer: int, _at: Vector2) -> void:
	pass

func _pointer_up(_pointer: int) -> void:
	pass

func _route_button(pointer: int, at: Vector2, pressed: bool) -> void:
	if pressed:
		_pointer_down(pointer, at)
	else:
		_pointer_up(pointer)

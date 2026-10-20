## Base of the battle input schemes. Turns pointer events (one id per touch finger, one for the mouse) into
## attack_requested / block_requested / block_released; subclasses decide what a pointer means and how the zone looks.
## Every scheme shows the player's first-person hands (PlayerRig) reacting to state and strikes; subclasses add
## only their own controls on top.
class_name InputScheme
extends Control

signal attack_requested
signal block_requested
## Block is held: emitted when the finger that started it lifts (the core decides how long the guard really stays).
signal block_released

const MOUSE_POINTER := -1

var input_enabled := true
## Screen rects (HUD buttons) where a press is not a battle action.
var excluded_rects: Array[Rect2] = []
## Pointers currently holding a block; block_released fires when the last one lifts.
var _block_pointers: Array[int] = []
var _rig: PlayerRig

func _init(loadout: PlayerLoadoutView = null) -> void:
	_rig = PlayerRig.new(loadout)
	add_child(_rig)

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
	_block_pointers.clear()
	_on_enabled_changed(enabled)

func layout(size_in_view: Vector2) -> void:
	position = Vector2.ZERO
	size = size_in_view
	_layout(size_in_view)

## Height of the bottom strip the scheme occupies; the HUD bars and the enemy stay above it.
func reserved_height(view_size: Vector2) -> float:
	return _rig.zone_height(view_size) + _bottom_inset(view_size)

## Strip under the hands that the scheme keeps for itself; the hands sit above it.
func _bottom_inset(_view_size: Vector2) -> float:
	return 0.0

func on_action_accepted(_action_id: StringName) -> void:
	pass

func on_action_rejected(_action_id: StringName, _reason: StringName) -> void:
	_rig.on_rejected()

func on_strike_resolved(result: StrikeResult) -> void:
	_rig.on_strike(result)

func on_player_state(state_id: StringName, _duration: float) -> void:
	_rig.on_state(state_id)

func _layout(view_size: Vector2) -> void:
	_rig.layout(view_size, _bottom_inset(view_size))

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
		for rect in excluded_rects:
			if rect.has_point(at):
				return
		_pointer_down(pointer, at)
	else:
		_pointer_up(pointer)
		_release_block(pointer)

func _hold_block(pointer: int) -> void:
	if not _block_pointers.has(pointer):
		_block_pointers.append(pointer)
	block_requested.emit()

func _release_block(pointer: int) -> void:
	if _block_pointers.has(pointer):
		_block_pointers.erase(pointer)
		if _block_pointers.is_empty():
			block_released.emit()

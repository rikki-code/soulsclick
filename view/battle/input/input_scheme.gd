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

## Share of the screen height the highlighted zone may take: the hands scheme answers taps anywhere, but the ring
## around the whole screen would point at nothing.
const ZONE_HEIGHT_SHARES := Vector2(0.2, 0.35)
## How far down the strip the default cue's arrow tip lands.
const CUE_DEPTH := 0.35

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

## Screen rect where the player acts for `action_id` (the tutorial highlights it): by default the left half of a
## bottom strip (the hands) blocks and the right half attacks.
func zone_rect(action_id: StringName) -> Rect2:
	var height := clampf(reserved_height(size), size.y * ZONE_HEIGHT_SHARES.x, size.y * ZONE_HEIGHT_SHARES.y)
	var left := size.x * 0.5 if action_id == Duel.ACTION_ATTACK else 0.0
	return Rect2(left, size.y - height, size.x * 0.5, height)

## How the tutorial points at `action_id`: an arrow from above onto that half of the strip. Schemes with their own
## controls (buttons, swipes) override it.
func cue(action_id: StringName) -> TutorialCue:
	var rect := zone_rect(action_id)
	return TutorialCue.of(Vector2(rect.get_center().x, rect.position.y + rect.size.y * CUE_DEPTH), Vector2.DOWN)

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

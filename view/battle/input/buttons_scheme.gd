## Two labeled buttons in a slim strip at the very bottom, below the hands (the hands are lifted above the strip). The buttons are only the look; presses are hit-tested from raw pointer events so both
## thumbs work at once.
class_name ButtonsScheme
extends InputScheme

const BUTTON_FONT := 44
const BUTTON_HEIGHT_SHARE := 0.075
const BUTTON_BOTTOM_SHARE := 0.015
const BUTTON_ALPHA := 0.82
const MARGIN_SHARE := 0.04
const HIT_GROW := 14.0
const LANDSCAPE_WIDTH_SHARE := 0.22
const LANDSCAPE_HEIGHT_SHARE := 0.6
const LANDSCAPE_TOP_SHARE := 0.3
const FLASH_COLOR := Color(1.6, 1.6, 1.6)
const FLASH_SECONDS := 0.15
const BLOCK_HELD_COLOR := Color(1.5, 1.5, 1.8)
const WIGGLE_ANGLE := 0.04
const ATTACK_COLOR := Color(0.62, 0.2, 0.14)
const BLOCK_COLOR := Color(0.16, 0.3, 0.5)

## Rig parts use absolute z (art z values); the buttons must draw above all of them.
const BUTTON_Z := 100

var _attack_button: Button
var _block_button: Button

func _init(loadout: PlayerLoadoutView = null) -> void:
	super(loadout)
	_attack_button = _make_button(tr("BATTLE_ATTACK"), ATTACK_COLOR, HORIZONTAL_ALIGNMENT_CENTER)
	_block_button = _make_button(tr("BATTLE_BLOCK"), BLOCK_COLOR, HORIZONTAL_ALIGNMENT_CENTER)

func on_action_accepted(action_id: StringName) -> void:
	var button := _button_for(action_id)
	button.modulate = FLASH_COLOR
	button.create_tween().tween_property(button, "modulate", Color.WHITE, FLASH_SECONDS)

func on_action_rejected(action_id: StringName, reason: StringName) -> void:
	super(action_id, reason)
	var button := _button_for(action_id)
	var tween := button.create_tween()
	tween.tween_property(button, "rotation", WIGGLE_ANGLE, 0.04)
	tween.tween_property(button, "rotation", -WIGGLE_ANGLE, 0.08)
	tween.tween_property(button, "rotation", 0.0, 0.04)

func on_player_state(state_id: StringName, duration: float) -> void:
	super(state_id, duration)
	_block_button.self_modulate = BLOCK_HELD_COLOR if state_id == &"blocking" else Color.WHITE

func _layout(view_size: Vector2) -> void:
	super(view_size)
	var margin := view_size.x * MARGIN_SHARE
	if view_size.x > view_size.y:
		var extent := Vector2(view_size.x * LANDSCAPE_WIDTH_SHARE, view_size.y * LANDSCAPE_HEIGHT_SHARE)
		var top := view_size.y * LANDSCAPE_TOP_SHARE
		_place(_block_button, Vector2(margin, top), extent)
		_place(_attack_button, Vector2(view_size.x - margin - extent.x, top), extent)
		return
	var button_size := Vector2((view_size.x - margin * 3.0) * 0.5, view_size.y * BUTTON_HEIGHT_SHARE)
	var button_y := view_size.y * (1.0 - BUTTON_BOTTOM_SHARE - BUTTON_HEIGHT_SHARE)
	_place(_block_button, Vector2(margin, button_y), button_size)
	_place(_attack_button, Vector2(margin * 2.0 + button_size.x, button_y), button_size)

func _bottom_inset(view_size: Vector2) -> float:
	if view_size.x > view_size.y:
		return 0.0
	return view_size.y * (BUTTON_BOTTOM_SHARE + BUTTON_HEIGHT_SHARE) + view_size.x * MARGIN_SHARE

func _on_enabled_changed(enabled: bool) -> void:
	_attack_button.disabled = not enabled
	_block_button.disabled = not enabled

func _pointer_down(pointer: int, at: Vector2) -> void:
	if _attack_button.get_rect().grow(HIT_GROW).has_point(at):
		attack_requested.emit()
	elif _block_button.get_rect().grow(HIT_GROW).has_point(at):
		_hold_block(pointer)

func _button_for(action_id: StringName) -> Button:
	return _attack_button if action_id == Duel.ACTION_ATTACK else _block_button

## Labels sit on the outer-free side so the shield and the weapon hand drawn above the strip do not cover them.
func _make_button(text: String, color: Color, align: HorizontalAlignment) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = align
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Over the forearms that run down to the screen edge; the hands and gear stay visible above the strip.
	button.z_index = BUTTON_Z
	button.add_theme_font_size_override("font_size", BUTTON_FONT)
	button.add_theme_stylebox_override("normal", _box(color))
	button.add_theme_stylebox_override("hover", _box(color.lightened(0.1)))
	button.add_theme_stylebox_override("pressed", _box(color.lightened(0.35)))
	button.add_theme_stylebox_override("disabled", _box(color.darkened(0.6)))
	add_child(button)
	return button

func _place(button: Button, at: Vector2, extent: Vector2) -> void:
	button.position = at
	button.size = extent
	button.pivot_offset = extent * 0.5

static func _box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(color, BUTTON_ALPHA)
	box.set_corner_radius_all(24)
	box.set_border_width_all(4)
	box.content_margin_left = 24
	box.content_margin_right = 24
	box.border_color = color.lightened(0.4)
	return box

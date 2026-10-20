## Victory and death panels over the duel: dimmed screen, title, optional souls line, buttons.
class_name BattleOverlay
extends Control

signal continue_pressed
signal revive_pressed
signal menu_pressed

const DIM_COLOR := Color(0.0, 0.0, 0.0, 0.7)
const FADE_SECONDS := 0.35
const BUTTON_SIZE := Vector2(560, 110)
const TITLE_SIZE := 64
const TEXT_SIZE := 40
const SEPARATION := 28
const AUTO_CONTINUE_SECONDS := 1.4


var _dim := ColorRect.new()
var _box := VBoxContainer.new()
var _auto_continue: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_dim.color = DIM_COLOR
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)
	_dim.gui_input.connect(_on_dim_input)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_box.add_theme_constant_override("separation", SEPARATION)
	center.add_child(_box)

func show_victory(souls: int, delay: float) -> void:
	_reset()
	_add_label(tr("BATTLE_VICTORY"), TITLE_SIZE)
	_add_label(tr("BATTLE_SOULS") % souls, TEXT_SIZE)
	Audio.play(&"souls_gain")
	_reveal(delay)
	# Victory moves on by itself; a tap skips the wait.
	_auto_continue = create_tween()
	_auto_continue.tween_interval(delay + AUTO_CONTINUE_SECONDS)
	_auto_continue.tween_callback(_continue_once)

func show_death(can_revive: bool, delay: float) -> void:
	_reset()
	_add_label(tr("BATTLE_DEATH"), TITLE_SIZE)
	if can_revive:
		_add_button(tr("BATTLE_REVIVE") % GameSession.revive_ads(), revive_pressed.emit)
	_add_button(tr("MENU_BACK"), menu_pressed.emit)
	_reveal(delay)

func hide_overlay() -> void:
	visible = false

func _reset() -> void:
	if _auto_continue != null:
		_auto_continue.kill()
		_auto_continue = null
	for child in _box.get_children():
		_box.remove_child(child)
		child.queue_free()

func _reveal(delay: float) -> void:
	modulate.a = 0.0
	visible = true
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "modulate:a", 1.0, FADE_SECONDS)

func _add_label(text: String, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	_box.add_child(label)

func _add_button(text: String, on_pressed: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = BUTTON_SIZE
	button.add_theme_font_size_override("font_size", TEXT_SIZE)
	button.pressed.connect(on_pressed)
	_box.add_child(button)

## Tapping anywhere skips the victory wait; death panels keep their buttons.
func _on_dim_input(event: InputEvent) -> void:
	if _auto_continue != null and event is InputEventMouseButton and event.pressed:
		_continue_once()

func _continue_once() -> void:
	if _auto_continue == null:
		return
	_auto_continue.kill()
	_auto_continue = null
	continue_pressed.emit()

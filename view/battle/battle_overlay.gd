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

var _dim := ColorRect.new()
var _box := VBoxContainer.new()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	_dim.color = DIM_COLOR
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_box.add_theme_constant_override("separation", SEPARATION)
	center.add_child(_box)

func show_victory(souls: int, delay: float) -> void:
	_reset()
	_add_label(tr("BATTLE_VICTORY"), TITLE_SIZE)
	_add_label(tr("BATTLE_SOULS") % souls, TEXT_SIZE)
	Audio.play(&"souls_gain")
	_add_button(tr("BATTLE_CONTINUE"), continue_pressed.emit)
	_reveal(delay)

func show_death(can_revive: bool, delay: float) -> void:
	_reset()
	_add_label(tr("BATTLE_DEATH"), TITLE_SIZE)
	if can_revive:
		_add_button(tr("BATTLE_REVIVE"), revive_pressed.emit)
	_add_button(tr("MENU_BACK"), menu_pressed.emit)
	_reveal(delay)

func hide_overlay() -> void:
	visible = false

func _reset() -> void:
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

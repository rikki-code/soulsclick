## Pause panel over the duel: Resume, Settings, Abandon run, Main menu. Built in code and keeps running while the tree is
## paused; it only emits signals, the game layer decides what each one does.
class_name PauseMenu
extends Control

signal resume_requested
signal settings_requested
signal abandon_requested
signal menu_requested

const DIM_COLOR := Color(0.0, 0.0, 0.0, 0.75)
const BUTTON_WIDTH := 560.0
const TITLE_SIZE := 64
const SEPARATION := 24

var _box := VBoxContainer.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var dim := ColorRect.new()
	dim.color = DIM_COLOR
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	center.theme = MenuKit.big_text_theme()
	_box.custom_minimum_size.x = BUTTON_WIDTH
	_box.add_theme_constant_override("separation", SEPARATION)
	center.add_child(_box)
	_show_main()

## Settings open inside the pause panel; the game layer is still told, in case it wants to react.
func _show_main() -> void:
	_clear()
	_box.add_child(MenuKit.label(BattleText.text("PAUSE_TITLE", "Paused"), TITLE_SIZE))
	MenuKit.button(_box, BattleText.text("PAUSE_RESUME", "Resume"), resume_requested.emit)
	MenuKit.button(_box, BattleText.text("PAUSE_SETTINGS", "Settings"), _show_settings)
	MenuKit.button(_box, BattleText.text("PAUSE_ABANDON", "Abandon run"), abandon_requested.emit)
	MenuKit.button(_box, BattleText.text("PAUSE_MENU", "Main menu"), menu_requested.emit)

func _show_settings() -> void:
	_clear()
	_box.add_child(MenuKit.label(tr("SETTINGS_TITLE"), TITLE_SIZE))
	SettingsPage.add_to(_box, _show_main, _show_settings)
	settings_requested.emit()

func _clear() -> void:
	for child in _box.get_children():
		_box.remove_child(child)
		child.queue_free()

func open() -> void:
	_show_main()
	visible = true

func close() -> void:
	visible = false

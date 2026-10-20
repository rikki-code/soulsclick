## Base of the full-screen run pages (omens, doors, level-up, rest, summary): dark background, centered page of big text.
class_name RunScreen
extends Control

const STATUS_SIZE := 30
const BIG_BUTTON_HEIGHT := 150.0
const MUTED := Color(0.75, 0.72, 0.68)

var _page: VBoxContainer

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

## Builds the page with a title; call once from the subclass setup.
func _build(title: String) -> void:
	add_child(MenuKit.background())
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var center := CenterContainer.new()
	center.theme = MenuKit.big_text_theme()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	_page = MenuKit.page(center, title)
	_page.get_child(0).add_theme_font_size_override("font_size", 56)
	scroll.resized.connect(func() -> void: center.custom_minimum_size = scroll.size)

func _text(text: String, size := MenuKit.FONT_SIZE, color := Color.WHITE) -> Label:
	var label := MenuKit.label(text, size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = MenuKit.PAGE_WIDTH
	label.add_theme_color_override("font_color", color)
	_page.add_child(label)
	return label

func _status(run: Run) -> void:
	_text(RunScreen.status_text(run), STATUS_SIZE, MUTED)

func _button(text: String, on_pressed: Callable, height := MenuKit.ROW_HEIGHT) -> Button:
	var button := MenuKit.button(_page, text, on_pressed)
	button.custom_minimum_size.y = height
	return button

static func status_text(run: Run) -> String:
	return TranslationServer.translate("RUN_STATUS") % [run.hp, run.config.max_hp, run.souls]

static func kind_name(kind_id: StringName) -> String:
	return TranslationServer.translate("ROOM_" + String(kind_id).to_upper())

static func affix_name(affix_id: StringName) -> String:
	return "" if affix_id == &"" else TranslationServer.translate("AFFIX_" + String(affix_id).to_upper())

static func stat_name(stat: StringName) -> String:
	return TranslationServer.translate("STAT_" + String(stat).to_upper())

static func stat_text(value: float) -> String:
	return "%d" % roundi(value) if absf(value - roundf(value)) < 0.001 else "%.1f" % value

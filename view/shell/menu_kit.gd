## Builders shared by the shell screens: large, touch-sized, built in code.
class_name MenuKit
extends RefCounted

const FONT_SIZE := 36
const TITLE_FONT_SIZE := 72
const ROW_HEIGHT := 96.0
const PAGE_WIDTH := 640.0
const PAGE_SEPARATION := 24
const BACKGROUND_COLOR := Color(0.06, 0.05, 0.07)

## Only the default font size; everything else comes from the project theme.
static func big_text_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = FONT_SIZE
	return theme

static func background() -> ColorRect:
	var result := ColorRect.new()
	result.color = BACKGROUND_COLOR
	result.set_anchors_preset(Control.PRESET_FULL_RECT)
	return result

static func label(text: String, font_size := FONT_SIZE) -> Label:
	var result := Label.new()
	result.text = text
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", font_size)
	return result

static func page(parent: Control, title: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = PAGE_WIDTH
	box.add_theme_constant_override("separation", PAGE_SEPARATION)
	parent.add_child(box)
	box.add_child(label(title, TITLE_FONT_SIZE))
	return box

static func row(caption: String, control: Control) -> HBoxContainer:
	var box := HBoxContainer.new()
	var caption_label := Label.new()
	caption_label.text = caption
	caption_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(caption_label)
	control.custom_minimum_size = Vector2(PAGE_WIDTH * 0.5, ROW_HEIGHT)
	box.add_child(control)
	return box

static func button(parent: Control, text: String, on_pressed: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = ROW_HEIGHT
	result.pressed.connect(on_pressed)
	parent.add_child(result)
	return result

static func slider(value: float) -> HSlider:
	var result := HSlider.new()
	result.min_value = 0.0
	result.max_value = 1.0
	result.step = 0.05
	result.value = value
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return result

## The dropdown is its own popup window, outside the panel theme.
static func option(items: Array[String], selected: int) -> OptionButton:
	var result := OptionButton.new()
	for item in items:
		result.add_item(item)
	result.select(selected)
	result.get_popup().add_theme_font_size_override("font_size", FONT_SIZE)
	return result

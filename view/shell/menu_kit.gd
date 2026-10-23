## Builders shared by the shell screens: large, touch-sized, built in code.
class_name MenuKit
extends RefCounted

const FONT_SIZE := 36
const TITLE_FONT_SIZE := 72
const ROW_HEIGHT := 96.0
const PAGE_WIDTH := 640.0
const PAGE_SEPARATION := 24
const BACKGROUND_COLOR := Color(0.06, 0.05, 0.07)

## Tile look shared with the altar: dark tiles in dark panels, gold edges, gold for the way out, red for the risky.
const GOLD := Color(1.0, 0.82, 0.38)
const MUTED := Color(0.75, 0.72, 0.68)
const WARN := Color(0.95, 0.4, 0.45)
const TILE_FILL := Color(0.11, 0.09, 0.13)
const PANEL_FILL := Color(0.08, 0.07, 0.1)
const ACCENT_FILL := Color(0.16, 0.12, 0.08)
const WARN_FILL := Color(0.2, 0.08, 0.1)
const TILE_FONT_SIZE := 30
const HINT_FONT_SIZE := 24
const TILE_HEIGHT := 76.0
const TILE_BUTTON_HEIGHT := 88.0
const TILE_CONTROL_WIDTH := 300.0
const TILE_GAP := 8
const TILE_RADIUS := 12
const PANEL_MARGIN := 12.0
const TILE_MARGIN_X := 16.0
const TILE_MARGIN_Y := 6.0
const TRACK_HALF_HEIGHT := 7.0
const GRABBER_SIZE := 40
## Width of the settings page and of the pause panel, so a caption and its control fit side by side.
const WIDE_PAGE_WIDTH := 760.0

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

## A tile in a group: caption on the left, `control` on the right.
static func row(caption: String, control: Control) -> PanelContainer:
	var tile := PanelContainer.new()
	tile.custom_minimum_size.y = TILE_HEIGHT
	tile.add_theme_stylebox_override("panel", _padded(tile_style(TILE_FILL, GOLD.darkened(0.6)), TILE_MARGIN_X, TILE_MARGIN_Y))
	var box := HBoxContainer.new()
	tile.add_child(box)
	var caption_label := Label.new()
	caption_label.text = caption
	caption_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption_label.add_theme_font_size_override("font_size", TILE_FONT_SIZE)
	box.add_child(caption_label)
	control.custom_minimum_size.x = TILE_CONTROL_WIDTH
	box.add_child(control)
	return tile

static func button(parent: Control, text: String, on_pressed: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = ROW_HEIGHT
	result.pressed.connect(on_pressed)
	parent.add_child(result)
	return result

## Dark tile button with a gold edge.
static func tile_button(parent: Control, text: String, on_pressed: Callable) -> Button:
	return _styled_button(parent, text, on_pressed, TILE_FILL, GOLD.darkened(0.25), Color.WHITE)

## Gold button for the way out (Back, Resume).
static func accent_button(parent: Control, text: String, on_pressed: Callable) -> Button:
	return _styled_button(parent, text, on_pressed, ACCENT_FILL, GOLD.darkened(0.2), GOLD)

## Red button for what throws progress away.
static func warn_button(parent: Control, text: String, on_pressed: Callable) -> Button:
	return _styled_button(parent, text, on_pressed, WARN_FILL, WARN.darkened(0.3), WARN)

## A dark panel under `parent` that holds tiles; returns the column to add them to.
static func group(parent: Control) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _padded(tile_style(PANEL_FILL, GOLD.darkened(0.4), 3, 14), PANEL_MARGIN, PANEL_MARGIN))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", TILE_GAP)
	panel.add_child(box)
	return box

## Small muted wrapped line for hints and status.
static func hint(text: String) -> Label:
	var result := label(text, HINT_FONT_SIZE)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_color_override("font_color", MUTED)
	return result

static func tile_style(fill: Color, border: Color, width := 2, radius := TILE_RADIUS) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style

## Gold track and a round gold grabber, so the slider matches the tiles.
static func slider(value: float) -> HSlider:
	var result := HSlider.new()
	result.min_value = 0.0
	result.max_value = 1.0
	result.step = 0.05
	result.value = value
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	result.add_theme_stylebox_override("slider", _track(Color(0.05, 0.04, 0.06), 2))
	result.add_theme_stylebox_override("grabber_area", _track(GOLD.darkened(0.45), 0))
	result.add_theme_stylebox_override("grabber_area_highlight", _track(GOLD.darkened(0.2), 0))
	result.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	result.add_theme_icon_override("grabber", _grabber(GOLD.darkened(0.1)))
	result.add_theme_icon_override("grabber_highlight", _grabber(GOLD.lightened(0.2)))
	return result

## The dropdown is its own popup window, outside the panel theme, so it is styled here too.
static func option(items: Array[String], selected: int) -> OptionButton:
	var result := OptionButton.new()
	for item in items:
		result.add_item(item)
	result.select(selected)
	result.add_theme_font_size_override("font_size", TILE_FONT_SIZE)
	_style_states(result, PANEL_FILL, GOLD.darkened(0.25))
	var popup := result.get_popup()
	popup.add_theme_font_size_override("font_size", TILE_FONT_SIZE)
	popup.add_theme_constant_override("v_separation", 12)
	popup.add_theme_color_override("font_hover_color", GOLD)
	popup.add_theme_stylebox_override("panel", _padded(tile_style(PANEL_FILL, GOLD.darkened(0.25)), 8.0, 8.0))
	popup.add_theme_stylebox_override("hover", tile_style(ACCENT_FILL, GOLD.darkened(0.4), 2, 8))
	return result

static func _styled_button(parent: Control, text: String, on_pressed: Callable, fill: Color, edge: Color, ink: Color) -> Button:
	var result := button(parent, text, on_pressed)
	result.custom_minimum_size.y = TILE_BUTTON_HEIGHT
	result.add_theme_font_size_override("font_size", TILE_FONT_SIZE)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		result.add_theme_color_override(state, ink)
	_style_states(result, fill, edge)
	return result

## Normal, hover and pressed looks of a button-like control from one fill and edge.
static func _style_states(control: Control, fill: Color, edge: Color) -> void:
	for state in ["normal", "disabled"]:
		control.add_theme_stylebox_override(state, tile_style(fill, edge))
	control.add_theme_stylebox_override("hover", tile_style(fill.lightened(0.12), edge.lightened(0.25)))
	control.add_theme_stylebox_override("pressed", tile_style(fill.lightened(0.2), edge.lightened(0.5), 3))
	control.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

static func _padded(style: StyleBoxFlat, horizontal: float, vertical: float) -> StyleBoxFlat:
	style.content_margin_left = horizontal
	style.content_margin_right = horizontal
	style.content_margin_top = vertical
	style.content_margin_bottom = vertical
	return style

## A rounded slider bar; its content margins give the bar its thickness.
static func _track(fill: Color, border_width: int) -> StyleBoxFlat:
	var style := tile_style(fill, GOLD.darkened(0.6), border_width, int(TRACK_HALF_HEIGHT))
	style.content_margin_top = TRACK_HALF_HEIGHT
	style.content_margin_bottom = TRACK_HALF_HEIGHT
	return style

## A flat disc: a radial gradient that is solid out to 80% of the radius and then fades fast.
static func _grabber(color: Color) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(color, 0.0))
	gradient.add_point(0.78, color)
	gradient.add_point(0.82, Color(color, 0.0))
	var result := GradientTexture2D.new()
	result.gradient = gradient
	result.fill = GradientTexture2D.FILL_RADIAL
	result.fill_from = Vector2(0.5, 0.5)
	result.fill_to = Vector2(1.0, 0.5)
	result.width = GRABBER_SIZE
	result.height = GRABBER_SIZE
	return result

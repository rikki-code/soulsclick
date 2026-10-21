## Post-fight reward choice over the battle/road: dimmed screen, title, one big tappable card per offered reward.
class_name RewardOverlay
extends Control

signal card_picked(index: int)

const DIM_COLOR := Color(0.0, 0.0, 0.0, 0.6)
const CARD_COLOR := Color(0.11, 0.09, 0.13)
const CARD_HOVER_COLOR := Color(0.18, 0.14, 0.2)
const CARD_BORDER := Color(0.45, 0.36, 0.22)
const TITLE_SIZE := 48
const TAG_SIZE := 18
const NAME_SIZE := 30
const INFO_SIZE := 22
const ICON_SIZE := 120.0
const ICON_INNER := 88.0
const GLYPH_SIZE := 64
const CARD_WIDTH := 260.0
const CARD_HEIGHT := 340.0
const CARD_SEPARATION := 20
const CARD_PADDING := 14
const TITLE_GAP := 32
const GRADIENT_TOP := Color(1, 1, 1, 0.07)
const GRADIENT_BOTTOM := Color(0, 0, 0, 0.35)
const HOVER_SCALE := 1.05
const HOVER_SECONDS := 0.1
const MARGIN := 48
const FADE_SECONDS := 0.2
const MUTED := Color(0.75, 0.72, 0.68)
const TAG_COLORS := {
	&"relic": Color(0.85, 0.65, 0.95),
	&"stat_level": Color(0.95, 0.6, 0.4),
	&"consumable": Color(0.55, 0.85, 0.6),
	&"souls": Color(0.55, 0.8, 1.0),
	&"heal": Color(0.95, 0.45, 0.5),
}
const GLYPHS := {
	&"relic": "*",
	&"stat_level": "^",
	&"consumable": "+",
	&"souls": "o",
	&"heal": "+",
}
const TAG_DEFAULT_COLOR := Color(0.9, 0.8, 0.5)

var _offer: RewardOffer
var _picked := false
var _row: HBoxContainer

func setup(offer: RewardOffer) -> RewardOverlay:
	_offer = offer
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = DIM_COLOR
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", TITLE_GAP)
	box.custom_minimum_size.x = 1080 - 2 * MARGIN
	center.add_child(box)
	var title := MenuKit.label(tr("REWARD_TITLE"), TITLE_SIZE)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", CARD_SEPARATION)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	_row = row
	var count := maxi(offer.cards.size(), 1)
	var width := floorf((1080.0 - 2 * MARGIN - CARD_SEPARATION * (count - 1)) / count)
	for i in offer.cards.size():
		row.add_child(_make_card(offer.cards[i], i, minf(width, CARD_WIDTH)))
	return self

## Wrapped texts only know their height once laid out: grow every card to the tallest content so nothing spills out.
func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if _row == null:
		return
	var tallest := CARD_HEIGHT
	for card: Control in _row.get_children():
		var column: Control = card.get_child(card.get_child_count() - 1)
		tallest = maxf(tallest, column.get_combined_minimum_size().y + 2.0 * CARD_PADDING)
	for card: Control in _row.get_children():
		card.custom_minimum_size.y = tallest

func _make_card(card: RewardCard, index: int, width: float) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(width, CARD_HEIGHT)
	var tag_color: Color = TAG_COLORS.get(card.kind_id, TAG_DEFAULT_COLOR)
	var border := CARD_BORDER.lerp(tag_color, 0.55)
	button.add_theme_stylebox_override("normal", _style(CARD_COLOR, border))
	button.add_theme_stylebox_override("hover", _style(CARD_HOVER_COLOR, tag_color))
	button.add_theme_stylebox_override("pressed", _style(CARD_HOVER_COLOR, tag_color))
	button.add_theme_stylebox_override("focus", _style(CARD_HOVER_COLOR, tag_color))
	button.pressed.connect(_pick.bind(index))
	button.resized.connect(func() -> void: button.pivot_offset = button.size / 2.0)
	button.mouse_entered.connect(_lift.bind(button, HOVER_SCALE))
	button.mouse_exited.connect(_lift.bind(button, 1.0))
	button.button_down.connect(_lift.bind(button, HOVER_SCALE))
	button.add_child(_make_shade())
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, CARD_PADDING)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 8)
	button.add_child(column)
	column.add_child(_make_art(card, tag_color))
	_add_text(column, tr(card.tag_key), TAG_SIZE, tag_color)
	_add_text(column, card.title(), NAME_SIZE, Color.WHITE)
	_add_text(column, card.info(), INFO_SIZE, MUTED)
	return button

func _make_shade() -> Control:
	var gradient := Gradient.new()
	gradient.set_color(0, GRADIENT_TOP)
	gradient.set_color(1, GRADIENT_BOTTOM)
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	var shade := TextureRect.new()
	shade.texture = tex
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return shade

func _make_art(card: RewardCard, tag_color: Color) -> Control:
	var frame := Panel.new()
	frame.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.05, 0.9)
	style.border_color = Color(tag_color, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(int(ICON_SIZE / 2.0))
	frame.add_theme_stylebox_override("panel", style)
	var art: Control
	if card.icon_path != "" and ResourceLoader.exists(card.icon_path):
		var icon := TextureRect.new()
		icon.texture = load(card.icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art = icon
	else:
		var glyph := MenuKit.label(GLYPHS.get(card.kind_id, "?"), GLYPH_SIZE)
		glyph.add_theme_color_override("font_color", tag_color)
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		art = glyph
	var inset := (ICON_SIZE - ICON_INNER) / 2.0
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, int(inset))
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(art)
	return frame

func _lift(button: Button, target: float) -> void:
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2(target, target), HOVER_SECONDS)

func _add_text(parent: Control, text: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

func _style(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	return style

func _pick(index: int) -> void:
	if _picked:
		return
	_picked = true
	card_picked.emit(index)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
	tween.tween_callback(queue_free)

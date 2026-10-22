## Light, childish tutorial layer: a cream speech bubble with a Skip pill and a big "Great!" praise pop. Pure view: text arrives
## already translated, the game layer decides when to show what. Only the bubble and the Skip button take mouse input.
class_name HintBubble
extends Control

signal skip_pressed

const CREAM := Color("#fff8e6")
const ORANGE := Color("#f2a33a")
const BROWN := Color("#4a3322")
const SKIP_STATES := {"normal": Color("#8fc9f0"), "hover": Color("#a8d6f4"), "pressed": Color("#6fb4e3")}
const GOLD := Color("#ffc83d")
const BORDER_WIDTH := 4
const CORNER_RADIUS := 36
const PILL_RADIUS := 60
const BUBBLE_MARGIN := 28
const FONT_SIZE := 40
const SKIP_FONT_SIZE := 30
const SKIP_HEIGHT := 72.0
const SKIP_PAD := 40
const SKIP_TOP_FRACTION := 0.1
const SKIP_LEFT_FRACTION := 0.24
const PRAISE_SIZE := 120
const PRAISE_OUTLINE := 16
const TOP_FRACTION := 0.18
## Right strip kept free for the item-slot column (up to two columns of slots), so the bubble never covers a slot.
const SLOT_RESERVE := 380.0
const SIDE_MARGIN := 20.0
const WIDTHS: Array[float] = [0.5, 0.86]  # landscape, portrait
const POP_SECONDS := 0.25
const HIDE_SECONDS := 0.2
const POP_SCALE := 0.8
const PRAISE_SECONDS := 0.9
const PRAISE_SCALES: Array[float] = [0.4, 1.2]  # start, peak

var _bubble := Panel.new()
var _label := Label.new()
var _skip := Button.new()
var _tween: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.hide()
	_bubble.add_theme_stylebox_override("panel", _box(CREAM, ORANGE, CORNER_RADIUS, BORDER_WIDTH, BUBBLE_MARGIN))
	_bubble.resized.connect(func() -> void: _bubble.pivot_offset = _bubble.size * 0.5)
	add_child(_bubble)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_color", BROWN)
	_bubble.add_child(_label)
	_skip.text = tr("TUT_SKIP")
	_skip.custom_minimum_size.y = SKIP_HEIGHT
	_skip.add_theme_font_size_override("font_size", SKIP_FONT_SIZE)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_skip.add_theme_color_override(color_name, BROWN)
	for state in SKIP_STATES:
		_skip.add_theme_stylebox_override(state, _box(SKIP_STATES[state], SKIP_STATES[state], PILL_RADIUS, 0, SKIP_PAD))
	_skip.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_skip.pressed.connect(skip_pressed.emit)
	add_child(_skip)
	resized.connect(_place_skip)
	_place_skip()

func show_hint(text: String) -> void:
	var view := get_viewport_rect().size
	var free := view.x - SLOT_RESERVE - SIDE_MARGIN * 2.0
	var width := minf(view.x * WIDTHS[int(view.y > view.x)], free)
	# Sized by hand (Panel, not a container): an autowrapped Label reports a tall minimum height until its width is
	# known, and a container would grow to it and never shrink back.
	var wrap_width := width - BUBBLE_MARGIN * 2.0
	var text_height := _label.get_theme_font("font").get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, wrap_width, FONT_SIZE).y
	_label.text = text
	_label.position = Vector2.ONE * BUBBLE_MARGIN
	_label.size = Vector2(wrap_width, text_height)
	_bubble.size = Vector2(width, text_height + BUBBLE_MARGIN * 2.0)
	_bubble.position = Vector2(SIDE_MARGIN + (free - width) * 0.5, view.y * TOP_FRACTION)
	_bubble.modulate.a = 0.0
	_bubble.scale = Vector2.ONE * POP_SCALE
	_bubble.show()
	_restart_tween().set_parallel(true).tween_property(_bubble, "modulate:a", 1.0, POP_SECONDS)
	_tween.tween_property(_bubble, "scale", Vector2.ONE, POP_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_hint() -> void:
	_restart_tween().tween_property(_bubble, "modulate:a", 0.0, HIDE_SECONDS)
	_tween.tween_callback(_bubble.hide)

## The Skip pill stays in the top row, right of the souls counter, whether or not a bubble is up.
func _place_skip() -> void:
	_skip.position = Vector2(size.x * SKIP_LEFT_FRACTION, size.y * SKIP_TOP_FRACTION)

func set_skippable(enabled: bool) -> void:
	_skip.visible = enabled

## Big gold text in the middle of the screen: pops, fades out, frees itself.
func flash_praise(text: String) -> void:
	var view := get_viewport_rect().size
	var praise := Label.new()
	praise.text = text
	praise.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	praise.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	praise.add_theme_font_size_override("font_size", PRAISE_SIZE)
	praise.add_theme_color_override("font_color", GOLD)
	praise.add_theme_color_override("font_outline_color", BROWN)
	praise.add_theme_constant_override("outline_size", PRAISE_OUTLINE)
	praise.size = view
	praise.pivot_offset = view * 0.5
	praise.scale = Vector2.ONE * PRAISE_SCALES[0]
	add_child(praise)
	var tween := praise.create_tween().set_parallel(true)
	tween.tween_property(praise, "scale", Vector2.ONE * PRAISE_SCALES[1], PRAISE_SECONDS * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(praise, "modulate:a", 0.0, PRAISE_SECONDS * 0.5).set_delay(PRAISE_SECONDS * 0.5)
	tween.chain().tween_callback(praise.queue_free)

func _restart_tween() -> Tween:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	return _tween

func _box(fill: Color, border: Color, radius: int, border_width: int, margin: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(margin)
	box.anti_aliasing = true
	return box

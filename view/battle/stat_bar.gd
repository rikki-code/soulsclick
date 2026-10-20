## Flat horizontal bar drawn in code: smoothly draining fill, a lagging "ghost" segment on loss, optional caption and "value / max" text.
class_name StatBar
extends Control

const BACK_COLOR := Color(0.03, 0.03, 0.04, 0.85)
const BORDER_COLOR := Color(0.45, 0.48, 0.55, 0.8)
const GHOST_COLOR := Color(1.0, 1.0, 1.0, 0.55)
const GHOST_DELAY := 0.25
const GHOST_SECONDS := 0.35
const FLASH_SECONDS := 0.25
const FONT_SIZE := 24
const CAPTION_FONT_SIZE := 20
const CAPTION_COLOR := Color(1, 1, 1, 0.7)
const CAPTION_PAD := 10.0
const FILL_SECONDS := 0.15

var fill_color := Color(0.8, 0.2, 0.2)
var show_text := true
var ghost_color := GHOST_COLOR
## Short label drawn at the left edge ("HP"); empty = none.
var caption := "":
	set(value):
		caption = value
		queue_redraw()
var _ratio := 1.0
var _target := 1.0
var _ghost := 1.0
var _value := 0.0
var _max := 1.0
var _flash := 0.0
var _ghost_tween: Tween
var _fill_tween: Tween
var _flash_tween: Tween

func configure(color: Color, text := true) -> void:
	fill_color = color
	show_text = text
	queue_redraw()

func set_values(value: float, max_value: float, animate := true) -> void:
	_value = value
	_max = maxf(max_value, 0.001)
	var target := clampf(value / _max, 0.0, 1.0)
	var lost := target < _target
	_target = target
	for tween in [_ghost_tween, _fill_tween]:
		if tween != null and tween.is_valid():
			tween.kill()
	if not animate:
		_ratio = target
		_ghost = target
		queue_redraw()
		return
	_fill_tween = create_tween()
	_fill_tween.tween_method(_set_ratio, _ratio, target, FILL_SECONDS)
	_ghost_tween = create_tween()
	if lost:
		_ghost_tween.tween_interval(GHOST_DELAY)
	_ghost_tween.tween_method(_set_ghost, maxf(_ghost, target) if lost else _ghost, target, GHOST_SECONDS if lost else FILL_SECONDS)
	queue_redraw()

func flash_warning() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_method(_set_flash, 1.0, 0.0, FLASH_SECONDS)

func _set_ratio(value: float) -> void:
	_ratio = value
	queue_redraw()

func _set_ghost(value: float) -> void:
	_ghost = value
	queue_redraw()

func _set_flash(value: float) -> void:
	_flash = value
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, BACK_COLOR)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * _ghost, size.y)), ghost_color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * _ratio, size.y)), fill_color.lerp(Color.WHITE, _flash))
	draw_rect(rect, BORDER_COLOR, false, 2.0)
	var font := get_theme_default_font()
	if caption != "":
		var caption_base := (size.y + font.get_ascent(CAPTION_FONT_SIZE) - font.get_descent(CAPTION_FONT_SIZE)) * 0.5
		draw_string(font, Vector2(CAPTION_PAD, caption_base), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_FONT_SIZE, CAPTION_COLOR)
	if not show_text:
		return
	var text := "%d / %d" % [ceili(_value), ceili(_max)]
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, FONT_SIZE).x
	var baseline := (size.y + font.get_ascent(FONT_SIZE) - font.get_descent(FONT_SIZE)) * 0.5
	draw_string(font, Vector2((size.x - width) * 0.5, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)

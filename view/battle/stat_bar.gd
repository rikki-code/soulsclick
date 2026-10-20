## Flat horizontal bar drawn in code: fill, a trailing "ghost" segment on loss, optional "value / max" text.
class_name StatBar
extends Control

const BACK_COLOR := Color(0.03, 0.03, 0.04, 0.85)
const BORDER_COLOR := Color(0.45, 0.48, 0.55, 0.8)
const GHOST_COLOR := Color(1.0, 1.0, 1.0, 0.55)
const GHOST_DELAY := 0.25
const GHOST_SECONDS := 0.35
const FLASH_SECONDS := 0.25
const FONT_SIZE := 24

var fill_color := Color(0.8, 0.2, 0.2)
var show_text := true
var _ratio := 1.0
var _ghost := 1.0
var _value := 0.0
var _max := 1.0
var _flash := 0.0
var _ghost_tween: Tween
var _flash_tween: Tween

func configure(color: Color, text := true) -> void:
	fill_color = color
	show_text = text
	queue_redraw()

func set_values(value: float, max_value: float, animate := true) -> void:
	_value = value
	_max = maxf(max_value, 0.001)
	var target := clampf(value / _max, 0.0, 1.0)
	var lost := target < _ratio
	_ratio = target
	if _ghost_tween != null and _ghost_tween.is_valid():
		_ghost_tween.kill()
	if lost and animate:
		_ghost_tween = create_tween()
		_ghost_tween.tween_interval(GHOST_DELAY)
		_ghost_tween.tween_method(_set_ghost, _ghost, _ratio, GHOST_SECONDS)
	else:
		_ghost = _ratio
	queue_redraw()

func flash_warning() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_method(_set_flash, 1.0, 0.0, FLASH_SECONDS)

func _set_ghost(value: float) -> void:
	_ghost = value
	queue_redraw()

func _set_flash(value: float) -> void:
	_flash = value
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, BACK_COLOR)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * _ghost, size.y)), GHOST_COLOR)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * _ratio, size.y)), fill_color.lerp(Color.WHITE, _flash))
	draw_rect(rect, BORDER_COLOR, false, 2.0)
	if not show_text:
		return
	var font := get_theme_default_font()
	var text := "%d / %d" % [ceili(_value), ceili(_max)]
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, FONT_SIZE).x
	var baseline := (size.y + font.get_ascent(FONT_SIZE) - font.get_descent(FONT_SIZE)) * 0.5
	draw_string(font, Vector2((size.x - width) * 0.5, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)

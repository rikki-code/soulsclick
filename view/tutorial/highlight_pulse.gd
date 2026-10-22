## Pulsing rounded ring drawn around a screen-space rect to point at a tutorial target. Pure view: it only draws while a target is set.
class_name HighlightPulse
extends Node2D

const RING_COLOR := Color("#ffd24a")
const PERIOD := 1.2
const WIDTH_MIN := 4.0
const WIDTH_MAX := 10.0
const ALPHA_MIN := 0.45
const ALPHA_MAX := 1.0
const CORNER_RADIUS := 24
const PADDING := 8.0
const DRAW_Z := 90

var _rect := Rect2()
var _time := 0.0
var _style := StyleBoxFlat.new()

func _ready() -> void:
	z_index = DRAW_Z
	_style.draw_center = false
	_style.set_corner_radius_all(CORNER_RADIUS)
	_style.anti_aliasing = true
	visible = false
	set_process(false)

## Shows the ring around `rect` (screen coordinates) and starts pulsing.
func target(rect: Rect2) -> void:
	_rect = rect
	_time = 0.0
	visible = true
	set_process(true)
	queue_redraw()

## Hides the ring and stops redrawing.
func clear() -> void:
	visible = false
	set_process(false)

func _process(delta: float) -> void:
	_time = fmod(_time + delta, PERIOD)
	queue_redraw()

func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(TAU * _time / PERIOD)
	var width := lerpf(WIDTH_MIN, WIDTH_MAX, pulse)
	_style.set_border_width_all(roundi(width))
	_style.border_color = Color(RING_COLOR, lerpf(ALPHA_MIN, ALPHA_MAX, pulse))
	draw_style_box(_style, _rect.grow(PADDING + width))

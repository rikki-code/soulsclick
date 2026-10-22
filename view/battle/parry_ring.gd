## Readable parry timing: a ring closes onto a target ring around the enemy's weapon and meets it exactly at the strike
## moment. The last `window` seconds before the strike are the parry window: the band between the target ring and
## the radius the approach ring has when the window opens is drawn dim, and lights up once the window is open.
class_name ParryRing
extends Node2D

signal window_opened

const TARGET_RADIUS := 64.0
const START_SCALE := 3.4
const LINE_WIDTH := 7.0
const TARGET_WIDTH := 5.0
const SEGMENTS := 96
const BAND_ALPHA := 0.22
const BAND_LIT_ALPHA := 0.55
const FADE_SECONDS := 0.18
const OPEN_PULSE := 0.5
const OPEN_PULSE_SECONDS := 0.16

var color := Color.WHITE
var anchor := Callable()
var radius_scale := 1.0
var _strike_in := 0.0
var _window := 0.0
var _elapsed := 0.0
var _active := false
var _opened := false
var _pulse := 0.0
var _fade := 0.0

func _ready() -> void:
	visible = false
	z_index = 50

## Seconds from now until the strike, and the length of the parry window that ends at the strike.
func start(strike_in: float, window: float, p_color: Color) -> void:
	_strike_in = maxf(strike_in, 0.001)
	_window = clampf(window, 0.0, _strike_in)
	color = p_color
	_elapsed = 0.0
	_opened = false
	_pulse = 0.0
	_fade = 0.0
	_active = true
	visible = true
	_follow()
	queue_redraw()

func stop() -> void:
	_active = false
	_fade = FADE_SECONDS if visible else 0.0
	if _fade <= 0.0:
		visible = false

func is_active() -> bool:
	return _active

func is_window_open() -> bool:
	return _active and is_window_open_at(_elapsed, _strike_in, _window)

## Share of the approach travelled at `elapsed`: 0 at the start, 1 at the strike.
static func progress_at(elapsed: float, strike_in: float) -> float:
	return clampf(elapsed / maxf(strike_in, 0.001), 0.0, 1.0)

## Approach ring radius: `start_radius` at 0 s, `target_radius` at the strike.
static func radius_at(elapsed: float, strike_in: float, start_radius: float, target_radius: float) -> float:
	return lerpf(start_radius, target_radius, progress_at(elapsed, strike_in))

## When (seconds after the start) the window opens.
static func window_open_time(strike_in: float, window: float) -> float:
	return maxf(strike_in - window, 0.0)

static func is_window_open_at(elapsed: float, strike_in: float, window: float) -> bool:
	return elapsed >= window_open_time(strike_in, window)

func _process(delta: float) -> void:
	if _pulse > 0.0:
		_pulse = maxf(_pulse - delta / OPEN_PULSE_SECONDS, 0.0)
	if not _active:
		if _fade > 0.0:
			_fade -= delta
			_follow()
			visible = _fade > 0.0
			queue_redraw()
		return
	_elapsed += delta
	_follow()
	if not _opened and is_window_open_at(_elapsed, _strike_in, _window):
		_opened = true
		_pulse = 1.0
		window_opened.emit()
	queue_redraw()

func _follow() -> void:
	if anchor.is_valid():
		position = anchor.call()

func _draw() -> void:
	var target := TARGET_RADIUS * radius_scale
	var start := target * START_SCALE
	var open_radius := radius_at(window_open_time(_strike_in, _window), _strike_in, start, target)
	var alpha := 1.0 if _active else clampf(_fade / FADE_SECONDS, 0.0, 1.0)
	var open := _opened and _active
	var band := Color(color, (BAND_LIT_ALPHA if open else BAND_ALPHA) * alpha)
	var mid := (target + open_radius) * 0.5
	if _window > 0.0:
		_stroke(mid, open_radius - target, band)
	var target_color := Color(Color.WHITE.lerp(color, 0.35), alpha) if open else Color(color, 0.8 * alpha)
	_stroke(target + _pulse * target * OPEN_PULSE * 0.5, TARGET_WIDTH * (1.0 + _pulse), target_color)
	if _active:
		var radius := radius_at(_elapsed, _strike_in, start, target)
		_stroke(radius, LINE_WIDTH, Color(color.lightened(0.25), 0.95))

## A closed ring of `width` around `radius` as one triangle strip. (draw_arc over a full circle leaves a notch where
## the polyline starts and ends, which shows on wide strokes.)
func _stroke(radius: float, width: float, stroke_color: Color) -> void:
	var half := width * 0.5
	var points := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in SEGMENTS:
		var direction := Vector2.from_angle(TAU * i / SEGMENTS)
		points.append(direction * (radius + half))
		points.append(direction * maxf(radius - half, 0.0))
		var next := (i + 1) % SEGMENTS * 2
		indices.append_array([i * 2, i * 2 + 1, next, i * 2 + 1, next + 1, next])
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), indices, points, PackedColorArray([stroke_color]))

## A chunky arrow with a small label, pointing at an input control. Bobs in place, or slides along its direction
## when the cue is a swipe. Pure view: it only draws while a cue is set.
class_name ArrowHint
extends Node2D

const FILL := Color("#f2a33a")
const OUTLINE := Color("#4a3322")
const PILL_FILL := Color("#fff8e6")
const OUTLINE_WIDTH := 4.0
## Arrow outline pointing along +x, tip at the origin.
const ARROW_POINTS: Array[Vector2] = [Vector2(0, 0), Vector2(-44, -38), Vector2(-44, -15), Vector2(-120, -15),
	Vector2(-120, 15), Vector2(-44, 15), Vector2(-44, 38)]
const ARROW_LENGTH := 120.0
const BOB := 18.0
const BOB_SECONDS := 0.45
const TRAVEL := 150.0
const TRAVEL_SECONDS := 0.9
const FADE_SECONDS := 0.2
const FONT_SIZE := 30
const PILL_RADIUS := 30
const PILL_PADDING := 20
const PILL_GAP := 12.0
const SCREEN_MARGIN := 12.0
const DRAW_Z := 95

var _arrow := Node2D.new()
var _pill := PanelContainer.new()
var _label := Label.new()
var _tween: Tween

func _ready() -> void:
	z_index = DRAW_Z
	_arrow.draw.connect(_draw_arrow)
	add_child(_arrow)
	var style := StyleBoxFlat.new()
	style.bg_color = PILL_FILL
	style.border_color = OUTLINE
	style.set_border_width_all(roundi(OUTLINE_WIDTH))
	style.set_corner_radius_all(PILL_RADIUS)
	style.set_content_margin_all(PILL_PADDING)
	_pill.add_theme_stylebox_override("panel", style)
	_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_color", OUTLINE)
	_pill.add_child(_label)
	add_child(_pill)
	visible = false

## Shows the arrow for `cue` with the already-translated `text`.
func show_cue(cue: TutorialCue, text: String) -> void:
	_label.text = text
	_pill.reset_size()
	_arrow.rotation = cue.dir.angle()
	_arrow.position = cue.anchor
	_arrow.modulate.a = 1.0
	_place_pill(cue)
	visible = true
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_loops()
	if cue.travel:
		_tween.tween_property(_arrow, "position", cue.anchor + cue.dir * TRAVEL, TRAVEL_SECONDS)
		_tween.parallel().tween_property(_arrow, "modulate:a", 0.0, FADE_SECONDS).set_delay(TRAVEL_SECONDS - FADE_SECONDS)
		_tween.tween_callback(func() -> void:
			_arrow.position = cue.anchor
			_arrow.modulate.a = 1.0)
		return
	_tween.tween_property(_arrow, "position", cue.anchor - cue.dir * BOB, BOB_SECONDS).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_arrow, "position", cue.anchor, BOB_SECONDS).set_trans(Tween.TRANS_SINE)

func clear() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	visible = false

## The label sits behind the arrow's tail, kept inside the screen.
func _place_pill(cue: TutorialCue) -> void:
	var size := _pill.get_combined_minimum_size()
	var tail := cue.anchor - cue.dir * (ARROW_LENGTH + PILL_GAP)
	var center := tail - cue.dir * (absf(cue.dir.x) * size.x * 0.5 + absf(cue.dir.y) * size.y * 0.5)
	var view := get_viewport_rect().size
	var top_left := center - size * 0.5
	top_left.x = clampf(top_left.x, SCREEN_MARGIN, maxf(view.x - size.x - SCREEN_MARGIN, SCREEN_MARGIN))
	top_left.y = clampf(top_left.y, SCREEN_MARGIN, maxf(view.y - size.y - SCREEN_MARGIN, SCREEN_MARGIN))
	_pill.position = top_left

func _draw_arrow() -> void:
	var points := PackedVector2Array(ARROW_POINTS)
	_arrow.draw_colored_polygon(points, FILL)
	points.append(points[0])
	_arrow.draw_polyline(points, OUTLINE, OUTLINE_WIDTH, true)

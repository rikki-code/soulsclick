## The realm as a vertical trail: walked rooms at the bottom, the current step branching into door nodes, faint "?" steps and the boss on top.
class_name PathView
extends Control

signal door_picked(index: int)

const MAP_HEIGHT := 760.0
const MARGIN := 70.0
const WALKED_RADIUS := 15.0
const DOOR_RADIUS := 38.0
const FUTURE_RADIUS := 17.0
const TAP_RADIUS := 52.0
const LINE_COLOR := Color(0.6, 0.57, 0.52)
const FAINT := Color(0.45, 0.43, 0.4, 0.45)
const KIND_COLORS := {
	&"fight": Color(0.58, 0.58, 0.6),
	&"elite": Color(0.85, 0.2, 0.18),
	&"altar": Color(0.95, 0.78, 0.25),
	&"bonfire": Color(0.95, 0.5, 0.15),
	&"boss": Color(0.7, 0.07, 0.2),
	&"shop": Color(0.3, 0.7, 0.65),
}

var _step_count := 0
var _step := 0
var _doors: Array[Door] = []
var _walked: Array[Dictionary] = []
var _grow := 0.0

func setup(run: Run) -> PathView:
	_step_count = run.offer.step_count
	_step = run.offer.step_index
	_doors = run.offer.doors
	for record in run.history:
		if int(record.get("depth", 0)) == run.depth:
			_walked.append(record)
	custom_minimum_size = Vector2(MenuKit.PAGE_WIDTH, MAP_HEIGHT)
	return self

func _ready() -> void:
	create_tween().tween_method(_set_grow, 0.0, 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _set_grow(value: float) -> void:
	_grow = value
	queue_redraw()

static func kind_color(kind_id: StringName) -> Color:
	return KIND_COLORS.get(kind_id, Color(0.6, 0.6, 0.6))

func _row_y(row: int) -> float:
	var span := size.y - MARGIN * 2.0
	return size.y - MARGIN - span * float(row + 1) / float(maxi(_step_count, 1))

func _start_pos() -> Vector2:
	return Vector2(size.x * 0.5, size.y - MARGIN)

func _lane_x(index: int, count: int) -> float:
	return size.x * (0.5 + (float(index) - float(count - 1) * 0.5) * 0.3)

func _door_pos(index: int) -> Vector2:
	return Vector2(_lane_x(index, _doors.size()), _row_y(_step))

func _walked_pos(record: Dictionary) -> Vector2:
	return Vector2(_lane_x(clampi(int(record.get("door", 1)), 0, 2), 3), _row_y(int(record.get("step", 0))))

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	for i in _doors.size():
		if _door_pos(i).distance_to(event.position) <= TAP_RADIUS:
			accept_event()
			door_picked.emit(i)
			return

func _draw() -> void:
	if _step_count <= 0:
		return
	var font := ThemeDB.fallback_font
	# Future steps up to the boss, faint.
	var boss_row := _step_count - 1
	var prev := _door_pos(0).lerp(_door_pos(_doors.size() - 1), 0.5) if not _doors.is_empty() else _start_pos()
	for row in range(_step + 1, boss_row):
		var pos := Vector2(size.x * 0.5, _row_y(row))
		draw_dashed_line(prev, pos, FAINT, 3.0, 10.0)
		_node(font, pos, FUTURE_RADIUS, FAINT, "?", 0.5)
		prev = pos
	if _step < boss_row:
		var boss_pos := Vector2(size.x * 0.5, _row_y(boss_row))
		draw_dashed_line(prev, boss_pos, FAINT, 3.0, 10.0)
		_node(font, boss_pos, DOOR_RADIUS, kind_color(&"boss"), RunScreen.kind_name(&"boss").substr(0, 1), 1.0, false)
	# Walked trail.
	var last := _start_pos()
	draw_circle(last, 8.0, LINE_COLOR)
	for record in _walked:
		var pos := _walked_pos(record)
		draw_line(last, pos, LINE_COLOR, 4.0, true)
		last = pos
	for record in _walked:
		var kind := StringName(record.get("kind", &"fight"))
		_node(font, _walked_pos(record), WALKED_RADIUS, kind_color(kind), RunScreen.kind_name(kind).substr(0, 1), 1.0)
	# Branches into the doors.
	for i in _doors.size():
		draw_line(last, last.lerp(_door_pos(i), _grow), LINE_COLOR, 5.0, true)
	for i in _doors.size():
		var end := last.lerp(_door_pos(i), _grow)
		if _grow > 0.0:
			var kind := _doors[i].kind_id
			_node(font, end, DOOR_RADIUS * _grow, kind_color(kind), RunScreen.kind_name(kind).substr(0, 1), _grow, false)

func _node(font: Font, pos: Vector2, radius: float, color: Color, glyph: String, alpha: float, filled := true) -> void:
	var fill := Color(color, alpha)
	draw_circle(pos, radius, Color(0.08, 0.07, 0.09))
	draw_circle(pos, radius, fill if filled else Color(color, 0.35 * alpha))
	if not filled:
		draw_arc(pos, radius, 0.0, TAU, 40, fill, 4.0, true)
	var font_size := int(radius * 1.1)
	if font_size < 10:
		return
	var width := font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, pos + Vector2(-width * 0.5, font_size * 0.35), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1, alpha))

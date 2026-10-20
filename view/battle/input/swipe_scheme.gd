## Swipe up = attack, swipe down = block. Fires as soon as a finger has travelled the threshold (not on release);
## one action per touch.
class_name SwipeScheme
extends InputScheme

const THRESHOLD := 40.0
const ZONE_SHARE := 0.2
const HINT_ALPHA := 0.32
const HINT_FONT := 40
const ARROW_HALF := 34.0
const ARROW_HEIGHT := 46.0
const ZONE_PAD := 14.0
const LABEL_GAP := 4.0
const LABEL_HEIGHT := 48.0

var _starts: Dictionary = {}
var _fired: Dictionary = {}
var _attack_label := _make_label(tr("BATTLE_ATTACK"))
var _block_label := _make_label(tr("BATTLE_BLOCK"))

func _init() -> void:
	add_child(_attack_label)
	add_child(_block_label)

func reserved_height(view_size: Vector2) -> float:
	return view_size.y * ZONE_SHARE

func _layout(view_size: Vector2) -> void:
	var up_y := _up_y(view_size)
	var down_y := _down_y(view_size)
	_attack_label.position = Vector2(0.0, up_y + ARROW_HEIGHT + LABEL_GAP)
	_attack_label.size = Vector2(view_size.x, LABEL_HEIGHT)
	_block_label.position = Vector2(0.0, down_y - ARROW_HEIGHT - LABEL_GAP - LABEL_HEIGHT)
	_block_label.size = Vector2(view_size.x, LABEL_HEIGHT)
	queue_redraw()

func _draw() -> void:
	var center_x := size.x * 0.5
	var up_y := _up_y(size)
	var down_y := _down_y(size)
	var color := Color(1, 1, 1, HINT_ALPHA)
	draw_colored_polygon(PackedVector2Array([Vector2(center_x - ARROW_HALF, up_y + ARROW_HEIGHT), Vector2(center_x + ARROW_HALF, up_y + ARROW_HEIGHT), Vector2(center_x, up_y)]), color)
	draw_colored_polygon(PackedVector2Array([Vector2(center_x - ARROW_HALF, down_y - ARROW_HEIGHT), Vector2(center_x + ARROW_HALF, down_y - ARROW_HEIGHT), Vector2(center_x, down_y)]), color)

static func _up_y(view_size: Vector2) -> float:
	return view_size.y * (1.0 - ZONE_SHARE) + ZONE_PAD

static func _down_y(view_size: Vector2) -> float:
	return view_size.y - ZONE_PAD

func _on_enabled_changed(_enabled: bool) -> void:
	_starts.clear()
	_fired.clear()

func _pointer_down(pointer: int, at: Vector2) -> void:
	_starts[pointer] = at
	_fired.erase(pointer)

func _pointer_moved(pointer: int, at: Vector2) -> void:
	if not _starts.has(pointer) or _fired.has(pointer):
		return
	var travel: Vector2 = at - _starts[pointer]
	if absf(travel.y) < THRESHOLD or absf(travel.y) <= absf(travel.x):
		return
	_fired[pointer] = true
	if travel.y < 0.0:
		attack_requested.emit()
	else:
		block_requested.emit()

func _pointer_up(pointer: int) -> void:
	_starts.erase(pointer)
	_fired.erase(pointer)

static func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.modulate = Color(1, 1, 1, HINT_ALPHA * 1.6)
	label.add_theme_font_size_override("font_size", HINT_FONT)
	return label

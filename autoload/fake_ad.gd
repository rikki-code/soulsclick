## Stand-in for a rewarded ad until a portal SDK is wired: a random enemy doing the "six seven" arm gesture (or the player's gauntlets) and a flashing "SIX / SEVEN". Frees itself.
class_name FakeAd
extends Control

signal finished

const SECONDS := 3.0
const HANDS_LIFT_SHARE := 0.1
const HANDS_SWING := 180.0
const ARM_SWING := 10.0
const FOREARM_FOLD := 70.0
const FOREARM_LIFT := 80.0
const WING_SWING := 25.0
const BOB := 0.9
const AMPLITUDE := 150.0

const RIG_INK_HEIGHT := 915.0
const RIG_FEET_Y := 975.0
const RIG_HEIGHT_SHARE := 0.5
const POSE_IDLE := &"idle"

## Dev hook: always show the player's hands.
static var force_hands := false
static var force_enemy := &""

var _time := 0.0
var _rig: EnemyRig
var _player: PlayerRig
var _show_hands := false
var _length := 0.1 if DisplayServer.get_name() == "headless" else SECONDS
var _done := false

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

## One of: every enemy with a rig (its arms do the gesture), or the player's two gauntlets.
func _ready() -> void:
	var ids := _enemy_ids()
	var pick := ids.size() if force_hands else randi() % (ids.size() + 1)
	if force_enemy != &"" and ids.has(force_enemy):
		pick = ids.find(force_enemy)
	if pick < ids.size():
		_rig = EnemyRig.new()
		add_child(_rig)
		_rig.setup(RigSpec.load_for(ids[pick], Color(0.9, 0.3, 0.2)))
		_rig.apply_pose(POSE_IDLE)
		return
	_show_hands = true
	_player = PlayerRig.new()
	add_child(_player)

static func _enemy_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for dir in DirAccess.get_directories_at(BattlePaths.ENEMY_PACK):
		if FileAccess.file_exists(BattlePaths.rig_json(StringName(dir))):
			ids.append(StringName(dir))
	return ids

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _time >= _length and not _done:
		_done = true
		finished.emit()
		queue_free()

func _draw() -> void:
	var view := size
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.22, 0.17, 0.34))
	var wave := sin(_time * TAU / BOB)
	var six_up := wave > 0.0
	var center := view * 0.5
	var scale_factor := minf(view.x / 1080.0, view.y / 1920.0) * 1.25
	if _rig != null:
		var rig_scale := view.y * RIG_HEIGHT_SHARE / RIG_INK_HEIGHT
		var feet := Vector2(view.x * 0.5, view.y * 0.84)
		_rig.position = feet - Vector2(512.0, RIG_FEET_Y) * rig_scale
		_rig.scale = Vector2.ONE * rig_scale
	if _rig != null:
		_gesture(wave)
	if _show_hands:
		_place_hands(wave)
	var font := ThemeDB.fallback_font
	var six_on := wave > 0.0
	var size_big := roundi(150.0 * scale_factor)
	var on := Color(1.0, 0.85, 0.2)
	var off := Color(0.45, 0.4, 0.55)
	_text(font, "SIX", center + Vector2(0.0, -view.y * 0.2), size_big, on if six_on else off)
	_text(font, "SEVEN", center + Vector2(0.0, -view.y * 0.2 + size_big * 1.15), size_big, off if six_on else on)
	var left := maxf(_length - _time, 0.0)
	_text(font, "AD  %.0f" % ceilf(left), Vector2(view.x * 0.5, view.y * 0.92), roundi(44.0 * scale_factor), Color(0.7, 0.7, 0.75))

func _text(font: Font, text: String, at: Vector2, font_size: int, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var base := at + Vector2(-width * 0.5, font_size * 0.35)
	draw_string_outline(font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 12, Color.BLACK)
	draw_string(font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

## The enemy's own arms: forearms folded in front of the belly, one hand rising while the other drops (six seven).
func _gesture(wave: float) -> void:
	_rig.set_part_rotation(&"arm_l", -ARM_SWING * wave)
	_rig.set_part_rotation(&"arm_r", ARM_SWING * wave)
	_rig.set_part_rotation(&"forearm_l", -FOREARM_FOLD)
	_rig.set_part_rotation(&"forearm_r", FOREARM_FOLD)
	_rig.shift_part(&"forearm_l", Vector2(0.0, -FOREARM_LIFT * wave))
	_rig.shift_part(&"forearm_r", Vector2(0.0, FOREARM_LIFT * wave))
	_rig.set_part_rotation(&"wing_l", -WING_SWING * wave)
	_rig.set_part_rotation(&"wing_r", WING_SWING * wave)

## The player's own hands with their shield and sword, one rising while the other drops.
func _place_hands(wave: float) -> void:
	var view := size
	_player.layout(view, view.y * HANDS_LIFT_SHARE)
	var rig := _player.current_rig()
	rig.shift_part(&"arm_l", Vector2(0.0, -HANDS_SWING * wave))
	rig.shift_part(&"arm_r", Vector2(0.0, HANDS_SWING * wave))

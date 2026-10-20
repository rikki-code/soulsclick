## Screen-level effects of the battle: shake, full-screen flash, pooled spark bursts and floating numbers.
class_name BattleFx
extends Control

const SPARK_POOL := 6
const NUMBER_POOL := 16
const SPARK_COUNT := 18
const SPARK_SECONDS := 0.45
const NUMBER_RISE := 90.0
const NUMBER_SECONDS := 0.8
const NUMBER_FONT := 56
const FLASH_PEAK := 0.55
const SHAKE_SECONDS := 0.3
const FX_Z := 60
const HIT_SPREAD_X := 90.0
const HIT_SPREAD_Y := 40.0
const HIT_SCALE := 0.75
const HIT_SECONDS := 0.5
const CRIT_SCALE := 1.7
const CRIT_SECONDS := 0.9
const CRIT_COLOR := Color(1.0, 0.82, 0.15)

var _shake_target: Node
var _shake_base := Vector2.ZERO
var _shake_tween: Tween
var _flash_rect := ColorRect.new()
var _flash_tween: Tween
var _sparks: Array[CPUParticles2D] = []
var _numbers: Array[Label] = []
var _next_spark := 0
var _next_number := 0

func setup(shake_target: Node) -> void:
	_shake_target = shake_target
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(1, 1, 1, 0)
	add_child(_flash_rect)
	for i in SPARK_POOL:
		_sparks.append(_make_sparks())
	for i in NUMBER_POOL:
		_numbers.append(_make_number())

func shake(strength: float, seconds := SHAKE_SECONDS) -> void:
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
		_shake_target.position = _shake_base
	_shake_tween = create_tween()
	_shake_tween.tween_method(func(t: float) -> void:
		var amount := strength * (1.0 - t)
		_shake_target.position = _shake_base + Vector2(randf_range(-amount, amount), randf_range(-amount, amount)), 0.0, 1.0, seconds)
	_shake_tween.tween_callback(func() -> void: _shake_target.position = _shake_base)

func flash(color: Color, alpha := FLASH_PEAK, seconds := 0.25) -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_rect.color = Color(color, alpha)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash_rect, "color:a", 0.0, seconds)

func burst(at: Vector2, color: Color, power := 1.0) -> void:
	var sparks := _sparks[_next_spark]
	_next_spark = (_next_spark + 1) % _sparks.size()
	sparks.position = at
	sparks.color = color
	sparks.amount = roundi(SPARK_COUNT * power)
	sparks.initial_velocity_min = 220.0 * power
	sparks.initial_velocity_max = 520.0 * power
	sparks.restart()
	sparks.emitting = true

func number(at: Vector2, text: String, color: Color, scale_factor := 1.0, seconds := NUMBER_SECONDS, rise := NUMBER_RISE) -> void:
	var label := _numbers[_next_number]
	_next_number = (_next_number + 1) % _numbers.size()
	if label.has_meta(&"tween"):
		var old := label.get_meta(&"tween") as Tween
		if old != null and old.is_valid():
			old.kill()
	label.text = text
	label.modulate = color
	label.scale = Vector2.ONE * scale_factor
	label.size = label.get_minimum_size()
	label.pivot_offset = label.size * 0.5
	label.position = at - label.size * 0.5
	label.visible = true
	var tween := label.create_tween().set_parallel()
	label.set_meta(&"tween", tween)
	tween.tween_property(label, "position:y", at.y - label.size.y * 0.5 - rise, seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, seconds * 0.6).set_delay(seconds * 0.4)
	tween.chain().tween_callback(label.hide)

## A player hit number: sprayed with a random offset; crit = bigger, golden, with a punch-in scale. Normal hits are small and quick.
func hit_number(at: Vector2, text: String, crit: bool) -> void:
	var spread := Vector2(randf_range(-HIT_SPREAD_X, HIT_SPREAD_X), randf_range(-HIT_SPREAD_Y, HIT_SPREAD_Y))
	if crit:
		number(at + spread * 0.5, text, CRIT_COLOR, CRIT_SCALE, CRIT_SECONDS, NUMBER_RISE * 1.3)
		var label := _numbers[(_next_number + _numbers.size() - 1) % _numbers.size()]
		label.scale = Vector2.ONE * CRIT_SCALE * 1.5
		label.create_tween().tween_property(label, "scale", Vector2.ONE * CRIT_SCALE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		return
	number(at + spread, text, Color.WHITE, HIT_SCALE, HIT_SECONDS, NUMBER_RISE * 0.7)

## A short-lived text that flies from one point to another and fades (souls pickup).
func fly_text(from: Vector2, to: Vector2, text: String, color: Color, seconds := 0.7) -> void:
	var label := _make_number()
	label.text = text
	label.modulate = color
	label.size = label.get_minimum_size()
	label.position = from - label.size * 0.5
	label.visible = true
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position", to - label.size * 0.5, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(label, "modulate:a", 0.0, seconds * 0.3).set_delay(seconds * 0.7)
	tween.chain().tween_callback(label.queue_free)

func _make_sparks() -> CPUParticles2D:
	var sparks := CPUParticles2D.new()
	sparks.emitting = false
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.lifetime = SPARK_SECONDS
	sparks.direction = Vector2.UP
	sparks.spread = 180.0
	sparks.gravity = Vector2(0, 900)
	sparks.scale_amount_min = 3.0
	sparks.scale_amount_max = 7.0
	sparks.z_index = FX_Z
	add_child(sparks)
	return sparks

func _make_number() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", NUMBER_FONT)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 10)
	label.visible = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = FX_Z
	add_child(label)
	return label

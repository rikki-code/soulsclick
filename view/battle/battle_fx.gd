## Screen-level effects of the battle: shake, full-screen flash, pooled spark bursts and floating numbers.
class_name BattleFx
extends Control

const SPARK_POOL := 6
const NUMBER_POOL := 8
const SPARK_COUNT := 18
const SPARK_SECONDS := 0.45
const NUMBER_RISE := 90.0
const NUMBER_SECONDS := 0.8
const NUMBER_FONT := 56
const FLASH_PEAK := 0.55
const SHAKE_SECONDS := 0.3
const FX_Z := 60

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
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
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

func number(at: Vector2, text: String, color: Color, scale_factor := 1.0) -> void:
	var label := _numbers[_next_number]
	_next_number = (_next_number + 1) % _numbers.size()
	label.text = text
	label.modulate = color
	label.scale = Vector2.ONE * scale_factor
	label.size = label.get_minimum_size()
	label.pivot_offset = label.size * 0.5
	label.position = at - label.size * 0.5
	label.visible = true
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", at.y - NUMBER_RISE, NUMBER_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, NUMBER_SECONDS).set_delay(NUMBER_SECONDS * 0.4)
	tween.chain().tween_callback(label.hide)

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

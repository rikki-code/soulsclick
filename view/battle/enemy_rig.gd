## Puppet of one enemy: a tree of part nodes posed by tweens. Parts come from a RigSpec (SVG textures or
## placeholder polygons). Glow parts get an additive overlay and a halo that pulse during a telegraph.
class_name EnemyRig
extends Node2D

signal pose_settled(serial: int)

const GLOW_MATERIAL := preload("res://view/battle/glow_add.tres")
const HALO_SIZE := 128
const HALO_SCALE := 1.6
const BREATH_PIXELS := 5.0
const BREATH_SECONDS := 1.4
const FLASH_COLOR := Color(2.2, 2.2, 2.2)
const NUDGE_SECONDS := 0.12
const FADED_ALPHA := 0.35

var spec: RigSpec
var accent := Color.WHITE
var _holder := Node2D.new()
var _nodes: Dictionary = {}
var _overlays: Dictionary = {}
var _halos: Dictionary = {}
var _tween: Tween
var _glow_tween: Tween
var _breath: Tween
var _serial := 0
var _glow_color := Color.WHITE
static var _halo_texture: GradientTexture2D

func setup(p_spec: RigSpec) -> void:
	spec = p_spec
	accent = spec.accent
	add_child(_holder)
	for part in spec.parts:
		_add_part(part)
	apply_pose(RigSpec.IDLE)
	set_glow(accent, 0.0)
	_start_breathing()

func apply_pose(pose_id: StringName) -> void:
	for part_id: StringName in _nodes:
		var target := _target(part_id, spec.pose_for(pose_id))
		_nodes[part_id].position = target["pos"]
		_nodes[part_id].rotation_degrees = target["rot"]

func play_pose(pose_id: StringName, duration: float, trans := Tween.TRANS_SINE) -> void:
	await play_sequence([[pose_id, duration, trans]])

## Steps: [pose_id, seconds] or [pose_id, seconds, transition]. Returns when the last one is reached or the
## sequence is replaced by a newer one.
func play_sequence(steps: Array) -> void:
	_interrupt()
	var mine := _serial
	_tween = create_tween()
	for step: Array in steps:
		var trans: Tween.TransitionType = step[2] if step.size() > 2 else Tween.TRANS_SINE
		_append_step(_tween, StringName(step[0]), float(step[1]), trans)
	_tween.finished.connect(func() -> void: pose_settled.emit(mine))
	while true:
		if await pose_settled == mine:
			return

func set_glow(color: Color, level: float) -> void:
	_glow_color = color
	for part_id: StringName in _overlays:
		var overlay: CanvasItem = _overlays[part_id]
		overlay.modulate = Color(color, level)
		var halo: CanvasItem = _halos[part_id]
		halo.modulate = Color(color, level * 0.7)

## Ramps the glow up over `duration` with a pulse on top; stays at the peak until stop_glow().
func pulse_glow(color: Color, duration: float, period: float, peak: float) -> void:
	_kill(_glow_tween)
	_glow_tween = create_tween()
	_glow_tween.tween_method(func(t: float) -> void:
		var ramp := smoothstep(0.0, 1.0, t)
		var wave := 0.65 + 0.35 * sin(t * duration / period * TAU)
		set_glow(color, peak * ramp * wave), 0.0, 1.0, maxf(duration, 0.01))

func stop_glow(fade := 0.2) -> void:
	_kill(_glow_tween)
	_glow_tween = create_tween()
	var start := _glow_level()
	_glow_tween.tween_method(func(level: float) -> void: set_glow(_glow_color, level), start, 0.0, fade)

func flash(time: float) -> void:
	modulate = FLASH_COLOR
	create_tween().tween_property(self, "modulate", Color.WHITE, time)

func nudge(offset_x: float) -> void:
	_holder.position.x = offset_x
	create_tween().tween_property(_holder, "position:x", 0.0, NUDGE_SECONDS).set_trans(Tween.TRANS_BACK)

func fade_out(time: float) -> void:
	_kill(_breath)
	create_tween().tween_property(self, "modulate:a", FADED_ALPHA, time)

func part_center(part_id: StringName) -> Vector2:
	var node: Node2D = _nodes.get(part_id, _holder)
	return node.global_position

func has_part(part_id: StringName) -> bool:
	return _nodes.has(part_id)

func _glow_level() -> float:
	for part_id: StringName in _overlays:
		return (_overlays[part_id] as CanvasItem).modulate.a
	return 0.0

func _add_part(part: Dictionary) -> void:
	var node := Node2D.new()
	node.name = part["id"]
	var parent_node: Node2D = _nodes.get(part["parent"], _holder)
	parent_node.add_child(node)
	_nodes[part["id"]] = node
	var art := _make_art(part)
	node.add_child(art)
	if not spec.glow_parts.has(part["id"]):
		return
	var overlay := _make_art(part)
	overlay.material = GLOW_MATERIAL
	node.add_child(overlay)
	_overlays[part["id"]] = overlay
	var halo := _make_halo(part, overlay)
	node.add_child(halo)
	_halos[part["id"]] = halo

func _make_art(part: Dictionary) -> CanvasItem:
	var result: CanvasItem
	if part.has("polygon"):
		var polygon := Polygon2D.new()
		polygon.polygon = part["polygon"]
		polygon.color = part["color"]
		polygon.position = -part["pivot"]
		result = polygon
	else:
		var sprite := Sprite2D.new()
		var file: String = part["file"]
		sprite.texture = load_texture(file if file.begins_with("res://") else spec.dir + file)
		sprite.centered = false
		sprite.offset = -part["pivot"]
		result = sprite
	result.z_as_relative = false
	result.z_index = part["z"]
	return result

func _make_halo(part: Dictionary, overlay: CanvasItem) -> Sprite2D:
	var halo := Sprite2D.new()
	halo.texture = _halo()
	halo.material = GLOW_MATERIAL
	halo.z_as_relative = false
	halo.z_index = part["z"]
	var size := Vector2(64, 64)
	var center := Vector2.ZERO
	if overlay is Sprite2D and (overlay as Sprite2D).texture != null:
		size = (overlay as Sprite2D).texture.get_size()
		center = size * 0.5 - part["pivot"]
	elif overlay is Polygon2D:
		var rect := Rect2((overlay as Polygon2D).polygon[0], Vector2.ZERO)
		for point in (overlay as Polygon2D).polygon:
			rect = rect.expand(point)
		size = rect.size
		center = rect.get_center() - part["pivot"]
	halo.position = center
	halo.scale = size / HALO_SIZE * HALO_SCALE
	return halo

static func _halo() -> GradientTexture2D:
	if _halo_texture != null:
		return _halo_texture
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	_halo_texture = GradientTexture2D.new()
	_halo_texture.gradient = gradient
	_halo_texture.fill = GradientTexture2D.FILL_RADIAL
	_halo_texture.fill_from = Vector2(0.5, 0.5)
	_halo_texture.fill_to = Vector2(1.0, 0.5)
	_halo_texture.width = HALO_SIZE
	_halo_texture.height = HALO_SIZE
	return _halo_texture

## Imported SVG when the editor imported it, raw rasterised SVG otherwise.
static func load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var image := Image.new()
	if image.load_svg_from_string(file.get_as_text()) != OK:
		return null
	return ImageTexture.create_from_image(image)

func _target(part_id: StringName, pose: Dictionary) -> Dictionary:
	var part := spec.part_by_id(part_id)
	var entry: Dictionary = pose.get(part_id, {})
	var parent_pivot := Vector2.ZERO
	if part["parent"] != &"":
		parent_pivot = spec.part_by_id(part["parent"])["pivot"]
	var move: Vector2 = entry.get("move", Vector2.ZERO)
	return {"pos": part["at"] + move - parent_pivot, "rot": entry.get("rot", 0.0)}

func _append_step(tween: Tween, pose_id: StringName, duration: float, trans: Tween.TransitionType) -> void:
	var pose := spec.pose_for(pose_id)
	var first := true
	for part_id: StringName in _nodes:
		var target := _target(part_id, pose)
		var node: Node2D = _nodes[part_id]
		if not first:
			tween.parallel()
		first = false
		tween.tween_property(node, "rotation_degrees", target["rot"], duration).set_trans(trans).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(node, "position", target["pos"], duration).set_trans(trans).set_ease(Tween.EASE_IN_OUT)

func _interrupt() -> void:
	_kill(_tween)
	pose_settled.emit(_serial)
	_serial += 1

func _start_breathing() -> void:
	_breath = create_tween().set_loops()
	_breath.tween_property(_holder, "position:y", BREATH_PIXELS, BREATH_SECONDS).set_trans(Tween.TRANS_SINE)
	_breath.tween_property(_holder, "position:y", 0.0, BREATH_SECONDS).set_trans(Tween.TRANS_SINE)

static func _kill(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()

## Parsed enemy rig: parts with pivots, pose table, glow parts. Built from a pack's rig.json or, when the
## enemy has no art yet, from coloured polygons with the same structure.
class_name RigSpec
extends RefCounted

const DEFAULT_CANVAS := Vector2(1024, 1024)
const PLACEHOLDER_COLOR := Color(0.1, 0.11, 0.14)
const IDLE := &"idle"

var enemy_id: StringName
var dir := ""
var accent := Color(0.9, 0.3, 0.2)
var canvas := DEFAULT_CANVAS
## Array of Dictionary: id, file, parent, pivot (Vector2), at (Vector2), z, optional polygon + color.
var parts: Array[Dictionary] = []
var poses: Dictionary = {}
var glow_parts: Array[StringName] = []
## Attach points for swappable parts (gear): slot id -> {parent, at (Vector2), z}.
var slots: Dictionary = {}
var is_placeholder := false

static func load_for(p_enemy_id: StringName, accent_fallback: Color) -> RigSpec:
	var spec := from_file(BattlePaths.rig_json(p_enemy_id))
	if spec == null:
		return _placeholder(p_enemy_id, accent_fallback)
	spec.enemy_id = p_enemy_id
	return spec

## Null when the file is missing or is not a JSON object.
static func from_file(path: String) -> RigSpec:
	var file := FileAccess.open(path, FileAccess.READ)
	var data: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	if not data is Dictionary:
		return null
	var spec := RigSpec.new()
	spec.dir = path.get_base_dir() + "/"
	spec._read(data)
	return spec

func _read(data: Dictionary) -> void:
	accent = Color.html(str(data.get("accent", "#e04030")))
	var size: Array = data.get("canvas", [DEFAULT_CANVAS.x, DEFAULT_CANVAS.y])
	canvas = Vector2(size[0], size[1])
	for raw: Dictionary in data.get("parts", []):
		parts.append({
			"id": StringName(raw["id"]), "file": raw["file"], "parent": StringName(raw.get("parent", "")),
			"pivot": to_vec(raw["pivot"]), "at": to_vec(raw["at"]), "z": int(raw.get("z", 0)),
		})
	for pose_id: String in data.get("poses", {}):
		var pose := {}
		for part_id: String in data["poses"][pose_id]:
			var entry: Dictionary = data["poses"][pose_id][part_id]
			pose[StringName(part_id)] = {"rot": float(entry.get("rot", 0.0)), "move": to_vec(entry.get("move", [0, 0]))}
		poses[StringName(pose_id)] = pose
	for slot_id: String in data.get("slots", {}):
		var raw_slot: Dictionary = data["slots"][slot_id]
		slots[StringName(slot_id)] = {"parent": StringName(raw_slot["parent"]), "at": to_vec(raw_slot["at"]), "z": int(raw_slot.get("z", 0))}
	for glow_id: String in data.get("glow_parts", []):
		glow_parts.append(StringName(glow_id))

static func to_vec(pair: Array) -> Vector2:
	return Vector2(float(pair[0]), float(pair[1]))

static func _placeholder(p_enemy_id: StringName, p_accent: Color) -> RigSpec:
	var spec := RigSpec.new()
	spec.enemy_id = p_enemy_id
	spec.accent = p_accent
	spec.is_placeholder = true
	spec.parts = [
		make_poly(&"legs", &"", Vector2(512, 760), Vector2(0, 0), 0, [Vector2(-90, 0), Vector2(90, 0), Vector2(110, 220), Vector2(-110, 220)], PLACEHOLDER_COLOR),
		make_poly(&"body", &"", Vector2(512, 760), Vector2(0, 0), 1, [Vector2(-130, 0), Vector2(130, 0), Vector2(150, -330), Vector2(-150, -330)], PLACEHOLDER_COLOR),
		make_poly(&"head", &"body", Vector2(0, -330), Vector2(0, 0), 2, [Vector2(-60, 0), Vector2(60, 0), Vector2(50, -130), Vector2(-50, -130)], PLACEHOLDER_COLOR),
		make_poly(&"arm_r", &"body", Vector2(140, -300), Vector2(0, 0), 3, [Vector2(-30, 0), Vector2(30, 0), Vector2(26, 220), Vector2(-26, 220)], PLACEHOLDER_COLOR),
		make_poly(&"weapon", &"arm_r", Vector2(0, 220), Vector2(0, 0), 4, [Vector2(-12, 40), Vector2(12, 40), Vector2(12, -260), Vector2(-12, -260)], p_accent.darkened(0.2)),
	]
	spec.glow_parts = [&"weapon"]
	spec.poses = {
		IDLE: {},
		&"windup_quick": {&"arm_r": make_pose(-100.0), &"body": make_pose(-6.0)},
		&"strike_quick": {&"arm_r": make_pose(80.0), &"body": make_pose(10.0)},
		&"windup_heavy": {&"arm_r": make_pose(-170.0), &"body": make_pose(-10.0)},
		&"strike_heavy": {&"arm_r": make_pose(60.0), &"body": make_pose(14.0, Vector2(0, 20))},
		&"windup_combo": {&"arm_r": make_pose(-60.0), &"body": make_pose(-8.0)},
		&"strike_combo": {&"arm_r": make_pose(70.0), &"body": make_pose(8.0)},
		&"recover": {&"arm_r": make_pose(10.0), &"body": make_pose(6.0)},
		&"staggered": {&"body": make_pose(-14.0, Vector2(-20, 0)), &"head": make_pose(-20.0), &"arm_r": make_pose(-40.0)},
		&"hurt": {&"body": make_pose(-6.0, Vector2(-14, 0))},
		&"death": {&"body": make_pose(-80.0, Vector2(-30, 120)), &"legs": make_pose(-4.0, Vector2(0, 40))},
	}
	return spec

static func make_poly(id: StringName, parent: StringName, at: Vector2, pivot: Vector2, z: int, points: Array, color: Color) -> Dictionary:
	return {"id": id, "file": "", "parent": parent, "pivot": pivot, "at": at, "z": z, "polygon": PackedVector2Array(points), "color": color}

static func make_pose(rot: float, move := Vector2.ZERO) -> Dictionary:
	return {"rot": rot, "move": move}

func pose_for(pose_id: StringName) -> Dictionary:
	return poses.get(pose_id, poses.get(IDLE, {}))

func part_by_id(part_id: StringName) -> Dictionary:
	for part in parts:
		if part["id"] == part_id:
			return part
	return {}

## Rig of the player's hands (shield bottom-left, weapon bottom-right). Loaded from the player pack's
## hands/rig.json when it exists, else built from dark polygons with the same parts and pose ids.
class_name PlayerRigSpec
extends RefCounted

const CANVAS := Vector2(1024, 768)
const ARM_COLOR := Color(0.1, 0.1, 0.13)
const SHIELD_COLOR := Color(0.18, 0.19, 0.25)
const BLADE_COLOR := Color(0.42, 0.44, 0.52)
const GUARD_COLOR := Color(0.2, 0.2, 0.26)
const SHIELD_ARM_AT := Vector2(220, 768)
const WEAPON_ARM_AT := Vector2(804, 768)
const ARM_LENGTH := 240.0

const SHIELD_SLOT := &"shield"
const WEAPON_SLOT := &"weapon"
## Root arm each gear's pose offsets move (the shoulder slides the whole arm chain).
const SLOT_ARMS := {SHIELD_SLOT: &"arm_l", WEAPON_SLOT: &"arm_r"}
const POSE_DEFAULT := "default"
const SLOT_KINDS := {SHIELD_SLOT: "shields", WEAPON_SLOT: "weapons"}

static func load_hands(loadout: PlayerLoadoutView = null) -> RigSpec:
	var spec := RigSpec.from_file(BattlePaths.hands_rig_json())
	if spec == null:
		return _placeholder()
	var gear: Variant = JSON.parse_string(FileAccess.get_file_as_string(BattlePaths.gear_json()))
	if gear is Dictionary:
		var chosen := PlayerLoadoutView.resolve(loadout)
		_attach(spec, gear, SHIELD_SLOT, chosen.shield_id)
		_attach(spec, gear, WEAPON_SLOT, chosen.weapon_id)
	return spec

static func gear_part_id(slot_id: StringName) -> StringName:
	return StringName("gear_%s" % slot_id)

## Bounding box (canvas pixels) of one part's art in a pose, from the same transform chain the rig plays
## (node origin = pivot, position = at + move - parent pivot). Empty Rect2 for polygon placeholders.
static func part_rect(spec: RigSpec, part_id: StringName, pose_id: StringName) -> Rect2:
	var part := spec.part_by_id(part_id)
	if part.is_empty() or part.has("polygon"):
		return Rect2()
	var texture := EnemyRig.load_texture(_texture_path(spec, part))
	if texture == null:
		return Rect2()
	var world := _world(spec, part_id, spec.pose_for(pose_id))
	var art := Rect2(-part["pivot"], texture.get_size())
	var corners := [art.position, Vector2(art.end.x, art.position.y), art.end, Vector2(art.position.x, art.end.y)]
	var result := Rect2(world * corners[0], Vector2.ZERO)
	for corner: Vector2 in corners:
		result = result.expand(world * corner)
	return result

static func _texture_path(spec: RigSpec, part: Dictionary) -> String:
	var file: String = part["file"]
	return file if file.begins_with("res://") else spec.dir + file

static func _world(spec: RigSpec, part_id: StringName, pose: Dictionary) -> Transform2D:
	var part := spec.part_by_id(part_id)
	var entry: Dictionary = pose.get(part_id, {})
	var parent_pivot := Vector2.ZERO
	var parent_world := Transform2D.IDENTITY
	if part["parent"] != &"":
		parent_pivot = spec.part_by_id(part["parent"])["pivot"]
		parent_world = _world(spec, part["parent"], pose)
	var local := Transform2D(deg_to_rad(entry.get("rot", 0.0)), part["at"] + entry.get("move", Vector2.ZERO) - parent_pivot)
	return parent_world * local

## Adds the gear sprite as a child of the slot's hand (its grip pivot sits on the slot point, it turns with the
## hand) and applies the gear's optional `pose_offsets` {pose id | "default": {move, rot}} on top of each pose:
## `move` slides the root arm of that hand (the whole arm), `rot` turns the hand (and so the gear).
static func _attach(spec: RigSpec, gear: Dictionary, slot_id: StringName, gear_id: StringName) -> void:
	var entry: Variant = gear.get(SLOT_KINDS[slot_id], {}).get(String(gear_id))
	if not entry is Dictionary or not spec.slots.has(slot_id):
		push_warning("PlayerRigSpec: unknown %s '%s'" % [slot_id, gear_id])
		return
	var slot: Dictionary = spec.slots[slot_id]
	spec.parts.append({
		"id": gear_part_id(slot_id), "file": BattlePaths.PLAYER_PACK + entry["file"], "parent": slot["parent"],
		"pivot": RigSpec.to_vec(entry["pivot"]), "at": slot["at"], "z": slot["z"],
	})
	var offsets: Dictionary = entry.get("pose_offsets", {})
	for pose_id: StringName in spec.poses:
		var offset: Dictionary = offsets.get(String(pose_id), offsets.get(POSE_DEFAULT, {}))
		var pose: Dictionary = spec.poses[pose_id]
		if offset.has("move") and pose.has(SLOT_ARMS[slot_id]):
			pose[SLOT_ARMS[slot_id]]["move"] += RigSpec.to_vec(offset["move"])
		if offset.has("rot") and pose.has(slot["parent"]):
			pose[slot["parent"]]["rot"] += float(offset["rot"])

static func _placeholder() -> RigSpec:
	var spec := RigSpec.new()
	spec.enemy_id = &"hands"
	spec.canvas = CANVAS
	spec.is_placeholder = true
	var arm := [Vector2(-60, 40), Vector2(60, 40), Vector2(44, -ARM_LENGTH), Vector2(-44, -ARM_LENGTH)]
	var shield := [Vector2(-140, -150), Vector2(140, -150), Vector2(150, 30), Vector2(0, 190), Vector2(-150, 30)]
	var blade := [Vector2(-18, 60), Vector2(18, 60), Vector2(18, 0), Vector2(12, -330), Vector2(0, -380), Vector2(-12, -330), Vector2(-18, 0)]
	var guard := [Vector2(-64, -10), Vector2(64, -10), Vector2(64, 12), Vector2(-64, 12)]
	var tip := Vector2(0, -ARM_LENGTH)
	spec.parts = [
		RigSpec.make_poly(&"shield_arm", &"", SHIELD_ARM_AT, Vector2.ZERO, 0, arm, ARM_COLOR),
		RigSpec.make_poly(&"shield", &"shield_arm", tip, Vector2.ZERO, 1, shield, SHIELD_COLOR),
		RigSpec.make_poly(&"weapon_arm", &"", WEAPON_ARM_AT, Vector2.ZERO, 0, arm, ARM_COLOR),
		RigSpec.make_poly(&"weapon", &"weapon_arm", tip, Vector2.ZERO, 1, blade, BLADE_COLOR),
		RigSpec.make_poly(&"guard", &"weapon", Vector2.ZERO, Vector2.ZERO, 2, guard, GUARD_COLOR),
	]
	spec.poses = {
		&"idle": _pose(8.0, Vector2.ZERO, 0.0, -10.0, Vector2.ZERO, 0.0),
		&"block": _pose(30.0, Vector2(150, -110), 0.0, -4.0, Vector2(10, 30), 0.0),
		&"parry": _pose(50.0, Vector2(180, -150), 12.0, -20.0, Vector2(-60, 0), 0.0),
		&"attack": _pose(8.0, Vector2.ZERO, 0.0, -62.0, Vector2(-300, -190), -30.0),
		&"hurt": _pose(14.0, Vector2(0, 70), 0.0, -4.0, Vector2(0, 70), 0.0),
		&"guard_broken": _pose(-30.0, Vector2(-80, 160), -25.0, -10.0, Vector2(0, 90), 0.0),
		&"staggered": _pose(-15.0, Vector2(-30, 140), 0.0, 15.0, Vector2(30, 140), 0.0),
	}
	return spec

static func _pose(shield_arm_rot: float, shield_arm_move: Vector2, shield_rot: float, weapon_arm_rot: float, weapon_arm_move: Vector2, weapon_rot: float) -> Dictionary:
	return {
		&"shield_arm": RigSpec.make_pose(shield_arm_rot, shield_arm_move),
		&"shield": RigSpec.make_pose(shield_rot),
		&"weapon_arm": RigSpec.make_pose(weapon_arm_rot, weapon_arm_move),
		&"weapon": RigSpec.make_pose(weapon_rot),
	}

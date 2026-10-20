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

static func load_hands() -> RigSpec:
	var spec := RigSpec.from_file(BattlePaths.hands_rig_json())
	return spec if spec != null else _placeholder()

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

## The player's hands as a puppet: an EnemyRig playing the hands rig (pack rig.json or the placeholder) with
## poses driven by the player's fighter state and by strike outcomes. Poses: idle, block, parry, attack, hurt,
## guard_broken, staggered.
class_name PlayerRig
extends Node2D

const HEIGHT_SHARE := 0.34
const PLACEHOLDER_ZONE_SHARE := 0.19
## Landscape: the resting hands (without gear) take at most this share of the height and sit at the sides, each fist
## at FIST_X_SHARE of the width, so the enemy and the player bars keep the middle.
const LANDSCAPE_ZONE_SHARE := 0.22
const FIST_X_SHARE := 0.2
const HAND_PARTS: Array[StringName] = [&"arm_l", &"forearm_l", &"hand_l", &"arm_r", &"forearm_r", &"hand_r"]
const ATTACK_SECONDS := 0.06
const RECOVER_SECONDS := 0.3
const BLOCK_SECONDS := 0.07
const STAGGER_SECONDS := 0.15
const HURT_SECONDS := 0.07
const PARRY_SECONDS := 0.05
const PARRY_HOLD_SECONDS := 0.22
const SETTLE_SECONDS := 0.25
const BLOCK_NUDGE := 12.0
const REJECT_NUDGE := -8.0
const MSEC := 1000.0

const STATE_STEPS := {
	&"attacking": [[&"attack", ATTACK_SECONDS, Tween.TRANS_EXPO], [&"idle", RECOVER_SECONDS]],
	&"blocking": [[&"block", BLOCK_SECONDS]],
	&"staggered": [[&"staggered", STAGGER_SECONDS, Tween.TRANS_BACK]],
	&"idle": [[&"idle", SETTLE_SECONDS]],
}

var spec: RigSpec
var _rig := EnemyRig.new()
var _hold_until_msec := 0
## Measured once from the spec: top of the resting hands (canvas y), their x centres, the root arms' rest `at`.
var _rest_top := 0.0
var _rest_gap := Vector2.ZERO
var _arm_at := {}
var _spread := 0.0

func _init(loadout: PlayerLoadoutView = null) -> void:
	spec = PlayerRigSpec.load_hands(loadout)
	add_child(_rig)
	_measure()

func _ready() -> void:
	_rig.setup(spec)

## Height of the bottom strip the resting hands take (without their gear, which rises over the enemy's lower body):
## measured from the hand art. Landscape reserves nothing: the hands sit at the sides and the bars between them.
func zone_height(view_size: Vector2) -> float:
	if spec.is_placeholder:
		return view_size.y * PLACEHOLDER_ZONE_SHARE
	if _is_landscape(view_size):
		return 0.0
	return (spec.canvas.y - _rest_top) * _fit(view_size)

## `bottom_inset` lifts the hands above a strip the scheme keeps at the very bottom (e.g. buttons).
func layout(view_size: Vector2, bottom_inset := 0.0) -> void:
	var fit := _fit(view_size)
	scale = Vector2.ONE * fit
	var centre_x := spec.canvas.x * 0.5
	var spread := 0.0
	if not spec.is_placeholder and _is_landscape(view_size):
		centre_x = (_rest_gap.x + _rest_gap.y) * 0.5
		spread = maxf(0.0, (0.5 - FIST_X_SHARE) * view_size.x / fit - (_rest_gap.y - _rest_gap.x) * 0.5)
	position = Vector2(view_size.x * 0.5 - centre_x * fit, view_size.y - bottom_inset - spec.canvas.y * fit)
	_set_spread(spread)

func on_state(state_id: StringName) -> void:
	if not STATE_STEPS.has(state_id):
		return
	if state_id == &"idle" and Time.get_ticks_msec() < _hold_until_msec:
		return
	_rig.play_sequence(STATE_STEPS[state_id])

func on_strike(result: StrikeResult) -> void:
	match result.outcome:
		StrikeResult.PARRIED:
			_hold_until_msec = Time.get_ticks_msec() + int(PARRY_HOLD_SECONDS * MSEC)
			_rig.play_sequence([[&"parry", PARRY_SECONDS], [&"parry", PARRY_HOLD_SECONDS], [&"idle", SETTLE_SECONDS]])
		StrikeResult.BLOCKED:
			_rig.nudge(BLOCK_NUDGE)
		StrikeResult.HIT:
			var pose_id := &"guard_broken" if result.guard_broken else &"hurt"
			_rig.play_sequence([[pose_id, HURT_SECONDS], [&"idle", RECOVER_SECONDS]])

func on_rejected() -> void:
	_rig.nudge(REJECT_NUDGE)

func current_rig() -> EnemyRig:
	return _rig

static func _is_landscape(view_size: Vector2) -> bool:
	return view_size.x > view_size.y

func _fit(view_size: Vector2) -> float:
	if spec.is_placeholder:
		return minf(view_size.x / spec.canvas.x, view_size.y * HEIGHT_SHARE / spec.canvas.y)
	var fit := view_size.x / spec.canvas.x
	if _is_landscape(view_size):
		fit = minf(fit, view_size.y * LANDSCAPE_ZONE_SHARE / (spec.canvas.y - _rest_top))
	return fit

func _measure() -> void:
	if spec.is_placeholder:
		return
	_rest_top = spec.canvas.y
	for part_id in HAND_PARTS:
		var rect := PlayerRigSpec.part_rect(spec, part_id, RigSpec.IDLE)
		_rest_top = minf(_rest_top, rect.position.y)
	_rest_gap = Vector2(PlayerRigSpec.part_rect(spec, &"hand_l", RigSpec.IDLE).get_center().x, PlayerRigSpec.part_rect(spec, &"hand_r", RigSpec.IDLE).get_center().x)
	for part_id: StringName in [&"arm_l", &"arm_r"]:
		_arm_at[part_id] = spec.part_by_id(part_id)["at"]

## Moves the root arms apart (left arm left, right arm right) by `amount` canvas pixels.
func _set_spread(amount: float) -> void:
	if spec.is_placeholder or is_equal_approx(amount, _spread):
		return
	_spread = amount
	spec.part_by_id(&"arm_l")["at"] = _arm_at[&"arm_l"] + Vector2(-amount, 0.0)
	spec.part_by_id(&"arm_r")["at"] = _arm_at[&"arm_r"] + Vector2(amount, 0.0)
	_rig.apply_pose(RigSpec.IDLE)

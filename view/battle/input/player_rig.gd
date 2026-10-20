## The player's hands as a puppet: an EnemyRig playing the hands rig (pack rig.json or the placeholder) with
## poses driven by the player's fighter state and by strike outcomes. Poses: idle, block, parry, attack, hurt,
## guard_broken, staggered.
class_name PlayerRig
extends Node2D

const HEIGHT_SHARE := 0.34
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

func _init() -> void:
	spec = PlayerRigSpec.load_hands()
	add_child(_rig)

func _ready() -> void:
	_rig.setup(spec)

func layout(view_size: Vector2) -> void:
	var height_share := HEIGHT_SHARE if spec.is_placeholder else 1.0
	var fit := minf(view_size.x / spec.canvas.x, view_size.y * height_share / spec.canvas.y)
	scale = Vector2.ONE * fit
	position = Vector2((view_size.x - spec.canvas.x * fit) * 0.5, view_size.y - spec.canvas.y * fit)

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

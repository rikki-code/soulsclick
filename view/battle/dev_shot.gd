## Dev-only: `-- --shot=<png path> --shot-at=<seconds> [--enemy=<id>] [--scheme=<id>] [--act=<attack|block>]` saves the
## viewport and quits; --act sends that action 0.35 s before the shot. Does nothing without the shot flag.
class_name DevShot
extends Node

signal act_requested(action_id: StringName)

const SHOT_FLAG := "--shot="
const AT_FLAG := "--shot-at="
const ENEMY_FLAG := "--enemy="
const SCHEME_FLAG := "--scheme="
const ACT_FLAG := "--act="
const ACT_LEAD := 0.35
const DEFAULT_AT := 2.0

var _path := ""
var _at := DEFAULT_AT
var _act := ""
var _acted := false
var _elapsed := 0.0

static var scheme_override := ""

static func install(parent: Node) -> DevShot:
	var args := OS.get_cmdline_user_args()
	var shot := DevShot.new()
	for arg in args:
		if arg.begins_with(SHOT_FLAG):
			shot._path = arg.trim_prefix(SHOT_FLAG)
		elif arg.begins_with(AT_FLAG):
			shot._at = float(arg.trim_prefix(AT_FLAG))
		elif arg.begins_with(SCHEME_FLAG):
			scheme_override = arg.trim_prefix(SCHEME_FLAG)
		elif arg.begins_with(ACT_FLAG):
			shot._act = arg.trim_prefix(ACT_FLAG)
		elif arg.begins_with(ENEMY_FLAG):
			var index := GameSession.ENEMY_ORDER.find(StringName(arg.trim_prefix(ENEMY_FLAG)))
			GameSession.run_index = maxi(index, 0)
	if shot._path == "":
		shot.free()
		return null
	parent.add_child(shot)
	return shot

func _ready() -> void:
	get_tree().root.gui_disable_input = true

func _process(delta: float) -> void:
	_elapsed += delta
	if _act != "" and not _acted and _elapsed >= _at - ACT_LEAD:
		_acted = true
		act_requested.emit(StringName(_act))
	if _elapsed < _at:
		return
	var image := get_viewport().get_texture().get_image()
	image.save_png(_path)
	get_tree().quit()

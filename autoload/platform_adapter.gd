## Base of every portal/store integration. Defaults are no-ops or instant so a missing feature never blocks the game.
class_name PlatformAdapter
extends RefCounted

var _tree: SceneTree

func id() -> StringName:
	return &"base"

func attach(tree: SceneTree) -> void:
	_tree = tree

func initialize() -> void:
	await _next_frame()

func show_interstitial() -> void:
	await _next_frame()

func show_rewarded() -> bool:
	await _next_frame()
	return false

func is_rewarded_available() -> bool:
	return false

func submit_score(_board_id: StringName, _value: int) -> void:
	pass

func gameplay_started() -> void:
	pass

func gameplay_stopped() -> void:
	pass

func game_ready() -> void:
	pass

## Language code reported by the portal, empty when it has none.
func language() -> String:
	return ""

func purchase(_product_id: StringName) -> bool:
	await _next_frame()
	return false

func owns(_product_id: StringName) -> bool:
	return false

func _next_frame() -> void:
	if _tree != null:
		await _tree.process_frame

# Timer that keeps running while the tree is paused (ads pause it).
func _wait(seconds: float) -> void:
	if _tree == null:
		return
	await _tree.create_timer(seconds, true, false, true).timeout

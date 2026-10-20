## The two top-level scenes and the way between them.
class_name SceneRouter
extends RefCounted

const MENU_SCENE := "res://game/menu_root.tscn"
const GAME_SCENE := "res://game/game_root.tscn"

static func to_menu() -> void:
	_go(MENU_SCENE)

static func to_game() -> void:
	_go(GAME_SCENE)

static func _go(path: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.paused = false
	tree.change_scene_to_file(path)

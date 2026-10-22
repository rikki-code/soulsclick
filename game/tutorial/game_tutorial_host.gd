## The real TutorialHost: forwards every call to GameRoot, which owns the view, the duel and the hero. When the
## tutorial is over (finished or skipped) every call parks its caller forever, so a lesson still in flight can never
## touch the real run.
class_name GameTutorialHost
extends TutorialHost

signal _never

var _root: GameRoot

func _init(root: GameRoot) -> void:
	_root = root

func start_fight(enemy_id: StringName, opts := {}) -> Duel:
	await _park_if_over()
	return await _root.tutorial_fight(enemy_id, opts)

func win_fight() -> void:
	await _park_if_over()
	await _root.tutorial_win()

func say(text_key: String) -> void:
	await _park_if_over()
	_root.tutorial_say(text_key)

func hush() -> void:
	await _park_if_over()
	_root.tutorial_hush()

func praise() -> void:
	await _park_if_over()
	_root.tutorial_praise()

func point_at(target: StringName) -> void:
	await _park_if_over()
	_root.tutorial_point(target)

func give_item(item_id: StringName, count := 1) -> void:
	await _park_if_over()
	_root.tutorial_give_item(item_id, count)

func set_hp(hp: int) -> void:
	await _park_if_over()
	_root.tutorial_set_hp(hp)

func pause(seconds: float) -> void:
	await _park_if_over()
	await _root.tutorial_pause(seconds)
	await _park_if_over()

func _park_if_over() -> void:
	if _root.tutorial_over():
		await _never

## Lesson 5: one toy knight for items and tricks. First he waits and cannot die: the player is hurt and drinks a flask,
## then throws a bomb (he keeps the damage; his hp is set so the bomb does not finish him). Then he is let loose for real and the first time he uses each trick (heavy blow, feint,
## series) a hint names it; the lesson ends when he falls.
class_name Lesson05Knight
extends TutorialLesson

const ENEMY_ID := &"tut_knight"
const FLASK_ID := &"flask"
const BOMB_ID := &"ember_bomb"
const LOW_HP := 2
const PRAISE_PAUSE := 1.0
## Attack kind id -> hint key, said the first time the enemy winds that kind up.
const KIND_HINTS := {&"heavy": "TUT_HEAVY", &"feint": "TUT_FEINT", &"combo": "TUT_SERIES"}

func id() -> StringName:
	return &"knight"

func play(host: TutorialHost) -> void:
	var duel: Duel = await host.start_fight(ENEMY_ID, {TutorialHost.OPT_HOLD: true})
	host.give_item(FLASK_ID, 1)
	host.give_item(BOMB_ID, 1)
	host.set_hp(LOW_HP)
	host.say("TUT_HEAL")
	host.point_at(&"slot_flask")
	await _item_used(duel, FLASK_ID)
	host.say("TUT_BOMB")
	host.point_at(&"slot_ember_bomb")
	await _item_used(duel, BOMB_ID)
	host.hush()
	host.praise()
	await host.pause(PRAISE_PAUSE)
	var told := {}
	duel.telegraph_started.connect(func(kind_id: StringName, _duration: float, _index: int) -> void:
		if told.has(kind_id) or not KIND_HINTS.has(kind_id):
			return
		told[kind_id] = true
		host.say(KIND_HINTS[kind_id]))
	duel.release_enemy()
	await TutorialWait.once(duel.duel_finished, func(winner_side: StringName) -> bool:
		return winner_side == Fighter.PLAYER)
	host.hush()
	host.praise()
	await host.pause(PRAISE_PAUSE)
	await host.win_fight()

func _item_used(duel: Duel, item_id: StringName) -> void:
	await TutorialWait.once(duel.item_used, func(used_id: StringName, _left: int) -> bool:
		return used_id == item_id)

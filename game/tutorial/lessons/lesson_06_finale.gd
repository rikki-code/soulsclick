## Lesson 6, the exam: the big teddy fights back with everything and the player has all the tools (strike, block,
## parry, flasks, a bomb). Nothing is restricted and the lesson ends when the teddy falls.
class_name Lesson06Finale
extends TutorialLesson

const ENEMY_ID := &"tut_teddy"
const FLASK_ID := &"flask"
const FLASKS_GIVEN := 2
const BOMB_ID := &"ember_bomb"
const BOMBS_GIVEN := 1
const PRAISE_PAUSE := 1.0

func id() -> StringName:
	return &"finale"

func play(host: TutorialHost) -> void:
	var duel: Duel = await host.start_fight(ENEMY_ID, {TutorialHost.OPT_MORTAL: true})
	host.give_item(FLASK_ID, FLASKS_GIVEN)
	host.give_item(BOMB_ID, BOMBS_GIVEN)
	host.say("TUT_FINALE")
	await TutorialWait.once(duel.duel_finished, func(winner_side: StringName) -> bool:
		return winner_side == Fighter.PLAYER)
	host.hush()
	host.praise()
	await host.pause(PRAISE_PAUSE)
	await host.win_fight()

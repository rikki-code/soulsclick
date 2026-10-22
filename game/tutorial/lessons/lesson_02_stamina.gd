## Lesson 2: attacks cost stamina. The player strikes until the bar runs dry, then waits for it to refill.
class_name Lesson02Stamina
extends TutorialLesson

const ENEMY_ID := &"tut_scarecrow"
const FULL_EPSILON := 0.5
const PRAISE_PAUSE := 1.0

func id() -> StringName:
	return &"stamina"

func play(host: TutorialHost) -> void:
	var allowed: Array[StringName] = [Duel.ACTION_ATTACK]
	var duel: Duel = await host.start_fight(ENEMY_ID, {TutorialHost.OPT_ALLOWED: allowed, TutorialHost.OPT_HOLD: true})
	host.point_at(TutorialHost.TARGET_ATTACK)
	await TutorialWait.once(duel.action_rejected, func(_action: StringName, reason: StringName) -> bool:
		return reason == Duel.REJECT_STAMINA)
	host.say("TUT_STAMINA")
	host.point_at(TutorialHost.TARGET_NONE)
	await TutorialWait.once(duel.stamina_changed, func(value: float, max_value: float) -> bool:
		return value >= max_value - FULL_EPSILON)
	host.hush()
	host.praise()
	await host.pause(PRAISE_PAUSE)
	await host.win_fight()

## Lesson 3: one slime teaches block, parry and the punish. Only block is allowed at first: the player stops two strikes,
## then must parry one (block at the last moment); then attack opens and the staggered slime is hit for a critical.
class_name Lesson03Slime
extends TutorialLesson

const ENEMY_ID := &"tut_slime"
const DEFENSES_NEEDED := 2
const PRAISE_PAUSE := 1.0

func id() -> StringName:
	return &"slime"

func play(host: TutorialHost) -> void:
	var block_only: Array[StringName] = [Duel.ACTION_BLOCK]
	var duel: Duel = await host.start_fight(ENEMY_ID, {TutorialHost.OPT_ALLOWED: block_only})
	host.point_at(TutorialHost.TARGET_BLOCK)
	await TutorialWait.count(duel.strike_resolved, DEFENSES_NEEDED, func(result: StrikeResult) -> bool:
		return result.outcome == StrikeResult.BLOCKED or result.outcome == StrikeResult.PARRIED)
	host.say("TUT_PARRY")
	await TutorialWait.once(duel.strike_resolved, func(result: StrikeResult) -> bool:
		return result.outcome == StrikeResult.PARRIED)
	var both: Array[StringName] = [Duel.ACTION_ATTACK, Duel.ACTION_BLOCK]
	duel.allowed_actions = both
	host.say("TUT_PUNISH")
	host.point_at(TutorialHost.TARGET_ATTACK)
	await TutorialWait.once(duel.player_hit, func(_damage: int, _enemy_hp: int, crit: bool, _combo: int) -> bool:
		return crit)
	host.hush()
	host.praise()
	await host.pause(PRAISE_PAUSE)
	await host.win_fight()

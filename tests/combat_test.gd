## Headless checks of the duel model: godot --headless --path . -s tests/combat_test.gd
extends SceneTree

const DT := 1.0 / 60.0
const TUNING_PATH := "res://data/tuning/default_tuning.tres"
const ENEMY_PATHS := [
	"res://data/enemies/grunt.tres",
	"res://data/enemies/knight.tres",
	"res://data/enemies/warden.tres",
]

var _failures := 0
var _checks := 0

class Probe extends RefCounted:
	var log: Array[String] = []
	var telegraphs: Array[Dictionary] = []
	var results: Array[StrikeResult] = []
	var attacks: Array[Dictionary] = []
	var stamina_events := 0
	var winner: StringName = &""
	var finished_count := 0
	var rejections: Array[String] = []

	func _init(duel: Duel) -> void:
		duel.telegraph_started.connect(_on_telegraph)
		duel.strike_resolved.connect(_on_strike)
		duel.player_attacked.connect(_on_attacked)
		duel.stamina_changed.connect(_on_stamina)
		duel.fighter_state_changed.connect(_on_state)
		duel.action_rejected.connect(_on_rejected)
		duel.duel_finished.connect(_on_finished)

	func _on_telegraph(kind_id: StringName, duration: float, index: int) -> void:
		telegraphs.append({"kind": kind_id, "duration": duration, "index": index})
		log.append("telegraph %s %.3f %d" % [kind_id, duration, index])

	func _on_strike(result: StrikeResult) -> void:
		results.append(result)
		log.append("strike %s %s %d %d %d/%d" % [result.kind_id, result.outcome, result.damage, result.target_hp, result.strike_index, result.strike_count])

	func _on_attacked(damage: int, enemy_hp: int) -> void:
		attacks.append({"damage": damage, "enemy_hp": enemy_hp})
		log.append("attacked %d %d" % [damage, enemy_hp])

	func _on_stamina(value: float, max_value: float) -> void:
		stamina_events += 1
		log.append("stamina %.2f %.0f" % [value, max_value])

	func _on_state(side: StringName, state_id: StringName) -> void:
		log.append("state %s %s" % [side, state_id])

	func _on_rejected(action_id: StringName, reason: StringName) -> void:
		rejections.append("%s:%s" % [action_id, reason])
		log.append("rejected %s %s" % [action_id, reason])

	func _on_finished(winner_side: StringName) -> void:
		winner = winner_side
		finished_count += 1
		log.append("finished %s" % winner_side)

func _initialize() -> void:
	_test_data_loads()
	_test_parry()
	_test_block()
	_test_hit()
	_test_late_and_early_block()
	_test_heavy()
	_test_feint()
	_test_combo()
	_test_combo_parry_ends_chain()
	_test_stamina_gating()
	_test_attack_lock()
	_test_stagger_punish()
	_test_input_gate()
	_test_death()
	_test_victory()
	_test_pattern_order()
	_test_scaling()
	_test_determinism()
	print("combat_test: %d checks, %d failed" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)

func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
	print("%s %s" % ["ok  " if ok else "FAIL", label])

func _tuning() -> CombatTuning:
	return (load(TUNING_PATH) as CombatTuning).duplicate()

func _step(kind_id: StringName, telegraph: float, recovery: float = 3.0) -> AttackStepDefinition:
	var step := AttackStepDefinition.new()
	step.kind_id = kind_id
	step.telegraph_time = telegraph
	step.recovery_time = recovery
	return step

func _definition(steps: Array[AttackStepDefinition], hp: int = 100, damage: int = 10) -> EnemyDefinition:
	var definition := EnemyDefinition.new()
	definition.id = &"test"
	definition.hp = hp
	definition.damage = damage
	definition.pattern = steps
	definition.opening_delay = 0.5
	definition.post_stagger_delay = 0.5
	return definition

func _single(kind_id: StringName, telegraph: float = 1.0, hp: int = 100, damage: int = 10) -> Duel:
	var steps: Array[AttackStepDefinition] = [_step(kind_id, telegraph)]
	return Duel.new(_tuning(), _definition(steps, hp, damage), 1)

func _run(duel: Duel, seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		duel.advance(minf(DT, left))
		left -= DT

func _run_to_telegraph(duel: Duel, probe: Probe) -> void:
	var guard := 0
	while probe.telegraphs.is_empty() and guard < 1000:
		duel.advance(DT)
		guard += 1

func _until_strike(duel: Duel, probe: Probe, count: int = 1) -> void:
	var guard := 0
	while probe.results.size() < count and guard < 2000 and not duel.finished:
		duel.advance(DT)
		guard += 1

func _test_data_loads() -> void:
	var tuning := load(TUNING_PATH) as CombatTuning
	_check(tuning != null and tuning.parry_window > 0.0, "tuning loads")
	for path in ENEMY_PATHS:
		var definition := load(path) as EnemyDefinition
		var valid := definition != null and not definition.pattern.is_empty() and definition.name_key.begins_with("ENEMY_")
		for step in definition.pattern:
			valid = valid and AttackKindCatalog.has(step.kind_id)
		_check(valid, "enemy loads with known kinds: %s" % path)

func _test_parry() -> void:
	var duel := _single(&"quick", 1.0)
	var probe := Probe.new(duel)
	_run_to_telegraph(duel, probe)
	_check(probe.telegraphs[0]["kind"] == &"quick" and is_equal_approx(probe.telegraphs[0]["duration"], 1.0), "telegraph reports kind and duration")
	_run(duel, 0.85)
	_check(duel.try_block(), "block accepted")
	_until_strike(duel, probe)
	var result := probe.results[0]
	_check(result.outcome == StrikeResult.PARRIED, "block just before strike parries")
	_check(result.damage == 0 and duel.player.hp == duel.player.max_hp, "parry deals no damage")
	_check(result.staggers_attacker and duel.enemy.state.id() == StaggeredState.ID, "parry staggers the enemy")
	_check(result.target_hp == duel.player.hp, "result carries target hp")

func _test_block() -> void:
	var duel := _single(&"quick", 1.0)
	var probe := Probe.new(duel)
	_run_to_telegraph(duel, probe)
	_run(duel, 0.55)
	duel.try_block()
	var stamina_before := duel.player.stamina
	_until_strike(duel, probe)
	var result := probe.results[0]
	var chip := roundi(10 * duel.tuning.chip_damage_share)
	_check(result.outcome == StrikeResult.BLOCKED, "early block outside parry window is a plain block")
	_check(result.damage == chip and duel.player.hp == 100 - chip, "block deals chip damage")
	_check(duel.player.stamina <= stamina_before - duel.tuning.block_stamina_cost + 1.0, "block costs stamina")
	_check(duel.enemy.state.id() != StaggeredState.ID, "plain block does not stagger")

func _test_hit() -> void:
	var duel := _single(&"quick", 1.0)
	var probe := Probe.new(duel)
	_until_strike(duel, probe)
	_check(probe.results[0].outcome == StrikeResult.HIT and duel.player.hp == 90, "no block takes full damage")

func _test_late_and_early_block() -> void:
	var duel := _single(&"quick", 1.0)
	var probe := Probe.new(duel)
	_run_to_telegraph(duel, probe)
	duel.try_block()
	duel.try_block_release()
	_until_strike(duel, probe)
	_check(probe.results[0].outcome == StrikeResult.HIT, "block that already ended before the strike does not help")

func _test_heavy() -> void:
	var duel := _single(&"heavy", 1.0)
	var probe := Probe.new(duel)
	_run_to_telegraph(duel, probe)
	_run(duel, 0.55)
	duel.try_block()
	_until_strike(duel, probe)
	var result := probe.results[0]
	var expected := roundi(10 * duel.tuning.guard_break_damage_share)
	_check(result.outcome == StrikeResult.HIT and result.guard_broken, "heavy breaks a plain block")
	_check(result.damage == expected and duel.player.stamina < duel.player.max_stamina, "guard break: reduced damage, stamina drained")
	var parried := _single(&"heavy", 1.0)
	var parry_probe := Probe.new(parried)
	_run_to_telegraph(parried, parry_probe)
	_run(parried, 0.85)
	parried.try_block()
	_until_strike(parried, parry_probe)
	_check(parry_probe.results[0].outcome == StrikeResult.PARRIED, "heavy can still be parried")

func _test_feint() -> void:
	var steps: Array[AttackStepDefinition] = [_step(&"feint", 0.8)]
	var feint_step := steps[0]
	feint_step.imitates = &"quick"
	var duel := Duel.new(_tuning(), _definition(steps), 1)
	var probe := Probe.new(duel)
	_until_strike(duel, probe)
	_check(probe.telegraphs[0]["kind"] == &"quick", "feint telegraph imitates the quick attack")
	var result := probe.results[0]
	_check(result.outcome == StrikeResult.FEINT and result.damage == 0 and result.kind_id == &"feint", "feint resolves with no damage")
	_check(duel.player.hp == duel.player.max_hp and duel.enemy.state.id() == IdleState.ID, "feint changes nothing")

func _combo_duel() -> Duel:
	var step := _step(&"combo", 0.0)
	step.telegraph_times = PackedFloat32Array([0.6, 0.4, 0.4])
	step.strike_gap = 0.1
	var steps: Array[AttackStepDefinition] = [step]
	return Duel.new(_tuning(), _definition(steps, 100, 10), 1)

func _test_combo() -> void:
	var duel := _combo_duel()
	var probe := Probe.new(duel)
	_until_strike(duel, probe, 3)
	var indices: Array[int] = []
	for entry in probe.telegraphs:
		indices.append(entry["index"])
	_check(indices == [0, 1, 2], "combo emits one telegraph per strike with its index")
	_check(is_equal_approx(probe.telegraphs[1]["duration"], 0.4), "each combo strike has its own telegraph time")
	_check(probe.results.size() == 3 and probe.results[2].strike_count == 3, "combo resolves three strikes")
	_check(duel.player.hp == 70, "unblocked combo deals damage per strike")

func _test_combo_parry_ends_chain() -> void:
	var duel := _combo_duel()
	var probe := Probe.new(duel)
	_run_to_telegraph(duel, probe)
	_run(duel, 0.45)
	duel.try_block()
	_until_strike(duel, probe)
	_check(probe.results[0].outcome == StrikeResult.PARRIED, "first combo strike parried")
	_run(duel, 1.0)
	_check(probe.results.size() == 1 and probe.telegraphs.size() == 1, "parry cancels the rest of the combo")

func _test_stamina_gating() -> void:
	var duel := _single(&"quick", 30.0, 1000)
	var probe := Probe.new(duel)
	var cost := duel.tuning.attack_stamina_cost
	var accepted := 0
	for i in 20:
		if duel.try_attack():
			accepted += 1
		_run(duel, duel.tuning.attack_duration + 0.05)
	_check(accepted < 20 and probe.rejections.has("attack:stamina"), "attack refused when stamina is too low")
	duel.player.stamina = cost - 0.5
	_check(not duel.try_attack(), "attack refused just below cost")
	duel.player.stamina = cost
	_check(duel.try_attack(), "attack accepted at exactly the cost")
	_check(is_zero_approx(duel.player.stamina), "attack spends stamina")
	_run(duel, 2.0)
	_check(duel.player.stamina > 20.0 and probe.stamina_events > 0, "stamina regenerates while idle and reports it")

func _test_attack_lock() -> void:
	var duel := _single(&"quick", 1.0)
	var probe := Probe.new(duel)
	_run_to_telegraph(duel, probe)
	_run(duel, 0.5)
	_check(duel.try_attack(), "attack accepted")
	_check(probe.attacks[0]["damage"] == duel.player.damage and probe.attacks[0]["enemy_hp"] == 100 - duel.player.damage, "attack event carries damage and enemy hp")
	_check(not duel.try_block() and probe.rejections.has("block:busy"), "block refused during attack lock")
	_check(not duel.try_attack(), "second attack refused during lock")
	_until_strike(duel, probe)
	_check(probe.results[0].outcome == StrikeResult.HIT, "strike landing during attack lock hits")

func _test_stagger_punish() -> void:
	var duel := _single(&"quick", 1.0)
	var probe := Probe.new(duel)
	_run_to_telegraph(duel, probe)
	_run(duel, 0.85)
	duel.try_block()
	_until_strike(duel, probe)
	_check(duel.try_attack(), "attack during stagger")
	var expected := roundi(duel.player.damage * duel.tuning.punish_multiplier)
	_check(probe.attacks[0]["damage"] == expected, "punish multiplier applies while staggered")
	_run(duel, duel.tuning.stagger_time + 0.1)
	_check(duel.enemy.state.id() == IdleState.ID, "stagger ends")
	duel.try_attack()
	_check(probe.attacks[1]["damage"] == roundi(duel.player.damage * (1.0 + duel.tuning.combo_step * duel.tuning.combo_crit_weight)), "normal damage after stagger")

func _test_input_gate() -> void:
	var duel := _single(&"quick", 1.0)
	var probe := Probe.new(duel)
	duel.input_enabled = false
	_check(not duel.try_attack() and not duel.try_block(), "try_* refused while input is disabled")
	_check(probe.rejections.has("attack:disabled"), "refusal reason reported")
	_check(duel.perform_attack(), "perform_* ignores the gate")
	duel.input_enabled = true
	_run(duel, 1.0)
	_check(duel.try_block(), "try_* works when enabled")

func _test_death() -> void:
	var duel := _single(&"quick", 0.5, 100, 10)
	duel.player.hp = 5
	var probe := Probe.new(duel)
	_until_strike(duel, probe)
	_check(duel.finished and probe.winner == Fighter.ENEMY and probe.finished_count == 1, "player death finishes the duel for the enemy")
	var attack_accepted := duel.try_attack()
	_run(duel, 5.0)
	_check(not attack_accepted and probe.results.size() == 1 and probe.finished_count == 1, "nothing happens after the duel ends")

func _test_victory() -> void:
	var duel := _single(&"quick", 30.0, 15, 10)
	var probe := Probe.new(duel)
	duel.player.damage = 8
	duel.perform_attack()
	_run(duel, 1.0)
	duel.perform_attack()
	_check(duel.finished and probe.winner == Fighter.PLAYER and duel.enemy.hp == 0, "enemy death finishes the duel for the player")

func _test_pattern_order() -> void:
	var steps: Array[AttackStepDefinition] = [_step(&"quick", 0.3, 0.2), _step(&"heavy", 0.3, 0.2), _step(&"feint", 0.3, 0.2)]
	var duel := Duel.new(_tuning(), _definition(steps, 100, 1), 1)
	duel.player.hp = 100000
	duel.player.max_hp = 100000
	var probe := Probe.new(duel)
	_until_strike(duel, probe, 6)
	var ids: Array[StringName] = []
	for result in probe.results:
		ids.append(result.kind_id)
	_check(ids == [&"quick", &"heavy", &"feint", &"quick", &"heavy", &"feint"], "pattern plays in order and loops")

func _test_scaling() -> void:
	var tuning := _tuning()
	var level_one := CombatScaling.new(tuning, 1)
	var level_three := CombatScaling.new(tuning, 3)
	_check(level_one.enemy_hp(100) == 100 and level_three.enemy_hp(100) > 100, "scaling grows enemy hp with level")
	var definition := load(ENEMY_PATHS[0]) as EnemyDefinition
	var duel := Duel.new(tuning, definition, 1, 3)
	_check(duel.enemy.hp == level_three.enemy_hp(definition.hp), "duel applies level scaling")

func _log_of_run(seed_value: int) -> Array[String]:
	var definition := load(ENEMY_PATHS[2]) as EnemyDefinition
	var duel := Duel.new(_tuning(), definition, seed_value)
	var probe := Probe.new(duel)
	for frame in 1800:
		if frame % 37 == 0:
			duel.perform_block()
		if frame % 53 == 0:
			duel.perform_attack()
		duel.advance(DT)
	return probe.log

func _test_determinism() -> void:
	var first := _log_of_run(7)
	var second := _log_of_run(7)
	_check(first.size() > 20 and first == second, "same seed and inputs give an identical event log (%d events)" % first.size())

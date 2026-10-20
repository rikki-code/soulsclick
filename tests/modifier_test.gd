## Headless checks of modifiers, equipment, hold block and revive: godot --headless --path . -s tests/modifier_test.gd
extends SceneTree

const DT := 1.0 / 60.0
const TUNING_PATH := "res://data/tuning/default_tuning.tres"
const ENEMY_PATH := "res://data/enemies/warden.tres"
const EQUIPMENT_DIR := "res://data/equipment/%s.tres"

var _failures := 0
var _checks := 0

class Looper extends Modifier:
	var calls := 0

	func _init(p_reacts: bool) -> void:
		reacts_to_proc = p_reacts

	func id() -> StringName:
		return &"looper"

	func on_damage_dealt(ctx: DamageCtx) -> void:
		calls += 1
		ctx.fx.damage(Fighter.ENEMY, 1)

class Log extends RefCounted:
	var lines: Array[String] = []
	var triggered: Array[StringName] = []
	var revived := 0
	var hp_events := 0

	func _init(duel: Duel) -> void:
		duel.telegraph_started.connect(func(kind: StringName, d: float, i: int) -> void: lines.append("t %s %.3f %d" % [kind, d, i]))
		duel.strike_resolved.connect(func(r: StrikeResult) -> void: lines.append("s %s %d %d %s" % [r.outcome, r.damage, r.target_hp, r.perfect]))
		duel.player_attacked.connect(func(d: int, hp: int) -> void: lines.append("a %d %d" % [d, hp]))
		duel.modifier_triggered.connect(func(mod_id: StringName, side: StringName) -> void: triggered.append(mod_id); lines.append("m %s %s" % [mod_id, side]))
		duel.player_hp_changed.connect(func(hp: int, _m: int) -> void: hp_events += 1; lines.append("p %d" % hp))
		duel.player_revived.connect(func(_hp: int) -> void: revived += 1)

func _initialize() -> void:
	_test_stacking()
	_test_equipment_stats()
	_test_equipment_in_duel()
	_test_guard_break_resist()
	_test_relics()
	_test_phoenix_and_revive()
	_test_affixes()
	_test_depth_cap()
	_test_hold_mode()
	_test_determinism()
	print("modifier_test: %d checks, %d failed" % [_checks, _failures])
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

func _duel(kind_id: StringName = &"quick", telegraph := 1.0, hp := 100, damage := 10, loadout: Loadout = null) -> Duel:
	var steps: Array[AttackStepDefinition] = [_step(kind_id, telegraph)]
	var definition := EnemyDefinition.new()
	definition.id = &"test"
	definition.hp = hp
	definition.damage = damage
	definition.pattern = steps
	definition.opening_delay = 0.5
	definition.post_stagger_delay = 0.5
	var tuning := _tuning()
	var player := Fighter.make_player(tuning)
	if loadout != null:
		loadout.apply_to(player)
	return Duel.new(tuning, definition, 1, 1, player)

func _gear(gear_id: String) -> Equipment:
	return load(EQUIPMENT_DIR % gear_id) as Equipment

func _run(duel: Duel, seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		duel.advance(minf(DT, left))
		left -= DT

func _run_to_telegraph(duel: Duel, log: Log) -> float:
	var guard := 0
	while not log.lines.any(func(l: String) -> bool: return l.begins_with("t ")) and guard < 1000:
		duel.advance(DT)
		guard += 1
	return float(log.lines.filter(func(l: String) -> bool: return l.begins_with("t "))[0].split(" ")[2])

## Presses block so the strike lands `lead` seconds after the press.
func _block_with_lead(duel: Duel, log: Log, lead: float) -> void:
	var duration := _run_to_telegraph(duel, log)
	_run(duel, duration - lead)
	duel.perform_block()

func _strike_lines(log: Log) -> Array:
	return log.lines.filter(func(l: String) -> bool: return l.begins_with("s "))

func _finish_strike(duel: Duel, log: Log) -> void:
	var guard := 0
	while _strike_lines(log).is_empty() and guard < 600 and not duel.finished:
		duel.advance(DT)
		guard += 1

func _test_stacking() -> void:
	var make := func(order: Array) -> float:
		var fighter := Fighter.make_player(_tuning())
		for entry in order:
			fighter.mods.add(entry)
		return fighter.stats.value(CombatStats.ATTACK_COST)
	var plus := func() -> Modifier: return StatModifier.new(CombatStats.ATTACK_COST, Modifier.Stage.ADD, 5.0, &"plus")
	var times := func() -> Modifier: return StatModifier.new(CombatStats.ATTACK_COST, Modifier.Stage.MUL, 2.0, &"times")
	var force := func() -> Modifier: return StatModifier.new(CombatStats.ATTACK_COST, Modifier.Stage.SET, 7.0, &"force")
	var base: float = _tuning().attack_stamina_cost
	_check(is_equal_approx(make.call([plus.call(), times.call()]), (base + 5.0) * 2.0), "add applies before mul")
	_check(is_equal_approx(make.call([times.call(), plus.call()]), (base + 5.0) * 2.0), "acquire order does not change add/mul result")
	_check(is_equal_approx(make.call([force.call(), times.call(), plus.call()]), 7.0), "set wins over add and mul")
	var fighter := Fighter.make_player(_tuning())
	fighter.mods.add(StatModifier.new(CombatStats.ATTACK_COST, Modifier.Stage.MUL, 2.0, &"a"))
	var cached := fighter.stats.value(CombatStats.ATTACK_COST)
	fighter.mods.add(StatModifier.new(CombatStats.ATTACK_COST, Modifier.Stage.ADD, 1.0, &"b"))
	_check(fighter.stats.value(CombatStats.ATTACK_COST) != cached, "adding a modifier invalidates the cache")
	fighter.damage = 8
	_check(fighter.damage == 8, "damage setter overrides the base value")

func _test_equipment_stats() -> void:
	var tuning := _tuning()
	var dagger := Fighter.make_player(tuning)
	Loadout.of(_gear("dagger"), null).apply_to(dagger)
	_check(dagger.stats.value(CombatStats.ATTACK_LOCK) < tuning.attack_duration and dagger.stats.value(CombatStats.ATTACK_COST) < tuning.attack_stamina_cost, "dagger is fast and cheap")
	_check(dagger.damage < tuning.player_damage, "dagger is weak")
	var great := Fighter.make_player(tuning)
	Loadout.of(_gear("greatsword"), null).apply_to(great)
	_check(great.stats.value(CombatStats.ATTACK_LOCK) > tuning.attack_duration and great.stats.value(CombatStats.ATTACK_COST) > tuning.attack_stamina_cost and great.damage > tuning.player_damage, "greatsword is slow, costly, heavy")
	var buckler := Fighter.make_player(tuning)
	Loadout.of(null, _gear("buckler")).apply_to(buckler)
	_check(buckler.stats.value(CombatStats.PARRY_WINDOW) > tuning.parry_window and buckler.stats.value(CombatStats.CHIP_SHARE) > tuning.chip_damage_share, "buckler: wide parry, high chip")
	var tower := Fighter.make_player(tuning)
	Loadout.of(null, _gear("tower_shield")).apply_to(tower)
	_check(tower.stats.value(CombatStats.BLOCK_STARTUP) > 0.0 and tower.stats.value(CombatStats.CHIP_SHARE) < tuning.chip_damage_share and tower.stats.value(CombatStats.GUARD_BREAK_RESIST) > 0.5, "tower: startup, low chip, guard-break resist")
	var armored := Fighter.make_player(tuning)
	Loadout.of(null, null, _gear("light_armor")).apply_to(armored)
	_check(armored.max_stamina > tuning.player_stamina and armored.stamina == armored.max_stamina, "armor raises the stamina pool and refills the gain")
	for gear_id in ["buckler", "kite_shield", "tower_shield", "dagger", "sword", "greatsword", "light_armor", "heavy_armor"]:
		var piece := _gear(gear_id)
		_check(piece != null and piece.id == StringName(gear_id) and not piece.modifiers().is_empty(), "equipment loads: %s" % gear_id)

func _test_equipment_in_duel() -> void:
	var tower := _duel(&"quick", 1.0, 100, 10, Loadout.of(null, _gear("tower_shield")))
	var log := Log.new(tower)
	_block_with_lead(tower, log, 0.05)
	_finish_strike(tower, log)
	_check(_strike_lines(log)[0].begins_with("s hit"), "tower shield: block pressed too late is still starting up and the strike hits")
	var plain := _duel(&"quick", 1.0)
	var plain_log := Log.new(plain)
	_block_with_lead(plain, plain_log, 0.3)
	_finish_strike(plain, plain_log)
	_check(_strike_lines(plain_log)[0].begins_with("s blocked"), "default shield: 0.3 s lead is a plain block")
	var buckler := _duel(&"quick", 1.0, 100, 10, Loadout.of(null, _gear("buckler")))
	var buckler_log := Log.new(buckler)
	_block_with_lead(buckler, buckler_log, 0.3)
	_finish_strike(buckler, buckler_log)
	_check(_strike_lines(buckler_log)[0].begins_with("s parried"), "buckler: 0.3 s lead is a parry")
	var early := _duel(&"quick", 1.0, 100, 10, Loadout.of(null, _gear("tower_shield")))
	var early_log := Log.new(early)
	_block_with_lead(early, early_log, 0.2)
	_finish_strike(early, early_log)
	_check(_strike_lines(early_log)[0].begins_with("s parried"), "tower shield parries when pressed early enough")

func _test_guard_break_resist() -> void:
	var plain := _duel(&"heavy", 1.0, 100, 10)
	var plain_log := Log.new(plain)
	_block_with_lead(plain, plain_log, 0.4)
	_finish_strike(plain, plain_log)
	var tower := _duel(&"heavy", 1.0, 100, 10, Loadout.of(null, _gear("tower_shield")))
	var tower_log := Log.new(tower)
	_block_with_lead(tower, tower_log, 0.4)
	_finish_strike(tower, tower_log)
	var plain_damage := int(_strike_lines(plain_log)[0].split(" ")[2])
	var tower_damage := int(_strike_lines(tower_log)[0].split(" ")[2])
	_check(tower_damage < plain_damage, "tower shield takes less from a guard break (%d < %d)" % [tower_damage, plain_damage])

func _test_relics() -> void:
	var menders := _duel()
	menders.player.mods.add(ModifierCatalog.create(MendersThread.ID))
	menders.player.hp = 50
	var log := Log.new(menders)
	_block_with_lead(menders, log, 0.1)
	_finish_strike(menders, log)
	_check(menders.player.hp == 53 and log.triggered == [MendersThread.ID], "menders thread heals on parry and announces itself")
	var perfect := _duel()
	perfect.player.mods.add(ModifierCatalog.create(MendersThread.ID))
	perfect.player.hp = 50
	var perfect_log := Log.new(perfect)
	_block_with_lead(perfect, perfect_log, 0.24)
	_finish_strike(perfect, perfect_log)
	_check(perfect.player.hp == 56 and _strike_lines(perfect_log)[0].ends_with("true"), "perfect parry doubles the heal")
	var tide := _duel()
	tide.player.mods.add(ModifierCatalog.create(CounterTide.ID))
	var tide_log := Log.new(tide)
	_block_with_lead(tide, tide_log, 0.1)
	_finish_strike(tide, tide_log)
	_check(tide.enemy.hp < tide.enemy.max_hp, "counter tide ripostes after a parry")
	var glass := _duel()
	glass.player.mods.add(ModifierCatalog.create(GlassBlade.ID))
	glass.perform_attack()
	_check(glass.enemy.max_hp - glass.enemy.hp == 5, "glass blade raises damage dealt (3 -> 5)")
	var taken := _duel()
	taken.player.mods.add(ModifierCatalog.create(GlassBlade.ID))
	var taken_log := Log.new(taken)
	_run_to_telegraph(taken, taken_log)
	_finish_strike(taken, taken_log)
	_check(taken.player.max_hp - taken.player.hp == 14, "glass blade raises damage taken (10 -> 14)")
	var over := _duel()
	over.player.mods.add(ModifierCatalog.create(Overreach.ID))
	over.perform_attack()
	_check(is_equal_approx(over.player.stamina, 100.0 - 10.0 * 1.5) and over.enemy.max_hp - over.enemy.hp == 5, "overreach costs more and hits harder")
	var pride := _duel()
	pride.player.mods.add(ModifierCatalog.create(DuelistsPride.ID))
	pride.player.damage = 20
	var pride_log := Log.new(pride)
	_block_with_lead(pride, pride_log, 0.1)
	_finish_strike(pride, pride_log)
	_check(pride.player.damage == 22, "duelist's pride grows damage per parry")
	var no_proc := _duel()
	var looker := Looper.new(false)
	no_proc.player.mods.add(looker)
	no_proc.perform_attack()
	_check(looker.calls == 1, "modifiers ignore proc events unless they opt in")

func _test_phoenix_and_revive() -> void:
	var duel := _duel(&"quick", 0.3, 100, 10)
	duel.player.mods.add(ModifierCatalog.create(PhoenixAsh.ID))
	duel.player.hp = 5
	var log := Log.new(duel)
	_run(duel, 1.5)
	_check(not duel.finished and duel.player.hp == 35, "phoenix ash survives the first lethal blow with 35% hp")
	duel.player.hp = 5
	_run(duel, 4.0)
	_check(duel.finished and duel.winner == Fighter.ENEMY, "phoenix ash works once")
	var enemy_hp := duel.enemy.hp
	_check(duel.revive_player(0.5), "revive after death is accepted")
	_check(not duel.finished and duel.winner == &"" and duel.player.hp == 50 and log.revived == 1, "revive continues the same duel at the given hp")
	_check(duel.enemy.hp == enemy_hp and duel.enemy.state.id() == IdleState.ID, "revive keeps enemy hp and resets it to idle")
	var results_before := _strike_lines(log).size()
	_run(duel, 1.0)
	_check(_strike_lines(log).size() == results_before, "enemy waits during the grace delay")
	_run(duel, 3.0)
	_check(_strike_lines(log).size() > results_before, "enemy attacks again after the grace delay")
	_check(not _duel().revive_player(0.5), "revive is refused while the player lives")
	var winning := _duel(&"quick", 5.0, 3, 10)
	winning.perform_attack()
	_check(winning.finished and not winning.revive_player(0.5), "revive is refused after a player victory")

func _test_affixes() -> void:
	var duel := _duel(&"quick", 1.0, 100, 10)
	duel.enemy.mods.add(ModifierCatalog.create(SwiftAffix.ID))
	duel.enemy.mods.add(ModifierCatalog.create(PlatedAffix.ID))
	var log := Log.new(duel)
	var duration := _run_to_telegraph(duel, log)
	_check(is_equal_approx(duration, 0.75), "swift shortens the telegraph")
	_check(duel.enemy.max_hp == 140 and duel.enemy.hp == 140, "plated raises enemy hp")
	var before := duel.enemy.hp
	duel.player.damage = 10
	duel.perform_attack()
	_check(before - duel.enemy.hp == 9 or before - duel.enemy.hp == 8, "plated reduces damage taken")

func _test_depth_cap() -> void:
	var duel := _duel()
	var looper := Looper.new(true)
	duel.player.mods.add(looper)
	duel.perform_attack()
	_check(looper.calls == 5, "proc chain stops at depth 4 (%d hook calls)" % looper.calls)
	_check(duel.enemy.max_hp - duel.enemy.hp == 3 + ModifierStack.MAX_DEPTH, "only four chained procs land")

func _test_hold_mode() -> void:
	var duel := _duel(&"quick", 1.5)
	var log := Log.new(duel)
	var timings: Array[float] = []
	duel.strike_timing.connect(func(strike_in: float, window: float, _k: StringName, _i: int) -> void: timings.append(strike_in); timings.append(window))
	_run(duel, 0.2)
	_check(duel.perform_block() and duel.player.state.id() == BlockingState.ID, "press raises the guard")
	_run(duel, 1.0)
	_check(duel.player.state.id() == BlockingState.ID, "guard outlasts block_min_duration while held")
	_check(is_equal_approx(duel.player.stamina, duel.player.max_stamina), "no stamina drain while held")
	_finish_strike(duel, log)
	_check(_strike_lines(log)[0].begins_with("s blocked"), "a long-held guard blocks the strike")
	_check(duel.player.stamina < duel.player.max_stamina - 10.0, "a blocked hit costs stamina by damage")
	_check(timings.size() >= 2 and is_equal_approx(timings[0], 1.5) and is_equal_approx(timings[1], 0.25), "strike_timing carries strike_in and parry window")
	_check(duel.try_block_release() and duel.player.state.id() == IdleState.ID and duel.player.block_cooldown > 0.0, "release after the minimum lowers the guard at once")
	_check(not duel.try_block_release(), "release without a guard is ignored")
	var early := _duel()
	early.perform_block()
	early.perform_block_release()
	_check(early.player.state.id() == BlockingState.ID, "early release keeps the guard for block_min_duration")
	_run(early, 0.6)
	_check(early.player.state.id() == IdleState.ID, "guard ends at press + block_min_duration")
	var attacker := _duel()
	attacker.perform_block()
	_check(attacker.perform_attack() and attacker.player.state.id() == AttackingState.ID, "attacking while holding drops the block")
	var parry := _duel(&"quick", 1.0)
	var parry_log := Log.new(parry)
	_block_with_lead(parry, parry_log, 0.1)
	_finish_strike(parry, parry_log)
	_check(_strike_lines(parry_log)[0].begins_with("s parried") and parry.player.state.id() == IdleState.ID, "fresh press parries and frees the player")
	var broken := _duel(&"quick", 1.0)
	var broken_log := Log.new(broken)
	_block_with_lead(broken, broken_log, 0.4)
	broken.player.stamina = 10.0
	_finish_strike(broken, broken_log)
	_check(_strike_lines(broken_log)[0].begins_with("s hit") and broken.player.stamina < 1.0 and broken.player.state.id() == IdleState.ID, "stamina out: guard breaks and drops")

func _run_all_relics(seed_value: int) -> Array[String]:
	var tuning := _tuning()
	var definition := load(ENEMY_PATH) as EnemyDefinition
	var player := Fighter.make_player(tuning)
	Loadout.of(_gear("sword"), _gear("buckler"), _gear("light_armor")).apply_to(player)
	for relic_id in ModifierCatalog.relic_ids():
		player.mods.add(ModifierCatalog.create(relic_id))
	var duel := Duel.new(tuning, definition, seed_value, 1, player)
	duel.enemy.mods.add(ModifierCatalog.create(SwiftAffix.ID))
	var log := Log.new(duel)
	for frame in 1800:
		if frame % 37 == 0:
			duel.perform_block()
		if frame % 53 == 0:
			duel.perform_attack()
		duel.advance(DT)
	return log.lines

func _test_determinism() -> void:
	var first := _run_all_relics(7)
	var second := _run_all_relics(7)
	_check(first.size() > 20 and first == second, "same seed and inputs give an identical log with every relic (%d events)" % first.size())

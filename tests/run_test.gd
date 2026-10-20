## Headless checks of the run model: godot --headless --path . -s tests/run_test.gd
extends SceneTree

const SEED_SAMPLES := 400
const MAX_ACTIONS := 64
const COMBAT_HP_LOSS := 7

var _failures := 0
var _checks := 0
var _realms: Array[RealmDefinition] = []

func _initialize() -> void:
	_realms = RealmCatalog.default_realms()
	_test_seed_code()
	_test_realm_definition()
	_test_determinism()
	_test_order_independence()
	_test_door_rules()
	_test_boss_at_end()
	_test_room_plans()
	_test_events_and_hp()
	_test_save_round_trip()
	_test_embers()
	print("RUN %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		return
	_failures += 1
	print("RUN FAIL: %s" % label)

func _new_run(run_seed: int, config_edit := Callable()) -> Run:
	var config := RunConfig.new(run_seed)
	if config_edit.is_valid():
		config_edit.call(config)
	return Run.new(config, _realms)

## One action: omen pick, door pick or room completion. Returns false when the run is over.
func _act(run: Run, last_door: bool, log: Array[String]) -> bool:
	if run.phase == Run.PHASE_OMEN:
		run.choose_omen(0)
		log.append("omen %s" % run.omen.id)
	elif run.phase == Run.PHASE_DOORS:
		var sigs: Array[String] = []
		for door in run.offer.doors:
			sigs.append(door.signature())
		log.append("doors %d/%d %s" % [run.offer.realm_index, run.offer.step_index, ",".join(sigs)])
		var plan := run.choose_door(run.offer.doors.size() - 1 if last_door else 0)
		log.append("plan %s %d hp%d x%.2f s%d %s" % [plan.kind_id, plan.combat_seed, plan.player_hp, plan.hp_multiplier, plan.souls_reward, JSON.stringify(plan.data)])
	elif run.phase == Run.PHASE_ROOM:
		var loss := COMBAT_HP_LOSS if run.plan.is_combat else 0
		run.complete_room(RoomResult.victory(maxi(run.hp - loss, 1)))
		log.append("done hp%d souls%d" % [run.hp, run.souls])
	return not run.is_ended()

func _drive(run: Run, last_door: bool, actions: int, log: Array[String]) -> void:
	for i in actions:
		if not _act(run, last_door, log):
			break

func _test_seed_code() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var ok := true
	for i in SEED_SAMPLES:
		var value := SeedCode.random_seed(rng)
		var code := SeedCode.encode(value)
		ok = ok and SeedCode.decode(code) == value and SeedCode.decode(code.to_lower().replace("-", " ")) == value
		ok = ok and code.length() == 8 and code[3] == "-"
	_check(ok, "seed code round trip")
	_check(SeedCode.decode("ASH-0000") == 0, "seed code zero")
	_check(SeedCode.decode(SeedCode.encode(SeedCode.SEED_MAX)) == SeedCode.SEED_MAX, "seed code max")
	_check(SeedCode.decode("ZZZ-1234") == SeedCode.INVALID, "unknown word rejected")
	_check(SeedCode.decode("ASH-12U4") == SeedCode.INVALID, "bad character rejected")
	_check(SeedCode.decode("ASH-12") == SeedCode.INVALID, "short code rejected")
	_check(SeedCode.decode("ASH-OIL0") == SeedCode.decode("ASH-0110"), "lookalike characters")
	_check(RunConfig.new(SeedCode.SEED_MAX + 5).seed <= SeedCode.SEED_MAX, "config masks seed")

func _test_realm_definition() -> void:
	_check(_realms.size() == 1 and _realms[0] != null, "realm_1 loads")
	_check(_realms[0].validate().is_empty(), "realm_1 sound: %s" % [_realms[0].validate()])
	_check(_realms[0].step_count() == 5, "realm_1 has 5 steps")
	for kind_id in RoomKindCatalog.ids():
		_check(RoomKindCatalog.get_kind(kind_id).id() == kind_id, "catalog id matches %s" % kind_id)
	_check(not RoomKindCatalog.has(&"nope"), "unknown kind not in catalog")

func _test_determinism() -> void:
	var same := true
	var differ := false
	for run_seed in 60:
		var a: Array[String] = []
		var b: Array[String] = []
		var c: Array[String] = []
		_drive(_new_run(run_seed), false, MAX_ACTIONS, a)
		_drive(_new_run(run_seed), false, MAX_ACTIONS, b)
		_drive(_new_run(run_seed + 1000), false, MAX_ACTIONS, c)
		same = same and a == b
		differ = differ or a != c
	_check(same, "same seed, same run")
	_check(differ, "different seeds differ")
	var a_omens := Omen.roll(5)
	_check(a_omens.size() == 2 and a_omens[0].id != a_omens[1].id and a_omens[0].tags.size() == 2, "two distinct omens of two tags")
	_check(Omen.roll(5)[0].id == a_omens[0].id, "omen roll deterministic")
	_check(RunRng.seed_for(1, RunRng.MAP, 0, 1) != RunRng.seed_for(1, RunRng.REWARD, 0, 1), "purpose separates streams")

func _doors_by_step(run_seed: int, last_door: bool) -> Array[String]:
	var run := _new_run(run_seed)
	var log: Array[String] = []
	_drive(run, last_door, MAX_ACTIONS, log)
	var doors: Array[String] = []
	for line in log:
		if line.begins_with("doors "):
			doors.append(line)
	return doors

func _test_order_independence() -> void:
	var ok := true
	for run_seed in 80:
		ok = ok and _doors_by_step(run_seed, false) == _doors_by_step(run_seed, true)
	_check(ok, "doors do not depend on earlier door choices")

func _test_door_rules() -> void:
	var realm := _realms[0]
	var ok_count := true
	var ok_unique := true
	var ok_required := true
	var ok_boss := true
	var ok_preview := true
	var ok_index := true
	var counts := {}
	var elites := 0
	for run_seed in SEED_SAMPLES:
		var run := _new_run(run_seed)
		run.choose_omen(0)
		for step in realm.step_count():
			run.step_index = step
			var offer := DoorGenerator.generate(run)
			var sigs := {}
			var kinds: Array[StringName] = []
			counts[offer.doors.size()] = int(counts.get(offer.doors.size(), 0)) + 1
			ok_count = ok_count and offer.doors.size() >= 1 and offer.doors.size() <= 3
			for door in offer.doors:
				ok_unique = ok_unique and not sigs.has(door.signature())
				sigs[door.signature()] = true
				kinds.append(door.kind_id)
				ok_boss = ok_boss and ((door.kind_id == &"boss") == (step == realm.step_count() - 1))
				ok_preview = ok_preview and door.preview.has("rewards") and door.preview["kind"] == door.kind_id
				ok_index = ok_index and offer.doors[door.index] == door
				if door.kind_id == &"elite":
					elites += 1
					ok_preview = ok_preview and door.affix_id != &""
			for required in realm.rule_at(step).required_kinds:
				ok_required = ok_required and kinds.has(required)
			if step == realm.step_count() - 1:
				ok_boss = ok_boss and offer.doors.size() == 1
	_check(ok_count, "1..3 doors per step")
	_check(ok_unique, "no two identical doors")
	_check(ok_required, "required kinds offered")
	_check(ok_boss, "boss only on the last step, alone")
	_check(ok_preview, "previews carry kind, rewards, affix for elites")
	_check(ok_index, "door indices match positions")
	_check(counts.has(1) and counts.has(2) and counts.has(3), "door count varies: %s" % [counts])
	_check(elites >= SEED_SAMPLES, "elite offered in every realm")

func _test_boss_at_end() -> void:
	var run := _new_run(3)
	var log: Array[String] = []
	_drive(run, false, MAX_ACTIONS, log)
	_check(run.is_ended() and run.summary.victory, "full run ends in victory")
	_check(run.history.size() == 5 and run.history[-1]["kind"] == &"boss", "boss is the last room")
	_check(run.summary.realm_reached == 1 and run.summary.rooms_cleared == 5, "summary position")
	var two: Array[RealmDefinition] = [_realms[0], _realms[0]]
	var long_run := Run.new(RunConfig.new(3), two)
	_drive(long_run, false, MAX_ACTIONS, [] as Array[String])
	_check(long_run.is_ended() and long_run.history.size() == 10 and long_run.summary.realm_reached == 2, "two realms chain before victory")
	_check(long_run.history[4]["kind"] == &"boss" and long_run.history[9]["kind"] == &"boss", "boss closes each realm")

func _first_plan_of(kind_id: StringName) -> RoomPlan:
	for run_seed in SEED_SAMPLES:
		var run := _new_run(run_seed)
		run.choose_omen(0)
		for step in _realms[0].step_count():
			run.step_index = step
			run.offer = DoorGenerator.generate(run)
			for door in run.offer.doors:
				if door.kind_id == kind_id:
					return RoomKindCatalog.get_kind(kind_id).enter(run, door)
	return null

func _test_room_plans() -> void:
	var fight := _first_plan_of(&"fight")
	_check(fight != null and fight.enemy != null and fight.is_combat and fight.souls_reward == fight.enemy.souls_reward, "fight plan")
	_check(fight.data.has("pick") and fight.data.has("offer_seed"), "fight pick rolled")
	var elite := _first_plan_of(&"elite")
	_check(elite.affix_id != &"" and is_equal_approx(elite.hp_multiplier, 1.3) and elite.souls_reward == roundi(elite.enemy.souls_reward * 2.0), "elite plan")
	var boss := _first_plan_of(&"boss")
	_check(boss.enemy == _realms[0].boss and boss.data.get("boss", false), "boss plan")
	for kind_id in [&"altar", &"shop", &"bonfire"]:
		var plan := _first_plan_of(kind_id)
		_check(plan != null and not plan.is_combat and plan.enemy == null and not plan.data.is_empty(), "%s plan data" % kind_id)
	_check(_first_plan_of(&"shop").data.has("heal_price"), "shop placeholder prices")
	var run := _new_run(11)
	run.choose_omen(0)
	var seeds := {}
	var door_total := 0
	for step in _realms[0].step_count():
		run.step_index = step
		run.offer = DoorGenerator.generate(run)
		for door in run.offer.doors:
			var entered := RoomKindCatalog.get_kind(door.kind_id).enter(run, door)
			if entered.is_combat:
				door_total += 1
				seeds[entered.combat_seed] = true
	_check(seeds.size() == door_total, "combat seeds differ per door: %d of %d" % [seeds.size(), door_total])
	var a := _first_plan_of(&"fight")
	var b := _first_plan_of(&"fight")
	_check(a.combat_seed == b.combat_seed and a.enemy == b.enemy, "plans repeat for the same seed")

class EventLog extends RefCounted:
	var omens := 0
	var chosen := 0
	var realms := 0
	var offers := 0
	var entered := 0
	var completed := 0
	var ended := 0
	var hp_deltas := 0
	var souls_deltas := 0
	var last_summary: RunSummary

	func _init(run: Run) -> void:
		run.omens_offered.connect(func(_o: Array[Omen]) -> void: omens += 1)
		run.omen_chosen.connect(func(_o: Omen) -> void: chosen += 1)
		run.realm_started.connect(func(_i: int, _id: StringName, _n: int) -> void: realms += 1)
		run.doors_offered.connect(func(_o: DoorOffer) -> void: offers += 1)
		run.room_entered.connect(func(_p: RoomPlan) -> void: entered += 1)
		run.room_completed.connect(func(_r: Dictionary) -> void: completed += 1)
		run.hp_changed.connect(func(_h: int, _m: int, _d: int) -> void: hp_deltas += 1)
		run.souls_changed.connect(func(_s: int, _d: int) -> void: souls_deltas += 1)
		run.run_ended.connect(func(s: RunSummary) -> void:
			ended += 1
			last_summary = s)

func _test_events_and_hp() -> void:
	var run := _new_run(21)
	var events := EventLog.new(run)
	run.resume()
	_check(events.omens == 1, "resume offers omens")
	_check(not run.choose_door(0) and run.phase == Run.PHASE_OMEN, "door before omen refused")
	_check(run.choose_omen(0) and not run.choose_omen(0), "omen picked once")
	_check(events.chosen == 1 and events.realms == 1 and events.offers == 1, "omen starts realm 1 with doors")
	_check(run.choose_door(99) == null, "bad door index refused")
	var plan := run.choose_door(0)
	_check(plan.player_hp == 100 and events.entered == 1, "room entered with full hp")
	_check(not run.complete_room(RoomResult.victory(60)) == false and run.hp == 60, "hp carries out of the room")
	_check(events.completed == 1 and events.hp_deltas == 1 and events.souls_deltas == 1 and events.offers == 2, "events per room")
	var next_plan := run.choose_door(0)
	_check(next_plan.player_hp == 60, "hp carries into the next room")
	run.plan.enemy = _realms[0].boss
	_check(not run.complete_room(RoomResult.defeat()) == false and run.is_ended(), "defeat ends the run")
	_check(events.ended == 1 and events.last_summary.outcome_id == &"death" and events.last_summary.killer_enemy_id != &"", "death summary names the killer")
	_check(run.choose_door(0) == null and not run.complete_room(RoomResult.victory()), "ended run refuses input")
	var heal_run := _new_run(21)
	heal_run.hp = 50
	heal_run.heal(1000)
	_check(heal_run.hp == 100, "heal clamps to max")
	heal_run.add_souls(-500)
	_check(heal_run.souls == 0, "souls never negative")

func _test_save_round_trip() -> void:
	var ok := true
	var rooms_ok := true
	for run_seed in [0, 1, 2, 9, 123, 4567]:
		for last_door in [false, true]:
			var full_log: Array[String] = []
			var full := _new_run(run_seed)
			_drive(full, last_door, MAX_ACTIONS, full_log)
			var cuts := full_log.size()
			for cut in range(0, 16):
				var head: Array[String] = []
				var first := _new_run(run_seed)
				_drive(first, last_door, cut, head)
				var text := JSON.stringify(first.to_dict())
				var parsed: Variant = JSON.parse_string(text)
				var restored := Run.from_dict(parsed, _realms)
				if restored == null:
					rooms_ok = false
					continue
				ok = ok and JSON.stringify(restored.to_dict()) == text
				var tail_a: Array[String] = []
				var tail_b: Array[String] = []
				_drive(first, last_door, MAX_ACTIONS, tail_a)
				_drive(restored, last_door, MAX_ACTIONS, tail_b)
				ok = ok and tail_a == tail_b and JSON.stringify(first.to_dict()) == JSON.stringify(restored.to_dict())
				ok = ok and head + tail_b == full_log
				if first.is_ended():
					ok = ok and JSON.stringify(first.summary.to_dict()) == JSON.stringify(restored.summary.to_dict())
			_check(cuts > 0, "log recorded")
	_check(rooms_ok, "saves restore")
	_check(ok, "mid-run save/load continues identically (all phases)")
	var empty: Array[RealmDefinition] = []
	_check(Run.from_dict({"version": 99}, _realms) == null, "unknown version dropped")
	_check(Run.from_dict(_new_run(1).to_dict(), empty) == null, "no realms dropped")
	var mid := _new_run(5)
	mid.choose_omen(0)
	mid.choose_door(0)
	var data := mid.to_dict()
	data["door"] = 77
	_check(Run.from_dict(data, _realms) == null, "bad pending door dropped")
	var ended := _new_run(5)
	ended.abandon()
	var again := Run.from_dict(JSON.parse_string(JSON.stringify(ended.to_dict())), _realms)
	_check(again.is_ended() and again.summary.outcome_id == &"abandon", "ended run restores its summary")

func _run_with_souls(souls: int, edit := Callable()) -> Run:
	var run := _new_run(8, edit)
	run.choose_omen(0)
	run.add_souls(souls)
	return run

func _test_embers() -> void:
	var dead := _run_with_souls(101)
	dead.choose_door(0)
	dead.complete_room(RoomResult.defeat())
	_check(dead.summary.embers == 50 and is_equal_approx(dead.summary.bank_rate, 0.5), "death banks 50%% (floor): %d" % dead.summary.embers)
	var abandoned := _run_with_souls(40)
	abandoned.abandon()
	_check(abandoned.summary.embers == 20 and abandoned.summary.outcome_id == &"abandon" and not abandoned.summary.victory, "abandon banks 50%")
	var upgraded := _run_with_souls(100, func(c: RunConfig) -> void: c.death_bank_rate = 0.8)
	upgraded.abandon()
	_check(upgraded.summary.embers == 80, "upgraded bank rate")
	var won := _new_run(8)
	_drive(won, false, MAX_ACTIONS, [] as Array[String])
	_check(won.summary.victory and won.summary.embers == won.souls and won.souls > 0, "victory banks 100%%: %d of %d" % [won.summary.embers, won.souls])
	_check(won.summary.seed_code == SeedCode.encode(8) and won.summary.omen_id == won.omen.id, "summary carries seed code and omen")
	var start := _new_run(8, func(c: RunConfig) -> void: c.start_souls = 30)
	_check(start.souls == 30, "start souls")
	var shop := _new_run(8)
	shop.choose_omen(0)
	shop.add_souls(50)
	var spend := RoomResult.victory()
	spend.souls_spent = 500
	shop.step_index = 0
	shop.phase = Run.PHASE_ROOM
	shop.plan = _first_plan_of(&"shop")
	shop.complete_room(spend)
	_check(shop.souls == 0, "spending is capped at held souls")

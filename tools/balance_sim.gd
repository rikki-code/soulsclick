## Run-depth balance sim: godot --headless --path . -s tools/balance_sim.gd [-- trials [max_node]]
## A bot with a level profile walks nodes 0..max_node (rooms entered, like Run) over the real realms, depth curve,
## enemies and tuning. Prints per-node survival (share of trials that cleared the node) and the median death node.
extends SceneTree

const DT := 1.0 / 60.0
const MAX_DUEL_SECONDS := 120.0
const DEFAULT_TRIALS := 30
const DEFAULT_MAX_NODE := 40
const TUNING_PATH := "res://data/tuning/default_tuning.tres"
const EQUIPMENT_PATH := "res://data/equipment/%s.tres"
const PERMANENT_PATH := "res://data/progression/permanent_levels.tres"
const RUN_PATH := "res://data/progression/run_levels.tres"
const PROFILES_PATH := "res://data/progression/balance_profiles.json"
const REALM_PATHS := [
	"res://data/realms/realm_1.tres", "res://data/realms/realm_2.tres",
	"res://data/realms/realm_3.tres", "res://data/realms/realm_4.tres",
]
const START_WEAPON := "sword"
const START_SHIELD := "kite_shield"
## Heal when HP is under this share: take a bonfire if the step offers one.
const REST_BELOW := 0.6
## Between rooms the bot drinks a flask (data/items/flask.tres heal share) when under this hp share.
const FLASK_BELOW := 0.45
const FLASK_PATH := "res://data/items/flask.tres"
const COMBAT_KINDS: Array[StringName] = [&"fight", &"elite", &"boss"]

## Level profiles (per stat, same level for every stat); `perm` = Embers levels, `run` = Souls/ad levels.
## Read from data/progression/balance_profiles.json so the level cap lives in data.
var _profiles := {}
## Print where and against whom each run died (third arg "log").
var _log := false
var _label := ""
var _flask_share := 0.35
var _tuning: CombatTuning
var _realms: Array[RealmDefinition] = []
var _perm_table: StatLevelTable
var _run_table: StatLevelTable

class Bot extends RefCounted:
	var noise := 0.05
	## Seconds added to the press time: positive = pressed late (the strike beats the guard).
	var bias := 0.0
	var _rng: RandomNumberGenerator
	var _press_at := -1.0

	func _init(p_noise: float, p_bias: float) -> void:
		noise = p_noise
		bias = p_bias

	func attach(duel: Duel, rng: RandomNumberGenerator) -> void:
		_rng = rng
		_press_at = -1.0
		duel.telegraph_started.connect(_on_telegraph.bind(duel))
		duel.strike_resolved.connect(func(_r: StrikeResult) -> void: _press_at = -1.0)

	func _on_telegraph(_kind: StringName, duration: float, _index: int, duel: Duel) -> void:
		var stats := duel.player.stats
		var lead := stats.value(CombatStats.BLOCK_STARTUP) + stats.value(CombatStats.PARRY_WINDOW) * 0.5
		_press_at = duel.time + duration - lead + bias + _rng.randfn(0.0, noise)

	func think(duel: Duel) -> void:
		if _press_at >= 0.0 and duel.time >= _press_at:
			_press_at = -1.0
			duel.perform_block()
			duel.perform_block_release()
			return
		var safe := _press_at < 0.0 or duel.time + duel.player.stats.value(CombatStats.ATTACK_LOCK) + 0.05 < _press_at
		if safe and not duel.player.state is BlockingState:
			duel.perform_attack()

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var trials := int(args[0]) if args.size() > 0 else DEFAULT_TRIALS
	var max_node := int(args[1]) if args.size() > 1 else DEFAULT_MAX_NODE
	_flask_share = (load(FLASK_PATH) as ConsumableItem).heal_share
	_log = args.size() > 2 and args[2] == "log"
	_tuning = load(TUNING_PATH) as CombatTuning
	_perm_table = load(PERMANENT_PATH) as StatLevelTable
	_run_table = load(RUN_PATH) as StatLevelTable
	for path in REALM_PATHS:
		_realms.append(load(path) as RealmDefinition)
	_profiles = JSON.parse_string(FileAccess.get_file_as_string(PROFILES_PATH))
	var bots := {"good": [0.05, 0.0], "bad": [0.12, 0.10]}
	var summary: Array[String] = []
	var table := {}
	for profile in _profiles:
		for bot_name in bots:
			var cfg: Array = bots[bot_name]
			var reached: Array[int] = []
			_label = "%s/%s" % [profile, bot_name]
			for trial in trials:
				reached.append(_run_one(profile, cfg[0], cfg[1], trial, max_node))
			reached.sort()
			table["%s/%s" % [profile, bot_name]] = reached
			summary.append("%-12s median node %2d  p25 %2d  p75 %2d  max %2d" % [
				"%s/%s" % [profile, bot_name], reached[reached.size() / 2], reached[reached.size() / 4],
				reached[reached.size() * 3 / 4], reached[-1]])
	var header := "node  " + "  ".join(table.keys().map(func(k: String) -> String: return "%-12s" % k))
	print(header)
	for node in range(0, max_node + 1, 2):
		var row := "%3d   " % node
		for key in table:
			var reached: Array = table[key]
			var cleared := 0
			for value in reached:
				if value > node:
					cleared += 1
			row += "  %-12s" % ("%3d%%" % roundi(100.0 * cleared / reached.size()))
		print(row)
	for line in summary:
		print(line)
	quit()

## One run: returns the node index the bot died on (max_node + 1 if it cleared them all).
func _run_one(profile: String, noise: float, bias: float, trial: int, max_node: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + trial
	var player := _make_player(_profiles[profile])
	var steps := _realms[0].step_count()
	var flasks := int(_profiles[profile].get("flasks", 0))
	for node in max_node + 1:
		var depth := node / steps
		var step := node % steps
		var realm := _realms[depth % _realms.size()]
		var kind := _pick_kind(realm, step, player, rng)
		if kind == &"bonfire":
			player.heal(roundi(player.max_hp * realm.bonfire_heal_share))
			continue
		if not COMBAT_KINDS.has(kind):
			continue
		if flasks > 0 and player.hp < player.max_hp * FLASK_BELOW:
			flasks -= 1
			player.heal(roundi(player.max_hp * _flask_share))
		if not _fight_room(realm, kind, depth, node, player, noise, bias, rng, 5000 + trial * 997 + node):
			return node
		var heal_share := realm.boss_heal_share if kind == &"boss" else 0.0
		if heal_share > 0.0:
			player.heal(roundi(player.max_hp * heal_share))
	return max_node + 1

func _make_player(profile: Dictionary) -> Fighter:
	var player := Fighter.make_player(_tuning)
	Loadout.of(load(EQUIPMENT_PATH % START_WEAPON) as Equipment, load(EQUIPMENT_PATH % START_SHIELD) as Equipment).apply_to(player)
	var perm := StatLevels.new(_perm_table)
	var run_levels := StatLevels.new(_run_table)
	for stat in _perm_table.stat_ids():
		perm.levels[stat] = int(profile.get("perm", 0))
	for stat in _run_table.stat_ids():
		run_levels.levels[stat] = int(profile.get("run", 0))
	perm.apply_to(player, &"perm_levels")
	run_levels.apply_to(player, &"run_levels")
	player.reset_pools()
	return player

## Bot choice among the step's doors: bonfire when hurt, else the first combat kind from the weights (fight over elite).
func _pick_kind(realm: RealmDefinition, step: int, player: Fighter, rng: RandomNumberGenerator) -> StringName:
	var rule := realm.rule_at(step)
	var kinds: Array[StringName] = []
	for kind in rule.required_kinds:
		kinds.append(kind)
	var all: Array[StringName] = []
	var weights: Array[float] = []
	for kind in rule.kind_weights:
		all.append(kind)
		weights.append(float(rule.kind_weights[kind]))
	# The other doors are weighted draws (door count 2 = the required kinds plus one more kind).
	for attempt in 6:
		if kinds.size() >= 2 or all.is_empty():
			break
		var picked := WeightedPick.index(rng, weights)
		if picked >= 0 and not kinds.has(all[picked]):
			kinds.append(all[picked])
	if kinds.has(&"bonfire") and player.hp < player.max_hp * REST_BELOW:
		return &"bonfire"
	for kind in [&"fight", &"elite", &"boss"]:
		if kinds.has(kind):
			return kind
	return kinds[0] if not kinds.is_empty() else &""

## Whole room (wave): true when the player survives every enemy.
func _fight_room(realm: RealmDefinition, kind: StringName, depth: int, node: int, player: Fighter, noise: float, bias: float, rng: RandomNumberGenerator, seed_value: int) -> bool:
	var curve := realm.curve()
	var elite := kind == &"elite"
	var boss := kind == &"boss"
	var pool := realm.elite_pool if elite else realm.fight_pool
	var first_hp := curve.hp_multiplier(node)
	var first_dmg := curve.damage_multiplier(node)
	if elite:
		first_hp *= realm.elite_hp_multiplier * curve.elite_hp_factor
		first_dmg *= curve.elite_damage_factor
	elif boss:
		first_hp *= curve.boss_hp_factor
		first_dmg *= curve.boss_damage_factor
	var wave: Array = []
	if boss:
		wave.append([realm.boss, [], first_hp, first_dmg])
	else:
		wave.append([_pick_entry(pool, rng), null, first_hp, first_dmg])
		var extra := 0
		if elite:
			extra = 1 if rng.randf() < curve.elite_wave_chance_at(depth) else 0
		else:
			var range_size := curve.fight_wave_range(depth, node)
			extra = rng.randi_range(range_size.x, range_size.y) - 1
		for i in extra:
			wave.append([_pick_entry(realm.fight_pool, rng), null, curve.hp_multiplier(node), curve.damage_multiplier(node)])
	player.stamina = player.max_stamina
	for index in wave.size():
		var item: Array = wave[index]
		var definition: EnemyDefinition
		var affixes: Array[StringName] = []
		if item[0] is RealmEnemyEntry:
			var entry := item[0] as RealmEnemyEntry
			definition = entry.enemy
			affixes = _roll_affixes(entry, curve, depth, elite and index == 0, rng)
		else:
			definition = item[0]
		var duel := Duel.new(_tuning, definition, seed_value + index, curve.combat_level(depth), player)
		for affix in affixes:
			if ModifierCatalog.has(affix):
				duel.enemy.mods.add(ModifierCatalog.create(affix))
		duel.enemy.mods.add(StatModifier.new(CombatStats.ATTACK_DAMAGE, Modifier.Stage.MUL, item[3], &"depth"))
		duel.enemy.max_hp = roundi(duel.enemy.max_hp * item[2])
		duel.enemy.reset_pools()
		var bot_rng := RandomNumberGenerator.new()
		bot_rng.seed = seed_value * 31 + index
		var bot := Bot.new(noise, bias)
		bot.attach(duel, bot_rng)
		while not duel.finished and duel.time < MAX_DUEL_SECONDS:
			bot.think(duel)
			duel.advance(DT)
		if duel.winner != Fighter.PLAYER:
			if _log:
				print("DEATH %s node %d %s %s wave %d/%d enemy %s affixes %s t=%.0f enemy_hp %d/%d" % [_label, node, kind, realm.id, index + 1, wave.size(), definition.id, affixes, duel.time, duel.enemy.hp, duel.enemy.max_hp])
			return false
	return true

func _pick_entry(pool: Array[RealmEnemyEntry], rng: RandomNumberGenerator) -> RealmEnemyEntry:
	var weights: Array[float] = []
	for entry in pool:
		weights.append(entry.weight)
	return pool[maxi(WeightedPick.index(rng, weights), 0)]

func _roll_affixes(entry: RealmEnemyEntry, curve: DepthCurve, depth: int, elite: bool, rng: RandomNumberGenerator) -> Array[StringName]:
	var result: Array[StringName] = []
	if entry.affixes.is_empty():
		return result
	if elite:
		result.append(entry.affixes[rng.randi_range(0, entry.affixes.size() - 1)])
	var chance := curve.double_affix_chance_at(depth) if elite else curve.fight_affix_chance_at(depth)
	if chance > 0.0 and rng.randf() < chance:
		var extra: StringName = entry.affixes[rng.randi_range(0, entry.affixes.size() - 1)]
		if not result.has(extra):
			result.append(extra)
	return result

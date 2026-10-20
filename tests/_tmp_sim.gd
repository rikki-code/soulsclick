## Bot-vs-enemy balance simulation: godot --headless --path . -s tests/combat_sim.gd [-- N]
extends SceneTree

const DT := 1.0 / 60.0
const MAX_DUEL_SECONDS := 180.0
const DEFAULT_RUNS := 200
const TUNING_PATH := "res://data/tuning/default_tuning.tres"
const EQUIPMENT_PATH := "res://data/equipment/%s.tres"
## weapon, shield: the three loadout archetypes plus the unequipped baseline.
const LOADOUTS := [
	["none", "", ""],
	["buckler+dagger", "dagger", "buckler"],
	["kite+sword", "sword", "kite_shield"],
	["tower+greatsword", "greatsword", "tower_shield"],
]
const ENEMY_PATHS := [
	"res://data/enemies/grunt.tres",
	"res://data/enemies/knight.tres",
	"res://data/enemies/warden.tres","res://data/enemies/hound.tres","res://data/enemies/dancer.tres","res://data/enemies/bulwark.tres","res://data/enemies/pilgrim.tres","res://data/enemies/hangman.tres","res://data/enemies/wretch.tres",
]

class Bot extends RefCounted:
	func attach(_duel: Duel, _rng: RandomNumberGenerator) -> void:
		pass

	func think(_duel: Duel) -> void:
		pass

class RandomBot extends Bot:
	var attack_chance: float
	var block_chance: float
	var _rng: RandomNumberGenerator

	func _init(p_attack_chance: float, p_block_chance: float) -> void:
		attack_chance = p_attack_chance
		block_chance = p_block_chance

	func attach(_duel: Duel, rng: RandomNumberGenerator) -> void:
		_rng = rng

	func think(duel: Duel) -> void:
		if _rng.randf() < attack_chance:
			duel.perform_attack()
		if _rng.randf() < block_chance:
			duel.perform_block()
			duel.perform_block_release()

## Reads telegraphs, presses block so the strike lands inside the parry window (plus timing noise),
## attacks whenever that cannot collide with a pending parry.
class ParryBot extends Bot:
	var noise: float
	var _rng: RandomNumberGenerator
	var _press_at := -1.0

	func _init(p_noise: float) -> void:
		noise = p_noise

	func attach(duel: Duel, rng: RandomNumberGenerator) -> void:
		_rng = rng
		duel.telegraph_started.connect(_on_telegraph.bind(duel))
		duel.strike_resolved.connect(_on_strike)

	func _on_telegraph(_kind_id: StringName, duration: float, _index: int, duel: Duel) -> void:
		var stats := duel.player.stats
		var lead := stats.value(CombatStats.BLOCK_STARTUP) + stats.value(CombatStats.PARRY_WINDOW) * 0.5
		_press_at = duel.time + duration * duel.enemy.stats.value(CombatStats.TELEGRAPH_SCALE) - lead + _rng.randfn(0.0, noise)

	func _on_strike(_result: StrikeResult) -> void:
		_press_at = -1.0

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
	var runs := DEFAULT_RUNS
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		runs = int(args[0])
	var tuning := load(TUNING_PATH) as CombatTuning
	for path in ENEMY_PATHS:
		var definition := load(path) as EnemyDefinition
		_report(tuning, definition, "parry bot (noise 0.05s)", func() -> Bot: return ParryBot.new(0.05), runs)
		_report(tuning, definition, "sloppy bot (noise 0.12s)", func() -> Bot: return ParryBot.new(0.12), runs)
		_report(tuning, definition, "random bot", func() -> Bot: return RandomBot.new(0.03, 0.03), runs)
		_report(tuning, definition, "masher bot", func() -> Bot: return RandomBot.new(1.0, 0.0), runs)
	for entry in LOADOUTS:
		for path in ENEMY_PATHS:
			var definition := load(path) as EnemyDefinition
			var loadout := _loadout(entry[1], entry[2])
			_report(tuning, definition, "%s parry 0.05" % entry[0], func() -> Bot: return ParryBot.new(0.05), runs, loadout)
			_report(tuning, definition, "%s sloppy 0.12" % entry[0], func() -> Bot: return ParryBot.new(0.12), runs, loadout)
	quit()

func _loadout(weapon_id: String, shield_id: String) -> Loadout:
	var weapon := load(EQUIPMENT_PATH % weapon_id) as Equipment if weapon_id != "" else null
	var shield := load(EQUIPMENT_PATH % shield_id) as Equipment if shield_id != "" else null
	return Loadout.of(weapon, shield)

func _report(tuning: CombatTuning, definition: EnemyDefinition, label: String, make_bot: Callable, runs: int, loadout: Loadout = null) -> void:
	var wins := 0
	var total_time := 0.0
	var win_hp := 0.0
	for run in runs:
		var player := Fighter.make_player(tuning)
		if loadout != null:
			loadout.apply_to(player)
		var duel := Duel.new(tuning, definition, run + 1, 1, player)
		var bot := make_bot.call() as Bot
		var bot_rng := RandomNumberGenerator.new()
		bot_rng.seed = run + 100000
		bot.attach(duel, bot_rng)
		while not duel.finished and duel.time < MAX_DUEL_SECONDS:
			bot.think(duel)
			duel.advance(DT)
		total_time += duel.time
		if duel.winner == Fighter.PLAYER:
			wins += 1
			win_hp += duel.player.hp
	print("SIM %-8s %-26s win %5.1f%%  avg length %6.1fs  avg hp left on win %5.1f" % [
		definition.id, label, 100.0 * wins / runs, total_time / runs, win_hp / maxf(wins, 1)])

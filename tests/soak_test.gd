## Leak guard: many headless duels, engine object count must stay flat: godot --headless --path . -s tests/soak_test.gd
extends SceneTree

const TUNING_PATH := "res://data/tuning/default_tuning.tres"
const ENEMY_PATH := "res://data/enemies/grunt.tres"
const FIGHTS := 300
const WARMUP := 30
const STEP := 0.02
const MAX_SECONDS := 120.0
const BOT_PERIOD := 0.5
const MAX_GROWTH := 300

func _initialize() -> void:
	var tuning := load(TUNING_PATH) as CombatTuning
	var enemy_def := load(ENEMY_PATH) as EnemyDefinition
	var base_objects := 0
	var base_nodes := 0
	for i in FIGHTS:
		if i == WARMUP:
			base_objects = int(Performance.get_monitor(Performance.OBJECT_COUNT))
			base_nodes = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		_fight(tuning, enemy_def, i + 1)
	var objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	print("INFO nodes: baseline %d, final %d" % [base_nodes, nodes])
	var growth := objects - base_objects
	if growth > MAX_GROWTH:
		print("FAIL soak: objects baseline %d, final %d (growth %d > %d)" % [base_objects, objects, growth, MAX_GROWTH])
		quit(1)
		return
	print("PASS soak: objects baseline %d, final %d (growth %d <= %d)" % [base_objects, objects, growth, MAX_GROWTH])
	quit(0)

func _fight(tuning: CombatTuning, enemy_def: EnemyDefinition, fight_seed: int) -> void:
	var player := Fighter.make_player(tuning)
	var duel := Duel.new(tuning, enemy_def, fight_seed, 1, player)
	var next_attack := 0.0
	while not duel.finished and duel.time < MAX_SECONDS:
		if duel.time >= next_attack:
			duel.perform_attack()
			next_attack += BOT_PERIOD
		duel.advance(STEP)
	duel.enemy.dispose()
	player.dispose()

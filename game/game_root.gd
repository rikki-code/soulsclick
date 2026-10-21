## Composition root of the game scene: owns the `Run`, shows the run screens (omen, doors, rest, level-up, summary), plays each
## fight room as a `Duel` through `BattleView`, saves the run at every room boundary and banks Embers when it ends.
class_name GameRoot
extends Control

const TUNING_PATH := "res://data/tuning/default_tuning.tres"
const ATTACK_KEYS: Array[Key] = [KEY_RIGHT, KEY_D, KEY_J]
const BLOCK_KEYS: Array[Key] = [KEY_LEFT, KEY_A, KEY_F]
const MAX_FRAME := 0.1
const REVIVE_HP_FRACTION := 0.5
const SAVE_HALF_RATE := 0.5
const SCREEN_FLAG := "--screen="
const DEPTH_SOURCE := &"depth"
const BEST_DEPTH := &"best_depth"
const REALM_BACKGROUNDS := 4
## Semitone shift of each realm's battle theme (gen_audio battle_1..4); tonal SFX follow it.
const REALM_KEY_SHIFTS: Array[float] = [0.0, -1.0, -3.0, -5.0]
## Pause between the death of a wave enemy and the next one stepping in.
const WAVE_PAUSE := 0.8
## A consumable tapped while the player is busy waits this long for a free moment.
const ITEM_QUEUE_SECONDS := 0.8
## How long the "Victory" banner stands before the reward cards (or the next room) come.
const VICTORY_BANNER := 1.0
## Road walks between rooms: through a single door, to the fork, from the fork into the chosen trail.
const WALK_SECONDS := 1.4
const FORK_WALK_SECONDS := 0.9
## "Deeper" after a boss: the walk that blends the road into the next realm.
const REALM_WALK_SECONDS := 2.5
const TRAIL_ARRIVE_TIMEOUT := 4.0
const OVERLAY_LAYER := 20
const OVERLAY_DIM := 0.8

var _tuning: CombatTuning
var _run: Run
var _run_levels: StatLevels
var _inventory := Inventory.new()
var _reward_ctx: RewardContext
## The view shows the next step's fork far ahead on the road (previewed at fight start).
var _fork_previewed := false
## The player just walked a trail to this room: its fight starts without the enemy stepping in.
var _arrived_on_trail := false
var _crossroads_fork := false
signal _arrival_done
var _arrival_token := 0
## Offer shown by the view right now; the pick handler applies it once.
var _pending_offer: RewardOffer
## Relic modifiers currently on the player (swapped for fresh ones at every fight start).
var _relic_mods: Array[Modifier] = []
## Realm whose road the persistent view shows, -1 = none yet.
var _road_realm := -1
var _paused := false
## Depth whose crossroads the player already answered with "go deeper".
var _crossroads_depth := -1
var _duel: Duel
var _wave_index := 0
var _queued_item: StringName = &""
var _queued_item_left := 0.0
var _view: BattleView
var _scheme: InputScheme
var _screen: Control
## Run page (altar, place, crossroads) shown above the persistent view in its own layer.
var _overlay_layer: CanvasLayer
var _gameplay_active := false
var _reviving := false
var _embers_banked := false
var _dev := false
var _summary_screen: SummaryScreen

func _ready() -> void:
	UiScale.fit(get_window())
	get_tree().root.size_changed.connect(func() -> void: UiScale.fit(get_window()))
	add_child(MenuKit.background())
	_tuning = load(TUNING_PATH) as CombatTuning
	_dev = DevShot.install(self) != null
	_run_levels = StatLevels.new(GameSession.run_table())
	_reward_ctx = RewardContext.new(_run_levels, _inventory)
	if GameSession.launch == GameSession.Launch.CONTINUE_RUN and _load_saved_run():
		pass
	else:
		_new_run()
	var dev_screen := _dev_screen()
	if dev_screen != "":
		_show_dev_screen(dev_screen)
	else:
		_show_phase()

func _exit_tree() -> void:
	_set_gameplay(false)

func _process(delta: float) -> void:
	if _duel != null and not _duel.finished and not _paused:
		_duel.advance(minf(delta, MAX_FRAME))
		_flush_queued_item(delta)

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or key.echo:
		return
	if not key.pressed:
		if BLOCK_KEYS.has(key.keycode):
			_on_block_release()
		return
	if key.keycode == KEY_ESCAPE:
		if _view != null and _view.visible and _overlay_layer == null:
			_view.toggle_pause()
		else:
			_to_menu()
	elif _view != null and _view.visible and ATTACK_KEYS.has(key.keycode):
		_on_attack()
	elif _view != null and _view.visible and BLOCK_KEYS.has(key.keycode):
		_on_block()

# --- run setup and saves ---------------------------------------------------------------------------------------

func _new_run() -> void:
	GameSession.revives_used = 0
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var config := RunConfig.new(SeedCode.random_seed(rng))
	config.max_hp = PlayerBuilder.build(_tuning, _permanent(), _run_levels).max_hp
	_run = Run.new(config, RealmCatalog.default_realms())

func _load_saved_run() -> bool:
	var envelope := SaveStore.load_run()
	var data: Variant = envelope.get("run")
	if not (data is Dictionary):
		return false
	var run := Run.from_dict(data, RealmCatalog.default_realms())
	if run == null or run.is_ended():
		return false
	_run = run
	_run_levels.from_dict(envelope.get("levels", {}))
	_inventory.from_dict(envelope.get("inventory", {}))
	_reward_ctx.from_dict(envelope.get("rewards", {}))
	# Old saves carried a bool `revive_used`.
	GameSession.revives_used = int(envelope.get("revives_used", 1 if bool(envelope.get("revive_used", false)) else 0))
	return true

func _save_run() -> void:
	if _dev or _run == null or _run.is_ended():
		return
	SaveStore.save_run({"run": _run.to_dict(), "levels": _run_levels.to_dict(), "inventory": _inventory.to_dict(), "rewards": _reward_ctx.to_dict(), "revives_used": GameSession.revives_used})

func _permanent() -> StatLevels:
	return GameSession.profile().permanent(GameSession.permanent_table())

# --- screens ---------------------------------------------------------------------------------------------------

func _show_phase() -> void:
	match _run.phase:
		Run.PHASE_OMEN:
			# Omens only steer the relic pool and runs offer no relics yet: take the first one silently.
			# Bring OmenScreen back here when relic rewards exist.
			_on_omen_picked(0)
		Run.PHASE_DOORS:
			_save_run()
			if _run.at_crossroads() and _crossroads_depth != _run.depth:
				_show_crossroads()
				return
			_travel()
		Run.PHASE_ROOM:
			_enter_room()
		_:
			_finish_run()

## After a boss: a fork on the road. Left trail = HOME (bank the Souls), right = DEEPER (next realm).
func _show_crossroads() -> void:
	_ensure_view()
	var view := _view
	view.preview_fork(crossroads_offer(_run.souls, _run.depth + 1))
	view.walk_to_fork()
	await view.fork_reached
	if _view != view or not is_instance_valid(view) or _run.phase != Run.PHASE_DOORS:
		return
	view.update_fork(crossroads_offer(_run.souls, _run.depth + 1))
	_crossroads_fork = true

static func crossroads_offer(souls: int, next_depth: int) -> DoorOffer:
	var offer := DoorOffer.new()
	var home := Door.make(&"home")
	home.index = 0
	home.preview = {"hint": TranslationServer.translate("PORTAL_HOME_LINE") % souls}
	var deeper := Door.make(&"deeper")
	deeper.index = 1
	deeper.preview = {"hint": TranslationServer.translate("PORTAL_DEEPER_LINE") % next_depth}
	offer.doors.append(home)
	offer.doors.append(deeper)
	return offer

func _on_crossroads_trail(index: int) -> void:
	var view := _view
	await view.trail_arrived
	if _view != view or not is_instance_valid(view):
		return
	if index == 0:
		_on_home_picked()
		return
	view.clear_road_fork()
	_on_deeper_picked()

func _on_home_picked() -> void:
	_run.retire()
	_finish_run()

func _on_deeper_picked() -> void:
	_crossroads_depth = _run.depth
	var realm_slot := _run.depth % REALM_BACKGROUNDS
	if _view == null or _road_realm == -1 or _road_realm == realm_slot:
		_show_phase()
		return
	var view := _view
	_road_realm = realm_slot
	view.transition_road(realm_slot, _run.config.seed, REALM_WALK_SECONDS)
	view.walk(REALM_WALK_SECONDS)
	await view.walk_finished
	if _view != view or not is_instance_valid(view):
		return
	_show_phase()

## Doors are on offer: walk the road. One door is no choice (walk, enter); several end at the fork, which stands on the
## road since the previous fight. The first room of a run (no view yet) has no walk: the enemy steps in.
func _travel() -> void:
	var first := _view == null
	_ensure_view()
	var view := _view
	if _run.offer.doors.size() == 1:
		if not first:
			view.walk(WALK_SECONDS)
			await view.walk_finished
			if _view != view or not is_instance_valid(view) or _run.phase != Run.PHASE_DOORS:
				return
		_run.choose_door(0)
		_show_phase()
		return
	if not _fork_previewed:
		view.preview_fork(_run.offer)
	_fork_previewed = false
	view.walk_to_fork()
	await view.fork_reached
	if _view != view or not is_instance_valid(view) or _run.phase != Run.PHASE_DOORS:
		return
	view.update_fork(_run.offer)

## The next step is a fork: it stands on the road ahead while this room is played.
func _preview_next_fork() -> void:
	var next_offer := _run.peek_next_offer()
	_fork_previewed = next_offer != null
	if _fork_previewed:
		_view.preview_fork(next_offer)

func _on_trail_picked(index: int) -> void:
	if _crossroads_fork:
		_crossroads_fork = false
		_on_crossroads_trail(index)
		return
	if _run.phase != Run.PHASE_DOORS or _run.choose_door(index) == null:
		return
	var view := _view
	_arrival_token += 1
	var token := _arrival_token
	var on_arrived := func(_i: int) -> void:
		if token == _arrival_token:
			_arrival_done.emit()
	view.trail_arrived.connect(on_arrived, CONNECT_ONE_SHOT)
	get_tree().create_timer(TRAIL_ARRIVE_TIMEOUT).timeout.connect(func() -> void:
		if token == _arrival_token:
			_arrival_done.emit())
	await _arrival_done
	_arrival_token += 1
	if is_instance_valid(view) and view.trail_arrived.is_connected(on_arrived):
		view.trail_arrived.disconnect(on_arrived)
	_arrived_on_trail = true
	if _view != view or not is_instance_valid(view):
		return
	_show_phase()

## The persistent view exists, is visible and shows the road of the current realm.
func _ensure_view() -> void:
	if _view == null:
		_create_view()
	_set_view_shown(true)
	var realm_slot := _run.depth % REALM_BACKGROUNDS
	if _road_realm != realm_slot:
		_road_realm = realm_slot
		_view.set_road(realm_slot, _run.config.seed)

## Run page above the view: its backdrop is dimmed so the road shows through.
func _show_overlay(screen: Control) -> void:
	_clear_overlay()
	if _view != null:
		_view.set_input_enabled(false)
	var back := screen.get_child(0) as CanvasItem
	if back != null:
		back.modulate.a = OVERLAY_DIM
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = OVERLAY_LAYER
	_overlay_layer.add_child(screen)
	add_child(_overlay_layer)
	Audio.play_music(&"menu")

func _clear_overlay() -> void:
	if _overlay_layer != null:
		_overlay_layer.queue_free()
		_overlay_layer = null

func _show(screen: Control) -> void:
	_hide_view()
	if _screen != null:
		_screen.queue_free()
	_screen = screen
	add_child(screen)
	Audio.play_music(&"menu")

func _on_omen_picked(index: int) -> void:
	_run.choose_omen(index)
	_show_phase()

func _enter_room() -> void:
	_save_run()
	var plan := _run.plan
	if plan.is_combat:
		_start_fight(plan)
		return
	_ensure_view()
	if _arrived_on_trail:
		_arrived_on_trail = false
		_view.clear_road_fork()
	_preview_next_fork()
	# The bonfire has one sensible action: rest without asking.
	if plan.kind_id == BonfireRoom.ID:
		_on_place_finished(BonfireRoom.HEAL)
		return
	if plan.kind_id == AltarRoom.ID:
		_show_altar()
		return
	# No other place kind has a page: pass through it.
	_on_place_finished(&"")

## Altar: stat levels and run buffs for Souls; rebuilt after every purchase so prices and Souls stay current.
func _show_altar() -> void:
	_ensure_view()
	var levels: Array[Dictionary] = []
	for stat in _run_levels.table.stat_ids():
		var cost := _run_levels.cost_of(stat)
		if cost < 0:
			continue
		var value := _stat_value(stat)
		levels.append({"id": stat, "name": RunScreen.stat_name(stat), "value": RunScreen.stat_text(value),
			"next": RunScreen.stat_text(value + _run_levels.table.def_of(stat).increment), "price": cost,
			"affordable": cost <= _run.souls, "ad": cost > _run.souls and Platform.is_rewarded_available()})
	var buffs: Array[Dictionary] = []
	for def in ShopStock.list(_inventory):
		if def.is_consumable():
			continue
		buffs.append({"id": def.id, "name": tr(def.name_key), "info": tr(def.desc_key), "price": _inventory.price_of(def),
			"affordable": _inventory.can_buy(def, _run.souls), "ad": _item_ad_offer(def)})
	var altar := AltarScreen.new().setup(_run, levels, buffs)
	altar.level_requested.connect(func(stat: StringName) -> void:
		if await _buy_run_level_or_ad(stat):
			_save_run()
		_show_altar())
	altar.buff_requested.connect(func(item_id: StringName) -> void:
		await _on_buy_item_requested(item_id)
		_show_altar())
	altar.leave_requested.connect(_on_place_finished.bind(&""))
	_show_overlay(altar)

func _on_place_finished(choice: StringName) -> void:
	var result := RoomResult.victory()
	result.choice = choice
	_complete(result)

## Reports the room to the run and moves on to the next screen (or the summary).
func _complete(result: RoomResult) -> void:
	_run.complete_room(result)
	_clear_overlay()
	if _run.is_ended():
		_finish_run()
	else:
		_end_fight_state()
		_show_phase()

func _stat_value(stat: StringName) -> float:
	return PlayerBuilder.stat_value(_tuning, _permanent(), _run_levels, stat)

## In-battle shop hook: the view asks to buy a run level with the live Souls.
func _on_buy_level_requested(stat: StringName) -> void:
	if not _buy_run_level(stat) or _duel == null:
		return
	var def := _run_levels.table.def_of(stat)
	_duel.player.mods.add(StatModifier.new(stat, Modifier.Stage.ADD, def.increment, PlayerBuilder.RUN_SOURCE))
	_sync_view_shop()
	_save_run()

## Pushes the live Souls and the shop stock (items, run levels) to the view.
func _sync_view_shop() -> void:
	if _view == null:
		return
	# Battle sells consumables only; levels and run buffs are bought at altars.
	var no_levels: Array[Dictionary] = []
	_view.set_shop(_shop_items(), no_levels, _run.souls)

## Shop rows for items: owned consumables show their charges and a Use button.
func _shop_items() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for def in ShopStock.list(_inventory):
		if not def.is_consumable():
			continue
		var price := _inventory.price_of(def)
		rows.append({"id": def.id, "name": tr(def.name_key), "icon_path": def.icon_path, "price": price, "info": tr(def.desc_key),
			"affordable": _inventory.can_buy(def, _run.souls), "ad": _item_ad_offer(def), "count": _inventory.charges(def.id),
			"usable": def.is_consumable()})
	return rows

## True when the item is unaffordable only for lack of Souls and a rewarded ad can stand in for the price.
func _item_ad_offer(def: ItemDefinition) -> bool:
	return Platform.is_rewarded_available() and not _inventory.can_buy(def, _run.souls) \
			and _inventory.can_buy(def, _inventory.price_of(def))

func _on_buy_item_requested(item_id: StringName) -> void:
	var def := ItemCatalog.get_def(item_id)
	if def == null:
		return
	if _inventory.can_buy(def, _run.souls):
		_run.add_souls(_inventory.buy(def, _run.souls) - _run.souls)
	elif _item_ad_offer(def):
		if not await _watch_ads(1):
			return
		# Free purchase: the Inventory is paid with Souls that are not taken from the run.
		_inventory.buy(def, _inventory.price_of(def))
	else:
		return
	# Battle slot: a consumable bought by a tap is used in the same tap (stays stored if it cannot be used now).
	if _duel != null and def.is_consumable():
		_use_item_now_or_soon(item_id)
	_sync_view_shop()
	_save_run()

## Watches `count` rewarded ads in a row; the duel clock stops meanwhile. Any refusal cancels (false).
func _watch_ads(count: int) -> bool:
	var was_paused := _paused
	_paused = true
	var granted := true
	for i in count:
		if not await Platform.show_rewarded():
			granted = false
			break
	_paused = was_paused
	return granted

func _on_use_item_requested(item_id: StringName) -> void:
	_use_item_now_or_soon(item_id)

## Drinking is only allowed while idle or guarding. A tap during a swing or a stagger would be rejected and
## the item would look dead, so it is remembered for a moment and used the instant the player is free.
func _use_item_now_or_soon(item_id: StringName) -> void:
	if _duel == null:
		return
	if _duel.player.state is IdleState or _duel.player.state is BlockingState:
		_queued_item = &""
		if _duel.use_item(item_id):
			_sync_view_shop()
		return
	_queued_item = item_id
	_queued_item_left = ITEM_QUEUE_SECONDS

func _flush_queued_item(delta: float) -> void:
	if _queued_item == &"":
		return
	_queued_item_left -= delta
	if _queued_item_left <= 0.0:
		_queued_item = &""
	elif _duel.player.state is IdleState or _duel.player.state is BlockingState:
		var item_id := _queued_item
		_queued_item = &""
		if _duel.use_item(item_id):
			_sync_view_shop()

func _on_souls_earned(amount: int, _source: StringName) -> void:
	_run.add_souls(amount)
	_view.on_souls_earned(amount)
	_sync_view_shop()

func _on_pause_requested() -> void:
	_paused = true

func _on_resume_requested() -> void:
	_paused = false

## Pause menu "Abandon": the run ends now (banked like a death).
func _on_abandon_requested() -> void:
	_paused = false
	_free_view()
	_run.abandon()
	_finish_run()

## Pause menu "Main menu": the run stays saved; Continue restarts this room's fight.
func _on_menu_requested() -> void:
	_paused = false
	_save_run()
	_to_menu()

## Per stat: {stat, value, increment, cost, level} for the view's level buttons.
func _shop_levels() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for stat in _run_levels.table.stat_ids():
		var cost := _run_levels.cost_of(stat)
		var increment: float = _run_levels.table.def_of(stat).increment
		rows.append({"id": stat, "name": tr("STAT_%s" % String(stat).to_upper()), "price": cost,
			"info": "%s → +%s" % [_stat_value(stat), increment], "affordable": cost >= 0 and cost <= _run.souls,
			"level": _run_levels.level_of(stat)})
	return rows

## Altar level: pays Souls, or one rewarded ad when the Souls are short.
func _buy_run_level_or_ad(stat: StringName) -> bool:
	var cost := _run_levels.cost_of(stat)
	if cost < 0 or cost <= _run.souls:
		return _buy_run_level(stat)
	if not Platform.is_rewarded_available() or not await _watch_ads(1):
		return false
	return _buy_run_level(stat, true)

## Pays Souls for the next run level; a max hp level also raises the run's hp cap and heals the gain.
func _buy_run_level(stat: StringName, free := false) -> bool:
	var cost := _run_levels.cost_of(stat)
	if cost < 0 or (not free and cost > _run.souls):
		return false
	if not free:
		_run.add_souls(-cost)
	_run_levels.level_up(stat)
	_refresh_max_hp()
	return true

## A max hp level raises the run's hp cap and heals the gain.
func _refresh_max_hp() -> void:
	var new_max := PlayerBuilder.build(_tuning, _permanent(), _run_levels).max_hp
	var gain := new_max - _run.config.max_hp
	_run.config.max_hp = new_max
	if gain > 0:
		_run.heal(gain)

# --- fights ----------------------------------------------------------------------------------------------------

func _start_fight(plan: RoomPlan) -> void:
	var step_in := not _arrived_on_trail
	_arrived_on_trail = false
	if _screen != null:
		_screen.queue_free()
		_screen = null
	_clear_overlay()
	_ensure_view()
	_preview_next_fork()
	var realm_slot := _run.depth % REALM_BACKGROUNDS
	var player := PlayerBuilder.build(_tuning, _permanent(), _run_levels)
	player.hp = clampi(plan.player_hp, 1, player.max_hp)
	_wave_index = 0
	_paused = false
	GameSession.begin_fight()
	_duel = _make_duel(plan, 0, player)
	_apply_relics(_duel)
	_inventory.begin_fight(_duel)
	_wire(_duel)
	_mount_scheme()
	_view.begin(_view_definition(plan, 0), _duel.enemy, _duel.player, step_in)
	_sync_view_shop()
	_set_gameplay(true)
	Audio.play_music(StringName("battle_%d" % (realm_slot + 1)))
	Audio.set_key_shift(REALM_KEY_SHIFTS[realm_slot])

## One view for the whole run: signals are wired once here.
func _create_view() -> void:
	_road_realm = -1
	_view = BattleView.new()
	add_child(_view)
	_view.revive_pressed.connect(_on_revive)
	_view.menu_pressed.connect(_on_give_up)
	_view.buy_level_requested.connect(_on_buy_level_requested)
	_view.buy_item_requested.connect(_on_buy_item_requested)
	_view.use_item_requested.connect(_on_use_item_requested)
	_view.pause_requested.connect(_on_pause_requested)
	_view.resume_requested.connect(_on_resume_requested)
	_view.abandon_requested.connect(_on_abandon_requested)
	_view.menu_requested.connect(_on_menu_requested)
	_view.reward_picked.connect(_on_reward_picked)
	_view.trail_picked.connect(_on_trail_picked)
	_view.home_picked.connect(_on_home_picked)
	_view.deeper_picked.connect(_on_deeper_picked)

## Owned relics become fresh modifiers on the player (the previous copies, if any, leave first).
func _apply_relics(duel: Duel) -> void:
	for mod in _relic_mods:
		duel.player.mods.remove(mod)
	_relic_mods = _reward_ctx.relic_modifiers()
	for mod in _relic_mods:
		duel.player.mods.add(mod)

## Duel against the wave's enemy `index`, fought by `player` (the same Fighter all wave long).
func _make_duel(plan: RoomPlan, index: int, player: Fighter) -> Duel:
	var duel := Duel.new(_tuning, plan.enemy_at(index), plan.combat_seed + index, plan.combat_level, player)
	_apply_room_scaling(duel.enemy, plan, index)
	return duel

func _apply_room_scaling(enemy: Fighter, plan: RoomPlan, index := 0) -> void:
	for affix_id in plan.affixes_at(index):
		if ModifierCatalog.has(affix_id):
			enemy.mods.add(ModifierCatalog.create(affix_id))
	var damage := plan.damage_multiplier_at(index)
	var hp := plan.hp_multiplier_at(index)
	if not is_equal_approx(damage, 1.0):
		enemy.mods.add(StatModifier.new(CombatStats.ATTACK_DAMAGE, Modifier.Stage.MUL, damage, DEPTH_SOURCE))
	if not is_equal_approx(hp, 1.0):
		enemy.max_hp = roundi(enemy.max_hp * hp)
	enemy.reset_pools()

## What the view gets: in a wave the name carries the progress ("Wolf 2/3"; an unknown key is shown as is).
func _view_definition(plan: RoomPlan, index: int) -> EnemyDefinition:
	var definition := plan.enemy_at(index)
	if plan.wave_size() <= 1:
		return definition
	var shown := definition.duplicate() as EnemyDefinition
	shown.name_key = "%s %d/%d" % [tr(definition.name_key), index + 1, plan.wave_size()]
	return shown

func _mount_scheme() -> void:
	var saved := DevShot.scheme_override if DevShot.scheme_override != "" else GameSession.profile().input_scheme
	var scheme_id := InputSchemeCatalog.resolve(saved)
	_scheme = InputSchemeCatalog.make(scheme_id, PlayerLoadoutView.from_equipment(PlayerBuilder.START_SHIELD, PlayerBuilder.START_WEAPON))
	_scheme.attack_requested.connect(_on_attack)
	_scheme.block_requested.connect(_on_block)
	_scheme.block_released.connect(_on_block_release)
	_view.mount_scheme(_scheme)
	_show_first_hint(scheme_id)

func _show_first_hint(scheme_id: StringName) -> void:
	var profile := GameSession.profile()
	if profile.was_hinted(scheme_id) and not _dev:
		return
	if not _dev:
		profile.mark_hinted(scheme_id)
		GameSession.save_profile()
	_view.show_hint(tr(InputSchemeCatalog.hint_key(scheme_id)))

func _wire(duel: Duel) -> void:
	duel.strike_timing.connect(_view.on_strike_timing)
	duel.telegraph_started.connect(_view.on_telegraph_started)
	duel.strike_resolved.connect(_view.on_strike_resolved)
	duel.player_attacked.connect(_view.on_player_attacked)
	duel.stamina_changed.connect(_view.on_stamina_changed)
	duel.fighter_state_timed.connect(_view.on_fighter_state_timed)
	duel.action_rejected.connect(_view.on_action_rejected)
	duel.duel_finished.connect(_on_duel_finished)
	duel.combo_changed.connect(_view.on_combo_changed)
	duel.player_hit.connect(_view.on_player_hit)
	duel.souls_earned.connect(_on_souls_earned)
	duel.player_hp_changed.connect(_view.on_player_hp_changed)
	duel.enemy_hp_changed.connect(_view.on_enemy_hp_changed)
	duel.item_used.connect(_view.on_item_used)

func _on_attack() -> void:
	if _duel != null:
		_press(Duel.ACTION_ATTACK, _duel.try_attack())

func _on_block() -> void:
	if _duel != null:
		_press(Duel.ACTION_BLOCK, _duel.try_block())

## Never gated: a finger lifted after the duel ended must still drop the guard.
func _on_block_release() -> void:
	if _duel != null:
		_duel.try_block_release()

func _press(action_id: StringName, accepted: bool) -> void:
	if accepted and _view != null:
		_view.press_feedback(action_id)

func _on_duel_finished(winner_side: StringName) -> void:
	_set_gameplay(false)
	_view.on_duel_finished(winner_side)
	if winner_side == Fighter.PLAYER:
		if _wave_index + 1 < _run.plan.wave_size():
			_next_wave_enemy()
		else:
			_on_room_won()
		return
	_view.show_death(GameSession.can_revive() and Platform.is_rewarded_available())

## Next enemy of the wave steps in after a short beat; player hp, stamina, mods, items and combo carry over.
func _next_wave_enemy() -> void:
	var previous := _duel
	await get_tree().create_timer(WAVE_PAUSE).timeout
	if _duel != previous or _view == null or _view.is_queued_for_deletion():
		return
	var plan := _run.plan
	var player := previous.player
	previous.enter_state(player, IdleState.new())
	player.holding_block = false
	_wave_index += 1
	_duel = _make_duel(plan, _wave_index, player)
	_duel.combo = previous.combo
	_apply_relics(_duel)
	_inventory.begin_fight(_duel)
	_wire(_duel)
	_view.begin(_view_definition(plan, _wave_index), _duel.enemy, _duel.player)
	if _duel.combo > 0:
		_view.on_combo_changed(_duel.combo, _duel.combo_multiplier())
	_sync_view_shop()
	_set_gameplay(true)

## Last wave down: banner, then the reward cards (or straight on when there is nothing to pick).
func _on_room_won() -> void:
	var duel := _duel
	_view.show_victory(_run.plan.souls_reward)
	var offer := RewardGenerator.generate(_run, _run.plan, _reward_ctx)
	await get_tree().create_timer(VICTORY_BANNER).timeout
	if _duel != duel or _view == null or _view.is_queued_for_deletion():
		return
	if offer.is_open():
		_pending_offer = offer
		_view.show_rewards(offer)
	else:
		_complete(RoomResult.victory(duel.player.hp))

func _on_reward_picked(index: int) -> void:
	var offer := _pending_offer
	if offer == null or _duel == null:
		return
	_pending_offer = null
	var hp_before := _run.hp
	offer.apply(index, _run, _reward_ctx)
	_refresh_max_hp()
	# Heals went to the run's hp; the duel's hp is the truth now, so carry the gain over.
	var hp_after := clampi(_duel.player.hp + _run.hp - hp_before, 1, _run.config.max_hp)
	_complete(RoomResult.victory(hp_after))

## Rewarded revive: the same duel continues, the view restarts on its numbers.
func _on_revive() -> void:
	if _reviving or not GameSession.can_revive() or _duel == null:
		return
	_reviving = true
	var granted := await _watch_ads(GameSession.revive_ads())
	_reviving = false
	if not granted or _duel == null or not _duel.revive_player(REVIVE_HP_FRACTION):
		return
	GameSession.use_revive()
	_save_run()
	_view.begin(_view_definition(_run.plan, _wave_index), _duel.enemy, _duel.player)
	_set_gameplay(true)

## Death panel "Back": no revive, the run ends here.
func _on_give_up() -> void:
	_free_view()
	_complete(RoomResult.defeat())

## Fight state off and the persistent view out of sight (a run screen takes over).
func _hide_view() -> void:
	_end_fight_state()
	if _view != null:
		_view.set_input_enabled(false)
		_set_view_shown(false)

## Run end / menu / give up: the view goes away for good.
func _free_view() -> void:
	_fork_previewed = false
	_end_fight_state()
	if _view != null:
		_view.queue_free()
		_view = null

func _end_fight_state() -> void:
	_set_gameplay(false)
	_inventory.end_fight()
	_duel = null
	_scheme = null
	_pending_offer = null
	_paused = false

## CanvasLayers ignore a hidden parent, so they are toggled with the view.
func _set_view_shown(shown: bool) -> void:
	_view.visible = shown
	for child in _view.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = shown

# --- end of run ------------------------------------------------------------------------------------------------

func _finish_run() -> void:
	_clear_overlay()
	_free_view()
	var summary := _run.summary
	if not _embers_banked:
		_embers_banked = true
		if not _dev:
			GameSession.profile().embers += summary.embers
			GameSession.profile().record_best(BEST_DEPTH, summary.depth_reached)
			GameSession.save_profile()
			SaveStore.delete_run()
	var can_save_half := not summary.victory and floori(summary.souls * SAVE_HALF_RATE) > 0 and Platform.is_rewarded_available()
	_summary_screen = SummaryScreen.new().setup(summary, can_save_half)
	_summary_screen.again_pressed.connect(func() -> void:
		GameSession.launch = GameSession.Launch.NEW_RUN
		SceneRouter.to_game())
	_summary_screen.menu_pressed.connect(_to_menu)
	_summary_screen.save_half_pressed.connect(_on_save_half)
	_show(_summary_screen)

## Rewarded "save half": a dead run banks half of its Souls as Embers after all.
func _on_save_half() -> void:
	if _reviving:
		return
	_reviving = true
	var granted := await _watch_ads(GameSession.revive_ads())
	_reviving = false
	var summary := _run.summary
	if not granted or summary.bank_rate >= SAVE_HALF_RATE or _summary_screen == null:
		return
	var extra := floori(summary.souls * SAVE_HALF_RATE) - summary.embers
	summary.bank_rate = SAVE_HALF_RATE
	summary.embers += extra
	GameSession.profile().embers += extra
	GameSession.save_profile()
	_summary_screen.hide_save_half()
	_summary_screen.count_to(summary.embers)

func _to_menu() -> void:
	GameSession.reset_run()
	SceneRouter.to_menu()

func _set_gameplay(active: bool) -> void:
	if active == _gameplay_active:
		return
	_gameplay_active = active
	if active:
		Platform.gameplay_started()
	else:
		Platform.gameplay_stopped()

# --- dev -------------------------------------------------------------------------------------------------------

## `-- --screen=<doors|fight>` skips the omen pick (with some Souls) and shows the doors or enters the first door; combine with `--shot`.
func _dev_screen() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(SCREEN_FLAG):
			return arg.trim_prefix(SCREEN_FLAG)
	return ""

func _show_dev_screen(screen_id: String) -> void:
	_run.choose_omen(0)
	_run.add_souls(200)
	if screen_id == "fight":
		_run.choose_door(0)
	elif screen_id == "altar":
		_show_altar()
		return
	_show_phase()

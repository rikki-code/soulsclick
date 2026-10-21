## State and flow of one run: omen pick, then per step doors -> room -> result, realm after realm.
## Content is derived statelessly from the seed (see RunRng), so a save is just position + choices.
class_name Run
extends RefCounted

const VERSION := 1
const PHASE_OMEN := &"omen"
const PHASE_DOORS := &"doors"
const PHASE_ROOM := &"room"
const PHASE_ENDED := &"ended"
const NO_CHOICE := -1

signal omens_offered(omens: Array[Omen])
signal omen_chosen(omen: Omen)
signal realm_started(realm_index: int, realm_id: StringName, step_count: int)
signal doors_offered(offer: DoorOffer)
signal room_entered(plan: RoomPlan)
## `record` keys: realm, depth, step, kind, variant, affix, door, souls_gained, hp_after.
signal room_completed(record: Dictionary)
signal hp_changed(hp: int, max_hp: int, delta: int)
signal souls_changed(souls: int, delta: int)
signal run_ended(summary: RunSummary)

var config: RunConfig
var realms: Array[RealmDefinition] = []
var phase: StringName = PHASE_OMEN
## Endless: realms completed so far (0-based); `realm_index` is the cycled definition it plays.
var depth := 0
var realm_index := 0
var step_index := 0
var hp := 0
var souls := 0
var omen_choices: Array[Omen] = []
var omen: Omen
var history: Array[Dictionary] = []
var offer: DoorOffer
var plan: RoomPlan
var summary: RunSummary
var killer_enemy_id: StringName = &""
var _outcome_id: StringName = &""

## Rooms entered so far, the current one included.
var node_index: int:
	get:
		return history.size() + (1 if phase == PHASE_ROOM else 0)

func _init(p_config: RunConfig, p_realms: Array[RealmDefinition]) -> void:
	config = p_config
	realms = p_realms
	hp = config.max_hp
	souls = config.start_souls
	omen_choices = Omen.roll(config.seed)

func realm() -> RealmDefinition:
	return realms[mini(realm_index, realms.size() - 1)]

func curve() -> DepthCurve:
	return realm().curve()

## 0-based ordinal of the room being chosen or played: the `node` the curve is evaluated at.
func upcoming_node() -> int:
	return history.size()

func is_ended() -> bool:
	return phase == PHASE_ENDED

func seed_code() -> String:
	return SeedCode.encode(config.seed)

## Emits the events of the current position. Call after the listeners are connected, for a new run and after from_dict.
func resume() -> void:
	_emit_current()

func choose_omen(index: int) -> bool:
	if phase != PHASE_OMEN or index < 0 or index >= omen_choices.size():
		return false
	omen = omen_choices[index]
	_fire_hook(&"on_run_start", {"seed": config.seed, "omen": omen})
	omen_chosen.emit(omen)
	_begin_realm()
	return true

func choose_door(index: int) -> RoomPlan:
	if phase != PHASE_DOORS or index < 0 or index >= offer.doors.size():
		return null
	var door := offer.doors[index]
	plan = RoomKindCatalog.get_kind(door.kind_id).enter(self, door)
	phase = PHASE_ROOM
	_fire_hook(&"on_room_enter", {"plan": plan})
	room_entered.emit(plan)
	return plan

func complete_room(result: RoomResult) -> bool:
	if phase != PHASE_ROOM:
		return false
	var entered := plan
	if result.hp_after >= 0:
		_set_hp(result.hp_after)
	if not result.won or hp <= 0:
		killer_enemy_id = entered.enemy.id if entered.enemy != null else &""
		_end(DeathOutcome.ID)
		return true
	var souls_before := souls
	RoomKindCatalog.get_kind(entered.kind_id).complete(self, entered, result)
	var record := {
		"realm": entered.realm_index, "depth": entered.depth, "step": entered.step_index, "kind": entered.kind_id,
		"variant": entered.door.variant, "affix": entered.affix_id, "door": entered.door_index,
		"souls_gained": souls - souls_before, "hp_after": hp,
	}
	history.append(record)
	plan = null
	_fire_hook(&"on_room_exit", {"record": record, "result": result})
	room_completed.emit(record)
	_advance()
	return true

## Doors of the step after the room being played (the pending step while choosing doors): null past the realm's last
## step or when it has fewer than 2 doors (no fork).
func peek_next_offer() -> DoorOffer:
	var step := step_index + (1 if phase == PHASE_ROOM else 0)
	if phase != PHASE_ROOM and phase != PHASE_DOORS or step >= realm().step_count():
		return null
	var next := DoorGenerator.generate_at(self, depth, step)
	return next if next.doors.size() > 1 else null

func abandon() -> void:
	if phase != PHASE_ENDED:
		_end(AbandonOutcome.ABANDON_ID)

## True right after a boss: a new realm begins and the player may end the journey instead of going deeper.
func at_crossroads() -> bool:
	return phase == PHASE_DOORS and depth > 0 and step_index == 0

## Ends the journey at the crossroads as a victory: every Soul becomes an Ember.
func retire() -> void:
	if at_crossroads():
		_end(VictoryOutcome.ID)

func add_souls(amount: int) -> void:
	var before := souls
	souls = maxi(souls + amount, 0)
	if souls != before:
		souls_changed.emit(souls, souls - before)

func heal(amount: int) -> void:
	_set_hp(mini(hp + amount, config.max_hp))

func to_dict() -> Dictionary:
	return {
		"version": VERSION, "config": config.to_dict(), "phase": phase,
		"depth": depth, "realm": realm_index, "step": step_index, "hp": hp, "souls": souls,
		"omen": omen_choices.find(omen) if omen != null else NO_CHOICE,
		"history": history, "door": plan.door_index if plan != null else NO_CHOICE,
		"outcome": _outcome_id, "killer": killer_enemy_id,
	}

## Rebuilds the run from the config, then overwrites the position. Null for an unknown version or bad data.
static func from_dict(data: Dictionary, p_realms: Array[RealmDefinition]) -> Run:
	if int(data.get("version", 0)) != VERSION or not (data.get("config") is Dictionary) or p_realms.is_empty():
		return null
	var run := Run.new(RunConfig.from_dict(data["config"]), p_realms)
	run.phase = StringName(data.get("phase", PHASE_OMEN))
	run.depth = maxi(int(data.get("depth", data.get("realm", 0))), 0)
	run.realm_index = run.depth % p_realms.size()
	run.step_index = clampi(int(data.get("step", 0)), 0, run.realm().step_count())
	run.hp = clampi(int(data.get("hp", run.config.max_hp)), 0, run.config.max_hp)
	run.souls = maxi(int(data.get("souls", 0)), 0)
	var omen_index := int(data.get("omen", NO_CHOICE))
	if omen_index >= 0 and omen_index < run.omen_choices.size():
		run.omen = run.omen_choices[omen_index]
	for record in data.get("history", []):
		run.history.append(_clean_record(record))
	run.killer_enemy_id = StringName(data.get("killer", ""))
	run._outcome_id = StringName(data.get("outcome", ""))
	if run.phase == PHASE_ENDED:
		run.summary = RunSummary.build(run, RunOutcomeCatalog.create(run._outcome_id))
	elif run.phase == PHASE_DOORS or run.phase == PHASE_ROOM:
		run.offer = DoorGenerator.generate(run)
	if run.phase == PHASE_ROOM:
		var door_index := int(data.get("door", NO_CHOICE))
		if door_index < 0 or door_index >= run.offer.doors.size():
			return null
		var door := run.offer.doors[door_index]
		run.plan = RoomKindCatalog.get_kind(door.kind_id).enter(run, door)
	return run

func _emit_current() -> void:
	if phase == PHASE_OMEN:
		omens_offered.emit(omen_choices)
	elif phase == PHASE_DOORS:
		realm_started.emit(realm_index, realm().id, realm().step_count())
		doors_offered.emit(offer)
	elif phase == PHASE_ROOM:
		room_entered.emit(plan)
	elif phase == PHASE_ENDED:
		run_ended.emit(summary)

static func _clean_record(record: Dictionary) -> Dictionary:
	var clean := record.duplicate()
	for key in ["kind", "variant", "affix"]:
		clean[key] = StringName(clean.get(key, ""))
	for key in ["realm", "depth", "step", "door", "souls_gained", "hp_after"]:
		clean[key] = int(clean.get(key, 0))
	return clean

func _begin_realm() -> void:
	step_index = 0
	realm_started.emit(realm_index, realm().id, realm().step_count())
	_offer_doors()

func _offer_doors() -> void:
	offer = DoorGenerator.generate(self)
	phase = PHASE_DOORS
	doors_offered.emit(offer)

func _advance() -> void:
	step_index += 1
	if step_index < realm().step_count():
		_offer_doors()
		return
	depth += 1
	realm_index = depth % realms.size()
	_begin_realm()

func _set_hp(value: int) -> void:
	var clamped := clampi(value, 0, config.max_hp)
	if clamped == hp:
		return
	var delta := clamped - hp
	hp = clamped
	hp_changed.emit(hp, config.max_hp, delta)

func _end(outcome_id: StringName) -> void:
	_outcome_id = outcome_id
	phase = PHASE_ENDED
	plan = null
	summary = RunSummary.build(self, RunOutcomeCatalog.create(outcome_id))
	run_ended.emit(summary)

## Extension point for the Modifier system (core_hooks.md): run-level hooks fire here.
## No-op until a ModifierHost exists on the run.
func _fire_hook(_hook: StringName, _ctx: Dictionary) -> void:
	pass

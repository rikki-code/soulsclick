## Items of one run: consumables with charges (kept between fights) and run buffs (Modifiers added at every
## fight start). Pure state: the game layer pays (buy returns the funds left) and saves to_dict with the run.
class_name Inventory
extends ItemBag

## id -> charges left.
var consumables := {}
## Owned run buff ids, in purchase order.
var buffs: Array[StringName] = []
## buff id -> its run_data (e.g. second wind spent); handed to the buff's modifiers by reference.
var buff_state := {}
## id -> number of purchases.
var bought := {}

var _duel: Duel
var _applied: Array[Modifier] = []

func owns(item_id: StringName) -> bool:
	return buffs.has(item_id)

func charges(item_id: StringName) -> int:
	return int(consumables.get(item_id, 0))

## Consumable ids with charges, in catalog order (HUD slot order).
func consumable_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for item_id in ItemCatalog.ids():
		if charges(item_id) > 0:
			result.append(item_id)
	return result

## Souls price of `def`.
func price_of(def: ItemDefinition) -> int:
	return def.price_souls

func purchases(item_id: StringName) -> int:
	return int(bought.get(item_id, 0))

func can_buy(def: ItemDefinition, souls: int) -> bool:
	if def == null or def.price_souls <= 0 or souls < price_of(def):
		return false
	if def is ConsumableItem:
		return charges(def.id) < (def as ConsumableItem).max_charges
	return not owns(def.id)

## Returns the Souls left; unchanged when refused (not sold, too poor, buff owned, stack full). Allowed any time;
## a buff bought mid-fight is added to the running duel at once.
func buy(def: ItemDefinition, souls: int) -> int:
	if not can_buy(def, souls):
		return souls
	var price := price_of(def)
	bought[def.id] = purchases(def.id) + 1
	if def is ConsumableItem:
		var item := def as ConsumableItem
		consumables[item.id] = mini(charges(item.id) + item.charges_per_buy, item.max_charges)
	else:
		buffs.append(def.id)
		if _duel != null:
			_apply(def.id)
	return souls - price

## Adds charges of a consumable without paying (reward). False for an unknown / non-consumable id or a full stack.
func grant(item_id: StringName, amount := 1) -> bool:
	var def := ItemCatalog.get_def(item_id) as ConsumableItem
	if def == null or amount <= 0 or charges(item_id) >= def.max_charges:
		return false
	consumables[item_id] = mini(charges(item_id) + amount, def.max_charges)
	return true

func take_charge(item_id: StringName) -> ConsumableItem:
	if charges(item_id) <= 0:
		return null
	var left := charges(item_id) - 1
	if left > 0:
		consumables[item_id] = left
	else:
		consumables.erase(item_id)
	return ItemCatalog.get_def(item_id) as ConsumableItem

## Adds the run buffs to the player and lets the duel spend consumables from here. Call before the first tick.
func begin_fight(duel: Duel) -> void:
	end_fight()
	_duel = duel
	duel.items = self
	for item_id in buffs:
		_apply(item_id)

func _apply(item_id: StringName) -> void:
	var def := ItemCatalog.get_def(item_id) as RunBuffItem
	if def == null:
		return
	if not buff_state.has(item_id):
		buff_state[item_id] = {}
	for mod in def.modifiers():
		mod.run_data = buff_state[item_id]
		_duel.player.mods.add(mod)
		_applied.append(mod)

## Removes the buffs added by begin_fight (they stay owned for the next fight).
func end_fight() -> void:
	if _duel != null:
		for mod in _applied:
			_duel.player.mods.remove(mod)
		if _duel.items == self:
			_duel.items = null
	_applied.clear()
	_duel = null

## Run over: forget everything.
func clear() -> void:
	end_fight()
	consumables.clear()
	buffs.clear()
	buff_state.clear()
	bought.clear()

func to_dict() -> Dictionary:
	var counts := {}
	for item_id in consumables:
		counts[String(item_id)] = int(consumables[item_id])
	var names: Array = []
	for item_id in buffs:
		names.append(String(item_id))
	var state := {}
	for item_id in buff_state:
		state[String(item_id)] = (buff_state[item_id] as Dictionary).duplicate()
	var spent := {}
	for item_id in bought:
		spent[String(item_id)] = int(bought[item_id])
	return {"consumables": counts, "buffs": names, "buff_state": state, "bought": spent}

func from_dict(data: Dictionary) -> void:
	clear()
	var counts: Dictionary = data.get("consumables", {})
	for key in counts:
		var item_id := StringName(key)
		if ItemCatalog.get_def(item_id) is ConsumableItem and int(counts[key]) > 0:
			consumables[item_id] = int(counts[key])
	for key in data.get("buffs", []):
		var item_id := StringName(key)
		if ItemCatalog.get_def(item_id) is RunBuffItem and not buffs.has(item_id):
			buffs.append(item_id)
	var state: Dictionary = data.get("buff_state", {})
	for key in state:
		if buffs.has(StringName(key)):
			buff_state[StringName(key)] = (state[key] as Dictionary).duplicate()
	var spent: Dictionary = data.get("bought", {})
	for key in spent:
		if ItemCatalog.has(StringName(key)):
			bought[StringName(key)] = maxi(int(spent[key]), 0)

---
name: modifiers
description: >
  Soulsclicker modifier system (core/modifiers, core/combat equipment): Modifier hooks, ModifierStack order,
  CombatStats, StatModifier, Equipment/Loadout data, relics and elite affixes, HookApi and the proc depth cap,
  how to add a relic, affix or equipment piece. Use when adding items, relics, affixes or changing stat rules.
---

## Model

- `Modifier` (RefCounted): `params`, `stacks`, `stage` (`ADD < MUL < SET`), `priority`, `reacts_to_proc`,
  `run_data` (saved by the run layer), `fight_data` (reset by `Duel` at the first tick), `rng` (seeded from the duel
  seed + id: deterministic). Hooks are no-op virtuals: `modify_stat(stat_id, value, ctx)`, `on_fight_start`,
  `modify_attack(AttackCtx)`, `on_parry/on_block/on_strike_result(StrikeCtx)`,
  `on_damage_dealt/on_damage_taken(DamageCtx)`, `on_would_die/on_death(DeathCtx)`. Add a hook only with an
  item that needs it (see `.claude/docs/design/core_hooks.md` for the planned rest).
- `ModifierStack` (one per `Fighter`, `fighter.mods`): order = stage, priority, acquire order (stable). `add/remove`
  invalidate the stats cache and re-sync hp/stamina pools (a max gain also heals the gain). `fire(hook, ctx, duel)`.
- `CombatStats` (`fighter.stats.value(CombatStats.X)`): base (tuning or enemy definition) -> modifiers, cached;
  call `mark_dirty()` from a modifier whose output depends on its own state. Stat ids are constants on `CombatStats`.
- Contexts (`HookCtx` and `StrikeCtx/DamageCtx/AttackCtx/DeathCtx`): `owner`, `foe`, `side`, `fx`, `rng`, `depth`,
  `is_proc`; read-only helpers `time()`, `hp_ratio(side)`. The duel itself is not exposed.
- `HookApi` (`ctx.fx`) is the only way to change the world: `heal`, `damage`, `add_stamina`, `stagger` (enemy),
  `queue_free_attack(mult)`, `prevent_death(hp)` (only valid inside `on_would_die`), `set_flag`, `cue`. Every
  successful call emits `Duel.modifier_triggered(mod_id, side)`.
- Procs: effects started through `fx` are tagged `proc`, carry `depth + 1`, and are ignored by modifiers unless
  `reacts_to_proc`. Hard cap `ModifierStack.MAX_DEPTH = 4` (a chain of at most 4 procs).

## Data

- `Equipment` Resource (`data/equipment/*.tres`): `id`, `name_key` (`EQUIP_X`), `desc_key` (`EQUIP_X_DESC`),
  `slot` (`weapon|shield|armor`), `stats: Array[EquipmentStat]` {stat, stage (0 add, 1 mul, 2 set), amount}.
  `Equipment.modifiers()` -> `StatModifier`s. `Loadout.of(weapon, shield, armor).apply_to(fighter)`.
- Pieces: buckler (wide parry, fast guard, high chip), kite_shield (balanced, some guard-break resist),
  tower_shield (block startup, long guard, low chip, high guard-break resist), dagger (fast, cheap, weak), sword,
  greatsword (slow, costly, heavy), light_armor (stamina), heavy_armor (damage taken x0.8, slower).
- Stats: `max_hp max_stamina stamina_regen attack_damage attack_cost attack_lock block_startup block_min_duration
  block_cooldown block_cost parry_window perfect_threshold chip_share guard_break_damage_share guard_break_resist
  stagger_time punish_mult telegraph_scale damage_taken_mult damage_dealt_mult`.

## Stat levels (core/progression)

- `StatLevelTable` Resource: `stats: Array[StatLevelDef]` {stat (CombatStats id), increment, cost_base, cost_growth};
  `cost_at(level) = round(cost_base * cost_growth ^ level)`. Tables: `data/progression/run_levels.tres` (Souls: fast, big
  steps, lost on death), `permanent_levels.tres` (Embers: slow, small steps, uncapped; `stat_levels.tres` = copy of run).
  Stats: `max_hp max_stamina attack_damage stamina_regen`.
- `StatLevels(table)` (RefCounted): `levels` dict, `level_of`, `cost_of(stat)` (-1 unknown), `level_up(stat)` (caller
  pays), `to_dict/from_dict`, `modifiers(source) -> Array[Modifier]` (one ADD `StatModifier` per leveled stat),
  `apply_to(fighter, source)`.
- Game layer: keep two `StatLevels` (run, permanent); before each duel build the player fighter, then
  `permanent.apply_to(player, &"perm_levels")` and `run.apply_to(player, &"run_levels")` (plus loadout and relics);
  both are plain ADD modifiers, so they stack. After a mid-fight level-up the stack re-syncs pools (max gain heals the gain).

## Add things

- Equipment: copy a `.tres`, change numbers, add the two locale keys. No code.
- Relic / affix: one file in `core/modifiers/relics|affixes/` extending `Modifier` with a `const ID`; override only
  the hooks it needs; one line in `ModifierCatalog`. Locale keys `RELIC_<ID>`, `RELIC_<ID>_DESC`, `AFFIX_<ID>`.
- Slice relics: `menders_thread` (heal on parry, x2 perfect), `glass_blade`, `counter_tide` (riposte on parry),
  `phoenix_ash` (survive once per run), `overreach`, `duelists_pride` (parry streak -> damage). Affixes: `swift`,
  `plated`. Build with `ModifierCatalog.create(id)`; add with `duel.player.mods.add(mod)` (enemy: `duel.enemy.mods`).
- Not yet wired: run layer owning relics/loadout and saving `run_data`, enemy affix choice, view for
  `modifier_triggered`.

## Items (core/items, data/items)

- Bought in battle with run Souls, any time, from a side panel. `ItemDefinition` (`id name_key desc_key icon
  price_souls`): `ConsumableItem` (`charges_per_buy max_charges`, effects `heal_share damage stagger stamina_share`
  via `ctx.fx`; new effect = subclass overriding `use(ctx)`) and `RunBuffItem` (`stats` -> `StatModifier`s, whole run).
  Data: flask, ember_bomb, whetstone_oil (damage x1.25), warding_ash (parry window x1.4). Add an id to `ItemCatalog.IDS`.
- `Inventory` (run state, `to_dict/from_dict`, `clear()` at run end): `buy(def, souls) -> souls_left`, `price_of`,
  `can_buy`, `consumable_ids()`, `charges(id)`. `ShopStock.list(inv)` = items for sale (owned buffs hidden).
- Game wiring: after building the duel `inventory.begin_fight(duel)` (adds buffs, sets `duel.items`); after the fight
  `end_fight()`. Shop tap: `souls = inv.buy(def, souls)` (a buff bought mid-fight applies at once). HUD slot tap:
  `duel.use_item(id)`; update on `item_used(item_id, charges_left)`; rejects via `action_rejected(&"item", reason)`.
- Income: `Duel.souls_earned(amount, source)` (`hit` = `souls_per_hit` x combo multiplier, `parry` = `souls_per_parry`).

## Run

`godot --headless --path . -s tests/modifier_test.gd`; loadout win rates: `tests/combat_sim.gd`.

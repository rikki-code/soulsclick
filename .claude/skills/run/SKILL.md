---
name: run
description: >
  Soulsclicker run model (core/run): Run state and flow, seed code, deterministic streams, realms and
  door generation, room kinds, omens, summary and Embers conversion, save/load, how to add a room kind
  or a realm. Use when touching run structure, map, rewards flow, or wiring the run to the game layer.
---

## Model

- `Run(config: RunConfig, realms: Array[RealmDefinition])`. `RunConfig`: `seed` (24 bit), `max_hp`,
  `start_souls`, `death_bank_rate` (0.5; meta upgrades raise it). Fields: `phase`, `realm_index`,
  `step_index`, `hp`, `souls`, `omen_choices`, `omen`, `history`, `offer`, `plan`, `summary`.
- Phases (`Run.PHASE_*`): `omen` -> `doors` -> `room` -> back to `doors`, then `ended`.
- Calls (all return accepted / null when out of phase): `choose_omen(i) -> bool`, `choose_door(i) -> RoomPlan`,
  `complete_room(RoomResult) -> bool`, `abandon()`, `heal(n)`, `add_souls(n)`.
- Game layer loop: build the `Run`, connect signals, `run.resume()` (emits the current position), then
  per room: `plan = choose_door(i)`, play `plan` (duel with `plan.enemy`, `plan.combat_seed`,
  `plan.combat_level`, `plan.hp_multiplier`, `plan.player_hp`; or an altar/shop/bonfire screen from
  `plan.data`), then `complete_room(RoomResult.victory(hp_after))` or `RoomResult.defeat()`.
- Signals (each carries full data): `omens_offered(omens)`, `omen_chosen(omen)`, `realm_started(index, id, step_count)`,
  `doors_offered(DoorOffer)`, `room_entered(RoomPlan)`, `room_completed(record)`, `hp_changed(hp, max, delta)`,
  `souls_changed(souls, delta)`, `run_ended(RunSummary)`. `DoorOffer/Door/RoomPlan/RunSummary.to_dict()` give plain data.
- `RoomResult`: `won`, `hp_after` (-1 = keep), `souls_bonus`, `souls_spent` (capped at held souls), `choice`, `flawless`.
- Souls from combat are `plan.souls_reward` (enemy `souls_reward` x kind multiplier), added by the room kind
  on completion. Elite/boss hp scaling is `plan.hp_multiplier`; level scaling stays in `CombatScaling`.

## Determinism

`RunRng.stream(seed, purpose, a, b, c)` / `seed_for(...)` are stateless: the stream is derived from the
seed, a purpose (`MAP`, `OMEN`, `REWARD`, `COMBAT`) and coordinates (realm, step, door). Doors of a step, omens, offer
seeds and combat seeds therefore never depend on earlier choices. Never keep a long-lived RNG in `Run`; derive a new stream.

`SeedCode.encode(seed) -> "ASH-7F3K"`, `decode(text) -> seed or SeedCode.INVALID` (case, hyphen, space and O/I/L lookalikes tolerated).
`SeedCode.random_seed(rng)` for a new run.

## Saves

`Run.to_dict()` (VERSION 1, JSON-safe) and `Run.from_dict(data, realms) -> Run or null`. The save holds
seed, position, phase, hp, souls, omen index, history and the entered door; offers, plans and omens are re-derived.
Call at every room boundary (after `doors_offered` and `room_completed`), delete the file on `run_ended`.
After `from_dict` connect signals and call `resume()`. `SaveStore` wiring is the game layer's job.

## Data

- `data/realms/realm_N.tres` (`RealmDefinition`): `step_rules: Array[StepRule]` (per step `kind_weights`, `required_kinds`,
  `door_count_weights`, `wave_bonus` = extra wave enemies on road steps), `fight_pool` / `elite_pool: Array[RealmEnemyEntry]` (enemy, weight, elite `affixes` ids), `boss`,
  tuning (`elite_hp_multiplier`, `elite_souls_multiplier`, `bonfire_heal_share`, `boss_heal_share`, offer sizes, shop prices,
  `fight_pick_chance`). `validate()` returns problems (needs elite, bonfire, altar required somewhere; last step boss only).
- `DoorGenerator.generate(run)`: required kinds first, then weighted fill, no duplicate `Door.signature()`
  (kind:enemy:affix), shuffled. Preview data comes from `RoomKind.make_preview`.
- `Omen.roll(seed)`: 2 omens of 2 tags (`Omen.TAGS`), `id` = sorted tags joined by `_`. Effects are read from `tags` later.

## Endless depth and curve

The run never ends on a boss win: after the last step `depth += 1`, `realm_index = depth % realms.size()`, `realm_started` fires again.
`Run.depth` = realms completed, `Run.node_index` = rooms entered (current included), `Run.upcoming_node()` = 0-based ordinal of the room
being chosen/played. RNG streams use `depth` (not `realm_index`), so cycled realms get fresh doors. Save keeps `depth`.
`DepthCurve` (`data/realms/depth_curve.tres`, `RealmDefinition.depth_curve`): per node hp x `hp_growth`^node (1.12), damage x `damage_growth`^node,
souls x `souls_growth`^node (1.08), elite/boss extra factors, `combat_level = depth + 1`; affix chances: normal fights roll one affix
from `fight_affix_depth` (entry `affixes` in the fight pool), elites a second one from `double_affix_depth`. All fed into `RoomPlan`:
`hp_multiplier`, `damage_multiplier`, `combat_level`, `affix_id` (first) + `affix_ids` (all), `depth`, `node`.
The game must scale every enemy damage by `plan.damage_multiplier` (like hp by `hp_multiplier`) and apply each affix of `plan.affix_ids`.
`RunSummary.depth_reached` (= `run.depth`) and `nodes_cleared` feed the profile's best depth. Run ends only by death or abandon.

## Ending

`RunSummary` (`outcome_id` victory|death|abandon, realm_reached, step_reached, rooms_cleared, souls, bank_rate, embers,
seed_code, omen_id, killer_enemy_id, history). Embers = floor(souls x rate): victory 1.0 (no longer reachable in endless), death/abandon `death_bank_rate`.
Pure data: the game layer adds `embers` to the profile once. Victory bonus Embers: `VictoryOutcome.bonus_embers`.

## Add a room kind

1. `core/run/<name>_room.gd` extending `RoomKind` (or `CombatRoomKind`: override `entries(realm)` and multipliers). Set `const ID`, `id()`;
   override only `make_door`, `make_preview`, `_fill_plan` (fill `plan.data`), `complete`.
2. One line in `RoomKindCatalog._factories`.
3. Use the kind id in a `StepRule` (`kind_weights` / `required_kinds`) of a realm `.tres`. Run `tests/run_test.gd`.

## Add a realm

Copy `data/realms/realm_1.tres`, change pools, steps, boss, add the path to `RealmCatalog.PATHS`, add its `name_key` to the locale
CSV. A run plays the realms in `PATHS` order and then cycles (endless).

## Extension points (Modifier system, not implemented)

`Run._fire_hook(hook, ctx)` is a no-op called for `on_run_start`, `on_room_enter`, `on_room_exit` (names from `core_hooks.md`).
A future `ModifierHost` hangs there; `modify_offer` belongs where relic offers are rolled from `plan.data.offer_seed`.
`Omen.tags` feed offer weighting. Elite `affix_id` is a placeholder string until the affix modifiers exist.

## Run

```
godot --headless --path . -s tests/run_test.gd    # exit 0/1
```
Rebuild the class cache after adding a `class_name` file: `--headless --path . --editor --quit-after 3`.

## Game layer wiring (G1)

`GameRoot` owns the `Run` and drives screens from `run.phase` (`view/run/`: `OmenScreen`, `DoorsScreen`, `PlacePanel` for bonfire/shop/altar placeholders, `SummaryScreen`). Fight rooms build the player with `PlayerBuilder` (kite_shield + sword, permanent levels, run levels), `Duel(tuning, plan.enemy, plan.combat_seed, plan.combat_level, player)`, affix modifier and `hp_multiplier` on the enemy; death -> rewarded `Duel.revive_player` once per run, else `RoomResult.defeat()`. Save envelope `user://run.json` = `{run, levels (run StatLevels), revive_used}` via `SaveStore.save_run/load_run/delete_run` at every doors/room boundary; deleted when the run ends. Death banks 0% (`RunConfig.death_bank_rate`); the summary's rewarded "save half" adds 50%. Run levels are bought in battle: `GameRoot._on_buy_level_requested` (hook for `BattleView.buy_level_requested`; items/shop wiring is a TODO in `_sync_view_shop`). Dev: `-- --screen=<doors|fight>`.

## Rewards (core/run/rewards, data/rewards/reward_tuning.tres)

After a won combat room the game layer calls `RewardGenerator.generate(run, plan, ctx) -> RewardOffer` (seeded by `RunRng.REWARD_CHOICE` from seed + depth + step; `ctx` only filters owned relics / full stacks). Elite/boss: 3 cards of different kinds (relic / stat_level / consumable); other fights: 2 of souls / consumable / heal; layout is `RewardTuning`. Show `offer.cards` (`title()`, `info()`, `tag_key`, `icon_path`, `payload`), then `offer.apply(index, run, ctx)` once; `RewardContext(run_levels, inventory)` holds the owned `relics` ids (`relic_modifiers()` at fight start, `to_dict/from_dict` to save). New kind = one `RewardKind` file + one line in `RewardKindCatalog` + a kind id in the tuning lists.

---
name: combat
description: >
  Soulsclicker duel model (core/combat): Duel, fighters and states, attack kinds, enemy/tuning data, signals
  and payloads, how to add an attack kind or an enemy, how to run the combat tests and the bot simulation.
  Use when touching combat rules, enemy data, balance, or wiring the battle view to the duel.
---

## Model

- `Duel(tuning, enemy_definition, seed, level = 1, player = null)`: `advance(dt)` (sliced into <= 0.02 s),
  `try_attack/try_block` (gated by `input_enabled`), `perform_attack/perform_block` (no gate), all return
  `bool accepted`. Fields: `player`, `enemy` (`Fighter`), `time`, `finished`, `winner`, `pattern`, `rng`.
- `Fighter`: `side` (`Fighter.PLAYER`/`ENEMY`), `max_hp`, `hp`, `max_stamina`, `stamina`, `damage`, `state`.
  States are classes (`IdleState`, `AttackingState`, `BlockingState`, `StaggeredState`) over `FighterState`
  hooks: `duration`, `enter`, `advance`, `on_finished`, `can_act`, `stamina_regen_factor`,
  `damage_taken_multiplier`, `receive_strike`, `after_strike`. State ids: `idle attacking blocking staggered`.
- Rules: parry = block pressed <= `parry_window` before the strike (frees the player at once, staggers the
  enemy, cancels the rest of a combo); plain block = chip share + `block_stamina_cost`; no block = full hit.
  Player attack damage lands when the attack is accepted; `attack_duration` is the recovery lock (a strike
  landing in it hits). Damage x `punish_multiplier` while the target is staggered. Block has `block_cooldown`
  after it ends. Stamina regenerates only in idle.
- Heavy: plain block fails -> `hit`, damage x `guard_break_damage_share`, stamina drained, `guard_broken`.
- Feint: telegraph reports the `imitates` kind id; resolves as outcome `feint`, no damage.
- Pattern: `AttackPattern.next_step(rng)` -> override `_pick_index` for random/weighted; assign `duel.pattern`.
- Scaling: `CombatScaling(tuning, level)` is the only place enemy hp/damage/souls grow with level.

## Signals (Duel)

- `telegraph_started(attack_kind_id, duration, index_in_combo)`
- `strike_resolved(result: StrikeResult)`: `kind_id outcome(hit|blocked|parried|feint) strike_index
  strike_count damage target_side target_hp stamina_cost staggers_attacker guard_broken`
- `player_attacked(damage, enemy_hp)`, `stamina_changed(value, max)`, `fighter_state_changed(side, state_id)`,
  `duel_finished(winner_side)`
- Extra: `fighter_state_timed(side, state_id, duration)` (right after state_changed, INF for idle),
  `action_rejected(action_id, reason)` (reasons: `disabled finished busy stamina cooldown`).

## Add an attack kind

New `core/combat/<name>_attack.gd` extending `AttackKind`; override `id`, and only the hooks that differ
(`telegraph_id`, `strike_count`, `telegraph_time`, `strike_damage`, `resolve`, `on_hit/on_blocked/on_parried`).
Add one line to `AttackKindCatalog._factories`. Extra numbers: new `@export` on `AttackStepDefinition`.

## Add an enemy

Copy a file in `data/enemies/`: `EnemyDefinition` with `name_key` (`ENEMY_X`, add it to the locale CSV) and a
`pattern` of `AttackStepDefinition` sub-resources. No code. Re-run the sim and tune.

## Run

```
godot --headless --path . -s tests/combat_test.gd          # exit 0/1, prints each check
godot --headless --path . -s tests/combat_sim.gd -- 200    # win rate / length per enemy and bot
```
Rebuild the class cache first after adding a `class_name` file: `--headless --path . --editor --quit-after 3`.

## Status of the modifier work (T6)

Done: nothing implemented in code yet. The codebase is unchanged and green (combat 53, run 86, platform, battle pass).

Not done yet (planned design, see `.claude/docs/design/core_hooks.md`, `items.md`):
- `core/modifiers/`: `Modifier` base (hooks as no-op virtuals, `modify_stat(stat_id, value, ctx)`), `ModifierStack`
  (priority then acquire order), `HookApi` whitelist with proc depth cap 4, `StatModifier` (add/mul/set), `ModifierCatalog`.
- `CombatStats` per fighter (base from `CombatTuning`, then modifiers, cached, invalidated on stack change) and
  `Duel` reading only `fighter.stats` (replaces direct `tuning` reads in `Duel`, `AttackKind`, `HeavyAttack`,
  `BlockingState`, `StaggeredState`). Planned extra stats: `stagger_time`, `perfect_threshold`, `block_hold_drain`,
  `telegraph_scale`, `damage_taken_mult`, `guard_break_damage_share`.
- Equipment (`Equipment`, `EquipmentStat`, `Loadout`) and `data/equipment/` (buckler, kite/tower shield, dagger,
  sword, greatsword, light/heavy armor); elite affixes `swift`, `plated`; relics menders_thread, glass_blade,
  counter_tide, phoenix_ash, overreach, duelists_pride.
- Hold-to-block (`block_mode` tap|hold, `perform_block_release`/`try_block_release`), `Duel.revive_player(hp_fraction)`
  with `on_would_die`, new signals (`player_hp_changed`, `enemy_hp_changed`, `modifier_triggered`, `player_revived`).
- Tests (`tests/modifier_test.gd`, extra combat tests) and the per-loadout sim.
- `.claude/skills/modifiers/SKILL.md`.

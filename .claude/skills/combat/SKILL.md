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
- `Fighter`: `side` (`Fighter.PLAYER`/`ENEMY`), `hp`, `stamina`, `state`, `mods` (`ModifierStack`), `stats`
  (`CombatStats`); `max_hp`, `max_stamina`, `stamina_regen`, `damage` are properties over `stats` (setting = new base).
  States are classes (`IdleState`, `AttackingState`, `BlockingState`, `StaggeredState`) over `FighterState`
  hooks: `duration`, `enter`, `advance`, `on_finished`, `can_act`, `stamina_regen_factor`,
  `damage_taken_multiplier(attacker_stats)`, `receive_strike`, `after_strike`. State ids: `idle attacking blocking staggered`.
- Numbers: nothing in `Duel`/kinds/states reads `CombatTuning` directly; they read `fighter.stats.value(CombatStats.X)`
  (base from tuning, then the modifiers of that fighter, see the `modifiers` skill). `duel.tuning` stays as the base.
- Block (hold + minimum): `try_block()` is the PRESS and starts the guard; it stays up while held and at least
  `block_min_duration` after the press (ends at max(release, press + min)); `try_block_release()` is the release
  (ungated, ignored without a guard; emits `fighter_state_timed(player, blocking, remaining)` if the guard must
  still last). A press with no release holds forever. Attacking while guarding drops the guard (if the attack is
  accepted). State `blocking` is timed INF while held.
- Parry = the strike lands within `parry_window` of the PRESS (after `block_startup`, the time before the guard
  is up; a strike earlier hits). Frees the player at once, staggers the enemy, cancels the rest of a combo.
  `StrikeResult.precision` (0..1 in the window) and `perfect` (>= `perfect_threshold`).
- Plain block: damage x `chip_share`, stamina cost = incoming damage x `block_cost` per hit (no drain over time).
  Stamina would reach 0 -> guard break (`hit`, damage x `guard_break_damage_share`, stamina drained, `guard_broken`,
  guard drops). `guard_break_resist` (0..1) pulls a break towards a plain block. No block = full hit.
- Player attack damage lands when the attack is accepted; `attack_lock` is the recovery lock (a strike landing in it
  hits). Damage x `punish_mult` while the target is staggered, x attacker `damage_dealt_mult`, x target
  `damage_taken_mult`. Block has `block_cooldown` after it ends. Stamina regenerates only in idle.
- Heavy: a plain block always fails as a guard break (see above).
- Enemy windups are scaled by `enemy.stats.telegraph_scale` (affix `swift`).
- Revive: `revive_player(hp_fraction) -> bool` (only after the enemy won): same duel continues, hp set, enemy idle,
  enemy waits `revive_grace`. Emits `player_revived`, `player_hp_changed`.
- Feint: telegraph reports the `imitates` kind id; resolves as outcome `feint`, no damage.
- Pattern: `AttackPattern.next_step(rng)` -> override `_pick_index` for random/weighted; assign `duel.pattern`.
- Scaling: `CombatScaling(tuning, level)` is the only place enemy hp/damage/souls grow with level.

## Tempo and combo (clicker feel)

- Tempo is data in `default_tuning.tres`: `attack_duration` (lock) 0.2, `attack_stamina_cost` 10, `player_damage` 3;
  enemy hp in `data/enemies` is x2.5 (grunt 175, knight 225, warden 550). Fights ~8-20 s for the bots.
- Block: `chip_damage_share` 0.05 (blocked damage is paid mostly in stamina), `block_stamina_cost` 1.35 per damage
  point (~4 quick hits or ~2 knight heavies per full bar); stamina gone = guard break. Shield chip modifiers are additive.
- Combo is a core rule in `Duel` (no modifier): `duel.combo` counts consecutive player hits without taking damage.
  Attack damage x `combo_multiplier()` = min(1 + `combo_step` * combo, `combo_max_multiplier`) (+10% per hit, cap x3).
  A hit while the enemy is staggered (post-parry window) is a crit: it already gets `punish_mult`, and counts
  `combo_crit_weight` (2) times. Reset to 0 when a strike outcome is `hit` with damage > 0 (so a guard break
  resets, a plain block, parry and feint do not); also on revive. Proc/free attacks do not use or feed the combo.
  Tuning: `combo_step`, `combo_max_multiplier`, `combo_crit_weight`.

## Signals (Duel)

- `telegraph_started(attack_kind_id, duration, index_in_combo)`
- `strike_resolved(result: StrikeResult)`: `kind_id outcome(hit|blocked|parried|feint) strike_index
  strike_count damage target_side target_hp stamina_cost staggers_attacker guard_broken`
- `player_attacked(damage, enemy_hp)`, `stamina_changed(value, max)`, `fighter_state_changed(side, state_id)`,
  `duel_finished(winner_side)`
- `player_hit(damage, enemy_hp, crit, combo)`: right after `player_attacked` (unchanged), `combo` = counter after
  this hit. `combo_changed(count, multiplier)`: on every hit and on reset (0, 1.0).
- `strike_timing(strike_in, parry_window, attack_kind_id, index_in_combo)`: with every telegraph and every combo
  strike (window from the player's stats), so the view can draw the timing cue.
- `player_hp_changed(hp, max)`, `enemy_hp_changed(hp, max)`, `modifier_triggered(mod_id, side)` (relic icon flash),
  `player_revived(hp)`.
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
godot --headless --path . -s tests/combat_sim.gd -- 200    # win rate / length per enemy, bot and loadout
godot --headless --path . -s tests/modifier_test.gd        # stats, equipment, relics, hold block, revive
```
The sim bots release the block right after the press and do not attack while guarding.
Rebuild the class cache first after adding a `class_name` file: `--headless --path . --editor --quit-after 3`.


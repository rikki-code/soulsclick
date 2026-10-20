# soulsclicker: core hooks (contract for programmers)

Goal: every relic, curse, status, enemy affix, pattern mutator, vessel creed, Dread rule and boss phase is **one file or one data entry**. No `if item == X` in core.
**PROPOSAL, needs user ack** (new abstraction per `godot-architecture`): one `Modifier` base class used by all of the above, hosted on fighters and on the run.

## 1. Model

```
Modifier (RefCounted)      all hooks = no-op virtuals. fields: definition, stacks, run_data{} (saved), fight_data{} (reset per fight)
                           param(key) -> float  (definition.params x rank curve x stacks)
ModifierDefinition (Resource)  id, name_key, desc_key, tags[], rarity, pools[], params{}, max_stacks, script_id,
                           stat_mods[] {stat, op: add|pct|more, value}, requires[], unlock_id, priority,
                           synergy_with[], visual_tag, wants_tick, reacts_to_proc
ModifierCatalog            script_id -> Modifier script (catalog, no match). No script_id => pure StatModifier (data only).
ModifierHost               ordered list (priority, acquire index); fire(hook, ctx); one on RunState, one per Fighter
HookApi ("fx")             the ONLY way a modifier changes the world (section 5)
```

- Player relics live in `RunState.mods`; `Duel` builds the player's host from it, enemy host from `EnemyDefinition` + affixes + mutators + room conditions.
- Same hooks fire for both sides. `ctx.owner` = fighter hosting the modifier, `ctx.foe` = the other. Player relic that debuffs the enemy just targets `foe`.
- Statuses (Bleed...) are Modifiers added to a host with `stacks`/`duration`, using `on_tick`.

## 2. Hooks

Receivers: **O** = owner's modifiers only, **B** = both hosts. `W` = writable ctx fields. P0 = needed for vertical slice.

### Run-level (called by `RunState`)
| Hook | When | Ctx (`RunCtx`/`RoomCtx`/`OfferCtx`) | W | P |
|---|---|---|---|---|
| `on_acquire(ctx)` | modifier added | run view | - | 0 |
| `on_remove(ctx)` | removed/fused/cleansed | run view | - | 0 |
| `on_run_start(ctx)` | run begins (vessel creed, curses, Dread rules) | vessel_id, dread, omens, seed | - | 0 |
| `on_room_enter(ctx)` | door chosen | room kind, depth, realm, enemy_def (if fight) | - | 0 |
| `on_room_exit(ctx)` | room done | room kind, fight summary (flawless, hp_lost, time) | - | 0 |
| `modify_offer(ctx)` | an offer (altar/elite/boss/shop/shrine) is generated | source, candidates[] (ModifierDefinition), prices[], size, rerolls | candidates, prices, size | 0 |

### Duel-level (called by `Duel`)
| Hook | When | Recv | Ctx | W | P |
|---|---|---|---|---|---|
| `on_fight_start(ctx)` | duel built, before 1st telegraph | B | `FightCtx` | - | 0 |
| `on_fight_end(ctx)` | winner decided | B | `FightCtx` + winner, flawless | - | 0 |
| `on_tick(ctx, dt)` | every frame, only if `wants_tick` | B | `FightCtx` | - | 1 |
| `modify_stat(ctx, value) -> float` | any stat read (cached, dirty flag) | B | `StatCtx`: stat, subject side | return value | 0 |
| `modify_enemy_step(ctx)` | before each enemy step starts | B | `StepCtx`: step, index, phrase_id | replace / insert_after / skip, step fields | 0 |
| `on_telegraph_started(ctx)` | telegraph begins | B | `TelegraphCtx`: kind_id, duration, index_in_combo, is_feint | parry_window_scale, reveal_feint, hide_glow | 0 |
| `modify_attack(ctx)` | player attack accepted, before cost | O (attacker) | `AttackCtx`: stamina_cost, hp_cost, lock_time, damage, hits, during_punish, combo_index | all those + cancel | 0 |
| `modify_strike(ctx)` | strike moment, outcome computed | B | `StrikeCtx` | outcome, damage, repeat | 0 |
| `on_parry(ctx)` | outcome parried | defender | `StrikeCtx` | - | 0 |
| `on_block(ctx)` | outcome blocked | defender | `StrikeCtx` | - | 0 |
| `on_strike_result(ctx)` | any outcome, after resolve | attacker | `StrikeCtx` | - | 1 |
| `on_block_ended(ctx)` | block timer ends | O | `BlockCtx`: duration, whiffed (no strike met it) | - | 1 |
| `on_damage_dealt(ctx)` | HP lost by target, after Ward | source | `DamageCtx` | - | 0 |
| `on_damage_taken(ctx)` | same event | target | `DamageCtx` | - | 0 |
| `on_heal(ctx)` | HP restored | O | `HealCtx`: amount, overflow | - | 1 |
| `on_stagger_started(ctx)` | fighter staggered | B | `StaggerCtx`: target side, cause, duration | duration | 0 |
| `on_stagger_ended(ctx)` | stagger over | B | `StaggerCtx` + hits_landed, punished | - | 0 |
| `on_stamina_empty(ctx)` | stamina reaches 0 (edge) | O | `FightCtx` | - | 0 |
| `on_status_applied(ctx)` | status about to apply | B | `StatusCtx`: status_id, target, stacks, source_mod | stacks, cancel | 0 |
| `on_would_die(ctx)` | HP <= 0, before death | O | `DeathCtx`: killer, damage | prevent(hp) | 0 |
| `on_death(ctx)` | death confirmed | B | `DeathCtx` | - | 0 |
| `on_cast(ctx)` | Art cast (Focus full, both buttons) | O | `CastCtx`: focus | - | 1 |

Total 28 hooks (6 run, 22 duel); 23 are P0. Rule: add a hook only with a relic that needs it.

## 3. Context types

Base `HookCtx` (all contexts extend it):

| Field | Meaning |
|---|---|
| `owner`, `foe` | `Fighter` (read) |
| `side` | `&"player"` / `&"enemy"` of owner |
| `fight` | read-only view: time, parry_streak, hits_taken, attacks_made, strikes_seen, flawless, punish_active, stamina_ratio, hp_ratio(side), is_boss |
| `run` | read-only: realm, depth, souls, dread, `has(id)`, `tag_count(tag)`, `curse_count` |
| `fx` | `HookApi` |
| `rng` | per-modifier `RandomNumberGenerator`, seeded from run seed + modifier id + fight index (determinism) |
| `depth` | proc chain depth (see rules) |
| `mod` | the modifier itself (params, stacks, `fight_data`) |

`StrikeCtx`: attacker, defender, kind_id, strike_index, damage (W), outcome (W: `hit`/`blocked`/`parried`/`negated`), **precision** 0..1 (1 = pressed at the last instant of parry window), `perfect` (precision >= `CombatTuning.perfect_threshold`), guard_breaking (heavy), time_since_block_press, `repeat` (W, default 1: Duel re-fires parry/block hooks `repeat` times = Balatro retrigger).
`DamageCtx`: source side, target side, amount (final, after Ward), prevented, tags[] (`strike`, `attack`, `punish`, `dot`, `reflect`, `proc`, `blast`, `self`), `strike` (StrikeCtx or null), killed, target_hp.
`StepCtx`: `step: AttackStep` {kind_id, telegraph_time, strike_delay, damage, strikes, gap_after, tags[]}, index, phrase_id.
`FightCtx`: summary counters above.

## 4. Stat bus (`modify_stat`)

Resolve: `(base + sum(add)) * (1 + sum(pct)) * product(1 + more)`, then clamp from data. Base = `CombatTuning` + vessel + bonfire upgrades.

| Stat | Stat | Stat |
|---|---|---|
| `max_hp` | `attack_damage` | `parry_window` |
| `max_stamina` | `attack_cost` | `perfect_threshold` |
| `stamina_regen` | `attack_lock` | `block_duration` |
| `block_cost` | `chip_share` | `punish_duration` |
| `punish_mult` | `stagger_time` | `telegraph_scale` (enemy) |
| `strike_delay_scale` (enemy) | `damage_taken_mult` | `damage_dealt_mult` |
| `heal_mult` | `souls_gain` | `focus_gain` |
| `status_potency` (per status id) | `forecast_depth` | `door_info` |
| `offer_size` | `rerolls` | `luck`, `shop_price_mult` |

Conditional stats (Last Stand, Tithe Crown) are a `modify_stat` override reading `ctx.owner.hp`/`ctx.run.souls`; no extra hook.

## 5. HookApi (effects; everything emits events, so the view stays dumb)

| Call | Effect |
|---|---|
| `heal(side, n)`, `damage(side, n, tags)` | HP change (tagged `proc`) |
| `add_ward(side, n)` | shield |
| `add_stamina(side, n)` | stamina |
| `apply_status(side, id, stacks, duration)` | goes through `on_status_applied` |
| `stagger(side, t, cause)` | stagger |
| `add_focus(n)` | Art meter |
| `add_souls(n)`, `add_curse(id)`, `grant(id)`, `remove(id)` | run-level, only in run hooks or `fight_end` |
| `prevent_death(hp)` | only in `on_would_die` |
| `queue_free_attack(damage_mult)` | auto-riposte; costs nothing, no lock |
| `set_flag(key, value)` | `fight_data`/`run_data` |
| `cue(cue_id, side, tag)` | view-only flourish (aura flash, sound layer) |

Every successful `fx` call also emits `modifier_triggered(mod_id, side)` automatically, so the UI flashes the relic icon without item code.

## 6. Rules

- **Procs**: effects from `fx` carry tag `proc` and `ctx.depth + 1`. A modifier ignores `proc` events unless `reacts_to_proc = true`; hard depth cap 4. No infinite loops.
- **Order**: priority, then acquire order; stat bus order is fixed by op, so stat items are order-free; hook items are order-dependent only if they set `priority` (default 0).
- **Determinism**: all randomness via `ctx.rng`; no wall clock; same seed + same inputs = same fight log (existing test style). Bot sims run relics too.
- **No state in fighters for items**: use `fight_data`/`run_data`; `run_data` is saved (recipe: seed + `[ {id, stacks, run_data} ]`).
- **Feints and fairness**: a modifier may hide info only via flagged ctx fields (`hide_glow`); pose of the telegraph is never hidden.
- **Perf**: lists are small; `on_tick` only for `wants_tick`; stat results cached with dirty flag on any modifier add/remove/status change.
- **View contract**: new signals on `Duel`/`RunState`, each carries full data:
  `modifier_triggered(mod_id, side)`, `status_changed(side, id, stacks, duration)`, `ward_changed(side, value)`, `focus_changed(value, max)`, `streak_changed(n)`, `forecast_changed(steps[])`, `stagger_started(side, duration, cause)`, `offer_ready(source, cards[])`, `room_entered(kind)`, `run_ended(summary)`.
- **Strike result** gets `precision`, `perfect` and `repeat`; `StrikeResult` in `architecture.md` must carry them.

## 7. Core additions beyond hooks

`Fighter.ward`, `Fighter.statuses` (via host), `Duel.focus`, `parry_streak`, `Duel.forecast()` (peek N steps), `AttackStep` extra fields (strike_delay, strikes, tags), pattern as phrases (`EnemyDefinition.phrases`), `ThreatBudget` generator, `RunState` (seed streams: map, loot, enemy, fight), `SetBonusTracker`, `RecipeService`, `StatsRecorder` (counters for achievements: parries, perfect_parries, flawless_fights, relics_held, tag counts, kills per enemy).

## 8. Examples (one file each)

```gdscript
class_name MendersThread extends Modifier
func on_parry(ctx: StrikeCtx) -> void:
    ctx.fx.heal(ctx.owner.side, param(&"heal") * (2.0 if ctx.perfect else 1.0))
```
```gdscript
class_name RecklessOath extends Modifier
func modify_attack(ctx: AttackCtx) -> void:
    ctx.hp_cost = ctx.owner.max_hp * param(&"hp_pct"); ctx.stamina_cost = 0.0
```
```gdscript
class_name VampireFang extends Modifier
func on_damage_dealt(ctx: DamageCtx) -> void:
    if ctx.has_status(ctx.foe, &"bleed") and fight_data.cooldown_ready(ctx.fight.time, 1.0):
        ctx.fx.heal(ctx.side, param(&"heal"))
```
Enemy affix example: `Swift` is data only: `stat_mods: [{stat: telegraph_scale, op: more, value: -0.25}]` on the enemy host.

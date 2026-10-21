# Road: view/game contract (agree first, build independently)

One persistent `BattleView` per run. It owns the road, the enemy rig, HUD, overlays. `GameRoot` drives it.
Enemy swap inside one view already exists (`begin(definition, enemy, player)` as in `_next_wave_enemy`).

## BattleView API (owner: view/battle/battle_view.gd, task V)

- `set_road(realm_index: int, seed: int) -> void`: replaces the background texture with a `RoadScene` of that realm
  (call at run start and when the realm changes). Road stands while fighting.
- `walk(seconds: float) -> void`: enemy rig, enemy bars, telegraph hidden; `RoadScene.set_speed` up for `seconds`,
  ease in/out; input disabled during; emits `walk_finished` at the end (also usable with `await view.walk_finished`).
- `clear_enemy() -> void`: hide rig and enemy bars (between encounters). `begin(...)` shows them again (enemy
  steps in: scale up from far, ~0.5 s) .
- `show_rewards(offer: RewardOffer) -> void` -> signal `reward_picked(index: int)` (uses `RewardOverlay`).
- `show_fork(offer: DoorOffer) -> void` -> signal `trail_picked(index: int)` (uses `ForkView`, removed after pick).
- The victory overlay "Continue" button is gone: `show_victory(souls)` only flashes a "Victory +N souls" banner for
  ~1 s, no button, no `continue_pressed`. Death overlay stays.
- Signals: `walk_finished`, `reward_picked(index)`, `trail_picked(index)`.

## GameRoot flow (owner: game/game_root.gd, tasks G1 then G2)

G1: persistent view (create once on first room, reuse; free only at run end / menu), `_start_fight` reuses it;
after the last wave: banner, then `RewardGenerator.generate(run, plan, ctx)`; if `is_open()`: `view.show_rewards`,
`offer.apply(index, run, ctx)`, then `_complete(RoomResult.victory(hp))`. `RewardContext` (relics, run_levels,
inventory) owned by GameRoot, saved in the run envelope, relics' `relic_modifiers()` added to `duel.player.mods` at
every fight start. Stat level reward: re-apply stats.
G2: after `complete_room`: doors offer with 1 door → `view.walk` then enter; >1 → `view.walk(short)`,
`view.show_fork(run.offer)`, `trail_picked` → `run.choose_door` → `view.walk` → next room. Non-combat rooms
(altar, bonfire, shop) and crossroads show as overlays above the persistent view (not replacing it). Realm change →
`view.set_road`.

## Addendum: fork is part of the road (visible in advance), 2026-10-21

The fork is a WORLD object of RoadScene, not an overlay. It is placed far ahead (visible as a junction with tiny
landmarks) while you still fight the room before it, then you walk up to it, stop, tap a trail.

RoadScene (owner: view/road/road_scene.gd + new view/road/road_fork.gd, task A):
- `show_fork(offer: DoorOffer) -> void`: the junction at depth `FORK_FAR_Z` (~0.9, near the horizon): the road splits
  in perspective into 2-3 trails (symmetric left/right, or left/straight/right), each trail a road to the
  horizon with its landmark (ForkLandmarks) at the far end + small label (kind name, hint, reward line). The fork
  depth is a world position: it approaches with `scroll`/`set_speed` exactly like props.
- `walk_to_fork() -> void`: starts walking (speed eased) until the fork reaches `FORK_STOP_Z` (~0.14, trails big,
  landmarks readable), stops, emits `fork_reached`.
- signal `fork_reached`, signal `trail_picked(index: int)`. Tap on a trail/landmark picks (hit polygons projected
  from the same world positions; works while approaching too but only emits after fork_reached).
- `update_fork(offer: DoorOffer)`: refresh labels with the real offer (same doors, may differ in reward text).
- `pick_trail(index)` (called internally by tap): the camera steers into that trail (lateral shift eases to the
  trail lane over ~0.8 s, other trails fade), fork then passes behind and is removed; `clear_fork()` also exists.
- Straight stretches have no fork. No bend inside the junction zone (road locally straight around the fork).

Run (owner: core/run, task C): `Run.peek_next_offer() -> DoorOffer`: the offer of the next step in this realm
(null when the next step is beyond the realm or has < 2 doors). Needs `DoorGenerator.generate_at(run, depth,
step_index)` (pure function of seed/depth/step, `generate(run)` calls it).

BattleView (task C): `preview_fork(offer)` -> `RoadScene.show_fork`; `walk_to_fork()` + signal `fork_reached`
forwarded, signal `trail_picked(index)` forwarded from RoadScene. The overlay `ForkView` is no longer used.

GameRoot (task C): when a fight starts, if `_run.peek_next_offer()` is a fork, `view.preview_fork(offer)`; after
the reward / `complete_room`: if the run offer is that fork: `view.walk_to_fork()` -> wait `fork_reached` ->
`view.update_fork(run.offer)` -> wait `trail_picked` -> `run.choose_door(index)` -> enter room (enemy steps in
from far on the chosen trail). Single-door steps unchanged (walk + enter).

## Addendum 2: you WALK the chosen trail (no enemy running in), 2026-10-21

- RoadScene: `pick_trail(i)` steers into trail i and KEEPS walking along it until that trail's landmark reaches
  `ARRIVE_Z` (~0.12, the depth where the enemy rig stands on screen), then stops, emits `trail_arrived(index: int)`.
  The landmark stays drawn (big now). `fade_fork(seconds: float)`: landmark + remaining trail fade out, then the
  fork is removed (`clear_fork`). The trunk must never peek out beside the chosen trail.
- Trails use EXACTLY the trunk's road texture (`_road_colors`, same noise, same edge), no own mottling.
- BattleView: forwards `trail_arrived(index)`; `begin(..., step_in := true)`: with `false` the enemy rig appears in
  place (quick 0.25 s fade-in, no scale from far) while `fade_fork(0.4)` runs.
- GameRoot: `trail_picked` -> `choose_door(index)` (room created, not yet entered) -> wait `trail_arrived` (replaces
  the 0.9 s timer) -> enter the room with `step_in = false` for fight rooms; altar/bonfire/boss gate rooms open their
  overlay after arrival. Single-door steps keep the old walk + step-in.

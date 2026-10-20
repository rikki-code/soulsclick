---
name: battle
description: >
  Soulsclicker duel screen (view/battle, game/game_root, GameSession run state): how Duel events map to
  visuals, EnemyRig and rig.json loading, layout rules, end-of-fight flow, dev screenshot flag, tests. Use when
  touching the battle view, enemy rig playback, HUD, overlays, input keys or the run/revive flow.
---

## Wiring

- `GameRoot` (`game/game_root.gd`, composition root): loads `CombatTuning`, builds `Duel` from
  `GameSession.current_enemy()`, calls `duel.advance(delta)` in `_process`, connects Duel signals to `BattleView.on_*`,
  mounts the active `InputScheme` into `BattleView` and maps its `attack_requested/block_requested` and the keys (Attack: Right/D/J, Block: Left/A/F, Esc: menu, handled once here) to `try_attack/try_block`. First battle per scheme shows a hint (`HINT_<ID>`, `ProfileData.hinted_schemes`).
- `GameSession` run state: `ENEMY_ORDER` (grunt, knight, warden), `run_index`, `revive_used`, `current_enemy()`,
  `advance_run()`, `reset_run()`, `use_revive()`. Reset when leaving to the menu.
- Victory: souls = `CombatScaling.souls(definition.souls_reward)` added to the profile, `save_profile()`, overlay
  Continue -> `advance_run` + `SceneRouter.to_game()`, after the last enemy -> menu. Death: Revive (once per run,
  `await Platform.show_rewarded()`) builds a NEW `Duel` with the same enemy hp and a fresh player (core is not
  reopened), `BattleView.begin()` rebuilds the view; Back -> menu. `Platform.gameplay_started/stopped` bracket a duel.

## view/battle

- Input (`view/battle/input/`): `InputScheme` base (full-rect Control; `handle_event` reads raw `InputEventScreenTouch/Drag` per finger index and left mouse; mouse events with `DEVICE_ID_EMULATION` (synthesized from touch) are skipped, so `emulate_mouse_from_touch` stays on for menus and project.godot is untouched). Hooks: `layout`, `reserved_height` (bottom strip the HUD/enemy stay above), `on_action_accepted/on_action_rejected/on_strike_resolved/on_player_state`. `HandsScheme` (left half block (hold), right half attack; `PlayerRig` = EnemyRig over `PlayerRigSpec.load_hands()`: pack `view/packs/player_pack/silhouette_pack/hands/rig.json` if present, else polygon placeholder; poses follow player fighter state + strike outcome), `ButtonsScheme` (buttons are only the look, hit-tested from touches so two thumbs work), `SwipeScheme` (40 px vertical travel fires, one action per touch). `InputSchemeCatalog`: ids, `make`, `resolve` (saved id, else Hands on touch devices / mobile web, Buttons otherwise). Chosen in Settings "Controls" (`ProfileData.input_scheme`, "" = auto), applied on the next battle.
- `BattleView`: layers bg (0) < stage with rig (1) < HUD (2) < fx (3) < overlay (4). Never reads the duel; only
  `on_*` handlers. `_layout()` on viewport size: ground = above the player bars, which sit above the scheme's reserved strip at the bottom; rig scaled to fit between the top HUD and the ground, background scaled/offset so its ground line (bg y 1500) meets it. Damage numbers on the player float above the bars (`_hit_point`).
- Event -> visual: `telegraph_started` windup pose over `duration` + glow pulse (`GlowStyles`, per kind id) + meter;
  `strike_resolved` strike pose -> recover -> idle, shake/flash/number per outcome, parry = sparks + `BATTLE_PARRY`;
  `player_attacked` hurt pose (only a nudge during a telegraph, to keep it readable); `fighter_state_timed`
  player = lock bar, enemy `staggered` = pose held until the enemy goes idle; `action_rejected` = button wiggle.
- `EnemyRig`: part tree from `RigSpec` (`rig.json`; polygon placeholder when missing). Part node origin = its
  pivot, `position = at + move - parent.pivot`, `z_index` absolute. `play_pose`/`play_sequence` are awaitable and
  resolve also when replaced. Glow parts get an additive overlay (`glow_add.tres`) plus a radial halo.
- `BattleFx`: pooled `CPUParticles2D` sparks, floating numbers, shake (stage), full-screen flash.
- `BattleOverlay`: victory/death panels. `StatBar`: bars with ghost trail.
- Packs: `BattlePaths` (`silhouette_pack` enemy and background packs).

## Clicker feel, pause, shop (public BattleView API)

- `on_combo_changed(count, multiplier)`: counter top-right ("x12" + "×2.2"), punch per hit, color heats up with the multiplier, shake+fade on 0 (shown from count 2). `on_player_hit(damage, enemy_hp, crit, combo)` right after `on_player_attacked`: owns the damage number (`on_player_attacked` only queues a deferred fallback number, dropped if player_hit arrives); crit = big golden number, "CRIT!" pop (key `BATTLE_CRIT`, falls back to English), extra sparks; short real-time hit-stop (`Engine.time_scale` dip) on crit or combo >= 8. `BattleFx.hit_number/number/fly_text`, pool 16.
- Pause: ☰ button (top-left) or `toggle_pause()/open_pause()/close_pause()/is_paused()`; `PauseMenu` (PROCESS_MODE_ALWAYS, layer 5). Signals: `pause_requested`, `resume_requested`, `settings_requested`, `abandon_requested`, `menu_requested`. The view disables the scheme input while paused but never pauses the tree; game_root stops the duel clock and routes Esc to `toggle_pause()`.
- Shop (`ShopPanel`, no drawer: always-visible right-edge column of ~96px round buttons, one tap = action: level buys, consumable uses if count>0 else buys, run buff buys; glyph + price, count badge, pulsing ring when actionable, long-press 0.4s tooltip; buttons update in place so holds survive refreshes; spills to a 2nd column if the band is too short): `set_shop(items, levels, souls)` dicts `{id, name, icon_path, price, info, affordable}` (+ items: `count`, `usable`); `set_souls(souls)` (rolling HUD counter "Souls N", refreshes affordability, affordable buttons pulse); `on_souls_earned(amount)` flying "+N" from the enemy. Signals: `buy_item_requested(id)`, `buy_level_requested(stat_id)`, `use_item_requested(id)`. `InputScheme.excluded_rects` keeps presses on the ☰ button and every shop button from becoming attack/block.
- Optional locale keys (English fallbacks via `BattleText.text`): BATTLE_CRIT, PAUSE_TITLE/RESUME/SETTINGS/ABANDON/MENU, SHOP_*, HUD_SOULS.
- `StatBar`: fill now drains smoothly; `caption` and `ghost_color` are available (unused by the view yet).

## New things

- New attack kind: add a `GlowStyles.BY_KIND` row and `windup_<kind>` / `strike_<kind>` poses in each rig.json
  (missing pose = idle). New enemy: id in `GameSession.ENEMY_ORDER`, rig + background in the packs.

## Dev and tests

- `godot --path . --windowed --resolution 786x1704 game/game_root.tscn -- --shot=<abs png> --shot-at=<sec> --enemy=<id> --scheme=<hands|buttons|swipes> --gear=<shield>,<weapon> --act=<attack|block>` (scene path required, main scene is the menu) saves the
  viewport and quits (input disabled). Grunt telegraph is about 1.5-2.3 s.
- `godot --headless --path . -s tests/battle_test.gd` (rig specs, pose tween, placeholder fallback, session).
- Scene smoke: `godot --headless --path . game/game_root.tscn --quit-after 600` must print no script errors.

## Hands, gear, parry ring

- `PlayerLoadoutView` (shield_id, weapon_id; defaults kite + sword; `from_equipment(shield_eq, weapon_eq)` holds the one id map: buckler, kite_shield->kite, tower_shield->tower, dagger, sword, greatsword). `InputSchemeCatalog.make(id, loadout)` -> `HandsScheme(loadout)` -> `PlayerRig(loadout)` -> `PlayerRigSpec.load_hands(loadout)` adds parts `gear_shield` (child of hand_l) and `gear_weapon` (child of hand_r) from rig.json `slots` + gear.json, and applies gear.json `pose_offsets`. Dev: `--gear=<shield_eq>,<weapon_eq>`.
- Hands layout is measured: `PlayerRigSpec.part_rect` (same transform chain as the rig) gives the resting hands' top; `PlayerRig.zone_height` = that strip (gear rises over the enemy's lower body, bars are drawn above it) = scheme `reserved_height`. Landscape: reserved 0, hands spread to FIST_X_SHARE (0.2 / 0.8 of the width) by shifting the root arms' `at`, bars stay in the middle, hint goes to the left column.
- Block is held: schemes emit `block_requested` on press and `block_released` when the last blocking finger lifts (`InputScheme._hold_block/_release_block`). The rig keeps the `block` pose until the core says the player state left blocking (`on_player_state`).
- `ParryRing` (view/battle/parry_ring.gd): approach ring closes on a target ring around the enemy weapon pivot; the last `window` s before the strike is a band that lights up (+ small flash + pitched `enemy_telegraph` tick) when the window opens. `BattleView.on_strike_timing(strike_in, window, kind_id, index)`; also derived from `on_telegraph_started` with `BattleView.parry_window` (default 0.25, set it from the tuning). Static math: `radius_at`, `window_open_time`, `is_window_open_at`.
- New `class_name` files need `godot --headless --path . --import` once before windowed runs (stale class cache hangs the window).

## Not done yet

- game_root must connect `duel.strike_timing` (if present) to `BattleView.on_strike_timing`, `block_released` to `Duel.try_block_release`, and pass real equipment to `InputSchemeCatalog.make`.
- No test yet for gear nodes under the right hands or the ring timing math.
- No live scheme switch during a battle (applied on the next one). Directional parry swipes not started.
- Real touch devices not tested; multitouch verified with synthetic events in tests/battle_test.gd only.

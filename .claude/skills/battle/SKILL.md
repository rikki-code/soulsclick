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

- Input (`view/battle/input/`): `InputScheme` base (full-rect Control; `handle_event` reads raw `InputEventScreenTouch/Drag` per finger index and left mouse; mouse events with `DEVICE_ID_EMULATION` (synthesized from touch) are skipped, so `emulate_mouse_from_touch` stays on for menus and project.godot is untouched). Hooks: `layout`, `reserved_height` (bottom strip the HUD/enemy stay above), `on_action_accepted/on_action_rejected/on_strike_resolved/on_player_state`. `HandsScheme` (left half block, right half attack; `PlayerRig` = EnemyRig over `PlayerRigSpec.load_hands()`: pack `view/packs/player_pack/silhouette_pack/hands/rig.json` if present, else polygon placeholder; poses follow player fighter state + strike outcome), `ButtonsScheme` (buttons are only the look, hit-tested from touches so two thumbs work), `SwipeScheme` (40 px vertical travel fires, one action per touch). `InputSchemeCatalog`: ids, `make`, `resolve` (saved id, else Hands on touch devices / mobile web, Buttons otherwise). Chosen in Settings "Controls" (`ProfileData.input_scheme`, "" = auto), applied on the next battle.
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

## New things

- New attack kind: add a `GlowStyles.BY_KIND` row and `windup_<kind>` / `strike_<kind>` poses in each rig.json
  (missing pose = idle). New enemy: id in `GameSession.ENEMY_ORDER`, rig + background in the packs.

## Dev and tests

- `godot --path . --windowed --resolution 786x1704 game/game_root.tscn -- --shot=<abs png> --shot-at=<sec> --enemy=<id> --scheme=<hands|buttons|swipes> --act=<attack|block>` (scene path required, main scene is the menu) saves the
  viewport and quits (input disabled). Grunt telegraph is about 1.5-2.3 s.
- `godot --headless --path . -s tests/battle_test.gd` (rig specs, pose tween, placeholder fallback, session).
- Scene smoke: `godot --headless --path . game/game_root.tscn --quit-after 600` must print no script errors.

## Not done yet

- Hands show the pack's arms/hands only: the equipped shield/weapon (`player_pack/silhouette_pack/gear.json`, shields/, weapons/) are not attached to the rig, and the pack canvas (1080x1920) is fitted full-screen, so `HandsScheme.RESERVED_SHARE` (0.19) is approximate and hands overlap the player bars area/enemy feet a little.
- Landscape + hands: the enemy gets small (hands strip reserved); the hint text overlaps the enemy. Layout needs a tune.
- No live scheme switch during a battle (applied on the next one). Directional parry swipes not started.
- Real touch devices not tested; multitouch verified with synthetic events in tests/battle_test.gd only.

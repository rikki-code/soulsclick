# soulsclicker: architecture

Follows the workspace skills (`godot-architecture`, `godot-code-style`, `godot-persistence`,
`godot-assets-packs`, `godot-verify`, `godot-web`). This file holds the project-specific contracts.
`rpgmatch` (sibling folder) is the reference implementation of the same style.

## Folders

| Folder | Holds |
|---|---|
| `core/combat/` | Duel model: fighters, enemy attack patterns, attack kinds, resolution, events. Headless. |
| `core/profile/` | `ProfileData` (souls, levels, stats), codecs. Headless. |
| `data/enemies/`, `data/tuning/` | `EnemyDefinition` / `CombatTuning` `.tres` files. |
| `data/locale/` | `strings.csv` (keys + `en`, `ru`), imported as translations. |
| `view/audio/` | `Audio` autoload (copied from rpgmatch), audio packs under `view/packs/audio_pack/`. |
| `view/shell/` | Menu screens, settings, `UiScale`, shared UI kit. |
| `view/battle/` | Duel screen: enemy view, telegraph, bars, two buttons, death/victory overlays. |
| `view/packs/` | Swappable art/audio packs. |
| `game/` | `SceneRouter`, `GameSession`, `SaveStore`, `menu_root.tscn`, `game_root.tscn` (composition root). |
| `autoload/` | `Platform` facade and its adapters. |
| `tests/` | Headless test scripts, one per area: `godot --headless --path . -s tests/<name>_test.gd`. |
| `ci/`, `.github/` | Copied unchanged from rpgmatch (only the project name replaced). |

Knowledge direction: `game` → `view` → `core`; `autoload/Platform` is called from `game` and `view`, never
from `core`.

## Combat model (`core/combat/`)

- `Duel` (RefCounted) owns `player: Fighter`, `enemy: Fighter`, the enemy's `AttackPattern` cursor and the clock.
  `advance(dt: float)` moves time; the view calls it from `_process`, a headless test calls it with a fixed
  step. Same inputs at the same times = same result (seeded `RandomNumberGenerator` on the duel).
- Player input: `try_attack()` / `try_block()` (gated by `input_enabled`) and `perform_attack()` /
  `perform_block()` (no gate, for bots and tests). They return `bool` accepted.
- `Fighter`: `max_hp`, `hp`, `max_stamina`, `stamina`, `damage`, a `state` object (idle / attacking /
  blocking / staggered: each a small class with `enter`, `advance`, `can_act`), never an enum + `match`.
- `AttackKind` (base class, virtual hooks with defaults): `telegraph_time()`, `resolve(duel, strike) ->
  StrikeResult` hooks `on_parried`, `on_blocked`, `on_hit`. Kinds: `QuickAttack`, `HeavyAttack` (block
  breaks guard), `FeintAttack` (no strike), `ComboAttack` (holds a list of strikes). New kind = new file.
- `EnemyDefinition` (Resource): id, name key, hp, damage, `pattern: Array[AttackStepDefinition]`, palette tag,
  souls reward. `AttackStepDefinition` names a kind id and its numbers; `AttackKindCatalog` turns ids
  into instances (catalog, not `match`).
- `CombatTuning` (Resource): parry window, block duration, attack duration, stamina costs and regen,
  stagger time, punish multiplier, chip damage share. Level scaling goes through one curve object.
- **Stats come from equipment and skills, not from global tuning** (decided). Each `Fighter` has a
  `CombatStats` resolved as: base values (`CombatTuning` = defaults only) → equipment (`Equipment`
  Resources: weapon, shield, armor) → run items and skills (modifier objects). Stats: damage,
  attack_duration, attack_stamina_cost, block_startup, block_duration, block_cooldown, parry_window,
  chip_share, block_stamina_cost, guard_break_resist, stamina_max, stamina_regen, hp_max, punish_multiplier.
  Resolution = ordered list of `StatModifier` (add / multiply / override per stat id), recomputed when
  the loadout changes; `Duel` reads only `fighter.stats`. Enemy speeds likewise come from its definition
  plus elite modifiers. Examples: buckler = fast, wide parry window, high chip; tower shield = slow
  startup, low chip, resists guard break; dagger = fast, cheap, weak; greatsword = slow, costly, heavy.
- Events are signals on `Duel`, each carries everything the view needs:
  `telegraph_started(attack_kind_id, duration, index_in_combo)`, `strike_resolved(result: StrikeResult)`
  (outcome id `hit`/`blocked`/`parried`/`feint`, damage, target hp after), `player_attacked(damage, enemy_hp)`,
  `stamina_changed(value, max)`, `fighter_state_changed(side, state_id)`, `duel_finished(winner_side)`.
- The view never diffs state and never waits on a duration constant from core: it plays what the events
  say and gates its own animations with tweens.

## Platform facade (`autoload/platform.gd`, autoload `Platform`)

One entry point for everything a store or portal provides. Game code calls only this:

- `show_interstitial() -> void` (await-able, finishes when closed or failed).
- `show_rewarded() -> bool` (await-able; `true` only if the reward was earned).
- `is_rewarded_available() -> bool`.
- `submit_score(board_id: StringName, value: int)`, `gameplay_started()`, `gameplay_stopped()` (portals
  want these), `game_ready()` (called once the menu is shown).
- `locale() -> String` (platform language or OS locale, `en` fallback).
- Purchases: `purchase(product_id) -> bool`, `owns(product_id) -> bool` (stub until needed).

Adapters are classes behind one base `PlatformAdapter` with no-op/instant defaults. For now only
`NullAdapter` exists (ads are a stub: rewarded succeeds after a short fake delay in debug builds). Portal
adapters (Yandex etc., over `JavaScriptBridge`) come later: one adapter file + one `PlatformCatalog` line,
chosen once at startup from a feature tag or URL parameter.
Ads pause the game and mute audio (`get_tree().paused`, `Audio` buses) and restore after.

## Profile and saves

- `SaveStore` is the only class touching files (`user://profile.json`), versioned JSON, atomic write
  (pattern from rpgmatch `game/save_store.gd`).
- `ProfileData`: souls, character levels per stat, best stats, settings that are not audio. Save at
  checkpoints (fight end, level up), never on close.

## Scenes

`menu_root.tscn` (main) → `SceneRouter.to_game()` → `game_root.tscn` (builds `Duel` from
`GameSession` data, owns `BattleView`, wires signals) → back with `SceneRouter.to_menu()`.
Cross-frame waits are tweens owned by the scene, never `SceneTree.create_timer`.

## Enemy visuals (`view/battle/`, packs)

- `EnemyRig` (Node2D): named parts (`body`, `head`, `arm_l`, `arm_r`, `weapon`, ...) as child nodes; placeholder
  parts are colored polygons, final parts are SVG textures from an enemy pack (`view/packs/enemy_pack/<pack>/
  <enemy_id>.tscn`). Pose = per-part transform set (`RigPose` Resource); `play_pose(pose_id, duration)`
  tweens there and returns when finished.
- Pack layout: `view/packs/enemy_pack/<pack>/<enemy_id>/` holds one SVG per part plus `rig.json`:
  ```
  {"accent": "#c43a2f", "canvas": [1024, 1024],
   "parts": [{"id": "body", "file": "body.svg", "parent": "", "pivot": [x, y], "at": [x, y], "z": 0}, ...],
   "poses": {"idle": {"arm_r": {"rot": -10, "move": [0, 0]}, ...}, "windup_quick": {...}, ...},
   "glow_parts": ["weapon", "eyes"]}
  ```
  `pivot` = rotation point in the part's own SVG pixels; `at` = where that pivot sits in the parent's
  pixels (root: in canvas pixels); `rot` in degrees, `move` in parent pixels, both relative to the rest
  pose. Pose ids: `idle`, `windup_<kind_id>`, `strike_<kind_id>`, `recover`, `staggered`, `hurt`,
  `death`. A missing pose falls back to `idle`.
- SVGs must render with Godot's ThorVG: no filters (blur, drop shadow), no text, no external refs.
  Glow is done in-engine. Previews: `tools/rig_preview.py` composes a pose and rasterizes it with Godot.
- Attack kinds map to poses and a glow by their kind id, in data (`EnemyVisualSpec` per enemy: accent color,
  pose per kind id, telegraph glow per kind id). Core still knows only semantic ids.

## Input schemes (`view/battle/input/`)

`InputScheme` base (Control/Node with `attack_requested` / `block_requested` signals and a layout hook),
one class per scheme (`HandsScheme`, `ButtonsScheme`, `SwipeScheme`), `InputSchemeCatalog` (id → class).
`game_root` connects the active scheme's signals to `duel.try_*`; keyboard handled once, outside schemes.
Touch handled with `InputEventScreenTouch/Drag` per finger index (no mouse emulation for the battle).
The player's hands are a rig in `view/packs/player_pack/<pack>/` (same `rig.json` format), parts from the
equipped shield and weapon; poses: idle, block, parry, attack, hurt, guard_broken, staggered.

## UI

Portrait base 1080×1920 (`project.godot`), `UiScale.fit()` turns it landscape on wide windows (rpgmatch
`view/ui_scale.gd`). UI built in code with a shared kit; all player-facing strings are translation keys
(`tr("BATTLE_ATTACK")`). Buttons large enough for thumbs; the two combat buttons fill the bottom third.

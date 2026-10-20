# soulsclicker: plan

Living doc. `[x]` done, `[~]` in progress / scaffolded, `[ ]` not started. Each task names the folders it
owns, so parallel work does not collide. Design: `game_design.md`. Contracts: `architecture.md`.

## Phase 0: skeleton

- [x] T0 Project folder, `project.godot`, CI (`ci/`, `.github/`) and export presets copied from rpgmatch,
      `.vscode`, Godot AI addon, docs and skills.
- [x] T1 Shell (`game/`, `view/shell/`, `view/audio/`, `core/profile/`): `SceneRouter`, `GameSession`,
      `SaveStore`, `ProfileData`, `UiScale`, `Audio` autoload copied from rpgmatch with a minimal
      generated audio pack, main menu (Play, Settings with volumes and language), placeholder
      `game_root.tscn` with a Back button.
- [x] T2 Combat core (`core/combat/`, `data/enemies/`, `data/tuning/`, `tests/combat_test.gd`): `Duel`,
      `Fighter` with state objects, attack kinds (quick, heavy, feint, combo), catalog, tuning, events;
      headless tests for parry/block/hit/stamina/determinism; a bot-vs-enemy simulation printing win rate.
- [x] T3 Platform and locale (`autoload/`, `data/locale/`, `tests/platform_test.gd`): `Platform` facade,
      `PlatformAdapter` base, `NullAdapter` (stub ads), adapter catalog,
      translation CSV (en, ru) registered in `project.godot`.
- [x] T4 Battle view (`view/battle/`, `game/game_root.*`; after T1 and T2): placeholder visuals: `EnemyRig`
      of colored polygons with tweened poses and weapon glow per attack kind (see architecture "Enemy
      visuals"), telegraph indicator, HP/stamina bars, Attack/Block buttons plus keys, victory/death
      overlays, souls reward saved to profile, revive via `Platform.show_rewarded()`.
- [ ] T5 Integration check: headless check clean, all tests pass, portrait and landscape screenshots, web
      export builds locally.

- [ ] T6 Stats from loadout (`core/combat/`, `data/equipment/`; after designer's `design/core_hooks.md`):
      `CombatStats` + `StatModifier`, `Equipment` Resources (weapon, shield, armor), `Duel` reads
      `fighter.stats` only; `CombatTuning` keeps defaults; 2–3 shields/weapons as data; sim per loadout.
      Merge with the item hooks from the design so items and equipment use one modifier pipeline.
      Also: hold-to-block mode in core (setting), `on_would_die` for revive, death bank 0% + ad rescue 50%.

## Phase 1: playable run

- [x] A1 Art: warden emblem (no logos), 3 realm-1 enemies, 32 relic icons (`view/packs/*`).
- [x] S1 Sound: parry clang, combat cues, darker music (`tools/gen_audio.py`, `view/packs/audio_pack/`).
- [x] R1 Run model (`core/run/`, `data/realms/`, `tests/run_test.gd`): realms, doors, rooms, omens,
      seed code, run summary; no Modifier yet.

- [x] I1 Input schemes (hands / buttons / swipes), multitouch, HUD layout fix.
- [x] A2 Art: first-person player hands with swappable shields and weapons (`view/packs/player_pack/`).
- [ ] D1 Data for hound, dancer, bulwark (`data/enemies/`), elites from affixes, sim tuning.
- [ ] G1 Run in the game: door screen, rooms → duels, save/continue run, death/victory summary,
      embers to profile.
- [ ] Tuning pass through bot simulations (win rate per enemy for a "good" and a "bad" bot).
- [ ] First enemy pack with SVG silhouette parts, VFX pool, parry clang and hit sounds.

## Phase 2: release slice

- [ ] Weapons with affixes, spells, prestige cycle.
- [ ] Yandex adapter for real (SDK init, ads, leaderboard, language), moderation checklist.
- [ ] Release on Yandex Games, then itch.

## Notes

- CI is identical to rpgmatch. The export filter does not exclude `addons/godot_ai` and `tests/` yet
  (rpgmatch ships them too): decide before release (`godot-web` skill says editor addons must not ship).
- Local editor is 4.7.2, installed templates are `4.7.stable`: local export may need matching templates.

## Handoff (2026-10-20, session stopped on token budget)

- In flight when stopped (told to wrap up at a stable point; check their skills' "Not done yet"):
  T6 (`.claude/skills/modifiers`, `combat`), I1 (`battle` skill), A2 (`art` skill, "Player hands").
- Next: T5 integration check (all tests: combat, platform, battle, run, modifier; screenshots; local web
  export; export filter must exclude `_previews`, `_src`, `tests/`, `addons/godot_ai` and include `*.json`),
  then D1, then G1.
- G1 must apply the user's decision: death banks 0% souls, rewarded ad rescues 50%
  (`RunConfig.death_bank_rate` default is still 0.5 and `tests/run_test.gd` checks 50%).
- Known: `battle_view.gd` uses `match result.outcome` for presentation (style rule says no enum+match);
  `BattlePaths` duplicates `view/pack_paths.gd`; web tab-visibility mute not implemented.
- Agents work in parallel only on disjoint folders; tell them to save tokens (terse).
- T6 status: NOT implemented (no code). Settled design for the next agent is in
  `.claude/skills/combat/SKILL.md`, section "Status of the modifier work (T6)". Tests at stop: combat 53/53,
  run 86/86, platform PASS, battle PASS.
- I1 done (hands/buttons/swipes, multitouch, settings, hints). Not done: gear from `gear.json` not attached
  to the hands, hands layout approximate (`HandsScheme.RESERVED_SHARE`), landscape hands layout, see
  `.claude/skills/battle/SKILL.md` "Not done yet".

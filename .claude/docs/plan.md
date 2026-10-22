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
- [~] T5 Integration check: headless check clean, all tests pass, portrait and landscape screenshots, web
      export builds locally.

- [x] T6 Stats from loadout (`core/combat/`, `data/equipment/`; after designer's `design/core_hooks.md`):
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

- [~] E1 Endless depth in core/run (realm loop, exponential scaling, best depth).
- [~] M1 Path visualization on the doors screen.
- [ ] W1 Waves: several enemies per fight room (after E1).
- [x] R2 Revive per fight with escalating ads, ad for missing souls, flask drinks on buy.
- [ ] R3 Run rewards after elites/bosses (+flask, +max HP...).
- [ ] W2 Two enemies at once for deep realms (later).

## Phase 1.5: playtest feedback 2026-10-21 (decisions by user)

- [x] B1 Balance: hit damage cap as % of max HP (no one-shots), bot sim over depth, tune DepthCurve and meta
      ceiling (`core/combat`, `data/`, `tools/`). Files: no UI.
- [x] RW1 Reward choice after a fight: 3 cards relic / stat level / consumable (elite+boss), 1 of 2 small
      (souls, charge) after normal fights. Core: `core/run/rewards/`, catalog, seeded. UI later (overlay on road).
- [x] CS1 Consumables: tap-to-use slots with charges (flask, bomb, oil, ash), refill at bonfire / after boss,
      loot from rewards, buyable any time (shop on a fork or in battle column). No buy-in-battle clutter.
- [x] RD1 Seamless road: one scene per run, enemies walk toward camera along a procedural road, kill = advance,
      forks split the road into 2-3 labeled paths (icon + name), per-realm procedural scenery (trees, buildings,
      mountains), no separate door/altar/bonfire screens (overlays on the road). Replaces PathView + doors screen.
- [ ] WEB1 Deployed Pages build is stale (lambda catalog fix not yet pushed): menu_root compile errors.

## Phase 1.6: architecture + tutorial (2026-10-22, user decisions)

- [~] H1 Persistent hero: one player Fighter per run, continuous stamina/cooldowns, `Fighter.dispose()` against
      RefCounted cycles (leak), `Fighter.recover/settle`; then `_process` recover between fights, one heal/item path
      (road, altar, battle), one souls path. Files: `game/game_root.gd`, `core/combat/fighter.gd`.
- [~] P1 Performance/leak: RoadScene redraw cap on web (30 Hz) and fewer rows, `PerfOverlay` (`--perf` / `?perf`)
      to measure objects/nodes/orphans/memory on phones; soak test. Next: pre-triangulated props, cached road colors.
- [~] T-TUT Tutorial floor 0, light childish style, once per profile: `design/tutorial.md`.
      Done: light road look (`SceneryCatalog.TUTORIAL = 4`), enemies `tut_slime/knight/teddy` (no rigs yet),
      `TUT_*` locale keys (`REALM_0` for the realm name), `Duel.allowed_actions` + `hold_enemy`,
      `profile.tutorial_done`, `HintBubble` + `HighlightPulse` (`view/tutorial/`).
      Todo: `lesson` room kind + `data/realms/realm_0.tres`, scarecrow enemy, `TutorialDirector`, GameRoot wiring
      (realm slot 4 for the road, tutorial run does not bank Embers), Settings replay, SVG rigs, calm music.
- 2026-10-22 tutorial wired: `GameRoot._start_tutorial` (new game, `tutorial_done == false`), `TutorialDirector` +
  `GameTutorialHost` (`game/tutorial/`), lessons 1-5. The bubble's Skip only switches hints off (the floor goes on as
  plain fights: slime, knight, teddy); Settings "Skip tutorial" sets `tutorial_done` (skips the floor). The tutorial
  ends with a seamless road blend into realm 1 and a reset of souls/hp/items/levels. Not yet: lessons 6-13, music,
  rigs. Pause-menu control change now remounts the scheme on resume. Skill `i18n` + `tools/check_locale.py`.
- 2026-10-22 later: SVG rigs for `tut_slime/knight/teddy/scarecrow` (light pastel, `_src/tut_*.py`), lesson 6 HEAL,
  every new run starts with 2 charges of each consumable (`START_CHARGES`), tutorial enemies are immortal until the
  lesson ends the fight (`Duel.enemy_immortal`), highlight zone bounded. Tests: combat 57/57, soak growth 0.
- 2026-10-22 tutorial order now: STAMINA (strike, opens it), BLOCK+PARRY+PUNISH (one slime), KNIGHT (one `tut_knight`:
  held and immortal while the player drinks a flask and throws a bomb, then let loose for real with hints on the first
  heavy/feint/series), FINALE exam (`tut_teddy`, real fight, everything allowed + 2 flasks + 1 bomb). Still to write:
  souls+shop, fork, reward, altar.
- 2026-10-22: block tuned (`block_stamina_cost` 1.35 -> 1.0, `guard_break_damage_share` 0.6 -> 0.45). Soak test:
  `tests/soak_test.gd`. Road props pre-triangulated.

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
- T5: export filters done and verified on an exported pck (2.8 MB, rig/gear json in, no scratch dirs);
  `import_etc2_astc=true` added (CI failed without it). Local full export blocked: editor 4.7.2 custom
  build, no matching templates (`4.7.2.stable/`, web_nothreads_*). Web build check goes through CI.
- 2026-10-20 evening: T6 done (modifiers, equipment, hold/tap block, strike_timing, revive_player);
  gear on hands + parry ring done; game_root wired (block release, strike_timing, start loadout kite+sword
  as consts until vessels). Revive in game_root still rebuilds the Duel (switch to `revive_player` in G1).
  Next: D1, G1. Locale keys EQUIP_*, RELIC_*, AFFIX_* still missing.
- 2026-10-20 night: done and wired in game_root: G1 run flow (omen/doors/rooms/summary, run save incl. inventory,
  revive_player, 0% bank + ad saves half, permanent upgrades screen), C1 tempo/combo/stat levels, C2 items
  (flask, ember_bomb, whetstone_oil, warding_ash), battle: combo/crit numbers, pause (stops duel clock; Settings
  button in pause does nothing yet), side shop (items + run levels, souls income per hit/parry), branding
  (icon, logos, store covers). Not played through by hand yet. Next: playtest + balance (numbers ×10 idea),
  pause → settings, D1 data for hound/dancer/bulwark.

- 2026-10-21: B1 (cap 0.35 + balance_sim), RW1+RW2 (rewards core + overlay), CS1 (tap slots), RD1/G1/G2 (road, fork signs, walk, persistent BattleView) done; contract `design/road_contract.md`. Not played by hand. Next: playtest road, bonfire path untested, no shop room kind, enemies_v2 (4 data-only + 9 needs-core), run_test/battle_test stale (7+2 fails).

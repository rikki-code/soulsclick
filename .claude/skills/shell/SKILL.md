---
name: shell
description: >
  Game shell of soulsclicker: SceneRouter, GameSession, SaveStore, ProfileData, UiScale, main menu and
  settings, Audio pack and how to regenerate it, translation keys used by the shell. Use when touching
  game/, view/shell/, view/audio/, core/profile/ or tools/gen_audio.py.
---

## Modules

- `SceneRouter` (`game/`): `to_menu()`, `to_game()`; unpauses, then `change_scene_to_file`. Scenes: `menu_root.tscn` (main), `game_root.tscn`.
- `GameSession`: static holder. `profile() -> ProfileData` (lazy load via SaveStore), `save_profile()`. Add launch data here only when a screen needs it; core gets values as parameters.
- `SaveStore`: only file I/O. `load_profile()` / `save_profile(p)` on `user://profile.json`, atomic (tmp + rename). Missing/corrupt file = fresh `ProfileData`.
- `ProfileData` (`core/profile/`, RefCounted): `souls`, `levels` (stat -> int), `best` (stat -> int), `language` ("" = auto), `input_scheme` ("" = auto by device), `hinted_schemes`, `level_of()`, `record_best()`, `to_dict()`/`from_dict()`. `VERSION` is in the dict; `_migrate()` steps old versions up, unknown/newer version gives a fresh profile. New field = key in both methods (+ migration if semantics change).
- `UiScale.fit(window)` (`view/shell/`): base size from project settings (portrait 1080x1920), landscape windows get it turned; `FACTOR` knob (1.25) is the content scale. Call from each top-level scene and on `root.size_changed`.
- `MenuKit` (`view/shell/`): `background()`, `label()`, `page()`, `row()`, `button()`, `slider()`, `option()`, `big_text_theme()`. Sizes are consts at the top.
- `SoundSettings.add_to(page)`: master/music/sfx sliders -> `Audio.set_volume` (saved to `user://audio.cfg` by `AudioSettings`, debounced).
- `LanguageSettings`: `codes()`, `label_for()`, `apply(code)` (`TranslationServer.set_locale`), `detect()` (Platform.locale() if the autoload exists, else OS; fallback `en`). New language = line in `NATIVE_NAMES` + CSV column.
- `MenuRoot`: applies saved language, builds Main/Settings pages in code, plays `menu` music, calls `Platform.game_ready()` if present, hides Quit on web.
- `GameRoot` (`game/game_root.gd`): placeholder (label + Back); battle wiring replaces its body.

## Audio

- `Audio` autoload = `view/audio/audio_director.gd`: `Audio.play(&"cue")`, `Audio.play_music(&"track")`. Missing names are silent. Every `BaseButton` gets `ui_click` automatically.
- Pack path: `PackPaths.AUDIO_PACK` (`view/pack_paths.gd`) = `view/packs/audio_pack/default_pack/` (`sound_bank.tres`, `sfx/`, `music/`).
- Cues (name: intended trigger; volume/jitter/cooldown live in `CUES` of the generator):
  - `ui_click`: any button/slider (automatic). `ui_hover`: button hover (automatic, quiet).
  - `attack`: player starts a swing. `feint`: enemy feint is revealed (air only, no impact).
  - `enemy_telegraph`: enemy light/normal attack wind-up starts (rising ticks). `telegraph_heavy`: heavy attack wind-up (deeper, slower).
  - `hit`: damage lands on the player or enemy (2 variants). `block`: attack blocked (dull knock, 2 variants).
  - `parry`: successful parry (clang + whoomp, 3 random variants). `perfect_parry`: parry in the tightest window (parry + chime layer; play instead of `parry`).
  - `guard_break`: block/guard broken by a heavy. `stagger`: a fighter is staggered/stunned. `stamina_empty`: action refused for lack of stamina.
  - `souls_gain`: souls added (kill reward, counter ticking up). `victory`: duel won. `death`: player died.
  - Music: `menu` (58 s), `battle` (38 s); both loop seamlessly (additive drone snapped to whole cycles + wrapped reverb tail).
- Regenerate: `python3 tools/gen_audio.py` then `godot --headless --path . --import`. New cue = builder function + row in `CUES` (variants > 1: builder takes `(P, v)`, files `name_1.wav`.., picked at random; stale sfx files are wiped on each run); new pack = `Profile` subclass in `PROFILES` + `PackPaths` constant.

## Translation keys used by the shell

`GAME_TITLE`, `MENU_PLAY`, `MENU_SETTINGS`, `MENU_QUIT`, `SETTINGS_TITLE`, `SETTINGS_MASTER`, `SETTINGS_MUSIC`, `SETTINGS_SFX`, `SETTINGS_LANGUAGE`, `SETTINGS_CONTROLS`, `CONTROLS_HANDS/BUTTONS/SWIPES`, `LANGUAGE_AUTO`, `MENU_BACK`.
(English/Russian language names are shown natively, not translated. The `battle goes here` placeholder is a literal.)

## Verify notes

- `--check-only` can take over a minute and hangs on the project lock while an editor is open; run it on an rsync copy of the project in the scratchpad.
- Autoloads (`Audio`) are invisible to `-s` scripts, so test menu code by running the scene: `godot --headless --path . game/menu_root.tscn --quit-after 60`.

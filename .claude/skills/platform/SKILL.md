---
name: platform
description: >
  soulsclicker platform facade and localization: the `Platform` autoload (ads, scores, language, lifecycle hints),
  adapters, how to add a portal, and how to add translation keys. Use when touching ads, revive, leaderboards,
  language selection, `autoload/` or `data/locale/`.
---

## Facade (`autoload/platform.gd`, autoload `Platform`, class `PlatformService`)

Game code calls only `Platform`, never an adapter.

- `await show_interstitial()`; `await show_rewarded() -> bool` (`true` only if the reward was earned);
  `is_rewarded_available() -> bool` (hide the revive button when false).
- `submit_score(board_id, value)`, `gameplay_started()`, `gameplay_stopped()`, `game_ready()`.
- `purchase(product_id) -> bool` (await-able), `owns(product_id) -> bool`: stubs, always false for now.
- `locale() -> String` (`en` / `ru`): override, else portal language, else OS language, else `en`.
  `set_locale_override(code)` (empty or unsupported = automatic) also calls `TranslationServer.set_locale`.
  The settings screen stores the choice in the profile and calls this at startup and on change.
- Signals: `initialized`, `ad_started(kind)`, `ad_finished(kind)`. `is_ad_active()`, `adapter_id()`.
- During an ad the tree is paused and Master is muted; the previous pause and mute state returns afterwards.
  Master is also muted while the window has no focus (`NOTIFICATION_APPLICATION_FOCUS_OUT/IN`). Several mute
  reasons are tracked, so an ad ending while unfocused keeps the mute.
- A second ad request while one is showing returns at once (`false` for rewarded).

## Adapters

`PlatformAdapter` is the base with no-op or instant defaults. `NullAdapter` serves desktop, itch and dev: debug
builds fake a rewarded ad (0.15 s, succeeds) and report it available; release builds report it unavailable and
return `false`. Interstitial returns immediately. `PlatformCatalog` maps id to class and picks the adapter once at
startup: custom export feature tag `platform_<id>`, else `null`.

## Add a portal (e.g. Yandex)

1. New file `autoload/<portal>_adapter.gd`, `class_name <Portal>Adapter extends PlatformAdapter`; override only what
   the portal provides (`id`, `initialize`, `show_*`, `language`, ...). Coroutines resolve through a signal the
   portal callback emits; deliver results asynchronously so the awaiting side already listens.
2. One line in `PlatformCatalog._all`.
3. Export preset for that portal gets the custom feature `platform_<id>` and whatever HTML the SDK needs.

Not implemented yet: Yandex and every other portal adapter, URL-parameter selection, tab-visibility muting on web
(only Godot focus notifications), real purchases.

## Translations

`data/locale/strings.csv`, columns `keys,en,ru`, imported to `strings.<lang>.translation` and registered in
`project.godot` `[internationalization]`. To add a key or a language:

1. Add a row (quote cells containing commas) or a column.
2. `godot --headless --path . --import` regenerates the `.translation` files.
3. A new language also needs its `.translation` path in `locale/translations` and its code in
   `PlatformService.SUPPORTED_LOCALES`.

Use keys through `tr("BATTLE_ATTACK")`; formatted ones are `tr("BATTLE_SOULS") % souls` (`Souls: %d`).
Keys are `AREA_NAME` upper case. No hard-coded player-facing strings.

## Test

`godot --headless --path . -s tests/platform_test.gd` prints `PLATFORM PASS` and exits 0 (adapter choice, ad
pause/mute restore, locale fallback, en and ru lookups).

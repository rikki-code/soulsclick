---
name: i18n
description: >
  Hard rule for soulsclicker: every player-facing string is translated (en + ru) via a locale key, never a literal.
  Use whenever you add or change any UI text, hint, button, enemy/item/relic/stat/room name, tutorial line, overlay,
  settings label, error shown to the player, or any `data/**/*.tres` with `name_key` / `desc_key` / `tag_key`.
---

# Everything is translated. Always.

If the player can read it, it has a key in `data/locale/strings.csv` with BOTH `en` and `ru`. No exceptions, no
"translate later", no English literal in a `Label.text`, `Button.text`, `draw_string`, bubble, toast or banner.

## Rules

1. Code: `tr("KEY")`, or `BattleText.text("KEY", "fallback")` in views that may run before the table loads (the
   key must STILL exist in the csv: the fallback is a safety net, not a substitute). Format with `tr("KEY") % value`;
   the placeholder (`%d`, `%s`) must be present in BOTH languages.
2. Data: resources hold keys (`name_key = "ENEMY_TUT_SLIME"`), never display text.
3. Dynamic keys follow a prefix + upper-case id convention, and every id needs its row: `ENEMY_<id>`,
   `ROOM_<kind>`, `STAT_<stat>`, `AFFIX_<id>`, `EQUIP_<id>` (+ `_DESC`), `RELIC_<id>` (+ `_DESC`), `ITEM_<id>`
   (+ `_DESC`), `REWARD_*`, `TAG_*`, `GLYPH_<id>`, `REALM_<n>`. New enemy/item/relic/stat/room = add its rows in the same change.
4. Russian is real Russian, not a transliteration; keep the tone of the existing rows. Keep the same line breaks,
   `%` placeholders and punctuation conventions as neighbouring rows.
5. Numbers, names of keys on the keyboard and the "AD" badge are the only things allowed without a key.

## After touching `strings.csv` (not optional)

1. Regenerate the compiled tables: `godot --headless --path . --import` (the editor does it on focus too).
   The `.translation` files are tracked in git: commit them with the csv. A csv newer than its `.translation`
   means new keys show up untranslated in the game.
2. Run `python3 tools/check_locale.py` and fix everything it reports. It checks: empty cells, keys used in code
   (`tr("..")`, `BattleText.text("..")`) and in `.tres` (`*_key`) that are missing from the csv, dynamic ids without
   rows (enemies), a stale `.translation`, and English-looking literals assigned to UI text.
3. New screen or overlay: switch the language to `ru` once and look at it; long Russian strings overflow first.

## Where things live

- Table: `data/locale/strings.csv` (columns `keys,en,ru`), imported to `strings.en.translation` / `strings.ru.translation`
  and registered in `project.godot`. Details: the `platform` skill, "Translations".
- Tutorial lines are `TUT_*`; settings labels `SETTINGS_*`.

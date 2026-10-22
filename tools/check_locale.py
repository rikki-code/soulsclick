#!/usr/bin/env python3
"""Locale guard: every player-facing string has a key with en + ru, and the compiled tables are fresh.

Run from the project root: python3 tools/check_locale.py   (exit 1 when something is wrong).
"""
import csv
import glob
import os
import re
import sys

CSV = "data/locale/strings.csv"
TRANSLATIONS = ["data/locale/strings.en.translation", "data/locale/strings.ru.translation"]
SKIP_DIRS = ("addons", "tests", ".godot", "tools", "build")
KEY_CALL = re.compile(r'''(?:\btr|\btranslate|BattleText\.text|\btr_n)\(\s*"([A-Z][A-Z0-9_]*[A-Z0-9])"''')
RES_KEY = re.compile(r'(?:name_key|desc_key|tag_key|info_key)\s*=\s*"([^"]+)"')
LITERAL_TEXT = re.compile(r'(?:\.text\s*=|MenuKit\.(?:label|button)\()\s*"([A-Za-z][A-Za-z ,.!?\'-]{2,})"')
ENEMY_ID = re.compile(r'^id = &"([^"]+)"', re.M)


def main() -> int:
    problems: list[str] = []
    with open(CSV, encoding="utf-8") as handle:
        rows = [row for row in csv.reader(handle) if row]
    keys = {row[0]: row for row in rows[1:]}
    for key, row in keys.items():
        if len(row) < 3 or not row[1].strip() or not row[2].strip():
            problems.append(f"empty en/ru cell: {key}")
        elif row[1].count("%") != row[2].count("%"):
            problems.append(f"placeholder count differs between en and ru: {key}")

    for path in glob.glob("**/*.gd", recursive=True):
        if path.startswith(SKIP_DIRS) or "/dev/" in path or path.startswith("view/debug"):
            continue
        with open(path, encoding="utf-8") as handle:
            for number, line in enumerate(handle, 1):
                for match in KEY_CALL.finditer(line):
                    if match.group(1) not in keys:
                        problems.append(f"{path}:{number} key not in csv: {match.group(1)}")
                if "tr(" not in line and (hit := LITERAL_TEXT.search(line)):
                    problems.append(f"{path}:{number} literal UI text, use a key: {hit.group(1)!r}")

    for path in glob.glob("data/**/*.tres", recursive=True):
        with open(path, encoding="utf-8") as handle:
            text = handle.read()
        for match in RES_KEY.finditer(text):
            if match.group(1) and match.group(1) not in keys:
                problems.append(f"{path} key not in csv: {match.group(1)}")

    for path in glob.glob("data/enemies/*.tres"):
        with open(path, encoding="utf-8") as handle:
            found = ENEMY_ID.search(handle.read())
        if found and f"ENEMY_{found.group(1).upper()}" not in keys and not re.search(r'name_key = "', open(path, encoding="utf-8").read()):
            problems.append(f"{path} enemy has no name_key and no ENEMY_<ID> row")

    csv_time = os.path.getmtime(CSV)
    for path in TRANSLATIONS:
        if not os.path.exists(path) or os.path.getmtime(path) < csv_time:
            problems.append(f"{path} is older than {CSV}: run godot --headless --path . --import")

    for problem in problems:
        print(problem)
    print(f"locale check: {len(problems)} problem(s), {len(keys)} keys")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())

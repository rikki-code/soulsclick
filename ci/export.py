#!/usr/bin/env python3
"""Export the project using presets from export_presets.cfg.

Requires Godot with export templates (GODOT env var or `godot` in PATH).
Without arguments, exports the preset native to the host.

    python3 ci/export.py
    python3 ci/export.py macos-universal web
    python3 ci/export.py all
    python3 ci/export.py --list
    GODOT=/Applications/Godot.app/Contents/MacOS/Godot python3 ci/export.py

Docker:

    docker build -t soulsclicker-godot ci
    docker run --rm -v "$PWD:/project" soulsclicker-godot python3 ci/export.py linux-x86_64
"""
import argparse
import configparser
import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

SYSTEMS = {"Darwin": "macos", "Linux": "linux", "Windows": "windows"}
MACHINES = {"arm64": "arm64", "aarch64": "arm64", "x86_64": "x86_64", "amd64": "x86_64"}


def load_presets():
    """Return {preset name: export path} in file order."""
    cfg = configparser.ConfigParser(interpolation=None)
    cfg.read(ROOT / "export_presets.cfg")
    return {
        cfg[s]["name"].strip('"'): cfg[s]["export_path"].strip('"')
        for s in cfg.sections()
        if s.startswith("preset.") and s.count(".") == 1
    }


def native_preset():
    system = SYSTEMS.get(platform.system())
    machine = MACHINES.get(platform.machine().lower())
    if not system or not machine:
        sys.exit(f"unsupported host: {platform.system()} {platform.machine()}")
    # Official macOS templates ship universal binaries only.
    if system == "macos":
        return "macos-universal"
    return f"{system}-{machine}"


def find_godot():
    godot = os.environ.get("GODOT") or shutil.which("godot")
    if not godot:
        sys.exit("godot not found: set GODOT=/path/to/godot or add it to PATH")
    return godot


def main():
    presets = load_presets()

    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("presets", nargs="*", metavar="PRESET", help="preset name or 'all' (default: native)")
    ap.add_argument("--list", action="store_true", help="list presets and exit")
    args = ap.parse_args()

    if args.list:
        native = native_preset()
        for name in presets:
            print(f"{name} (native)" if name == native else name)
        return

    selected = args.presets or [native_preset()]
    if "all" in selected:
        selected = list(presets)
    unknown = [p for p in selected if p not in presets]
    if unknown:
        sys.exit(f"unknown preset: {', '.join(unknown)}; see --list")

    godot = [find_godot(), "--headless", "--path", str(ROOT)]

    # Import resources; .godot/ is not tracked.
    subprocess.run([*godot, "--import"])

    for preset in selected:
        out = ROOT / presets[preset]
        shutil.rmtree(out.parent, ignore_errors=True)
        out.parent.mkdir(parents=True)
        print(f"== export {preset} -> {presets[preset]}", flush=True)
        if subprocess.run([*godot, "--export-release", preset, str(out)]).returncode != 0:
            sys.exit(f"export failed: {preset}")
        if not out.is_file():
            sys.exit(f"export failed: {out} not found")


if __name__ == "__main__":
    main()

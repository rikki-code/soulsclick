---
name: ci-export
description: >
  Exporting builds of soulsclicker: export presets, ci/export.py, the Docker
  image, and the GitHub Actions workflow (artifacts, Pages, releases). Use
  when building, exporting, or changing CI for this project.
---

## Presets

`export_presets.cfg`: `macos-universal`, `linux-x86_64`, `linux-arm64`, `windows-x86_64`,
`windows-arm64`, `web`. Output: `build/<preset>/`.

## Export filters (every preset)

- `exclude_filter="build/*, tests/*, tools/*, addons/godot_ai/*, */_previews/*, */_src/*, ci/*"`,
  `include_filter="*.json"`. The json include is required: `rig.json`/`gear.json` are read with `FileAccess`,
  and non-resource files are not exported otherwise. Keep both lines identical in all presets.
- Excluding `addons/godot_ai/*` is safe even though `project.godot` has the `_mcp_game_helper` autoload: the
  addon's export plugin (`export/mcp_export_plugin.gd`) strips that autoload from the exported project settings
  (works in headless export). Verified: pack exported without the addon runs with no autoload errors.
- Check a pack without templates: `godot --headless --path . --export-pack web /tmp/x.pck`, then
  `strings /tmp/x.pck | grep -E 'rig.json|_previews|_src|tests/'`.
- Keep `rendering/textures/vram_compression/import_etc2_astc=true` in `project.godot` (the web/mobile presets
  need it; without it exports fail with "configuration errors"), and run `--import` after changing it.
- Local export needs a template folder named exactly like the editor version (`4.7.2.stable` for the custom
  build); `4.7.stable` is not found.

## Local export

```
python3 ci/export.py              # native preset
python3 ci/export.py web linux-x86_64
python3 ci/export.py all
python3 ci/export.py --list
GODOT=/path/to/godot python3 ci/export.py
```

Requires Godot with export templates (`GODOT` env or `godot` in PATH).

## Docker

```
docker build -t soulsclicker-godot ci
docker run --rm -v "$PWD:/project" soulsclicker-godot python3 ci/export.py linux-x86_64
```

`ci/Dockerfile` pins `GODOT_VERSION`/`GODOT_RELEASE` (build args).

## GitHub Actions (`.github/workflows/export.yml`)

- Triggers: push to `main`, tags `v*`, pull requests, manual run with a preset choice.
- Default set: `macos-universal`, `linux-x86_64`, `windows-x86_64`, `web`.
- The Godot image is built once per Dockerfile hash and pushed to GHCR; exports run inside it.
- Artifacts: `soulsclicker-<preset>`. `web` on `main` deploys to GitHub Pages. Tags `v*` publish a release
  with zipped builds.

## Changing the Godot version

Update `GODOT_VERSION` in the workflow `env` (passed as a build arg) and the `ci/Dockerfile` default.
The image tag is `<version>-<release>-<Dockerfile hash>`, so either change triggers a rebuild.

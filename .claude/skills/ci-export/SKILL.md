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

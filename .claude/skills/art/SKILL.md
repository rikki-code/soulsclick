---
name: art
description: >
  Silhouette art for soulsclicker: enemy rigs (per-part SVG + rig.json + poses), backgrounds, relic icons,
  palette, and how to preview or add an enemy or icon. Use when drawing or changing enemy parts, poses,
  accents, backgrounds or relic icons, or adding a new enemy/icon to the silhouette pack.
---

## Style

- Near-black silhouettes (`#0a0c10`, secondary `#141922`) with a thin cold-gray rim (`#2f3947`) and lighter
  rim-light lines (`#7686a0`, opacity 0.5-0.8) on the top/left edges. Shapes first: pose must read in a
  fraction of a second at phone size (enemy ~600 px tall). Clear negative space between weapon and body.
- ONE accent color per enemy, used only on glowing parts (weapon edge, eyes, runes, core). Glow strokes are
  thick (8-9 px at 1024 canvas), fills not hairlines. Glow itself is added in-engine (no filters in SVG).
- Original designs only. Backgrounds are low-contrast gradients with distant silhouettes.
- No real logos, brands or trademark-like marks (e.g. a circle with three spokes = car badge, swoosh, apple,
  arches, crossed-circles). Emblems are invented: ember crack, rune, eye, jagged fissure. Check any ring + radial
  lines or letter-like glyph before shipping. (The warden ball emblem is a single jagged ember crack.)

## Enemies and palette

| id | accent | design |
|----|--------|--------|
| `grunt` | `#8fe04a` | hunched hooded undead, claws, short curved cleaver, quick attacks |
| `knight` | `#5cb8ff` | armored, spiked pauldrons, great helm with crest, two-handed greatsword |
| `warden` | `#ff4a3d` | hollow giant (ribcage void with ember core), horned skull, chained spiked ball (`weapon` haft -> `chain` -> `ball`); fills ~85% of the canvas height |
| `hound` | `#ff9a1f` | Chain Hound: low crouched wolf-eared skirmisher, spiked collar, chain bandolier, tail, hooked sickle with a chain tail; ~60% of canvas height |
| `dancer` | `#b57bff` | Veil Dancer: tall slender masked duelist, long crown tines, trailing veil strips and skirt, thin curved saber; narrowest silhouette |
| `bulwark` | `#e3c66a` | Bell Bulwark: squat bell-shaped giant, bell helm with loop, tower shield (extra part `shield`, child of `forearm_l`, world angle set with `hold`), bell-headed mace (bell mouth glows) |

Realm I roster mapping (run_and_progression 3.3): grunt = Hollow Soldier basics, hound = Chain Hound, bulwark =
Bell Warden (heavies), dancer = Veil Dancer (feints); knight = elite-weight enemy; warden = elite/mini-boss. All 12
poses exist for every enemy, so any attack kind works; the poses are DRAWN FOR (distinct, readable telegraphs):

| id | quick | heavy | feint | combo | notes for data |
|----|-------|-------|-------|-------|----------------|
| `hound` | yes (sickle drawn back low, pounce slash) | leap: sickle overhead, slam | yes (crouch, head twitch, sickle raised right) | yes, best (sweep left then right) | fast phrases, short telegraphs, stamina test |
| `bulwark` | shield bash side-swipe | yes, best (mace overhead, bell mouth glows) | yes (shield dips, mace lifted slowly) | yes (mace back-hand left, shield-swung right) | slow, long heavy telegraph, parry-only enemy |
| `dancer` | yes (saber drawn back to the side) | thrust/slam: saber high, lunge | yes, best (saber low and tilted, head tilt) | yes (saber sweep out left, then right) | patient phrases with feints |

Windup silhouettes are unique per enemy: hound = curved blade out to the side with a low crouch; dancer = long thin
blade, narrow body, saber hand held low for feints; bulwark = shield stays up, mace head (bell) goes above the helm.
## Files

- Enemy: `view/packs/enemy_pack/silhouette_pack/<id>/` = one SVG per part + `rig.json` (format in
  `.claude/docs/architecture.md`, "Enemy visuals").
- Background: `view/packs/background_pack/silhouette_pack/<id>.svg`, 1080x1920, ground line at y~1500. The enemy
  canvas (1024 square, feet at y~975) is meant to sit with its top-left at bg (28, 560).
- Scratch (not shipped, each has a `.gdignore`; also exclude them in export filters): `_previews/` (PNG/SVG
  output of the preview tool) and `_src/` (Python generator of the parts and rig.json).
- Backgrounds so far: `grunt` moon courtyard, `knight` nave, `warden` ring gate, `hound` kennel yard with
  chains, `dancer` hall of hanging drapes, `bulwark` belfry. `_src/bg.py` `make(..., kind)`; kinds: moon, nave,
  ring, chains, veil, bell.
- Part names: `legs`, `body`, `head`, `eyes`, `arm_l`, `forearm_l`, `arm_r`, `forearm_r`, `weapon`
  (+ `core`, `chain`, `ball` for the warden, `shield` for the bulwark). Hierarchy: body -> head -> eyes; body -> arm -> forearm
  -> weapon (-> chain -> ball). `legs` and `body` are roots with the pivot at the hips (death pose rotates both).
- `z` is an ABSOLUTE draw order for the whole rig (legs 0, body 1, head, arms ..., weapon last). The game
  must not sum z along the parent chain.
- Rest pose = everything unrotated; every pose lists every part (rot degrees clockwise, move in parent px).
  `glow_parts` = parts tinted/pulsed with the accent (eyes, weapon, core, ball).
- Pivots at real joints: shoulder, elbow, neck, hips, weapon grip, chain top.

## Poses (all 12 for every enemy)

`idle` neutral guard. `windup_quick` short blade drawn back to the side, body twisted. `strike_quick` fast
slash across the body. `windup_heavy` big weapon raised high (warden: ball over the head). `strike_heavy` slam
down, body leaning in. `windup_feint` like heavy but subtly off (lower, tilted, head twitch; warden: ball
up-right). `windup_combo` weapon swept out low to one side; `strike_combo` sweep to the other side. `recover`
hunched, weapon dropping. `staggered` thrown back, arms flung out (punish window). `hurt` small flinch.
`death` falls and lies on the ground (body and legs rotated about the hips, shifted to stay in the canvas).
Each pose keeps ink 12 px inside the 1024 canvas (checked by the tool).

## Preview tool

```
tools/rig_preview.py <enemy_dir> [pose ... | sheet] [--out dir] [--scale s] [--no-bg] [--lint]
tools/rig_preview.py --icons <icon_dir>     # icon lint + contact sheet
tools/rig_preview.py view/packs/enemy_pack/silhouette_pack/knight sheet     # contact sheet, 4x3
tools/rig_preview.py view/packs/enemy_pack/silhouette_pack/knight windup_heavy strike_heavy
```

Composes each pose as one SVG (flat transforms from the parent chain, sorted by z), rasterizes it with
Godot headless via `tools/svg_to_png.gd` (same ThorVG as the game), writes to `<pack>/_previews/<id>/`. Sheet
order: idle, windup_quick, strike_quick, windup_heavy / strike_heavy, windup_feint, windup_combo, strike_combo /
recover, staggered, hurt, death. Always runs lint: forbidden SVG constructs (filter, text, image, style, class,
href), file size < 30 KB, pivots, poses naming unknown parts, ink leaving the canvas. Env `GODOT` overrides
the binary. Look at the PNGs after every change.

## Add or change an enemy

1. Copy `_src/knight.py` (or grunt/warden) to `_src/<id>.py`; set `ACCENT`, hip/shoulder/neck coordinates, draw
   parts with `Art` helpers (`poly`, `smooth`, `line`, `circle`, `ellipse`) in a local frame whose origin is the
   pivot; `Rig.part(id, parent, pivot_in_canvas, z, art, glow=)`.
2. Poses: `make_pose_fn` gives `pose(name, body=(rot, dx, dy), head=, legs=, hr=<hand target>, hl=, blade=<deg,
   0=up>, grip_l=<left hand distance up the weapon>, bend_r/bend_l=+-1)`; arms are solved with 2-bone IK.
3. Add the id to `_src/build.py` (default list) , run `python3 _src/build.py <id>` (writes the SVGs and rig.json), then the preview
   tool. Add a matching background in `_src/bg.py` (`make(...)`) and run `python3 _src/bg.py`.
4. Hand-edited SVGs are fine too, but the generator overwrites them on the next build.

## Relic icons

`view/packs/icon_pack/silhouette_pack/relics/<relic_id>.svg`, one per relic id in `items.md`; the 32 vertical-slice
relics are done (generator `view/packs/icon_pack/silhouette_pack/_src/relics.py`, `python3 relics.py` rewrites all;
scratch `_src/` and `_previews/` have a `.gdignore`).

- 256x256, viewBox 0 0 256 256, filename = relic id. Layers: round plate (r 124, `#1a212c`, edge `#2f3947`), a dark
  silhouette (`#07090c`, inset `#10141b`, void `#000`) with a rim stroke `#56657e` and a few rim-light lines
  `#9fb0cc`, plus ONE accent color on the glowing/key part (edge, flame, rune, eyes, drop, thread).
- Readable at 64 px: one idea per icon, a bold center mass, no stroke below 3 px (silhouette rim 3-4 px,
  details and accent 8-14 px), nothing smaller than ~10 px. Same ThorVG rules as enemies (no filter/text/image/style/
  class/href), under 12 KB each, no gradients needed.
- Accent = tag color of the relic (items.md section 2, hex below). Primary tag = the first tag listed in items.md, except:
  `glass_blade` and `reckless_oath` use curse; `ember_wick` burn; `vampire_fang` bleed; `counter_tide` block.
  The map is `TAGS`/`ICONS` in `_src/relics.py`; the UI can recolor from data the same way.

| tag | hex | tag | hex | tag | hex |
|-----|-----|-----|-----|-----|-----|
| parry | `#f2c14e` | stamina | `#6fd36a` | frost | `#5fd8f0` |
| block | `#6aa3d9` | vital | `#f06b8a` | shock | `#a06bff` |
| strike | `#e8e2d0` | bleed | `#d6283c` | soul | `#2fd3b5` |
| read | `#c3a6ff` | burn | `#ff7a1a` | focus | `#fff0b0` |
| curse | `#e43cd8` | | | | |

- Add an icon: write a function in `_src/relics.py` (helpers `sil`, `sm`, `acc`, `accfill`, `hi`, `fat`, `disc`, `rot`;
  coordinates in the 256 box), register it in `ICONS` with its accent tag, run `python3 relics.py`, then
  `tools/rig_preview.py --icons view/packs/icon_pack/silhouette_pack/relics` (lint: 256x256, forbidden
  constructs, size, exactly one non-neutral color, hairline strokes; writes `_previews/relics_sheet.png` = 8-column
  128 px grid plus a true-size 64 px strip). Look at the 64 px strip.

## Player hands (`view/packs/player_pack/silhouette_pack/`)

First-person hands for the Hands input scheme. Canvas 1080x1920, same `rig.json` format as the enemies
(`pivot` / `at` / `rot` / `move`, absolute `z`), but gear is separate so it can be swapped.

- `hands/`: `arm_l, forearm_l, hand_l, arm_r, forearm_r, hand_r` + `hands/rig.json`. Left hand = shield,
  right hand = weapon. Parents: arm -> forearm -> hand. `arm_*` is a root: its `move` slides the (offscreen)
  shoulder per pose so the forearm always enters steeply from the bottom edge. Rest = hands upright (fist opens
  up, gear points up); `idle` is a real pose, not all zeros.
- Gear attach rule: `hands/rig.json` has `slots`: `shield` (parent `hand_l`, `at` = fist centre in hand_l pixels,
  `z` 14, above hand_l so the hand hides behind the shield) and `weapon` (parent `hand_r`, `z` 22, below hand_r
  so the fist wraps the grip). A gear SVG is a child of that hand: its `pivot` (grip point, in the gear's SVG
  pixels, listed in `gear.json`) sits at the slot `at`, and it rotates with the hand (no own rot). Gear art is
  drawn upright (blade/shield top = up).
- `gear.json`: `shields` {buckler, kite, tower}, `weapons` {dagger, sword, greatsword}: `file`, `pivot`, `size`,
  `glow` (true: accent strokes `#e6a65d`, tint with the accent), `note`.
- Poses (gear-agnostic, every hand part listed): `idle, block, parry, attack, hurt, guard_broken, staggered`.
  block = shield raised left of centre (kite top ~y1000, eyes/head stay visible); parry = higher and tilted 24
  deg (snap); attack = right hand sweeps up-left, blade -55 deg across the centre; guard_broken = shield flung
  out left; staggered = both arms thrown out. Tower shield raised covers x~130-670, y~1000 down (hides the
  lower enemy body, not the head); greatsword in `attack` crosses the whole enemy (intended).
- Accent: player-only warm steel/ember `#e6a65d`. Never use it for an enemy.
- Generator + preview: `python3 view/packs/player_pack/silhouette_pack/_src/build.py` (writes hands, gear,
  gear.json, rig.json and `_previews/<shield>_<weapon>.png`: 4x2 sheet, order idle, block, parry, attack /
  hurt, guard_broken, staggered; dashed rectangle = enemy area, blue dot = eyes). It rasterizes with
  `tools/svg_to_png.gd`; `tools/rig_preview.py` does not know gear, do not use it here.
- Add a shield/weapon: add a drawing function + `GEAR_K` scale + `GEAR_NOTES` entry in `_src/build.py`
  (`GEAR` dict, origin = grip point, shape upright), add the combo to `COMBOS`, run the build, look at the sheet.
- `gear.json` per-gear `pose_offsets` {pose id | "default": {move [x,y], rot}} (source: `POSE_OFFSETS` in `_src/build.py`): `move` slides the whole arm of that hand, `rot` turns the hand (and gear), added on top of the pose; used to sink shields at rest and tilt long blades outward off the edge (tower block/parry lowered so they do not hide the eyes). The game loader is `PlayerRigSpec` (see the battle skill); preview sheets apply the same offsets.
- Not done yet: right-hand fist art is generic (no per-weapon grip variations); wrist cuff is a flat band wider than the bracer; no hurt/parry shake tuning.

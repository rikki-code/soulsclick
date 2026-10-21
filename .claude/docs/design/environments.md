# soulsclicker: environments (seamless road)

Extends `run_and_progression.md` (realms, rooms). Palettes = current `view/road/scenery_catalog.gd` (realm idx 0-3), new props = new `SceneryKind` classes (poly lists, `body`+`glow`, units: height 1 = -y). Names are proposals.
Road model: one endless path, enemy walks toward camera, kill = step forward. Fork = road splits Y into 2-3 trails, each ends in a landmark + signpost. Rule: everything is a flat silhouette (`silhouette` color) on fog layers, only `glow` polys use accent. No textures.

## 1. Realms

### I. Cinder Road (idx 0) - forest, dusk, cold
- Mood: lonely, quiet, first steps. Hope low.
- Sky `#080b12`>`#222e40`; ground `#0d1117`/`#10151c`; road `#1a212b`, far `#2a3646`; edge `#4a586c`; fog `#222e40`; accent `#8fe04a`.
- Props (6-8): Pine, RoundTree, DeadTree (have); Ruin, Gravestone (have); NEW: Stump (trapezoid + 2 root spikes), Boulder (blob), Scarecrow (cross poly + hat triangle).
- Landmarks: elite = Hanged tree (DeadTree + rope line + body blob, red eyes glow); altar = Mossy stone (Boulder + flat slab, green glow); bonfire = Coiled-sword fire (sword poly stuck in ground, orange flame tri); shop = Cart (box + 2 circles wheels + lantern glow); boss gate = Rotten timber gate (2 posts + lintel, chains).
- Ambient: low ground mist (2 scrolling alpha bands), fireflies (green dots), few crows on branches, leaves drift.
- Music: solo cello drone, wind, sparse plucks. 60 bpm feel.
- Enemies: wretch, grunt, hound, pilgrim; elite: warden; boss Gatekeeper.

### II. Drowned Chapel (idx 1) - graveyard, violet haze
- Mood: sorrow, wet, whispering. Wrongness: water where none should be.
- Sky `#0b0912`>`#33284a`; ground `#100d16`/`#140f1b`; road `#1f1a29`, far `#3a2f4d`; edge `#5a4c72`; fog `#33284a`; accent `#b57bff` (boss cyan `#4ad8e0`).
- Props: Gravestone, Cross, DeadTree, Spire (have); NEW: Puddle (flat ellipse + mirrored tiny props, no code beyond ellipse), Broken arch (2 pillars, half arc), Bell on post (blob + clapper), Reeds (3-5 thin spikes).
- Landmarks: elite = Giant bell tower (Tower + bell blob, violet glow in belfry); altar = Reliquary (small gable box on steps, glow slit); bonfire = Candle cluster in a font (3-5 thin rects, tiny flames); shop = Pew-merchant (hooded blob behind a lectern, 2 candles); boss gate = Flooded nave doors (tall pointed arch, water line cuts it, cyan glow).
- Ambient: rain (diagonal thin lines, 2 speeds), ground mist heavier, soul wisps (violet dots rising), ripples on puddles.
- Music: choir pad (one note), distant bell every ~20 s, rain noise bed.
- Enemies: pilgrim, dancer, wretch, hangman; elite: knight; boss Tidewarden.

### III. Hollow Throne (idx 2) - ruined city, ash and rust
- Mood: fallen grandeur, heat, pride rotting.
- Sky `#0f0a0a`>`#4a2a22`; ground `#130d0c`/`#171010`; road `#241a18`, far `#4a3430`; edge `#6d4a40`; fog `#4a2a22`; accent `#ff9a1f` (boss white-violet `#d8c8ff`).
- Props: Ruin, Tower, Spire, DeadTree, Gravestone (have); NEW: Column (rect + capital, broken top variant), Statue (headless body poly on plinth), Banner pole (pole + torn flag tri), Rubble pile (jagged heap), Brazier (bowl on stand, orange glow).
- Landmarks: elite = Colossus statue (Statue x2.5 size, eye glow); altar = Throne-step slab (stairs + empty chair silhouette, violet glow); bonfire = Brazier ring (3 braziers around a sword); shop = Ruined stall with awning (tri roof + crate + lantern); boss gate = Broken portcullis (arch + hanging spike row, gap in middle).
- Ambient: falling ash (slow grey flakes), heat shimmer line on horizon (sin offset), embers drifting up, banners wave.
- Music: low brass swell, war drum single hit, dry strings.
- Enemies: knight, bulwark, hangman, hound; elite: warden, bulwark; boss Hollow King.

### IV. Ember Void (idx 3) - black, red glow, end
- Mood: dread, endgame, ground is cracked. Sparse: less props = more fear.
- Sky `#050405`>`#3a0f0f`; ground `#0a0606`/`#0e0808`; road `#190d0d`, far `#3a1616`; edge `#6a2a24`; line = fog `#ff4a3d` glow cracks; accent `#ff4a3d`.
- Props: Spire, DeadTree, Tower, Cross (have); NEW: Lava crack (jagged glow-only polyline on ground), Floating shard (rotated diamond, bobs), Charred hand (arm poly reaching up, 4 finger spikes), Giant rib (curved arc poly pair).
- Landmarks: elite = Thorn idol (Spire cluster, red eye); altar = Floating shard ring (3 shards circle a glow); bonfire = Last fire (small white-orange flame, only warm color in realm); shop = Faceless vendor (tall cloak tri, empty hood, glow coins); boss gate = Eye gate (round arch, vertical slit eye glows, opens on approach).
- Ambient: rising embers (dense), pulsing red sky, lightning flicker rare, no crows (silence).
- Music: sub-bass drone, reversed choir, heartbeat under combat.
- Enemies: all, mutated affixes; elite: knight, warden; final boss.

### Ideas V-VI (not built)
- V. Frozen Bastion: ice blue `#0a1018`>`#3a5a78`, accent `#9fe8ff`. Props: icicle spikes, snow drifts, frozen banner, ice pillar. Snow, breath fog. Mood: numb, calm before. Enemies: frost knights, wolves; hazard: slow fights.
- VI. Gilded Rot: sickly gold `#120f06`>`#5a4a1a`, accent `#e8d048`. Props: gilded throne, melted candelabra, rotten fruit tree, hanging cage. Gold dust, flies. Mood: decadent decay. Enemies: dancers, hangmen, courtiers; shop-heavy realm (greed theme).

## 2. Fork signage
Signpost at the split: wooden plank (rect + notch tip) per trail, pointing along the trail, rune icon above, label under. Plank tinted by room kind accent, text 1-2 words, outlined glyph (simple strokes, one polygon each). Elite plank has a red nail; locked/unknown has "?".

| Kind | Icon (cheap poly) | EN | RU |
|---|---|---|---|
| fight | crossed swords (2 thin rects) | Foe | Враг |
| elite | horned skull (circle + 2 tris) | Champion | Страж |
| altar | chalice / small gable | Altar | Алтарь |
| bonfire | spiral sword + flame tri | Bonfire | Костёр |
| shop | coin circle with hole | Trader | Торговец |
| shrine | eye in diamond | Shrine | Святыня |
| event | question mark | Unknown | Неведомое |
| boss | arch with slit | Gate | Врата |
| secret | keyhole | Hidden | Тайна |

Labels are locale keys (`room.<kind>.sign`), never inline. Trails of 3: left/center/right planks stagger by depth for portrait readability. Selected trail: plank glows, others dim 40%.

## 3. Hints of what awaits (silhouette on the horizon)
- Each trail shows its landmark (section 1) small and fogged at the far end of the branch, 1 per trail, before the player chooses. Reward is read by shape, not text.
- Fight: figure silhouette standing (a random enemy of the realm, 30% scale, no glow). Elite: same but bigger, with accent ring + second-color glow. Mystery (event): a fog blob + "?".
- Fog depth: further = more fog color mix; hints are never fully black so they read on the dark ground (min contrast: silhouette +12% over ground).
- Reward icon floats above the landmark (relic dot, heart, coin) when known; hidden if the Omen/curse hides it.
- Sound hint: bonfire = crackle, shop = coin clink, elite = low growl, quiet at fork distance, louder as the player nears.
- Hover/tap preview: camera drift 5% toward the trail, others dim.

## 4. Realm transition
- Boss gate is the exit of each realm (landmark above). Kill boss: gate opens (two halves slide, light bleeds in accent of the next realm), walk through = 1.2 s fade-to-black, new palette lerps over 2 s during the walk, realm title card (name, 1 line EN/RU) fades over the first steps.
- Gate arch always on a stone bridge/ledge so the horizon is a clean silhouette; new realm props start spawning at the far end behind the gate, old ones stop (no hard cut).
- Cross-fade per realm: sky, ground, road, fog colors lerp; ambient particles swap by fade in/out (rain stops, ash starts). Music crossfades 3 s.
- Gate per realm: I timber, II flooded nave, III portcullis, IV eye. Final boss: no gate, the road ends in a cliff and the boss stands on it.

## 5. Cheap-first build order
1. Landmarks reuse existing props (Tower, Spire, Ruin) + glow poly: bonfire flame, altar glow only.
2. Signpost: one generic plank class + 9 icon polys.
3. Ambient: 3 particle types cover all realms (mist band, falling dots, rising dots); rain = falling lines.
4. New props per realm: 3-4 poly classes, enough for variety; the rest later.
5. Transition: palette lerp + gate poly + fade. No new art assets.

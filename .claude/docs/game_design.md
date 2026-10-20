# soulsclicker: game design

Working title. A souls-like duel reduced to two buttons: **Attack** and **Block**. The joke "Dark Souls is a
clicker" taken literally, but the core is timing, not mashing.

Own world and naming only: no Dark Souls names, fonts, "YOU DIED" or other trademarked phrases (portal
moderation checks third-party rights).

## Target

- Platforms: web first (Yandex Games, then CrazyGames / Poki / itch), Android later. Portrait first, landscape
  must work.
- Session: 1–3 minutes per fight, 10–20 minutes per run.
- Monetization: rewarded ads (revive, double souls), interstitial between runs, later "remove ads" purchase.
  All through the `Platform` facade (`.claude/docs/architecture.md`).

## Core loop (v0, decided: rhythm combat)

1. The enemy shows a **telegraph** (windup) for the next attack in its pattern, then **strikes**.
2. **Block** pressed shortly before the strike = **parry**: no damage, the enemy is staggered, a **punish
   window** opens with a damage multiplier. Block held earlier = **block**: chip damage plus stamina cost.
   No block = full damage.
3. **Attack** deals damage but locks the player for the attack duration; a strike landing during it hits.
   Attacking costs stamina; stamina regenerates when idle.
4. Enemy HP 0 = victory, souls reward. Player HP 0 = death: souls of the run are dropped (rewarded ad:
   revive once, or keep the souls).

Attack kinds (each a class, see architecture): quick (short telegraph), heavy (long telegraph, block breaks
guard: parry only), feint (telegraph without strike), combo (several strikes). Unblockable/grab later.

All timings and numbers are data (`EnemyDefinition`, `CombatTuning`), never inline.

## Progression (after the duel works)

- **Souls** (currency) from victories, spent on levels (HP, stamina, damage) at the **bonfire**.
- **Run** = a chain of enemies ending with a boss. Death resets the run; levels stay.
- **Bonfire rest = prestige**: start a new cycle (NG+) with harder enemies and a permanent multiplier.
- **Weapons** = base + random affixes (bleed, parry window bonus, lightning on block...). Each affix is a
  small behavior class; content grows combinatorially.
- **Spells** = a list of effect behaviors plus a VFX tag; a third button may appear later, two-button core
  stays.
- Every few minutes something new: enemy, weapon, spell, area. New content is data, not code.

## Vertical slice (first release)

1 area, 5 enemies (last is a boss), 10 weapon bases, ~20 affixes, 6–8 spells, one prestige cycle, RU + EN.
Then measure (day-1 return, rewarded per player) before adding content.

## Input (decided)

Several schemes, picked in Settings (saved in the profile), all calling the same two actions:
- **Hands** (default on touch): first-person view, the player's shield bottom-left and weapon bottom-right.
  Tap the left half = block, right half = attack. No button UI; the hands show the equipped gear.
- **Buttons**: two big labeled buttons (current layout).
- **Swipes**: swipe toward the enemy (up) = attack, swipe down = block; recognized on a short movement
  threshold, not on release, to keep latency low. Directional parry (swipe against the strike side)
  is a later idea that needs strike directions in core.
Keyboard always works (Attack →/D/J, Block ←/A/F). Multitouch: both thumbs register.

## Art and sound (decided)

- **Silhouettes**: dark 2D enemies on gradient backgrounds, one accent color per enemy (glowing weapon,
  eyes). The visual's first job is a readable telegraph: pose + weapon glow per attack kind (heavy = its
  own color, feint = flicker).
- **Puppet animation**: an enemy is a rig of parts (body, head, arms, weapon) posed by tweens; no frame
  animation. Parts are SVG drawn per part. A new enemy = parts + palette + pose set, in a pack.
- **VFX**: shaders and pooled particles (parry sparks, hit flash, dust).
- **Sound**: procedural SFX from `tools/gen_audio.py` (no licensing). Later: parry clang and hits layered
  with CC0 samples, music from CC0 or bought royalty-free (dark ambient, choir, low strings); every
  third-party file listed in `view/packs/audio_pack/LICENSES.md`.

## Open questions (ask the user, do not decide alone)

- Whether spells get their own button.
- Hold-to-block vs tap-to-block (v0 assumes tap: block lasts `block_duration`).

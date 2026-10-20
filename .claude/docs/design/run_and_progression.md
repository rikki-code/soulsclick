# soulsclicker: run structure and progression

Extends `game_design.md` (replaces its "Progression" section once approved). Relics: `items.md`. Code contracts: `core_hooks.md`.
Pillars: (1) core stays two buttons and skill; (2) every run looks and plays different because of what you pick; (3) permanent progress = more options, not more power; (4) a run is 6-18 min and restarts in 2 taps.

Glossary (names are proposals, own world, no third-party terms): **Souls** run gold; **Embers** permanent currency; **Relic** run item; **Art** active (Focus meter); **Vessel** character; **Omen** run theme (2 tags); **Dread** difficulty/prestige level; **Realm** floor; **Door** choice node.

## 1. Run structure

### 1.1 Shape
A run = up to 3 Realms. A Realm = 5 steps. Each step shows 2 (sometimes 1 or 3) **Doors** with a preview icon of room type and reward (Hades). Linear chain with forks, not a branching map: one tap per decision, fits portrait.

```
Realm: [1 Fight|Fight] -> [2 Fight|Altar/Shrine/Event] -> [3 Elite|Fight|Shop] -> [4 Bonfire|Shop|Shrine] -> [5 Boss]
Run:   Realm I (Cinder Road) -> Realm II (Drowned Chapel) -> Realm III (Hollow Throne) -> final boss
```

### 1.2 Room types
| Room | Content | Reward | VS |
|---|---|---|---|
| Fight | 1 normal enemy (+0-1 mutator) | souls, 40% chance relic-or-heal pick | y |
| Elite | enemy + 1-2 affixes | souls x2, relic pick 1 of 3 (U+), may drop a curse option | y |
| Altar | free relic pick 1 of 3 (Isaac treasure room) | relic | y |
| Shop | 3 relics, heal, reroll, curse removal; prices in Souls | trade | y |
| Bonfire | heal 40% OR Reforge (rank up one relic / fuse a recipe) OR cleanse a curse | choose 1 | y |
| Shrine | trade-off table (`items.md` section 8) | relic for a cost | later |
| Event | 2-button vignette, outcomes shown as icons (no text wall) | varies | later |
| Boss | 2-phase fight with a signature rule | boss relic pick 1 of 3, full heal 30% | y |
| Secret | appears after a **flawless** fight (no damage taken): extra door | shrine or relic | later |

Guarantees per Realm: >= 1 relic source, >= 1 recovery, 1 elite, 1 boss. Door table weights are data (`RealmDefinition`).

### 1.3 Length targets
| Room | Time | Notes |
|---|---|---|
| Normal fight | 40-75 s | good parry player kills in ~35 s |
| Elite | 75-120 s | |
| Boss | 120-180 s | |
| Non-combat | 15-40 s | |
| Realm | ~5-6 min | |
| Full run (3 Realms) | 15-18 min clear, 6-10 min typical death | VS (1 Realm): 5-7 min |

### 1.4 HP and economy flow
- HP persists between fights (attrition makes relics matter, Slay the Spire). Heal sources: Bonfire, shop, shrine, relics (`camp_kit`, `menders_thread`), boss clear.
- Souls: from fights, shop-spent. Unspent Souls convert to Embers at run end (see 4.2), so spending vs banking is a real choice.
- No Estus-style flask: it needs a third input. Healing Art `mending_light` covers it.

### 1.5 Omens (run identity)
At run start (after Vessel pick) the game rolls 2 Omen pairs of tags, e.g. `parry + frost`. Player taps one. Effects: relic offer weight x2 for those tags; Realm background tint and UI accent blend the two tag colors. Run looks different before the first fight. Daily run: fixed Omens.

### 1.6 Seeds, saves
- One run seed; separate RNG streams: map, loot, enemy mutations, per-fight (so fight skill never changes loot). Seed shown as a short code ("ASH-7F3K"), shareable, enterable in settings.
- Save at every room boundary (`RunSave` = seed + choices + modifier entries). Web tabs die; "Continue run" button on the menu. Fits `godot-persistence` (versioned JSON, determinism as the test).

### 1.7 Elites and bosses
- Elite = normal enemy + affixes (3.2), accent ring in a second color, 1.3x HP.
- Boss = own rig, 2 phases (`PhaseShift` enemy modifier on `on_damage_taken` hp threshold), signature rule as an enemy modifier. Realm I boss: **Gatekeeper** (ember orange): blocks cost double stamina in phase 2. Realm II **Tidewarden** (cyan): copies your last action. Realm III **Hollow King** (white-violet): plunders one random relic until phase 2 ends.
- Bosses teach the Realm's lesson and test the build, never a hard gate on one relic.

### 1.8 How a run ends
| Ending | Condition | Result |
|---|---|---|
| Victory | final boss dead | Embers 100% of Souls + bonus; unlock reveal; next Dread unlocked |
| Death | HP 0 and no revive | Embers = Souls x bank rate (50% base); shows death screen |
| Abandon | menu | same as death, no ad offers |

Revive: once per run, rewarded ad (or relic `phoenix_ash`), returns at 50% HP with 2 s Ward; the same Modifier class serves both.

### 1.9 Death screen (the "one more run" engine)
In order, each fits one screen:
1. **Killer card**: enemy silhouette in its accent, last attack kind icon, mini-replay of the final telegraph slowed ("you blocked early" / "you pressed late" from `precision`).
2. **Near-miss line**: "Gatekeeper had 8% HP" (shown only when < 25%).
3. **Build bar**: relic icons with colored synergy links, Mantle aura if any.
4. **Stats**: rooms cleared, parries, perfect parries, best streak, time.
5. **Embers counting up** (+ "double" rewarded button), then **unlock progress**: "New: 2 relics unlocked" or bar "42/50 to next upgrade".
6. **Two buttons**: big `Again` (instant, same Vessel, new Omens) and small `Bonfire`. Interstitial only between `Again` press and the run start, cap 1 per 3 min, never in the first 3 runs.

## 2. In-run progression (summary; full list in `items.md`)

- **Relics change rules, not just numbers.** ~35% data stat items, ~65% hook items. Every relic carries tags; tags drive color, synergy links, Mantles (3 same-tag relics), recipes (named fusions at Bonfire), offer weighting, Omens.
- **Offers**: 3 cards = 1 on-build, 1 Omen, 1 wildcard. Reroll costs Souls or 1 rewarded ad per Realm. Rarity C/U/R + boss/cursed; 1 guaranteed rare per Realm.
- **Curses and trade-offs**: shrines, cursed relics (Glass Blade, Reckless Oath), curse offers on elites. Payoffs: Masochist's Crown, Condemned Mantle. Cleanse at Bonfire.
- **Arts (actives)**: one slot, Focus meter charged by parries/hits taken. Input stays two buttons: **cast = press both buttons together** when the meter glows. Why: both thumbs already rest on the buttons, the gesture cannot fire by accident in solo play (gated by full meter), no timing delay on Block (double-tap would). Accessibility: auto-cast option. Arts are post-VS; before that, "charged relics" (e.g. every 3rd parry riposte) give the same fantasy with zero input.
- **Examples of how a run diverges**: Parry/Duelist run (never attacks except after parries), Bleed Tank (blocks all, wins by DoT), Reckless Glass (HP as stamina), Frost Clockwork (enemy time slowed, you attack first), Souls Banker (skips shops, snowballs damage).

## 3. Enemy variety per run

### 3.1 Phrases and mutators
Enemy pattern = 3-4 **phrases** (2-4 steps each). The fight picks phrase order by seed. **Mutators** are enemy-side Modifiers using `modify_enemy_step`:

| Mutator | Effect |
|---|---|
| tempo_shift | telegraph/gap +-15% |
| insert_feint | 30% chance feint before a step |
| delayed_strike | strike held 0.3 s past telegraph end (weapon flickers) |
| double_tap | quick attack repeated |
| heavy_swap | a quick replaced by heavy |
| long_breath | longer recovery gaps (easier, pays more souls less) |

Fairness rules: parry window constant; telegraph pose always visible; delayed strike is flagged by a flicker; first appearance of a kind in the profile (`seen_kinds`) gets a slow replay and 50% damage.

### 3.2 Elite affixes (accent ring color, icon)
| Affix | Mechanic (hook) |
|---|---|
| Swift | telegraph_scale x0.75 (data) |
| Plated | damage_taken x0.5 unless staggered (conditional stat) |
| Vampiric | heals on hit (`on_damage_dealt`) |
| Feinting | extra feints before heavies (`modify_enemy_step`) |
| Echoing | each strike repeats once 0.6 s later |
| Warded | starts with 30% Ward; a parry breaks it and doubles stagger |
| Thorned | attacks outside punish reflect 5% |
| Enraged | after stagger ends, next step 25% faster |
| Mirror | after your attack, counters with a quick |
| Volatile | on death blast, avoidable by blocking at the right moment |
| Cursed | its hit adds a curse |
| Thief | its hit steals Souls |
| Shrouded (Dread 5+) | weapon glow dimmed |

### 3.3 Variety multipliers
- **Threat budget**: each room has points from depth + Dread; affixes and mutators cost points; generator fills the budget randomly (data costs).
- **Recolor conveyor**: same rig, new accent + phrase set + affix pool = new enemy entry for near-zero art cost.
- **Realm I roster (VS)**: Hollow Soldier (crimson, basics), Chain Hound (amber, quick chains, stamina test), Bell Warden (brass, heavies, parry only), Veil Dancer (violet, feints, patience), Gatekeeper boss. Each is an exam of one skill.
- Room conditions later (fog, blood moon) as room-level Modifiers.

## 4. Meta progression (permanent)

### 4.1 Rules that keep skill relevant
1. No permanent upgrades to parry window, telegraph length or damage. Permanent HP is capped +16%.
2. Unlocks add **options** (sidegrades, build-enablers), never strictly better items.
3. Difficulty scales with Dread, so mastery always has a target.
4. Bot-sim gate (`plan.md` tuning): Rookie/Adept/Master bots; best build vs median build < 3x.

### 4.2 Currencies
| Currency | Scope | Source | Sink |
|---|---|---|---|
| Souls | run | fights, parries, relics | shops, shrines, rerolls |
| Embers | permanent | Souls x bank rate at run end (50% death, 100% win; upgradable to 80% death), first-time milestones | Bonfire upgrades, Tributes, Vessels |

Early numbers: normal fight 12 Souls, elite 30, boss 60; a death in Realm I ~ 25-40 Embers; first Bonfire upgrade 30 Embers (buyable after run 1). Cost growth 1.6x per rank. Rewarded "double Embers" on the end screen.

### 4.3 What persists
| Item | Permanent | Run-only |
|---|---|---|
| Embers | y | |
| Souls | | y (converted at end) |
| Bonfire upgrades (HP +4% x4, start Souls, rest heal, bank rate, +1 free reroll, +1 offer size once, door affix preview) | y | |
| Relic unlocks (enter the pool) | y | |
| Vessels (start loadouts) and Vessel mastery | y | |
| Realms unlocked, Dread levels unlocked | y | |
| Codex (seen/owned items, enemies, affixes), kill counters | y | |
| Achievements, daily streak, best times, seed history | y | |
| Settings, seen tutorial flags, `seen_kinds` | y | |
| Relics held, ranks, Mantles, recipes done | | y |
| HP, stamina, Focus, Ward, statuses | | y |
| Curses | | y |
| Map position, Omens, seed | | y (saved as continue-run) |
| Revive used, rerolls used | | y |

### 4.4 Unlocks (Isaac-style, silhouettes)
- Relics start locked (about 40% of the list). Locked entry in the Codex = black silhouette with a one-line riddle ("Parry 10 times in a row").
- Unlock paths: **achievements** (skill, ~70% of unlocks) and **Tribute** (spend Embers on a common relic, ~30%, so no one gets stuck).
- Vessels unlock by goals, not Embers alone.
- New Realms: kill the previous boss. Alt route (Isaac Downpour): later.

### 4.5 Vessels (data: tuning overrides, start relic(s), pool bias, creed modifier)
| Vessel | Creed | VS |
|---|---|---|
| Wanderer | picks 1 of 3 starter relics | y |
| Ashen Duelist | parry_window +25%, chip_share +50% (block is weak) | y (unlock: beat Gatekeeper) |
| Bulwark | blocks cost 0, parry window -20%, slow strong attacks | |
| Penitent | max HP -30%, each hit taken +Focus, starts with a curse payoff | |
| Ember Witch | starts with an Art, low HP | |

### 4.6 Dread (prestige / NG+)
Dread 1-10, per Vessel, unlocked by winning the previous one. Each level adds data rules (D1 elites more common, D2 enemy HP +10%, D3 whispers curse, D4 no bonfire heal in Realm II...). Reward: Embers multiplier +10% per level, Dread-only relics. A reset-style "Rekindle" prestige (wipe Bonfire upgrades for a permanent Ember multiplier) is **not** recommended: unlocks never reset; Dread is the prestige (Slay the Spire Ascension, Hades Heat).

## 5. Engagement and retention

### 5.1 First 60 seconds (no text, only icons, light, bullet time)
| Time | Beat | Teaches |
|---|---|---|
| 0:00 | Dark scene, one enemy, pulsing Block button, hand icon | the whole game is 2 buttons |
| 0:08 | Enemy windup glows; time slows to 20% near the strike; Block glows | parry |
| 0:12 | Parry: clang, hitstop, flash, enemy staggers; Attack glows | punish window |
| 0:15 | 2 more parries with shorter assist | rhythm |
| 0:30 | Attack spam makes stamina bar empty and gasp animation (no assist) | stamina |
| 0:45 | Enemy hit drains HP once (damage capped, cannot die in tutorial) | cost of failure |
| 0:55 | Victory; first relic reveal (3 flashy cards, no wrong choice) | progression |
| 1:10 | Fight 2 with chosen relic visibly changing the player glow | "builds matter" |

Rule: fight 1-2 are scripted data (`TutorialScript`), the player cannot die before the first relic.

### 5.2 First 10 minutes
| Minutes | Goal |
|---|---|
| 0-2 | tutorial fight, first relic |
| 2-6 | Realm I fights 2-4; first elite; early pools seeded so one synergy pair appears (e.g. parry + stamina) |
| ~6-8 | first death (expected): death screen, first Embers, 2 unlock reveals, first Bonfire upgrade bought |
| 8-10 | run 2: different Omens, new relics from unlocks; Codex silhouettes visibly filling |
| ~session 1-2 | first Gatekeeper kill by decent players; Ashen Duelist unlock reveal |

### 5.3 Retention surfaces
| Feature | Design |
|---|---|
| Daily run | shared seed, fixed Vessel/Omens, one scored attempt (+1 retry via rewarded ad); score = rooms + parries + time bonus; `Platform.submit_score(&"daily", n)`; streak gives small Embers, not power. No ad-bought power in Daily/Challenge |
| Weekly challenge | fixed loadout and rules (data): Glass Knight (1 HP, parry heals), Pacifist's Oath (attack only in punish), Stamina Famine |
| Achievements | ~30 in VS, data conditions on `StatsRecorder` counters, each gives an unlock or a cosmetic |
| Codex | grid of silhouettes; discovered = lit in its accent color; tap shows description + synergies seen |
| Seeds | short code, shareable |
| Run history | last 10 runs with build bar |
| Mastery | per-Vessel counter unlocks alt starts |

### 5.4 Rewarded ads (never during a fight, never required)
| Placement | Reward | Limit |
|---|---|---|
| Death: Revive | 50% HP + Ward | 1 per run |
| End screen | double Embers | 1 per run |
| Altar/Elite offer | reroll the 3 cards | 1 per Realm |
| Shop | one restock | 1 per shop |
| Run start | see 3 Omen pairs instead of 2 | 1 per run |
| Daily | 1 extra attempt | 1 per day |

Not pay-to-win because: no permanent power for ads; unique rewards only save time or add choice; disabled in Daily/Challenge scoring. Interstitials: only after death/win before `Again`, frequency cap, never in tutorial. "Remove ads" purchase keeps rewarded options as opt-in.

### 5.5 "Colorful" with silhouettes
- **Accent-per-tag**: relic tags (gold, steel, crimson, orange, cyan, violet, teal...) paint the player: blade glow, trail, parry spark shape, hit numbers, aura. The build is visible on the character (Isaac item sprites).
- **Realm tint + Omen blend** on gradient background.
- **Juice budget**: hitstop 60-90 ms on parry, short chromatic-aberration pulse, radial flash in tag color, slow-mo on boss finisher, screen shake scaled by streak.
- **Procedural sound**: parry clang layered per tag (fire crackle, ice ping, zap); pitch climbs a pentatonic scale per streak; extra music voices fade in as streak grows.
- **Relic reveal**: dim, silhouette rises, color floods, one-line plain effect.
- **Icon flash** (`modifier_triggered`) tells which relic did what.

## 6. Hook list
See `core_hooks.md`.

## 7. Vertical slice scope

| Area | VS | Later |
|---|---|---|
| Realms | 1 (5 steps) | 3, then alt routes |
| Enemies | 4 + Gatekeeper boss | 12 + 3 bosses, recolors |
| Affixes / mutators | 6 / 4 (Swift, Plated, Vampiric, Feinting, Echoing, Warded; tempo, feint, delayed, double) | all |
| Rooms | Fight, Elite, Altar, Shop, Bonfire, Boss | Shrine, Event, Secret |
| Relics | 32 (`items.md` marked y), 3 Mantles, 3 recipes, 3 curses | ~75+, Arts, boss relics |
| Vessels | 2 | 5 |
| Unlocks | 10 relics, 1 Vessel, Dread 1 | codex-wide |
| Bonfire upgrades | 6 | 12 |
| Meta | Embers, Codex, death screen, continue-run | Daily, challenges, achievements UI |
| Ads | revive, double Embers, interstitial | rerolls, restock, daily retry |

Ordered design-driven tasks (each names its owner area, matches `plan.md` Phase 1-2):
1. `Modifier` base, `ModifierHost`, stat bus, ctx types, `HookApi` (`core/modifiers/`); headless tests with 5 relics (parry heal, Reckless, bleed relay).
2. `RunState`, seed streams, `RealmDefinition`, door generator, `RunSave` (`core/run/`).
3. Phrases + `ThreatBudget` + mutators/affixes (reuses Modifier) (`core/combat/`, `data/enemies/`).
4. Relic data + the 32 VS relics, offer policy (Omens, 1/1/1), SetBonusTracker, RecipeService.
5. Run UI: door picker, 3-card pick, shop, bonfire, boss intro (`view/run/`).
6. Death/victory screens, Embers conversion, profile fields (`core/profile/`).
7. Tutorial script + `seen_kinds` assists (`data/`, `view/battle/`).
8. Visual build language: tag colors, player aura/trails, relic reveal, `modifier_triggered` flashes.
9. Bot sims: Rookie/Adept/Master win rate per build archetype; fix power outliers.
10. Hub: Bonfire upgrades, Vessel select, Codex with silhouettes.
11. Platform placements: revive, double Embers, interstitial caps.
12. Post-VS: Daily seed + leaderboard, achievements, Arts (both-button cast), Realms II-III.

## 8. Open questions (recommendation each)
| # | Question | Recommendation |
|---|---|---|
| 1 | Approve one `Modifier` abstraction for relics/affixes/statuses | yes; it is the only way items stay one file each |
| 2 | Tap vs hold block | tap with fixed block duration (keeps cast chord and parry simple) |
| 3 | Arts/spells: both-buttons chord? | defer to post-VS, test chord + auto-cast option; ship charged relics first |
| 4 | Death penalty for Souls | bank 50% as Embers; ad doubles to 100% |
| 5 | Any permanent combat power? | only +16% max HP cap; none for parry/damage |
| 6 | HP persists between fights? | yes, with Bonfire/shop/relic heals |
| 7 | Unlock method | achievements (70%) plus Embers Tribute (30%) |
| 8 | Run length | VS 1 Realm (~6 min), full game 3 Realms (~17 min) |
| 9 | Prestige | Dread levels only, no wipe-style prestige |
| 10 | Continue-run after closing the tab | yes, save at room boundaries |
| 11 | Daily run in VS? | no, right after the Yandex adapter (needs leaderboard) |
| 12 | Names (Embers, Vessel, Omen, Dread, Gatekeeper...) | user to approve; avoid third-party terms |
| 13 | Content tone for portals (curses, blood) | keep abstract, no gore, check portal rules before art |

## 9. Borrowed from (from design knowledge; no fresh web check done)
| Source | Borrowed | Why it fits |
|---|---|---|
| Binding of Isaac | item synergies, transformations (3 of a set), curses/deals, silhouettes of unlocks, seeds | build changes feel and look; data-friendly |
| Slay the Spire | intent display (forecast), Ascension (Dread), pick-of-3, persistent HP | readable choices, short sessions |
| Hades | door previews, duo boons (recipes), keepsakes/Mirror (small meta), Heat | one-tap choices, meta without trivializing |
| Dead Cells | color-coded stats/tags, cursed trade-offs | colorful builds |
| Vampire Survivors | evolutions (recipes), short runs, unlock-by-condition | quick power fantasy |
| Balatro | retrigger (`ctx.repeat`), scaling by counters, interest (Hoarder) | few inputs, deep math |
| Punch-Out!! | learned patterns, first-seen assists, star-punch reward for timing | pure-timing core |
| Sekiro | deflect precision, posture-style punish windows | parry-first feel |
| Incremental/idle | exponential Bonfire costs, ad-doubled currency | long tail without power creep |

## Decisions (user, 2026-10-20)

| Question | Decision |
|---|---|
| One `Modifier` abstraction | Yes: relics, elite affixes, statuses, curses, vessels, equipment |
| Block input | **Hold or tap** (replaces the tap/hold setting, 2026-10-20 later): block lasts while held and at least `block_min_duration` after a tap; holding reduces damage; each blocked hit costs stamina (scaled by hit damage and shield stats), no drain while idle-holding; stamina 0 = guard broken. Parry = block **pressed** within the parry window before the strike. Attack while holding drops the block |
| Arts | Deferred until after the slice |
| Souls on death | **0% banked**; a rewarded ad rescues 50% (not the designer's 50%) |
| Permanent power | **Changed (2026-10-20 evening): two layers.** Run: fast stat levels for Souls after each fight (lost on death). Permanent: slow stat levels for Embers, rising price, no cap (clicker feel). Stats: HP, stamina, damage, stamina regen. Enemies scale with realm level / Dread |
| Unlocks | ~70% achievements, ~30% Embers |
| Continue run | Yes, at room boundaries |
| Equipment | Vessel gives the starting set; swaps in shops and rewards; all Modifiers |
| Daily run | After a portal adapter exists |
| Names (Embers, Vessel, Omen, Dread) | Working names, not final |
| Parry readability | View shows the strike moment explicitly: an approach ring that closes on a target ring at the strike, the parry window lit on it, a tell (flash + tick) when the window opens. Core events carry strike time and parry window |
| Tempo | Clicker feel: cheap fast attacks (lock ~0.2 s, cost ~10), lower damage per hit, more enemy HP, combo multiplier for consecutive hits without taking damage, crit clicks in the post-parry punish window |
| Mouse | Keep halves of the screen as on touch (keyboard can hold block + attack) |
| Run purchases | **In battle, side panel** (final): a collapsible shop drawer during every fight, paid in run Souls, any time. Sells consumables (persist through the run, used from HUD slots), run-long buffs, and run stat levels (replaces the post-fight level-up screen). Souls come in during the fight: small amount per hit (scaled by combo) and per parry, plus the kill reward. No pre-run shop |
| Pause | Pause menu in battle (☰ / Esc): resume, settings, abandon run, main menu; pausing stops the duel clock |
| Endless | **Depth** (2026-10-20 night): after the boss the next realm starts deeper; enemy stats grow exponentially per node; the run lasts until death; best depth is recorded (leaderboard later). New affixes join with depth so difficulty is not only numbers |
| Map | Keep the door choice per step, but visualize the path: nodes already walked, the branching doors now, unknown steps ahead |
| Enemies per room | Waves (one after another, combo and souls carry over) now; two at once later for deep realms |
| Revive | Once **per fight** (not per run); the k-th revive of the run costs k rewarded ads (1, then 2, then 3; 3 is the cap, every later revive stays 3) |
| Ad for missing souls | When a shop/altar purchase lacks souls, the button offers "watch 1 ad" to get it anyway |
| Flask on purchase | Buying a flask in battle drinks it at once if HP is not full (else it is stored) |
| Room rewards | Later: rewards along the run (e.g. +flask, +max HP) picked after elites/bosses |

# soulsclicker: relics, tags, synergies

Companion to `run_and_progression.md` (run/meta) and `core_hooks.md` (hook contracts). Terms: **relic** = run item, **Focus** = charge meter for **Arts** (actives), **Souls** = in-run gold, **Omen** = 2 favored tags rolled per run.
Rarity: C common, U uncommon, R rare, B boss-only, X cursed (trade-off). `VS` = ships in vertical slice. `data` = pure stat entry, zero code.
Numbers are defaults in `ModifierDefinition.params`; tune by bot sims, never in code.

## 1. How synergy works (no special code)

Relics never reference each other. They talk through 4 shared vocabularies:

| Vocabulary | Meaning | Example |
|---|---|---|
| Stats | named numbers on the stat bus (`modify_stat`) | `parry_window`, `attack_cost` |
| Statuses | Bleed, Burn, Chill, Shock, Ward, Fervor on a fighter | A applies Bleed, B heals on hitting a bleeder |
| Events | hooks fired by core (`on_parry`...) | A makes parries free-attack, B refunds stamina on attacks |
| Counters | run/fight read-only numbers | `tag_count(&"curse")`, `souls`, `parry_streak` |

Synergy patterns (design checklist; every new relic should join at least one):

| Pattern | Shape | Example |
|---|---|---|
| Status relay | A applies, B consumes/amplifies | Serrated Edge -> Vampire Fang |
| Trigger relay | A's effect is an event for B | Riposte Charm (free attack after parry) -> Overreach (punish attacks free) |
| Resource loop | A makes a resource, B spends it | Echo Bell (stamina) -> Twin Fang |
| Stat scaling | B reads a counter A raises | Masochist's Crown reads curses; Tithe Crown reads souls |
| Rule bender + patch | A breaks a rule, B pays its cost | Reckless Oath (attacks cost HP) + Mender's Thread |
| Retrigger | multiplies other hooks (`ctx.repeat`) | Duelist's Pride doubles parry hooks on perfect parry |
| Tag set | 3+ relics of one tag grant a Mantle | section 4 |
| Recipe | named pair/triple fuses at bonfire | section 5 |

UI: data field `synergy_with: [ids/tags]` draws colored links between icons on the build bar and the death screen (teaches synergies). Offers weight x1.5 for relics sharing a tag with owned ones, x2 for Omen tags; each 3-card offer = 1 on-build, 1 Omen, 1 wildcard slot (policy classes, data-tuned).

## 2. Tags and colors (one accent per tag, drives player glow, trails, parry sparks, number colors)

| Tag | Color | Theme |
|---|---|---|
| parry | gold | timing, riposte |
| block | steel blue | guard, thorns, ward |
| strike | bone white | attack, punish |
| stamina | green | endurance |
| vital | rose | HP, heal, ward |
| bleed | crimson | DoT stacks |
| burn | orange | DoT, spread |
| frost | cyan | slow enemy clock |
| shock | violet | stagger |
| soul | teal | economy |
| read | lilac | telegraph info |
| focus | white-gold pulse | Arts charge |
| curse | acid magenta | trade-offs |

Tag count = distinct relics holding the tag (stacks do not count twice).

## 3. Statuses (each = one small Modifier class, data numbers)

| Status | On | Rule |
|---|---|---|
| Bleed | enemy | stacks to 5; each stack 0.25x player dmg per second; 4 s, refresh on apply |
| Burn | enemy | no stack, intensity; 0.8x dmg per second; 3 s |
| Chill | enemy | stacks to 3; each +10% telegraph length. 3 stacks = Frozen: stagger 1.5 s, then immune 6 s |
| Shock | enemy | stacks to 4; at 4 discharge: 1x dmg + stagger 0.5 s, reset |
| Ward | either | absorbs damage first; does not regen |
| Fervor | player | next attack(s) +dmg; consumed on attack |

## 4. Mantles (tag-set transformations, Isaac style)

Hold 3 relics with the tag (VS) => a hidden Mantle modifier is granted, player rig gets the tag aura. Data: `SetBonusDefinition{tag, count, modifier_id}`; one `SetBonusTracker` in `RunState` listens to `on_acquire/on_remove`. Mantle itself is a normal Modifier.

| Mantle | Tag x3 | Effect | VS |
|---|---|---|---|
| Duelist | parry | each parry auto-ripostes for 50% dmg; perfect window +25% | yes |
| Crimson Saint | bleed | bleed ticks heal you 0.5 HP; bleeding enemies cannot gain Ward | yes |
| Bastion | block | block chip 0; blocked strikes reflect 100% dmg | yes |
| Pyre Walker | burn | Burn spreads: staggered enemy gets Burn doubled; Burn ticks give Focus | |
| Winter Vigil | frost | Frozen punish hits deal x1.5; Chill max stacks 4 | |
| Stormcaller | shock | every discharge repeats once (retrigger) | |
| Second Lungs | stamina | attacks cost 0 while stamina above 70% | |
| Overflow | vital | overheal becomes Ward | |
| Tithe King | soul | 1 soul = +0.2% dmg, cap +40% | |
| Oracle | read | forecast depth +1, feints revealed, parry window +10% | |
| Condemned | curse | curses give +10% dmg each and heal 1 HP per hit taken | |

## 5. Recipes (fusion at bonfire, Hades duo / Vampire Survivors evolution)

`RecipeDefinition{inputs[], output, where: bonfire}`; the bonfire shows a glowing "merge" button when owned inputs match. Output is a normal relic (stronger, replaces inputs).

| Output | Inputs | Effect | VS |
|---|---|---|---|
| Endless Dance | riposte_charm + echo_bell | while parry streak >= 2, attacks cost 0 and have no lock | yes |
| Sanguine Chalice | menders_thread + vampire_fang | bleeding hits heal 1; overheal -> Ward | yes |
| Thorn Mirror | mirror_shard + barbed_shield | parry/block reflect dmg and apply 2 Bleed | yes |
| Stilled Hour | hourglass_sand + heartbeat | heavy telegraphs +40% and parry window x1.5 | |
| Rime-Rot | frostbitten_fang + serrated_edge | Frozen enemies take double Bleed ticks | |
| Wildfire | ember_wick + cinder_blade | Burn spreads to Bleed stacks (converts) | |
| Storm Mirror | spark_plate + mirror_shard | parry reflect becomes Shock discharge | |
| Hollow Crown | glass_blade + phoenix_ash | +60% dmg, revive at 50% HP once, max HP -35% stays | |

## 6. Relic list (by hook). Format: id | name | tags | rarity | effect

### 6.1 `modify_stat` (data only, no class)
| id | Name | Tags | R | Effect | VS |
|---|---|---|---|---|---|
| whetstone | Whetstone | strike | C | attack_damage +15% (stack 3) | y |
| iron_lung | Iron Lung | stamina | C | max_stamina +25% | y |
| wind_ring | Ring of Wind | stamina | C | stamina_regen +25% | |
| hawk_feather | Hawk Feather | parry | C | parry_window +12% | y |
| tower_shard | Tower Shard | block | C | chip_share -30% | y |
| thick_hide | Thick Hide | vital | C | max_hp +20% (heals the gain) | y |
| hourglass_sand | Hourglass Sand | read | U | enemy telegraph_scale +10% | |
| light_gauntlet | Light Gauntlet | strike | C | attack_lock -20%, attack_damage -10% | |
| executioners_hood | Executioner's Hood | strike | U | punish_mult +0.5 | y |
| greedy_purse | Greedy Purse | soul | C | souls_gain +30% | |
| lead_boots | Lead Boots | strike | U | stagger_time +25% | |
| plate_harness | Plate Harness | block | U | chip_share -50%, stamina_regen -20% | |
| featherweight | Featherweight | stamina | C | attack_cost -30%, attack_damage -15% | |
| lucky_knuckle | Lucky Knuckle | soul | U | luck +1 (rarity weights shift up) | |
| foresight | Foresight | read | R | forecast_depth +2: UI shows next 2 enemy attacks (Slay the Spire intent) | y |
| glass_blade | Glass Blade | strike, curse | X | attack_damage +60%, max_hp -35% | y |
| tangled_thread | Tangled Thread | read, curse | X | enemy telegraph_scale -15%, parry_window +40% | |

### 6.2 `on_parry` (and `ctx.repeat`)
| id | Name | Tags | R | Effect | VS |
|---|---|---|---|---|---|
| menders_thread | Mender's Thread | parry, vital | C | parry heals 1 HP (perfect 2) | y |
| spark_plate | Spark Plate | parry, shock | U | parry applies 1 Shock | |
| riposte_charm | Riposte Charm | parry, strike | U | next attack within 2 s of a parry costs 0 stamina | y |
| echo_bell | Echo Bell | parry, stamina | C | parry restores 20% stamina | y |
| gilded_gauntlet | Gilded Gauntlet | parry, soul | C | parry +1 soul (+1 more per 3 streak) | |
| perfect_rhythm | Perfect Rhythm | parry | R | every 3rd streak parry: free riposte 150% dmg | |
| mirror_shard | Mirror Shard | parry, strike | R | parry reflects strike dmg x0.5 (perfect x1) | y |
| ember_wick | Ember Wick | parry, burn | U | parry applies Burn | y |
| frost_rune | Frost Rune | parry, frost | U | parry applies 2 Chill | |
| kindling | Kindling | parry, focus | U | parry +15 Focus | |
| duelists_pride | Duelist's Pride | parry | R | perfect parry fires all `on_parry` hooks twice (`ctx.repeat = 2`) | y |

### 6.3 `on_block`, `on_block_ended`, `modify_strike` (guard rules)
| id | Name | Tags | R | Effect | VS |
|---|---|---|---|---|---|
| barbed_shield | Barbed Shield | block, bleed | C | block applies 1 Bleed to attacker | y |
| bulwark_sigil | Bulwark Sigil | block, stamina | U | blocking costs no stamina | y |
| stoneskin | Stoneskin | block, vital | U | block gives Ward = 50% of prevented dmg (cap 20% max HP) | |
| counter_tide | Counter Tide | block, strike | C | block of a quick attack fires counter, 30% dmg | y |
| static_mail | Static Mail | block, shock | U | block applies 1 Shock, reflects chip x3 | |
| patient_guard | Patient Guard | block, stamina | C | block that ended with no strike (bait): +10 stamina | |
| iron_vigil | Iron Vigil | block | B | blocks of quick attacks count as parries; heavy dmg x1.5 | |
| ghost_cloak | Ghost Cloak | vital, read | R | first strike each fight is negated | y |
| forgiving_guard | Forgiving Guard | parry, block | U | block within 2x parry window counts as parry vs quick | |

### 6.4 `on_damage_taken`, `on_would_die`, `on_heal`
| id | Name | Tags | R | Effect | VS |
|---|---|---|---|---|---|
| martyrs_brand | Martyr's Brand | vital, strike | U | after a hit taken, Fervor: next attack x2 | y |
| bloodsoaked_rag | Bloodsoaked Rag | bleed, vital | C | hit taken gives enemy 2 Bleed | y |
| last_stand_charm | Last Stand Charm | vital | U | below 30% HP damage taken -30% (conditional stat) | |
| penance_coin | Penance Coin | soul, curse | X | each hit taken +5 souls, max_hp -10% | |
| phoenix_ash | Phoenix Ash | vital | R | once per run: survive death at 30% HP (same modifier the revive ad grants) | y |
| last_breath | Last Breath | vital, strike | U | once per fight: survive lethal at 1 HP and stagger enemy 3 s | |
| overheal_veil | Overheal Veil | vital | U | healing above max becomes Ward | |

### 6.5 `modify_attack` (attack rules)
| id | Name | Tags | R | Effect | VS |
|---|---|---|---|---|---|
| reckless_oath | Reckless Oath | strike, vital, curse | X | attacks cost 4% max HP instead of stamina; dmg +25% | y |
| twin_fang | Twin Fang | strike | U | 25% attack hits twice | |
| overreach | Overreach | strike, stamina | U | attacks in punish window cost 0 | y |
| heavy_hand | Heavy Hand | strike | C | every 3rd attack of the fight x1.8 dmg | |
| ambushers_cloak | Ambusher's Cloak | strike, read | U | fight opens with enemy staggered 1.2 s (`on_fight_start`) | |

### 6.6 `on_damage_dealt` (your hits: status procs)
| id | Name | Tags | R | Effect | VS |
|---|---|---|---|---|---|
| serrated_edge | Serrated Edge | bleed, strike | C | attack applies 1 Bleed | y |
| cinder_blade | Cinder Blade | burn, strike | U | 30% apply Burn | y |
| frostbitten_fang | Frostbitten Fang | frost, strike | C | hit applies 1 Chill | |
| vampire_fang | Vampire Fang | vital, bleed | U | hit on bleeding enemy heals 1 HP (1/s) | y |
| thunderhead | Thunderhead | shock, strike | U | hit applies 1 Shock | |
| soul_siphon | Soul Siphon | soul | C | punish hits +1 soul | y |
| deep_cut | Deep Cut | bleed | U | punish hits apply 3 Bleed | |

### 6.7 `on_stagger_started` / `on_stagger_ended`
| id | Name | Tags | R | Effect | VS |
|---|---|---|---|---|---|
| executioner | Executioner | strike | R | stagger ends after >= 3 hits: finishing blow 10% enemy max HP | |
| hamstring | Hamstring | strike, frost | U | stagger starts: 2 Chill | |
| relentless | Relentless | strike, stamina | R | each hit during punish +5 stamina | |
| opportunists_eye | Opportunist's Eye | strike, read | U | punish duration +0.4 s (data) | |

### 6.8 `on_stamina_empty`
| id | Name | Tags | R | Effect | VS |
|---|---|---|---|---|---|
| second_wind | Second Wind | stamina | U | first time stamina hits 0 each fight: refill 50% | y |
| exhaustion_fury | Exhaustion Fury | stamina, strike | U | stamina below 20%: dmg +50% (conditional stat) | |

### 6.9 `on_telegraph_started`, `modify_enemy_step` (reading the enemy)
| id | Name | Tags | R | Effect | VS |
|---|---|---|---|---|---|
| seers_eye | Seer's Eye | read | U | feint telegraphs show a ghost glow (`ctx.reveal_feint`) | y |
| heartbeat | Heartbeat | read, parry | U | heavy telegraph: parry_window x1.25 for that strike | |
| dull_instinct | Dull Instinct | read | U | feints removed from patterns; enemy dmg +10% | |
| hollow_eye | Hollow Eye | read | B | forecast full phrase; stamina_regen -40% | |

### 6.10 Run hooks (`on_fight_start/end`, `on_room_exit`, `modify_offer`)
| id | Name | Tags | R | Effect | VS |
|---|---|---|---|---|---|
| pilgrims_lantern | Pilgrim's Lantern | soul | C | fight start +10 souls | y |
| camp_kit | Camp Kit | vital | C | fight end heal 10% max HP | y |
| flawless_medal | Flawless Medal | soul, parry | U | flawless fight: +25 souls, +1 reroll | |
| hoarders_ledger | Hoarder's Ledger | soul | R | room exit: +1 soul per 10 held (cap 10) | y |
| scavengers_eye | Scavenger's Eye | soul | U | altar/elite offers show +1 card | |
| mapmakers_compass | Mapmaker's Compass | read, soul | U | door previews show affixes (`door_info` stat) | |
| tithe_crown | Tithe Crown | soul, strike | R | attack_damage +5% per 50 souls held | |
| masochists_crown | Masochist's Crown | curse, strike | R | dmg +10% per curse owned | |

### 6.11 `on_tick`, `on_status_applied`, `on_fight_start`
| id | Name | Tags | R | Effect | VS |
|---|---|---|---|---|---|
| ember_heart | Ember Heart | vital | U | idle 8 s in fight: +1 HP | |
| heat_haze | Heat Haze | burn, block | R | while blocking, 2 Burn/s on enemy | |
| rotting_mantle | Rotting Mantle | bleed, curse | X | -1 HP / 10 s; enemy +1 Bleed / 5 s | |
| witchfire_oil | Witchfire Oil | burn, frost | U | Burn applied to Chilled enemy: steam stagger 0.5 s | |
| crimson_chalice | Crimson Chalice | bleed | R | `status_potency` bleed +50% | |
| conductor_rod | Conductor Rod | shock | R | Shock discharge at 3 stacks instead of 4 | |
| wardstone | Wardstone | vital, block | C | fight start: Ward 15% max HP | |

### 6.12 Arts (actives, `on_cast`): one Art slot per run, cast = both buttons when Focus is full
| id | Name | Tags | Effect |
|---|---|---|---|
| cinder_burst | Cinder Burst | burn, focus | 4x dmg + 3 Burn |
| veil_step | Veil Step | parry, focus | next strike auto-parried, precision 1 |
| mending_light | Mending Light | vital, focus | heal 30% max HP |
| time_snare | Time Snare | read, focus | enemy telegraph frozen 2.5 s (free attacks) |
| thunder_call | Thunder Call | shock, focus | stagger 1.5 s + 4 Shock |
| blood_rite | Blood Rite | bleed, vital, focus | pay 15% HP: refill stamina + 5 Bleed |

Focus sources (data stat `focus_gain` + relics like Kindling): parry +10, hit taken +8, punish hit +3. Auto-cast accessibility option: cast on full Focus.

### 6.13 Boss relics (boss pool, strong plus downside)
| id | Effect |
|---|---|
| crown_of_cinders | dmg +40%; every enemy gets +1 affix |
| heart_of_the_gate | max HP +30%; bonfire heals nothing |
| iron_vigil | see 6.3 |
| hollow_eye | see 6.9 |
| gatekeepers_key | unlock a secret door each realm; shop prices +30% |

## 7. Curses (imposed by shrines, events, elite drops; data)
| id | Effect | Cleanse |
|---|---|---|
| frailty | max_hp -15% | bonfire |
| weight | attack_lock +25% | bonfire |
| brittle_guard | chip_share +50% | bonfire |
| hunger | stamina_regen -30% | bonfire |
| whispers | 1 in 6 enemy steps gets an extra fake telegraph (feint) | shrine |
| greed | shop prices +30% | shop |
| dread_mark | elites get +1 affix | boss kill |
| thin_blood | -2 souls per hit taken | bonfire |

Curse refunds in the item-power budget: each curse pays back about 1 rarity tier of reward at the offering shrine.

## 8. Shrines (trade-offs, `ShrineDefinition` = list of options as data)
| Shrine | Options |
|---|---|
| Blood Altar | pay 25% max HP (run-long) -> rare relic |
| Gambler's Bell | 50% rare relic / 50% curse |
| Cursed Chest | free relic + 1 curse, pick curse from 2 |
| Wandering Smith | upgrade 1 relic rank (+50% params) |
| Hollow Merchant | sell a relic for souls (x3 shop price) |
| Quiet Pool | heal 40% or remove 1 curse |

## 9. Rarity, pools, power budget
| Rarity | Offer weight | Power pts | Notes |
|---|---|---|---|
| C | 50 | 1 | stat and simple hooks, stackable up to 3 |
| U | 30 | 2 | status procs, resource loops |
| R | 15 | 4 | rule benders, retrigger, build-definers |
| B | boss only | 4 + downside | one pick from 3 |
| X | shrine/elite | 3 + curse payload | negative stat is the cost |

Pools (data field `pools`): `altar`, `elite` (U+), `boss`, `shop`, `shrine`. Guarantee: 1 rare per realm (pity counter). Luck stat shifts weights. Duplicate rule: unique relics leave the pool; C stackables stay to max stacks. Bot-sim gate: best-build / median-build clear-time ratio < 3.

## 10. Hook coverage (every hook has >= 1 relic, else cut it)
`modify_stat` stat items; `on_parry` 6.2; `on_block` 6.3; `on_block_ended` patient_guard; `modify_strike` ghost_cloak, iron_vigil; `modify_attack` 6.5; `on_damage_dealt` 6.6; `on_damage_taken` 6.4; `on_heal` overheal_veil; `on_stagger_*` 6.7; `on_stamina_empty` 6.8; `on_telegraph_started` seers_eye, heartbeat; `modify_enemy_step` dull_instinct; `on_status_applied` witchfire_oil; `on_would_die` phoenix_ash; `on_cast` Arts; `on_tick` ember_heart; run hooks 6.10.

## 11. Count
Total listed: ~75 relics, Arts and boss relics + 8 curses + 6 shrines + 11 Mantles + 8 recipes. VS slice: 32 relics (marked `y`), 3 Mantles, 3 recipes, 3 curses (frailty, weight, hunger), 0 Arts.

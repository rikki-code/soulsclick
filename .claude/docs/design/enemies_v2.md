# Enemies v2: 13 new (proposal, needs user ack for core classes)

Existing 9: grunt knight warden (R1) / hound dancer bulwark (R2) / pilgrim hangman wretch (R3-4). R4 boss is still a hangman reuse. This doc adds 13: 3 R1, 4 R2, 3 R3, 3 R4. All data = `data/enemies/<id>.tres` (+ locale `ENEMY_<ID>`, rig in `art` skill). Bosses R1 warden, R2 bulwark, R3 hangman stay; only R4 gets a new boss. R1 elites = grunt/knight + affixes (pool exists).

## Rules of thumb

- Player has only Attack + Block. No dodge, no player heavy. "Dodge/stamina" fights = stamina budget (block cost, drain, attack cost), not rolling.
- Shield/ward is broken by PARRY (stagger), never by a heavy of ours.
- Grunt ref: Q tell .8/.7, recovery 1.3/.9, opening 1.5, post-stagger .8. Notation: `Q t/r` quick, `H t/r` heavy (dmg x1.9-2.2), `F(q|h) t/r` feint imitating quick/heavy, `C(t1,t2..)/r` combo. Dmg scales in brackets when not default.
- Fairness (core_hooks): parry window constant, telegraph pose always visible, new kind first seen = slow replay.
- Twist tag: `existing` = data only or existing class (Swift/Plated affix, feint, combo). `needs-core` = new class named below.
- Fight type: P = parry-focused, S = stamina/block-economy, B = burst (open a window, dump damage).

## Realm I: Ashen Halls (teaches basics)

| Id / en / ru | Silhouette (parts) | Role | Pattern | Twist |
|---|---|---|---|---|
| `thrall` Ash Thrall / Пепельный раб | hunched body, drooping head, 1 long arm, club (4). Accent ember red | P, tutorial | H 1.0/1.2 [x1.5], Q .9/1.0, Q .8/1.3. opening 1.6, post-stagger 1.3 | Dazed: long stagger = huge punish window. `existing` (data only: post_stagger_delay) |
| `cultist` Torch Cultist / Факельщик | hooded head, robe body, arm, torch w/ glow (4). Accent orange | S | Q .6/.9, C(.5,.35)/1.0 [x.8], Q .7/1.1 | Burn: each hit that lands (not parry; blocked chip too) adds Burn, 3 s DoT, 2 stacks max. `needs-core`: `BurnStatus` (Modifier on_tick, on fighter host), `ApplyStatusOnHit` enemy modifier. |
| `crow` Carrion Crow / Падальщик-ворон | round body, small head+beak, 2 wing parts (4). Accent pale yellow eyes | S, flurry | C(.4,.25,.25,.25)/.8 [x.5], Q .5/.7, F(q) .4/.3, C(.4,.25,.25)/.9 | Fast flurry: 4 weak strikes, blocking all costs less than hp; tests hold-vs-tap. `existing` (combo data) |

## Realm II: Drowned Crypt (statuses and attrition)

| Id / en / ru | Silhouette | Role | Pattern | Twist |
|---|---|---|---|---|
| `acolyte` Drowned Acolyte / Утопленник-послушник | bloated body, bowed head, dripping arm, censer (4). Accent sick green | P | Q .7/1.0, Q .7/1.2, H 1.0/1.1, F(h) .9/.4 | Poison: blocked chip and hits add Poison (1 dmg/s, stacks, ends at fight end). Parry = clean, so forces parry. `needs-core`: `PoisonStatus` (Modifier, shares `ApplyStatusOnHit`) |
| `leech` Leech Swarm / Пиявочный рой | one blob body + 3 wriggling leech parts (4). Accent dark red | S | C(.45,.3,.3)/.9 [x.4], Q .5/.8, C(.45,.3,.3,.3)/1.0 [x.35] | Siphon: blocked hit drains stamina x2 (guard breaks early); hits are weak, so taking some is fine. `needs-core`: `SiphonCombo` AttackKind (extends `ComboAttack`, overrides `on_blocked`; `AttackKindCatalog` line) |
| `shieldbearer` Sunken Shieldbearer / Затонувший щитоносец | tall body, head in helm, arm, tower shield (big part), spear (5). Accent cyan rim | B | stance cycle: guard 2.5 s (shield up pose) -> H 1.1/1.4 [x2.0] -> open recovery. Plus Q .7/.9 between | Guard stance: damage taken x0.15 while shield is up; open only in its recovery or after parry. Attacking into shield wastes stamina. `needs-core`: `GuardStanceModifier` (conditional `damage_taken`, state flag from pattern step, new `stance` field on `AttackStepDefinition`) |
| ELITE `reaver` Tide Reaver / Приливный жнец | lean body, long head hood, 2 arms, scythe (5). Accent deep teal ring | P | Q .6/.8, F(q) .5/.3, D(.5+.6 pause)/1.0 [x1.5], Q .5/.7 | Delayed strike (riptide): tell, flicker, pause, then hit. Early parry fails. Pause flicker is the cue. `needs-core`: `DelayedAttack` AttackKind (`telegraph_time` + `delay_time` on step def, flicker event via telegraph) |

## Realm III: Bone Cathedral (rhythm and big hits)

| Id / en / ru | Silhouette | Role | Pattern | Twist |
|---|---|---|---|---|
| `choirboy` Bone Choirboy / Костяной хорист | small skeleton, huge jaw head, 2 arms w/ hymnal (4). Accent bone white | P | C(.5,.5,.5)/1.2 [x.9, gap .15], Q .6/.8, C(.5,.5,.5,.5)/1.3 [x.8], H .9/1.0 | Metronome: equal gaps, learn the beat and parry the whole chain. `existing` (combo data) |
| `gargoyle` Cathedral Gargoyle / Горгулья собора | crouched body, horned head, 2 wing parts, claw (5). Accent violet | B | H 1.3/1.8 [x2.4] (long recovery), Q .6/.9, F(h) 1.1/.5, H 1.2/1.8 | Stone skin: damage x0.5 unless staggered (`PlatedAffix` as innate). Parry its big heavy, then dump combo in the long punish. `existing` (PlatedAffix) |
| ELITE `abbot` Bone Abbot / Костяной аббат | tall robe body, mitre head, arm, staff w/ lamp, censer (5). Accent gold | P | F(q) .6/.3, C(.5,.35,.35)/1.0, F(h) .9/.4, H 1.0/1.0 | Ward: starts with a ward = 30% hp that takes 0 dmg until a parry breaks it (stagger x2). `needs-core`: `WardedAffix` (`modify_damage_taken` + `on_parried`; also the listed "Warded" affix) |

## Realm IV: Ashen Abyss (everything at once)

| Id / en / ru | Silhouette | Role | Pattern | Twist |
|---|---|---|---|---|
| `duelist` Abyss Duelist / Бездонный дуэлянт | slim body, plumed head, 2 arms, thin blade (5). Accent white-grey | S | Q .5/.7, Q .5/.7, F(q) .4/.3, C(.4,.3)/.8, H .8/.9 | Riposte: after each of your attacks it queues a counter quick (.5 tell); spamming costs hp. `needs-core`: `MirrorCounterModifier` (`on_damage_taken` -> `fx.queue_step`, uses `HookApi`; the listed "Mirror" affix) |
| ELITE `berserker` Cinder Berserker / Берсерк-головня | broad body, tiny head, huge arm, cleaver w/ glow (4). Accent hot orange | B | H .8/.9, Q .6/.7, C(.45,.35)/.9 | Enrage <30% hp: tells x0.7, dmg x1.25, glow white. Burst him before it. `needs-core`: `EnrageModifier` (hp threshold in `on_damage_taken`, also `PhaseShift`) |
| BOSS `sovereign` Ash Sovereign / Пепельный владыка | huge crowned head, body w/ cape, 2 arms, sword + cracked halo (6). Accent white-violet | P+S+B | P1: H 1.0/1.1, Q .6/.8, F(h) .9/.4, C(.5,.35,.35)/1.0. P2 (<50%): adds Echo | P2 Echo: every strike repeats once .6 s later (second hit parry-able separately). Phase swap clears feint. `needs-core`: `PhaseShift` (shared w/ berserker), `EchoingAffix` (`on_strike_resolved` -> `fx.repeat_strike`, depth cap by HookApi) |

## Numbers vs grunt (hp x1.0 = 175, dmg x1.0 = 18, souls x1.0 = 10). Level scaling via `CombatScaling`.

| Id | hp | dmg | souls | opening | fight type |
|---|---|---|---|---|---|
| thrall | .8 | 1.0 | .8 | 1.6 | P |
| cultist | .9 | .8 | 1.3 | 1.4 | S |
| crow | .6 | .7 | 1.2 | 1.2 | S |
| acolyte | 1.3 | .9 | 2.0 | 1.4 | P |
| leech | 1.0 | .6 | 2.0 | 1.3 | S |
| shieldbearer | 1.6 | 1.1 | 2.5 | 1.5 | B |
| reaver (elite) | 2.2 | 1.0 | 5 | 1.2 | P |
| choirboy | 1.0 | .9 | 2.0 | 1.5 | P |
| gargoyle | 1.8 | 1.3 | 3.5 | 1.6 | B |
| abbot (elite) | 2.8 | 1.1 | 7 | 1.3 | P |
| duelist | 1.5 | .9 | 4.0 | 1.2 | S |
| berserker (elite) | 2.5 | 1.2 | 9 | 1.2 | B |
| sovereign (boss) | 5.5 | 1.5 | 20 | 1.4 | mix |

Compare existing: knight 1.3/.9/3, warden 3.1/1.1/12, hangman 3.7/1.3/9, wretch 2.4/.8/8. Bot-sim each (`tests/combat_sim.gd`) before shipping: target 8-20 s normal, 75-120 s elite, boss 120-180 s (run doc 1.7).

## Variety check

Realm mix per run: R1 = P+S+S, R2 = P+S+B (+P elite), R3 = P+B (+P elite), R4 = S (+B elite, mix boss). R3 is parry-heavy by design (Cathedral = rhythm). R2/R3 add one S each via relics/chips if sim shows too many P.

## Two at once (needs `Duel` with `enemies[]`; targeting = nearest alive, attack hits front one)

Rule: second enemy dmg x0.6, hp x0.7, its telegraph start >= .6 s apart from the first (stagger pairs by `opening_delay` offset), so two parries never need the same instant. Core: `needs-core`: `EncounterGroup` (list of `EnemyDefinition` + offsets), second `Fighter`, `target_index`, `strike_resolved` carries `source_index`, souls split.

| Pair | Why it works |
|---|---|
| thrall + crow | slow big tell + fast flurry; parry thrall, block crow. Tutorial for two threats. |
| cultist + thrall | burn ticks while you parry the club. |
| leech + shieldbearer | shield tanks hits, leech siphons stamina behind it; kill leech first. |
| choirboy x2 | same beat, shifted .25 s (ragged rhythm). Hard mode. |
| acolyte + crow | poison + flurry forces parry over block. |
| Sovereign P2 + thrall summon | boss add, each summon = one parry of a slow club; keeps B players honest. |

## Core work list (all `needs-core`, one file each)

`BurnStatus`, `PoisonStatus`, `ApplyStatusOnHit`, `SiphonCombo`, `DelayedAttack`, `GuardStanceModifier`, `WardedAffix`, `MirrorCounterModifier`, `EnrageModifier`/`PhaseShift`, `EchoingAffix`, `EncounterGroup`. Order by cost/value: PhaseShift+Enrage (also boss), SiphonCombo, DelayedAttack, statuses, GuardStance, Ward, Mirror, Echo, EncounterGroup. Data-only batch available now: thrall, crow, choirboy, gargoyle (4 enemies, zero core).

# Tutorial: floor 0 (design, revised 2026-10-22)

A scripted prologue that teaches every mechanic by doing it. Light, almost childish look (pastel sky, round
trees, toy enemies), the opposite of the dark realms, so leaving it for realm 1 feels like going deeper.

## Player flow (decided by the user)

- New game, `profile.tutorial_done == false`: the run starts with the tutorial. When it ends the SAME road
  continues, seamlessly, into realm 1 (road look blends with `transition_road`), no summary, no loading.
- New game, `tutorial_done == true`: straight to realm 1 as today.
- Settings: button "Show tutorial" (sets `tutorial_done = false`: the next new game starts with it) and button
  "Skip tutorial" (sets `tutorial_done = true`). Inside the tutorial the bubble has a Skip pill (confirm, then the
  same exit as finishing). Finishing or skipping sets `tutorial_done = true`.
- Continue-run keeps working as before. The tutorial is never saved mid-way: quitting during it means it starts
  again next time.

## Architecture: a prologue outside `Run`

`Run`, saves, depth curves and realm looping stay untouched. The tutorial is a sandbox played BEFORE the real
run's first doors, inside `GameRoot`, on the same persistent `BattleView`/road/hero:

- `GameRoot` (when `Launch.NEW_RUN` and not `tutorial_done`) creates the normal `_run` as usual, then instead of
  `_show_phase()` it calls `_start_tutorial()`. The road shows `SceneryCatalog.TUTORIAL` (slot 4).
- `TutorialDirector` (`game/tutorial/tutorial_director.gd`) runs a list of lessons in order with `await`.
- Lessons talk to the game ONLY through `TutorialHost` (`game/tutorial/tutorial_host.gd`, an API class);
  `GameRoot` supplies the implementation (`GameTutorialHost`). A lesson never touches `GameRoot`, `Run`, views.
- The tutorial may change souls, hp, items and run levels on the real objects; at its end
  `_end_tutorial()` resets them to a fresh run (souls = start souls, full hp, empty inventory, new run levels,
  hero rebuilt), `profile.tutorial_done = true`, `transition_road` to realm 1, then `_show_phase()`.
- Hand-built `RoomPlan`s (core allows it) feed `_start_fight`; GameRoot reads the plan through `_current_plan()`
  (tutorial plan or `_run.plan`). While the tutorial runs: `_save_run` does nothing, win goes to the director
  (not `_on_room_won`), the player cannot die (hp floor of 1: "Oops, try again!").
- Core gates that exist: `Duel.allowed_actions`, `Duel.hold_enemy`.

## Host API (what a lesson may call)

See `game/tutorial/tutorial_host.gd` (source of truth). Lessons use Duel signals + `TutorialWait.count` to detect
goals, `host.say/praise/point_at` for guidance, `host.win_fight()` to end a fight, then return.

## Lessons (one file each in `game/tutorial/lessons/`, class `Lesson<NN><Name>` extends `TutorialLesson`)

1. (removed: STRIKE duplicated STAMINA) The tutorial opens with STAMINA.
2. STAMINA: same dummy; hit until `REJECT_STAMINA` shows, say TUT_STAMINA, wait until stamina is full.
3. BLOCK: `tut_slime`, only block allowed, hp floor; 2 blocked strikes.
4. PARRY: `tut_slime`, block allowed; 2 parried strikes.
5. PUNISH: `tut_slime`; after a parry the enemy is staggered; 1 crit hit.
6. HEAL: hp set low, flask given, point at the flask slot; goal `item_used`.
7. SOULS + SHOP: dummy again; hits pay souls; point at the shop slot for a bomb, buy and throw it.
8. COMBO: dummy; `combo_changed` count >= 5.
9. TRICKS: `tut_knight`: heavy (parry it), feint (do not react), series.
10. FORK: two-trail fork, pick one. 11. REWARD: card picker with fixed cards. 12. ALTAR: buy a level.
13. FINALE: `tut_teddy`, no hints; win leads to the exit.

## Content

- Done: light road look, `tut_slime/knight/teddy`, `TUT_*` locale keys, `HintBubble`, `HighlightPulse`,
  `profile.tutorial_done`.
- Todo: `tut_scarecrow` (+ rigs later), settings buttons, lessons, host implementation in GameRoot, calm music,
  SVG rigs (rounded toy enemies, `art` skill).

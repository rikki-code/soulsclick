## Headless checks of the battle view pieces that need no autoload: rig specs, poses, placeholder fallback,
## glow styles and the run state in GameSession.
extends SceneTree

const POSE_WAIT_FRAMES := 60

var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures += 1
		print("BATTLE FAIL: ", label)

func _run() -> void:
	_check_session()
	_check_specs()
	await _check_rig()
	await _check_schemes()
	_check(GlowStyles.color_for(&"quick", Color.RED) == Color.RED, "quick glow uses the accent")
	_check(GlowStyles.color_for(&"heavy", Color.RED) != Color.RED, "heavy glow has its own colour")
	_check(GlowStyles.style_for(&"unknown_kind") == GlowStyles.DEFAULT_STYLE, "unknown kind uses the default style")
	print("BATTLE ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(1 if _failures > 0 else 0)

func _check_session() -> void:
	GameSession.reset_run()
	_check(GameSession.current_enemy_id() == &"grunt", "run starts at the grunt")
	_check(GameSession.has_next_enemy(), "grunt has a successor")
	GameSession.advance_run()
	GameSession.advance_run()
	_check(GameSession.current_enemy_id() == &"warden", "third enemy is the warden")
	_check(not GameSession.has_next_enemy(), "warden is last")
	_check(GameSession.can_revive(), "revive available at the start")
	GameSession.use_revive()
	_check(not GameSession.can_revive(), "revive is used once per run")
	GameSession.reset_run()
	_check(GameSession.can_revive() and GameSession.run_index == 0, "reset restores the run")
	for id in GameSession.ENEMY_ORDER:
		_check(GameSession.ENEMY_DIR != "" and load("%s%s.tres" % [GameSession.ENEMY_DIR, id]) is EnemyDefinition, "definition loads: %s" % id)

func _check_specs() -> void:
	for id in GameSession.ENEMY_ORDER:
		var spec := RigSpec.load_for(id, Color.WHITE)
		_check(not spec.is_placeholder and spec.parts.size() >= 9, "rig.json parsed: %s" % id)
		_check(spec.poses.has(&"idle") and spec.poses.has(&"windup_heavy") and spec.poses.has(&"death"), "poses present: %s" % id)
		_check(not spec.glow_parts.is_empty(), "glow parts: %s" % id)
	var missing := RigSpec.load_for(&"no_such_enemy", Color.GREEN)
	_check(missing.is_placeholder and missing.accent == Color.GREEN and not missing.parts.is_empty(), "missing rig falls back to a placeholder")
	_check(missing.pose_for(&"no_such_pose") == missing.pose_for(&"idle"), "missing pose falls back to idle")

func _check_rig() -> void:
	for id: StringName in [&"grunt", &"no_such_enemy"]:
		var rig := EnemyRig.new()
		root.add_child(rig)
		rig.setup(RigSpec.load_for(id, Color.WHITE))
		var part_id: StringName = &"arm_r"
		_check(rig.has_part(part_id), "rig has arm_r: %s" % id)
		var idle_rot: float = (rig.get_child(0).find_child(part_id, true, false) as Node2D).rotation_degrees
		var wind := rig.spec.pose_for(&"windup_quick")
		var expected: float = wind[part_id]["rot"] if wind.has(part_id) else 0.0
		var done := [false]
		rig.play_pose(&"windup_quick", 0.05)
		rig.pose_settled.connect(func(_serial: int) -> void: done[0] = true)
		for i in POSE_WAIT_FRAMES:
			if done[0]:
				break
			await process_frame
		var arm := rig.get_child(0).find_child(part_id, true, false) as Node2D
		_check(done[0] and is_equal_approx(arm.rotation_degrees, expected), "pose tween reaches target: %s" % id)
		_check(idle_rot != expected or id == &"no_such_enemy", "windup differs from idle: %s" % id)
		rig.play_pose(&"strike_quick", 1.0)
		rig.play_pose(&"idle", 0.05)
		for i in POSE_WAIT_FRAMES:
			await process_frame
		_check(is_equal_approx(arm.rotation_degrees, rig.spec.pose_for(&"idle").get(part_id, {"rot": 0.0})["rot"]), "newer pose replaces the older: %s" % id)
		rig.queue_free()

func _touch(index: int, at: Vector2, pressed := true) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = pressed
	return event

func _drag(index: int, at: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = at
	return event

func _click(at: Vector2, pressed := true, device := 0) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = at
	event.pressed = pressed
	event.device = device
	return event

func _scheme(id: StringName, view_size: Vector2) -> InputScheme:
	var scheme := InputSchemeCatalog.make(id)
	root.add_child(scheme)
	scheme.layout(view_size)
	return scheme

func _count(scheme: InputScheme) -> Dictionary:
	var counts := {"attack": 0, "block": 0}
	scheme.attack_requested.connect(func() -> void: counts["attack"] += 1)
	scheme.block_requested.connect(func() -> void: counts["block"] += 1)
	return counts

func _check_schemes() -> void:
	var view_size := Vector2(864, 1536)
	_check(InputSchemeCatalog.ids() == [&"hands", &"buttons", &"swipes"], "catalog lists the three schemes")
	_check(InputSchemeCatalog.resolve("nonsense") == InputSchemeCatalog.default_id(), "unknown scheme id falls back to the device default")
	_check(InputSchemeCatalog.resolve("swipes") == &"swipes", "known scheme id is kept")
	_check(ProfileData.from_dict(ProfileData.new().to_dict()).input_scheme == "", "profile keeps an empty scheme as auto")
	var profile := ProfileData.new()
	profile.input_scheme = "swipes"
	profile.mark_hinted("hands")
	var loaded := ProfileData.from_dict(profile.to_dict())
	_check(loaded.input_scheme == "swipes" and loaded.was_hinted("hands") and not loaded.was_hinted("swipes"), "profile saves scheme and hints")

	var hands := _scheme(&"hands", view_size)
	var hands_count := _count(hands)
	hands.handle_event(_touch(0, Vector2(100, 800)))
	hands.handle_event(_touch(1, Vector2(700, 800)))
	_check(hands_count["block"] == 1 and hands_count["attack"] == 1, "hands: left half blocks, right half attacks, two fingers both fire")
	hands.handle_event(_touch(0, Vector2(100, 800), false))
	hands.handle_event(_click(Vector2(700, 100)))
	hands.handle_event(_click(Vector2(700, 100), true, InputEvent.DEVICE_ID_EMULATION))
	_check(hands_count["attack"] == 2 and hands_count["block"] == 1, "hands: mouse click works, emulated mouse from touch is ignored")
	hands.set_input_enabled(false)
	hands.handle_event(_touch(2, Vector2(100, 800)))
	_check(hands_count["block"] == 1, "hands: disabled ignores input")
	_check(hands.reserved_height(view_size) > 0.0, "hands reserve a bottom strip")
	await process_frame
	hands.queue_free()

	var buttons := _scheme(&"buttons", view_size)
	var buttons_count := _count(buttons)
	var attack_at := Vector2(view_size.x * 0.75, view_size.y * 0.9)
	var block_at := Vector2(view_size.x * 0.25, view_size.y * 0.9)
	buttons.handle_event(_touch(0, attack_at))
	buttons.handle_event(_touch(1, block_at))
	buttons.handle_event(_touch(2, Vector2(view_size.x * 0.5, view_size.y * 0.4)))
	_check(buttons_count["attack"] == 1 and buttons_count["block"] == 1, "buttons: each button fires on touch-down, empty space does not, two fingers both fire")
	buttons.handle_event(_click(attack_at))
	_check(buttons_count["attack"] == 2, "buttons: mouse click works")
	await process_frame
	buttons.queue_free()

	var swipes := _scheme(&"swipes", view_size)
	var swipe_count := _count(swipes)
	var start := Vector2(400, 800)
	swipes.handle_event(_touch(0, start))
	swipes.handle_event(_drag(0, start + Vector2(0, -SwipeScheme.THRESHOLD * 0.5)))
	_check(swipe_count["attack"] == 0, "swipes: below the threshold nothing fires")
	swipes.handle_event(_drag(0, start + Vector2(0, -SwipeScheme.THRESHOLD - 1.0)))
	_check(swipe_count["attack"] == 1, "swipes: up past the threshold attacks before release")
	swipes.handle_event(_drag(0, start + Vector2(0, 200)))
	_check(swipe_count["block"] == 0 and swipe_count["attack"] == 1, "swipes: one action per touch")
	swipes.handle_event(_touch(0, start, false))
	swipes.handle_event(_touch(1, start))
	swipes.handle_event(_touch(2, start + Vector2(200, 0)))
	swipes.handle_event(_drag(1, start + Vector2(0, SwipeScheme.THRESHOLD + 1.0)))
	swipes.handle_event(_drag(2, start + Vector2(200, -SwipeScheme.THRESHOLD - 1.0)))
	_check(swipe_count["block"] == 1 and swipe_count["attack"] == 2, "swipes: down blocks, two fingers swipe independently")
	swipes.handle_event(_touch(3, start))
	swipes.handle_event(_drag(3, start + Vector2(SwipeScheme.THRESHOLD * 2.0, -SwipeScheme.THRESHOLD - 1.0)))
	_check(swipe_count["attack"] == 2, "swipes: mostly horizontal movement is ignored")
	swipes.handle_event(_click(start))
	var motion := InputEventMouseMotion.new()
	motion.position = start + Vector2(0, -SwipeScheme.THRESHOLD - 5.0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	swipes.handle_event(motion)
	_check(swipe_count["attack"] == 3, "swipes: mouse drag works")
	await process_frame
	swipes.queue_free()

	var hands_rig := PlayerRig.new()
	root.add_child(hands_rig)
	_check(hands_rig.spec.parts.size() >= 4 and hands_rig.spec.poses.has(&"block") and hands_rig.spec.poses.has(&"attack"), "player hands rig has parts and poses")
	hands_rig.layout(view_size)
	hands_rig.on_state(&"blocking")
	for i in POSE_WAIT_FRAMES:
		await process_frame
	var block_pose := hands_rig.spec.pose_for(&"block")
	var part_id: StringName = block_pose.keys()[0]
	var part := hands_rig.current_rig().get_child(0).find_child(String(part_id), true, false) as Node2D
	_check(part != null and is_equal_approx(part.rotation_degrees, block_pose[part_id]["rot"]), "hands block pose is reached")
	hands_rig.queue_free()

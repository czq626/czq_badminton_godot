extends SceneTree

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if packed == null:
		push_error("Could not load Main.tscn")
		quit(1)
		return

	var scene: Node = packed.instantiate()
	root.add_child(scene)
	scene._ready()
	for i in range(180):
		scene._physics_process(1.0 / 60.0)
		if scene.state == "serve" and i == 8:
			scene._hit_shuttle(scene.PLAYER_SIDE, "clear")

	scene.player_energy = scene.MAX_ENERGY
	scene._hit_shuttle(scene.PLAYER_SIDE, "skill")
	for i in range(18):
		scene._physics_process(1.0 / 60.0)
	if scene.player_energy != 0.0:
		push_error("Skill shot did not consume player energy")
		quit(1)
		return
	if not scene.shuttle_is_skill:
		push_error("Skill shot did not mark the shuttle as skill-powered")
		quit(1)
		return
	if scene.player_swing_timer <= 0.0:
		push_error("Skill shot did not trigger player swing state")
		quit(1)
		return
	scene.rng.seed = 12345
	var center_target: Vector2 = scene._pick_target(scene.PLAYER_SIDE, "clear", 1.0, Vector2.ZERO)
	scene.rng.seed = 12345
	var right_target: Vector2 = scene._pick_target(scene.PLAYER_SIDE, "clear", 1.0, Vector2.RIGHT)
	scene.rng.seed = 12345
	var left_target: Vector2 = scene._pick_target(scene.PLAYER_SIDE, "clear", 1.0, Vector2.LEFT)
	scene.rng.seed = 12345
	var down_target: Vector2 = scene._pick_target(scene.PLAYER_SIDE, "clear", 1.0, Vector2.DOWN)
	scene.rng.seed = 12345
	var up_target: Vector2 = scene._pick_target(scene.PLAYER_SIDE, "clear", 1.0, Vector2.UP)
	if right_target.x <= center_target.x or left_target.x >= center_target.x:
		push_error("Horizontal aim did not bias target X")
		quit(1)
		return
	if down_target.y <= center_target.y or up_target.y >= center_target.y:
		push_error("Vertical aim did not bias target Y")
		quit(1)
		return

	if scene.score_label == null or scene.player_stamina_bar == null:
		push_error("HUD was not initialized")
		quit(1)
		return

	print("Smoke test passed: state=%s score=%d:%d stamina=%.1f/%.1f" % [
		scene.state,
		scene.player_score,
		scene.ai_score,
		scene.player_stamina,
		scene.ai_stamina,
	])
	quit()

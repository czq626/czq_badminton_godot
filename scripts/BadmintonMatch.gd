extends Node2D

const COURT := Rect2(140.0, 300.0, 1000.0, 230.0)
const NET_X := COURT.position.x + COURT.size.x * 0.5
const STAGE_Y := 548.0
const COURT_TOP_Y := 310.0
const COURT_BOTTOM_Y := 535.0
const LEFT_MIN_X := 250.0
const LEFT_MAX_X := NET_X - 62.0
const RIGHT_MIN_X := NET_X + 62.0
const RIGHT_MAX_X := 1030.0
const PLAYER_SIDE := -1
const AI_SIDE := 1
const GRAVITY := 920.0
const HIT_RADIUS := 86.0
const WIN_SCORE := 7
const FEEDBACK_TIME := 0.72
const MAX_ENERGY := 100.0
const SWING_TIME := 0.24
const RECOVERY_TIME := 0.12
const AIM_X_BIAS := 210.0
const AIM_Y_BIAS := 72.0
const USE_RIG_CHARACTERS := true
const FOOT_Y_OFFSET := 30.0
const HIT_FRAME_PROGRESS := 0.48

var rng := RandomNumberGenerator.new()

var player_pos := Vector2(360.0, 380.0)
var ai_pos := Vector2(920.0, 380.0)
var player_velocity := Vector2.ZERO
var ai_velocity := Vector2.ZERO
var player_stamina := 100.0
var ai_stamina := 100.0
var player_energy := 0.0
var ai_energy := 0.0
var player_recovery := 0.0
var ai_recovery := 0.0
var player_swing_timer := 0.0
var ai_swing_timer := 0.0
var player_swing_type := ""
var ai_swing_type := ""
var player_pending_shot := ""
var ai_pending_shot := ""
var player_last_pos := Vector2.ZERO
var ai_last_pos := Vector2.ZERO
var player_aim := Vector2.ZERO
var last_player_target := Vector2.ZERO
var player_lane_bias := 0.0
var ai_lane_bias := 0.0
var player_run_phase := 0.0
var ai_run_phase := 0.0

var player_score := 0
var ai_score := 0
var server := PLAYER_SIDE
var last_hitter := PLAYER_SIDE
var state := "serve"
var state_timer := 0.0
var message := ""

var shuttle_pos := Vector2.ZERO
var shuttle_vel := Vector2.ZERO
var shuttle_z := 0.0
var shuttle_vz := 0.0
var shuttle_spin := 0.0
var shuttle_trail: Array[Vector2] = []
var landing_marker := Vector2.ZERO
var shuttle_power_color := Color(0.74, 1.0, 0.42)
var shuttle_is_skill := false

var ai_reaction_timer := 0.0
var ai_next_shot := "clear"
var shake := 0.0
var rally_count := 0
var last_player_quality := 0.0
var feedback_text := ""
var feedback_timer := 0.0
var feedback_pos := Vector2.ZERO
var feedback_color := Color.WHITE
var arena_background: Texture2D
var player_texture: Texture2D
var rival_texture: Texture2D
var move_icon: Texture2D
var clear_icon: Texture2D
var drop_icon: Texture2D
var smash_icon: Texture2D
var skill_icon: Texture2D
var court_fx: Array[Dictionary] = []

var score_label: Label
var message_label: Label
var player_stamina_bar: ProgressBar
var ai_stamina_bar: ProgressBar

func _ready() -> void:
	rng.randomize()
	_load_optional_assets()
	_build_hud()
	reset_match()


func _load_optional_assets() -> void:
	arena_background = _first_texture([
		"res://assets/generated/images/match-stage-sideview.png",
		"res://assets/generated/images/match-stage-sideview-2.png",
		"res://assets/generated/images/match-stage-sideview-3.png",
		"res://assets/generated/images/match-stage-sideview-4.png",
		"res://assets/generated/images/badminton-arena-bg-3.png",
		"res://assets/generated/images/badminton-arena-bg.png",
		"res://assets/generated/images/badminton-arena-bg.jpg",
	])
	player_texture = _first_texture([
		"res://assets/generated/images/player-athlete-yellow-blue-cutout.png",
		"res://assets/generated/images/player-athlete-yellow-blue.png",
	])
	rival_texture = _first_texture([
		"res://assets/generated/images/rival-demon-red-black-cutout.png",
		"res://assets/generated/images/rival-demon-red-black.png",
	])
	move_icon = _load_texture_file("res://assets/generated/images/ui-move-shoe.png")
	clear_icon = _load_texture_file("res://assets/generated/images/ui-shot-clear.png")
	drop_icon = _load_texture_file("res://assets/generated/images/ui-shot-drop.png")
	smash_icon = _load_texture_file("res://assets/generated/images/ui-shot-smash.png")
	skill_icon = _load_texture_file("res://assets/generated/images/ui-shot-skill.png")


func _first_texture(paths: Array[String]) -> Texture2D:
	for path in paths:
		var texture := _load_texture_file(path)
		if texture != null:
			return texture
	return null


func _load_texture_file(path: String) -> Texture2D:
	var texture: Texture2D
	if ResourceLoader.exists(path):
		texture = load(path)
		if texture != null:
			return texture
	if FileAccess.file_exists(path):
		var image := Image.load_from_file(path)
		if image != null and not image.is_empty():
			return ImageTexture.create_from_image(image)
	return null


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	score_label = Label.new()
	score_label.position = Vector2(536, 20)
	score_label.size = Vector2(208, 52)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 42)
	score_label.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	layer.add_child(score_label)

	message_label = Label.new()
	message_label.position = Vector2(390, 78)
	message_label.size = Vector2(500, 34)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 20)
	message_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.78))
	layer.add_child(message_label)

	player_stamina_bar = ProgressBar.new()
	player_stamina_bar.position = Vector2(170, 36)
	player_stamina_bar.size = Vector2(280, 16)
	player_stamina_bar.max_value = 100
	player_stamina_bar.show_percentage = false
	layer.add_child(player_stamina_bar)

	ai_stamina_bar = ProgressBar.new()
	ai_stamina_bar.position = Vector2(830, 36)
	ai_stamina_bar.size = Vector2(280, 16)
	ai_stamina_bar.max_value = 100
	ai_stamina_bar.show_percentage = false
	layer.add_child(ai_stamina_bar)


func reset_match() -> void:
	player_score = 0
	ai_score = 0
	server = PLAYER_SIDE
	player_stamina = 100.0
	ai_stamina = 100.0
	player_energy = 35.0
	ai_energy = 35.0
	_start_serve("First to %d" % WIN_SCORE)


func _start_serve(new_message: String = "") -> void:
	state = "serve"
	state_timer = 0.0
	message = new_message
	player_pos = Vector2(380.0, STAGE_Y)
	ai_pos = Vector2(900.0, STAGE_Y)
	player_lane_bias = 0.0
	ai_lane_bias = 0.0
	player_pending_shot = ""
	ai_pending_shot = ""
	player_swing_timer = 0.0
	ai_swing_timer = 0.0
	player_swing_type = ""
	ai_swing_type = ""
	shuttle_vel = Vector2.ZERO
	shuttle_vz = 0.0
	shuttle_z = 52.0
	shuttle_is_skill = false
	shuttle_power_color = Color(0.74, 1.0, 0.42)
	shuttle_trail.clear()
	ai_reaction_timer = 0.45
	_attach_shuttle_to_server()


func _attach_shuttle_to_server() -> void:
	if server == PLAYER_SIDE:
		shuttle_pos = player_pos + Vector2(42, -42)
	else:
		shuttle_pos = ai_pos + Vector2(-42, -42)
	landing_marker = shuttle_pos


func _physics_process(delta: float) -> void:
	state_timer += delta
	shake = maxf(0.0, shake - delta * 7.0)
	feedback_timer = maxf(0.0, feedback_timer - delta)
	player_recovery = maxf(0.0, player_recovery - delta)
	ai_recovery = maxf(0.0, ai_recovery - delta)
	var previous_player_swing := player_swing_timer
	var previous_ai_swing := ai_swing_timer
	player_swing_timer = maxf(0.0, player_swing_timer - delta)
	ai_swing_timer = maxf(0.0, ai_swing_timer - delta)
	_process_pending_shots(previous_player_swing, previous_ai_swing)
	_update_player(delta)
	_update_ai(delta)
	_update_court_fx(delta)
	_recover_stamina(delta)

	if state == "serve":
		_attach_shuttle_to_server()
		if server == PLAYER_SIDE:
			message = "SPACE serve  |  J clear  K drop  L smash  I skill"
			if Input.is_action_just_pressed("serve") or Input.is_action_just_pressed("shot_clear"):
				_start_swing(PLAYER_SIDE, "clear")
			elif Input.is_action_just_pressed("shot_drop"):
				_start_swing(PLAYER_SIDE, "drop")
			elif Input.is_action_just_pressed("shot_skill") and player_energy >= MAX_ENERGY:
				_start_swing(PLAYER_SIDE, "skill")
			elif Input.is_action_just_pressed("shot_smash"):
				_start_swing(PLAYER_SIDE, "smash")
		elif state_timer > 0.7:
			message = "Opponent serves"
			_start_swing(AI_SIDE, "clear")
	elif state == "rally":
		_update_shuttle(delta)
		_try_player_hit()
		_try_ai_hit(delta)
	elif state == "point":
		if state_timer > 1.15:
			if player_score >= WIN_SCORE or ai_score >= WIN_SCORE:
				reset_match()
			else:
				_start_serve(message)

	_update_hud()
	queue_redraw()


func _update_player(delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if input_vector.length_squared() > 1.0:
		input_vector = input_vector.normalized()
	player_aim = input_vector

	var speed := lerpf(285.0, 205.0, 1.0 - player_stamina / 100.0)
	if player_recovery > 0.0:
		speed *= 0.45
	player_last_pos = player_pos
	var movement := Vector2(input_vector.x, 0.0)
	player_velocity = player_velocity.move_toward(movement * speed, 1550.0 * delta)
	player_pos += player_velocity * delta
	player_pos.x = clampf(player_pos.x, LEFT_MIN_X, LEFT_MAX_X)
	player_pos.y = STAGE_Y
	player_lane_bias = move_toward(player_lane_bias, input_vector.y, 6.0 * delta)
	player_run_phase = _advance_run_phase(player_run_phase, player_velocity.length(), delta)
	_maybe_spawn_step_fx(player_pos, player_velocity, delta, Color(0.35, 0.65, 1.0))


func _update_ai(delta: float) -> void:
	var defend_pos := Vector2(905.0, STAGE_Y)
	var target := defend_pos
	if state == "rally" and shuttle_pos.x > NET_X - 120.0:
		target = Vector2(clampf(shuttle_pos.x, RIGHT_MIN_X, RIGHT_MAX_X), STAGE_Y)
	elif state == "serve" and server == AI_SIDE:
		target = Vector2(900.0, STAGE_Y)

	var to_target := target - ai_pos
	var desired := Vector2.ZERO
	if to_target.length() > 8.0:
		desired = to_target.normalized() * lerpf(255.0, 190.0, 1.0 - ai_stamina / 100.0)
	if ai_recovery > 0.0:
		desired *= 0.48
	ai_last_pos = ai_pos
	ai_velocity = ai_velocity.move_toward(desired, 1320.0 * delta)
	ai_pos += ai_velocity * delta
	ai_pos.x = clampf(ai_pos.x, RIGHT_MIN_X, RIGHT_MAX_X)
	ai_pos.y = STAGE_Y
	ai_lane_bias = move_toward(ai_lane_bias, 0.0, 4.0 * delta)
	ai_run_phase = _advance_run_phase(ai_run_phase, ai_velocity.length(), delta)
	_maybe_spawn_step_fx(ai_pos, ai_velocity, delta, Color(1.0, 0.38, 0.34))


func _update_court_fx(delta: float) -> void:
	for i in range(court_fx.size() - 1, -1, -1):
		court_fx[i]["age"] += delta
		if court_fx[i]["age"] >= court_fx[i]["life"]:
			court_fx.remove_at(i)


func _maybe_spawn_step_fx(pos: Vector2, velocity: Vector2, delta: float, color: Color) -> void:
	if velocity.length() < 180.0 or state == "point":
		return
	if rng.randf() > delta * 8.0:
		return
	court_fx.push_back({
		"type": "step",
		"pos": pos + Vector2(rng.randf_range(-18.0, 18.0), 34.0),
		"age": 0.0,
		"life": 0.34,
		"color": color,
	})


func _recover_stamina(delta: float) -> void:
	var player_rest := 1.0 - clampf(player_velocity.length() / 285.0, 0.0, 1.0)
	var ai_rest := 1.0 - clampf(ai_velocity.length() / 255.0, 0.0, 1.0)
	player_stamina = clampf(player_stamina + (7.5 + player_rest * 13.0) * delta, 0.0, 100.0)
	ai_stamina = clampf(ai_stamina + (7.5 + ai_rest * 12.0) * delta, 0.0, 100.0)


func _advance_run_phase(phase: float, speed: float, delta: float) -> float:
	var speed_t := clampf(speed / 280.0, 0.0, 1.0)
	if speed_t < 0.08:
		return lerp_angle(phase, 0.0, minf(1.0, delta * 8.0))
	return wrapf(phase + delta * lerpf(7.2, 12.0, speed_t), -PI, PI)


func _update_shuttle(delta: float) -> void:
	shuttle_pos += shuttle_vel * delta
	shuttle_z += shuttle_vz * delta
	shuttle_vz -= GRAVITY * delta
	shuttle_spin += delta * (9.0 + shuttle_vel.length() * 0.018)
	shuttle_trail.push_front(shuttle_pos - Vector2(0, shuttle_z))
	if shuttle_trail.size() > 12:
		shuttle_trail.pop_back()

	if shuttle_z <= 0.0:
		_finish_landing()


func _finish_landing() -> void:
	shuttle_z = 0.0
	var in_court := shuttle_pos.x >= LEFT_MIN_X and shuttle_pos.x <= RIGHT_MAX_X
	if in_court:
		if shuttle_pos.x < NET_X:
			_score_point(AI_SIDE, "Opponent lands it")
		else:
			_score_point(PLAYER_SIDE, "Point won")
	else:
		_score_point(-last_hitter, "Out")


func _score_point(winner: int, reason: String) -> void:
	state = "point"
	state_timer = 0.0
	server = winner
	rally_count = 0
	player_pending_shot = ""
	ai_pending_shot = ""
	if winner == PLAYER_SIDE:
		player_score += 1
		message = "%s  +1" % reason
		_show_feedback("POINT", Vector2(458, 128), Color(0.8, 1.0, 0.35))
	else:
		ai_score += 1
		message = "%s  +1" % reason
		_show_feedback("LOST", Vector2(822, 128), Color(1.0, 0.42, 0.36))
	if player_score >= WIN_SCORE:
		message = "You win the match"
	elif ai_score >= WIN_SCORE:
		message = "Opponent wins the match"


func _try_player_hit() -> void:
	if shuttle_pos.x > NET_X + 20.0:
		return
	if not _can_hit(player_pos):
		return

	if Input.is_action_just_pressed("shot_skill") and player_energy >= MAX_ENERGY:
		_start_swing(PLAYER_SIDE, "skill")
	elif Input.is_action_just_pressed("shot_smash"):
		_start_swing(PLAYER_SIDE, "smash")
	elif Input.is_action_just_pressed("shot_drop"):
		_start_swing(PLAYER_SIDE, "drop")
	elif Input.is_action_just_pressed("shot_clear"):
		_start_swing(PLAYER_SIDE, "clear")


func _try_ai_hit(delta: float) -> void:
	if shuttle_pos.x < NET_X - 20.0:
		return
	if not _can_hit(ai_pos):
		return

	ai_reaction_timer -= delta
	if ai_reaction_timer > 0.0:
		return

	var choice_roll := rng.randf()
	if ai_energy >= MAX_ENERGY and choice_roll < 0.22:
		ai_next_shot = "skill"
	elif player_pos.x < LEFT_MIN_X + (LEFT_MAX_X - LEFT_MIN_X) * 0.36:
		ai_next_shot = "clear" if choice_roll < 0.72 else "drop"
	elif player_stamina < 35.0:
		ai_next_shot = "drop" if choice_roll < 0.45 else "smash"
	else:
		ai_next_shot = "smash" if choice_roll < 0.24 else ("drop" if choice_roll < 0.52 else "clear")
	_start_swing(AI_SIDE, ai_next_shot)


func _can_hit(character_pos: Vector2) -> bool:
	var visual_shuttle := shuttle_pos - Vector2(0.0, shuttle_z * 0.38)
	return absf(character_pos.x - visual_shuttle.x) <= HIT_RADIUS and shuttle_z >= 14.0 and shuttle_z <= 165.0


func _start_swing(side: int, shot_type: String) -> void:
	if side == PLAYER_SIDE:
		if not player_pending_shot.is_empty() or player_swing_timer > 0.0:
			return
		player_pending_shot = shot_type
		player_swing_type = shot_type
		player_swing_timer = _swing_duration(shot_type)
		player_recovery = maxf(player_recovery, RECOVERY_TIME * 0.75)
	else:
		if not ai_pending_shot.is_empty() or ai_swing_timer > 0.0:
			return
		ai_pending_shot = shot_type
		ai_swing_type = shot_type
		ai_swing_timer = _swing_duration(shot_type)
		ai_recovery = maxf(ai_recovery, RECOVERY_TIME * 0.75)


func _swing_duration(shot_type: String) -> float:
	if shot_type == "skill":
		return SWING_TIME * 1.35
	if shot_type == "smash":
		return SWING_TIME * 1.18
	if shot_type == "drop":
		return SWING_TIME * 0.92
	return SWING_TIME


func _process_pending_shots(previous_player_swing: float, previous_ai_swing: float) -> void:
	if not player_pending_shot.is_empty():
		var duration := _swing_duration(player_pending_shot)
		var previous_progress := 1.0 - clampf(previous_player_swing / duration, 0.0, 1.0)
		var progress := 1.0 - clampf(player_swing_timer / duration, 0.0, 1.0)
		if previous_progress < HIT_FRAME_PROGRESS and progress >= HIT_FRAME_PROGRESS:
			var shot := player_pending_shot
			player_pending_shot = ""
			if state == "serve" or _can_hit(player_pos):
				_hit_shuttle(PLAYER_SIDE, shot, false)
			else:
				player_recovery = RECOVERY_TIME
				_show_feedback("MISS", player_pos + Vector2(0, -78), Color(1.0, 0.42, 0.33))
	if not ai_pending_shot.is_empty():
		var duration := _swing_duration(ai_pending_shot)
		var previous_progress := 1.0 - clampf(previous_ai_swing / duration, 0.0, 1.0)
		var progress := 1.0 - clampf(ai_swing_timer / duration, 0.0, 1.0)
		if previous_progress < HIT_FRAME_PROGRESS and progress >= HIT_FRAME_PROGRESS:
			var shot := ai_pending_shot
			ai_pending_shot = ""
			if state == "serve" or _can_hit(ai_pos):
				_hit_shuttle(AI_SIDE, shot, false)
			else:
				ai_recovery = RECOVERY_TIME


func _hit_shuttle(side: int, shot_type: String, start_animation: bool = true) -> void:
	if start_animation:
		_start_swing(side, shot_type)
		return
	state = "rally"
	state_timer = 0.0
	last_hitter = side
	ai_reaction_timer = rng.randf_range(0.10, 0.28)
	var quality := _hit_quality(side)
	if side == PLAYER_SIDE:
		last_player_quality = quality
	var from_pos := player_pos if side == PLAYER_SIDE else ai_pos
	shuttle_pos = from_pos + Vector2(34.0 * -side, -28.0)
	shuttle_z = 76.0

	var target := _pick_target(side, shot_type, quality, player_aim if side == PLAYER_SIDE else Vector2.ZERO)
	if side == PLAYER_SIDE:
		last_player_target = target
	var distance := shuttle_pos.distance_to(target)
	var duration := clampf(distance / _shot_speed(side, shot_type, quality), 0.36, 1.18)
	if shot_type == "drop":
		duration = clampf(duration * 0.92, 0.42, 0.92)
	elif shot_type == "smash":
		duration = clampf(duration * 0.62, 0.30, 0.58)
	elif shot_type == "skill":
		duration = clampf(duration * 0.50, 0.26, 0.48)

	landing_marker = target
	shuttle_vel = (target - shuttle_pos) / duration
	shuttle_vz = (0.0 - shuttle_z + 0.5 * GRAVITY * duration * duration) / duration
	shuttle_is_skill = shot_type == "skill"
	if shot_type == "skill":
		shuttle_vz -= 160.0 * quality
		shake = 1.6 * quality
		shuttle_power_color = Color(0.38, 1.0, 0.88)
	elif shot_type == "smash":
		shuttle_vz -= 105.0 * quality
		shake = 1.0 * quality
		shuttle_power_color = Color(0.76, 1.0, 0.30)
	elif shot_type == "drop":
		shuttle_vz += 55.0
		shuttle_power_color = Color(1.0, 0.83, 0.32)
	else:
		shuttle_power_color = Color(0.74, 1.0, 0.42)

	var cost := 9.0
	if shot_type == "drop":
		cost = 12.0
	elif shot_type == "smash":
		cost = 24.0
	elif shot_type == "skill":
		cost = 18.0
	if side == PLAYER_SIDE:
		player_stamina = maxf(0.0, player_stamina - cost)
		player_recovery = RECOVERY_TIME if shot_type != "skill" else RECOVERY_TIME * 1.55
		player_swing_type = shot_type
		if shot_type == "skill":
			player_energy = 0.0
		else:
			player_energy = clampf(player_energy + 13.0 + quality * 12.0, 0.0, MAX_ENERGY)
	else:
		ai_stamina = maxf(0.0, ai_stamina - cost * 0.85)
		ai_recovery = RECOVERY_TIME if shot_type != "skill" else RECOVERY_TIME * 1.55
		ai_swing_type = shot_type
		if shot_type == "skill":
			ai_energy = 0.0
		else:
			ai_energy = clampf(ai_energy + 10.0 + quality * 10.0, 0.0, MAX_ENERGY)

	rally_count += 1
	var quality_label := _quality_label(quality)
	if shot_type == "skill":
		message = "SPECIAL SMASH"
		_show_feedback(message, from_pos + Vector2(0, -84), Color(0.36, 1.0, 0.9))
	else:
		message = "%s %s" % [quality_label, shot_type.capitalize()]
		_show_feedback(message, from_pos + Vector2(0, -76), _quality_color(quality))
	_spawn_hit_fx(from_pos + Vector2(58.0 * -side, -48.0), shot_type, shuttle_power_color)
	shuttle_trail.clear()


func _spawn_hit_fx(pos: Vector2, shot_type: String, color: Color) -> void:
	court_fx.push_back({
		"type": "hit",
		"pos": pos,
		"age": 0.0,
		"life": 0.26 if shot_type != "skill" else 0.42,
		"color": color,
		"skill": shot_type == "skill",
	})


func _hit_quality(side: int) -> float:
	if state == "serve":
		return 1.0
	var character_pos := player_pos if side == PLAYER_SIDE else ai_pos
	var visual_shuttle := shuttle_pos - Vector2(0.0, shuttle_z * 0.38)
	var distance := character_pos.distance_to(visual_shuttle)
	var quality := 1.0 - clampf(distance / HIT_RADIUS, 0.0, 1.0)
	return clampf(0.36 + quality * 0.82, 0.36, 1.18)


func _quality_label(quality: float) -> String:
	if quality >= 1.04:
		return "Perfect"
	if quality >= 0.78:
		return "Good"
	if quality >= 0.55:
		return "Reach"
	return "Weak"


func _quality_color(quality: float) -> Color:
	if quality >= 1.04:
		return Color(0.74, 1.0, 0.36)
	if quality >= 0.78:
		return Color(0.46, 0.9, 1.0)
	if quality >= 0.55:
		return Color(1.0, 0.86, 0.38)
	return Color(1.0, 0.42, 0.33)


func _show_feedback(text: String, pos: Vector2, color: Color) -> void:
	feedback_text = text
	feedback_pos = pos
	feedback_color = color
	feedback_timer = FEEDBACK_TIME


func _pick_target(side: int, shot_type: String, quality: float, aim: Vector2 = Vector2.ZERO) -> Vector2:
	var target_x := 0.0
	var lane_y := STAGE_Y
	if side == PLAYER_SIDE:
		if shot_type == "drop":
			target_x = rng.randf_range(RIGHT_MIN_X + 5.0, RIGHT_MIN_X + 140.0)
		elif shot_type == "smash" or shot_type == "skill":
			target_x = rng.randf_range(RIGHT_MIN_X + 120.0, RIGHT_MAX_X - 35.0)
		else:
			target_x = rng.randf_range(RIGHT_MIN_X + 170.0, RIGHT_MAX_X - 20.0)
		if aim.length_squared() > 0.01:
			target_x += aim.x * AIM_X_BIAS
			lane_y += aim.y * 28.0
	else:
		if shot_type == "drop":
			target_x = rng.randf_range(LEFT_MAX_X - 140.0, LEFT_MAX_X - 5.0)
		elif shot_type == "smash" or shot_type == "skill":
			target_x = rng.randf_range(LEFT_MIN_X + 35.0, LEFT_MAX_X - 120.0)
		else:
			target_x = rng.randf_range(LEFT_MIN_X + 20.0, LEFT_MAX_X - 170.0)
		lane_y += rng.randf_range(-22.0, 22.0)

	var stamina := player_stamina if side == PLAYER_SIDE else ai_stamina
	var error := lerpf(58.0, 9.0, stamina / 100.0) * lerpf(1.55, 0.7, clampf(quality, 0.0, 1.0))
	if shot_type == "smash":
		error *= 1.35
	elif shot_type == "skill":
		error *= 0.55
	target_x += rng.randf_range(-error, error)
	var side_min_x := LEFT_MIN_X
	var side_max_x := LEFT_MAX_X
	if side == PLAYER_SIDE:
		side_min_x = RIGHT_MIN_X
		side_max_x = RIGHT_MAX_X
	return Vector2(clampf(target_x, side_min_x, side_max_x), clampf(lane_y, STAGE_Y - 34.0, STAGE_Y + 34.0))


func _shot_speed(side: int, shot_type: String, quality: float) -> float:
	var stamina := player_stamina if side == PLAYER_SIDE else ai_stamina
	var base := 760.0
	if shot_type == "drop":
		base = 620.0
	elif shot_type == "smash":
		base = 1250.0
	elif shot_type == "skill":
		base = 1520.0
	return base * lerpf(0.82, 1.08, stamina / 100.0) * lerpf(0.82, 1.13, clampf(quality, 0.0, 1.0))


func _update_hud() -> void:
	score_label.text = "%d : %d" % [player_score, ai_score]
	message_label.text = message
	player_stamina_bar.value = player_stamina
	ai_stamina_bar.value = ai_stamina


func _draw() -> void:
	var offset := Vector2.ZERO
	if shake > 0.0:
		offset = Vector2(rng.randf_range(-3.0, 3.0), rng.randf_range(-2.0, 2.0)) * shake
	draw_set_transform(offset)
	_draw_arena()
	_draw_court_fx(false)
	_draw_aim_preview()
	_draw_landing_marker()
	_draw_hit_window()
	_draw_motion_ghost(player_last_pos, player_pos, Color(0.22, 0.48, 1.0), PLAYER_SIDE, player_velocity.length(), player_swing_timer)
	_draw_motion_ghost(ai_last_pos, ai_pos, Color(1.0, 0.25, 0.21), AI_SIDE, ai_velocity.length(), ai_swing_timer)
	_draw_player(player_pos, Color(0.22, 0.48, 1.0), PLAYER_SIDE, player_velocity.length(), player_swing_timer, player_swing_type)
	_draw_player(ai_pos, Color(1.0, 0.25, 0.21), AI_SIDE, ai_velocity.length(), ai_swing_timer, ai_swing_type)
	_draw_shuttle()
	_draw_court_fx(true)
	_draw_feedback()
	draw_set_transform(Vector2.ZERO)
	_draw_match_overlay()


func _draw_arena() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.045, 0.054, 0.07))
	if arena_background != null:
		draw_texture_rect(arena_background, Rect2(Vector2.ZERO, Vector2(1280, 720)), false, Color(1, 1, 1, 0.92))
		draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.01, 0.014, 0.025, 0.14))
		draw_rect(Rect2(0, 0, 1280, 118), Color(0.025, 0.03, 0.05, 0.74))
	else:
		draw_rect(Rect2(0, 0, 1280, 118), Color(0.035, 0.04, 0.06, 0.92))
		draw_rect(Rect2(0, 570, 1280, 150), Color(0.15, 0.12, 0.14, 0.84))
	for i in range(6):
		var x := 90.0 + float(i) * 215.0
		draw_line(Vector2(x, 118), Vector2(x + 62, 588), Color(0.18, 0.27, 0.33, 0.10), 4.0)
	for i in range(10):
		var x := 48.0 + float(i) * 132.0
		draw_rect(Rect2(x, 70, 54, 18), Color(0.18, 0.55, 0.65, 0.09))

	var back_left := Vector2(166, COURT_TOP_Y)
	var back_right := Vector2(1114, COURT_TOP_Y)
	var front_left := Vector2(122, COURT_BOTTOM_Y)
	var front_right := Vector2(1158, COURT_BOTTOM_Y)
	var court_poly := PackedVector2Array([back_left, back_right, front_right, front_left])
	if arena_background == null:
		draw_colored_polygon(court_poly, Color(0.06, 0.42, 0.29, 0.96))
		draw_colored_polygon(PackedVector2Array([back_left, back_right, Vector2(front_right.x, STAGE_Y), Vector2(front_left.x, STAGE_Y)]), Color(0.13, 0.72, 0.48, 0.32))

	var line_alpha := 0.22 if arena_background != null else 1.0
	var line_color := Color(0.90, 1.0, 0.94, line_alpha)
	if arena_background == null:
		_draw_polyline([back_left, back_right, front_right, front_left, back_left], line_color, 2.6)
	else:
		draw_line(front_left, front_right, Color(0.90, 1.0, 0.94, 0.16), 1.2)
	for x in [LEFT_MIN_X, LEFT_MAX_X, NET_X, RIGHT_MIN_X, RIGHT_MAX_X]:
		var top_x := lerpf(back_left.x, back_right.x, inverse_lerp(front_left.x, front_right.x, x))
		draw_line(Vector2(top_x, COURT_TOP_Y), Vector2(x, COURT_BOTTOM_Y), line_color, 1.0)
	if arena_background == null:
		for t in [0.34, 0.62, 0.82]:
			var left := back_left.lerp(front_left, t)
			var right := back_right.lerp(front_right, t)
			draw_line(left, right, line_color, 1.4)

	var play_line_alpha := 0.24 if arena_background != null else 0.46
	draw_line(Vector2(LEFT_MIN_X, STAGE_Y), Vector2(LEFT_MAX_X, STAGE_Y), Color(0.52, 0.92, 1.0, play_line_alpha), 4.0)
	draw_line(Vector2(RIGHT_MIN_X, STAGE_Y), Vector2(RIGHT_MAX_X, STAGE_Y), Color(0.52, 0.92, 1.0, play_line_alpha), 4.0)
	draw_line(Vector2(LEFT_MIN_X, STAGE_Y), Vector2(LEFT_MAX_X, STAGE_Y), Color(0.01, 0.04, 0.06, 0.35), 1.0)
	draw_line(Vector2(RIGHT_MIN_X, STAGE_Y), Vector2(RIGHT_MAX_X, STAGE_Y), Color(0.01, 0.04, 0.06, 0.35), 1.0)
	draw_line(Vector2(NET_X, COURT_TOP_Y - 8), Vector2(NET_X, COURT_BOTTOM_Y + 10), Color(0.72, 0.96, 1.0, 0.68), 3.0)
	draw_line(Vector2(NET_X - 8, COURT_TOP_Y), Vector2(NET_X - 8, COURT_BOTTOM_Y), Color(0.0, 0.0, 0.0, 0.28), 2.0)
	_draw_ellipse(Vector2(NET_X, COURT_BOTTOM_Y + 15), Vector2(26, 8), Color(0.0, 0.0, 0.0, 0.3))
	draw_rect(Rect2(NET_X - 18, COURT_BOTTOM_Y - 2, 36, 28), Color(0.06, 0.15, 0.21, 0.86))

	if arena_background == null:
		_draw_crowd_band(Rect2(0, 118, 1280, 54), Color(0.09, 0.14, 0.18, 0.72))


func _draw_line_rect(rect: Rect2, color: Color, width: float) -> void:
	draw_line(rect.position, Vector2(rect.end.x, rect.position.y), color, width)
	draw_line(Vector2(rect.end.x, rect.position.y), rect.end, color, width)
	draw_line(rect.end, Vector2(rect.position.x, rect.end.y), color, width)
	draw_line(Vector2(rect.position.x, rect.end.y), rect.position, color, width)


func _draw_polyline(points: Array, color: Color, width: float) -> void:
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], color, width)


func _draw_landing_marker() -> void:
	if state != "rally":
		return
	var marker_color := Color(0.7, 1.0, 0.45, 0.55)
	draw_arc(landing_marker, 18.0, 0.0, TAU, 36, marker_color, 2.0)
	draw_arc(landing_marker, 31.0, 0.0, TAU, 36, Color(marker_color.r, marker_color.g, marker_color.b, 0.18), 4.0)
	draw_line(landing_marker + Vector2(-14, 0), landing_marker + Vector2(14, 0), marker_color, 2.0)
	draw_line(landing_marker + Vector2(0, -14), landing_marker + Vector2(0, 14), marker_color, 2.0)


func _draw_aim_preview() -> void:
	if state == "point":
		return
	var aim_target := _preview_player_target()
	var color := Color(0.46, 0.9, 1.0, 0.36)
	if player_aim.length_squared() > 0.01:
		color = Color(0.55, 1.0, 0.75, 0.54)
	draw_arc(aim_target, 26.0, 0.0, TAU, 36, color, 2.0)
	draw_arc(aim_target, 42.0, 0.0, TAU, 36, Color(color.r, color.g, color.b, color.a * 0.32), 3.0)
	draw_line(aim_target + Vector2(-18, 0), aim_target + Vector2(18, 0), color, 1.5)
	draw_line(aim_target + Vector2(0, -18), aim_target + Vector2(0, 18), color, 1.5)
	if state == "rally" and shuttle_pos.x < NET_X + 32.0:
		var visual_shuttle := shuttle_pos - Vector2(0.0, shuttle_z * 0.38)
		draw_line(visual_shuttle, aim_target, Color(color.r, color.g, color.b, 0.18), 2.0)


func _preview_player_target() -> Vector2:
	var base_x := NET_X + COURT.size.x * 0.34
	var base_y := STAGE_Y
	if state == "rally" and last_hitter == AI_SIDE:
		base_x = NET_X + COURT.size.x * 0.32
	elif last_player_target != Vector2.ZERO:
		base_x = last_player_target.x
		base_y = last_player_target.y
	var preview := Vector2(base_x + player_aim.x * AIM_X_BIAS, base_y + player_aim.y * AIM_Y_BIAS)
	return Vector2(
		clampf(preview.x, RIGHT_MIN_X, RIGHT_MAX_X),
		clampf(preview.y, STAGE_Y - 34.0, STAGE_Y + 34.0)
	)


func _draw_motion_ghost(from_pos: Vector2, pos: Vector2, color: Color, side: int, speed: float, swing_timer: float) -> void:
	if speed < 120.0 and swing_timer <= 0.0:
		return
	var ghost_pos := from_pos.lerp(pos, 0.28)
	var alpha := clampf(speed / 420.0, 0.0, 0.24) + (0.12 if swing_timer > 0.0 else 0.0)
	if USE_RIG_CHARACTERS:
		_draw_rig_character(ghost_pos, Color(color.r, color.g, color.b, alpha * 0.65), side, speed, swing_timer, "", true)
		return
	var texture := player_texture if side == PLAYER_SIDE else rival_texture
	if texture != null:
		_draw_character_texture(texture, ghost_pos, side, 0.0, "", Color(color.r, color.g, color.b, alpha * 0.55))
		return
	_draw_player_shape(ghost_pos, Color(color.r, color.g, color.b, alpha), side, 0.0, swing_timer, true)


func _draw_player(pos: Vector2, color: Color, side: int, speed: float, swing_timer: float, swing_type: String) -> void:
	var shadow_scale := 1.0 + clampf(speed / 380.0, 0.0, 0.25)
	var shadow_size := Vector2(54, 10) if side == PLAYER_SIDE else Vector2(62, 11)
	_draw_ellipse(pos + Vector2(0, 24), shadow_size * shadow_scale, Color(0.0, 0.0, 0.0, 0.30))
	_draw_ellipse(pos + Vector2(0, 23), shadow_size * 0.55 * shadow_scale, Color(0.0, 0.0, 0.0, 0.20))
	if USE_RIG_CHARACTERS:
		_draw_rig_character(pos, color, side, speed, swing_timer, swing_type, false)
		return
	var texture := player_texture if side == PLAYER_SIDE else rival_texture
	if texture != null:
		_draw_character_texture(texture, pos, side, swing_timer, swing_type)
		return
	_draw_player_shape(pos, color, side, speed, swing_timer, false, swing_type)


func _draw_character_texture(texture: Texture2D, pos: Vector2, side: int, swing_timer: float, swing_type: String, tint: Color = Color(1, 1, 1, 1)) -> void:
	var swing_phase := _swing_phase(swing_timer, swing_type)
	var windup: float = swing_phase["windup"]
	var commit: float = swing_phase["commit"]
	var follow: float = swing_phase["follow"]
	var base_height := 194.0 if side == PLAYER_SIDE else 218.0
	if swing_type == "skill":
		base_height += 8.0 * commit
	var aspect := float(texture.get_width()) / float(texture.get_height())
	var velocity := player_velocity if side == PLAYER_SIDE else ai_velocity
	var speed := velocity.length()
	var moving := speed > 45.0
	var run_cycle := Time.get_ticks_msec() * 0.018 + pos.x * 0.04
	var bob := absf(sin(run_cycle)) * (5.0 if moving else 1.0)
	var lean := clampf(velocity.x / 320.0, -1.0, 1.0) * 10.0
	var jump := _jump_offset(swing_phase, swing_type)
	var stretch_y := 1.0 - 0.045 * commit + 0.025 * follow
	var stretch_x := 1.0 + 0.045 * commit
	var size := Vector2(base_height * aspect * stretch_x, base_height * stretch_y)
	var foot_lift := -8.0 if side == PLAYER_SIDE else -10.0
	var x_bias := 6.0 * side
	var swing_shift := Vector2(-18.0 * side * commit + 7.0 * side * windup, -8.0 * windup + 7.0 * follow)
	var draw_pos := pos + Vector2(lean, -bob - jump) + swing_shift - Vector2(size.x * 0.5 - x_bias, size.y - 35.0 + foot_lift)
	draw_texture_rect(texture, Rect2(draw_pos, size), false, tint)
	if windup > 0.0 or commit > 0.0 or follow > 0.0:
		var arc_center := pos + Vector2(74.0 * -side, -72.0 - jump * 0.45) + swing_shift
		var arc_alpha := clampf(commit + follow * 0.45, 0.0, 1.0)
		var arc_color := Color(0.8, 1.0, 0.92, 0.42 * arc_alpha)
		if swing_type == "skill":
			arc_color = Color(0.38, 1.0, 0.88, 0.66 * arc_alpha)
		elif swing_type == "smash":
			arc_color = Color(1.0, 0.80, 0.28, 0.56 * arc_alpha)
		draw_arc(arc_center, 42.0 + 24.0 * commit, -0.7, 2.0, 28, arc_color, 5.0)


func _draw_rig_character(pos: Vector2, color: Color, side: int, speed: float, swing_timer: float, swing_type: String, ghost: bool) -> void:
	var swing_phase := _swing_phase(swing_timer, swing_type)
	var windup: float = swing_phase["windup"]
	var commit: float = swing_phase["commit"]
	var follow: float = swing_phase["follow"]
	var moving := speed > 45.0
	var speed_t := clampf(speed / 300.0, 0.0, 1.0)
	var run_cycle := player_run_phase if side == PLAYER_SIDE else ai_run_phase
	var stride := sin(run_cycle) * speed_t
	var stride_back := sin(run_cycle + PI) * speed_t
	var lift_a := pow(maxf(0.0, sin(run_cycle)), 0.7) * speed_t
	var lift_b := pow(maxf(0.0, sin(run_cycle + PI)), 0.7) * speed_t
	var jump := _jump_offset(swing_phase, swing_type)
	var ground_y := pos.y + FOOT_Y_OFFSET
	var airborne := jump > 0.0
	var stance_width := 42.0
	var crouch := 9.0 + 7.0 * speed_t - 5.0 * jump / 42.0
	var hip := Vector2(pos.x - 2.0 * side, ground_y - 62.0 + crouch - jump)
	var torso_lean: float = (13.0 + 5.0 * speed_t + 10.0 * commit - 7.0 * windup) * -side
	var chest := hip + Vector2(torso_lean, -50.0)
	var head := chest + Vector2(7.0 * -side, -29.0)
	var shoulder_left := chest + Vector2(-18.0, 2.0)
	var shoulder_right := chest + Vector2(18.0, 2.0)
	var hip_left := hip + Vector2(-13.0, 4.0)
	var hip_right := hip + Vector2(13.0, 4.0)
	var lead_sign := -side
	var rear_sign := side
	var lead_foot := Vector2(pos.x + lead_sign * (stance_width + 10.0 * stride), ground_y - 2.0 - 6.0 * lift_a - jump * 0.12)
	var rear_foot := Vector2(pos.x + rear_sign * (stance_width * 0.72 + 8.0 * stride_back), ground_y + 3.0 - 5.0 * lift_b - jump * 0.12)
	if not moving:
		lead_foot = Vector2(pos.x + lead_sign * 48.0, ground_y - 2.0)
		rear_foot = Vector2(pos.x + rear_sign * 30.0, ground_y + 3.0)
	if commit > 0.0:
		lead_foot += Vector2(14.0 * lead_sign, -3.0) * commit
	if airborne:
		lead_foot.y -= jump * 0.18
		rear_foot.y -= jump * 0.18
	var lead_hip := hip_left if lead_sign < 0.0 else hip_right
	var rear_hip := hip_right if lead_sign < 0.0 else hip_left
	var lead_knee := Vector2((lead_hip.x + lead_foot.x) * 0.5 + 12.0 * lead_sign, ground_y - 29.0 - 5.0 * lift_a - jump * 0.22)
	var rear_knee := Vector2((rear_hip.x + rear_foot.x) * 0.5 + 9.0 * rear_sign, ground_y - 26.0 - 4.0 * lift_b - jump * 0.18)
	var skeleton_color := Color(0.88, 0.96, 1.0, color.a)
	var joint_color := Color(0.12, 0.18, 0.22, color.a)
	if side == AI_SIDE:
		skeleton_color = Color(1.0, 0.78, 0.72, color.a)
		joint_color = Color(0.18, 0.05, 0.06, color.a)
	if ghost:
		skeleton_color.a *= 0.55
		joint_color.a *= 0.55

	_draw_bone(lead_hip, lead_knee, lead_foot, skeleton_color, joint_color, 5.0)
	_draw_bone(rear_hip, rear_knee, rear_foot, skeleton_color, joint_color, 5.0)
	draw_line(hip_left, hip_right, skeleton_color, 4.0)
	draw_line(hip, chest, skeleton_color, 6.0)
	draw_line(shoulder_left, shoulder_right, skeleton_color, 4.0)
	draw_circle(head, 16.0, Color(0.96, 0.78, 0.56, skeleton_color.a) if side == PLAYER_SIDE else Color(0.96, 0.92, 0.88, skeleton_color.a))
	draw_circle(head + Vector2(5.0 * -side, -3.0), 4.0, joint_color)
	draw_line(head + Vector2(7.0 * -side, 7.0), head + Vector2(18.0 * -side, 9.0), joint_color, 2.0)

	var racket_pose := _racket_pose(chest, side, swing_phase, swing_type, speed_t, stride)
	var racket_hand: Vector2 = racket_pose["hand"]
	var racket_head: Vector2 = racket_pose["head"]
	var shoulder_racket := shoulder_left if side == AI_SIDE else shoulder_right
	var shoulder_free := shoulder_right if side == AI_SIDE else shoulder_left
	var free_hand := chest + Vector2(28.0 * side, -8.0 - 4.0 * commit + 8.0 * windup)
	var elbow_racket := shoulder_racket.lerp(racket_hand, 0.48) + Vector2(8.0 * -side, -11.0 * windup - 5.0 * commit + 8.0 * follow)
	var elbow_free := shoulder_free.lerp(free_hand, 0.52) + Vector2(8.0 * side, 7.0)
	_draw_bone(shoulder_free, elbow_free, free_hand, skeleton_color, joint_color, 4.0)
	_draw_bone(shoulder_racket, elbow_racket, racket_hand, skeleton_color, joint_color, 4.0)
	_draw_racket(racket_hand, racket_head, side, skeleton_color, skeleton_color, ghost)

	if commit > 0.0 and not ghost:
		var arc_color := Color(0.74, 1.0, 0.87, 0.42 * commit)
		if swing_type == "skill":
			arc_color = Color(0.32, 1.0, 0.88, 0.64 * commit)
		elif swing_type == "smash":
			arc_color = Color(1.0, 0.78, 0.24, 0.56 * commit)
		draw_arc(racket_head, 46.0 + 28.0 * commit, -0.85, 2.05, 32, arc_color, 5.0)


func _swing_phase(swing_timer: float, swing_type: String) -> Dictionary:
	var total := SWING_TIME
	if swing_type == "skill":
		total *= 1.35
	if swing_timer <= 0.0 or swing_type.is_empty():
		return {
			"progress": 0.0,
			"windup": 0.0,
			"commit": 0.0,
			"follow": 0.0,
		}
	var progress := 1.0 - clampf(swing_timer / total, 0.0, 1.0)
	var windup := sin(clampf(progress / 0.46, 0.0, 1.0) * PI)
	var commit := sin(clampf((progress - 0.34) / 0.30, 0.0, 1.0) * PI)
	var follow := sin(clampf((progress - 0.58) / 0.38, 0.0, 1.0) * PI)
	return {
		"progress": progress,
		"windup": windup,
		"commit": commit,
		"follow": follow,
	}


func _jump_offset(phase: Dictionary, swing_type: String) -> float:
	var progress: float = phase["progress"]
	var commit: float = phase["commit"]
	if swing_type == "smash":
		return 26.0 * sin(progress * PI) * maxf(commit, 0.2)
	if swing_type == "skill":
		return 42.0 * sin(progress * PI) * maxf(commit, 0.25)
	return 0.0


func _racket_pose(chest: Vector2, side: int, phase: Dictionary, swing_type: String, speed_t: float, stride: float) -> Dictionary:
	var windup: float = phase["windup"]
	var commit: float = phase["commit"]
	var follow: float = phase["follow"]
	var ready_hand := chest + Vector2(30.0 * -side, -24.0 + stride * 1.5)
	var ready_head := ready_hand + Vector2(24.0 * -side, -24.0)
	var windup_hand := chest + Vector2(26.0 * side, -55.0)
	var windup_head := windup_hand + Vector2(36.0 * side, -34.0)
	var hit_hand := chest + Vector2(42.0 * -side, -58.0)
	var hit_head := hit_hand + Vector2(46.0 * -side, -26.0)
	var follow_hand := chest + Vector2(36.0 * -side, 12.0)
	var follow_head := follow_hand + Vector2(42.0 * -side, 22.0)
	if swing_type == "drop":
		windup_hand = chest + Vector2(18.0 * side, -34.0)
		windup_head = windup_hand + Vector2(28.0 * side, -20.0)
		hit_hand = chest + Vector2(38.0 * -side, -34.0)
		hit_head = hit_hand + Vector2(36.0 * -side, -8.0)
		follow_hand = chest + Vector2(31.0 * -side, -8.0)
		follow_head = follow_hand + Vector2(30.0 * -side, 6.0)
	elif swing_type == "smash" or swing_type == "skill":
		windup_hand = chest + Vector2(32.0 * side, -70.0)
		windup_head = windup_hand + Vector2(42.0 * side, -38.0)
		hit_hand = chest + Vector2(48.0 * -side, -68.0)
		hit_head = hit_hand + Vector2(54.0 * -side, -38.0)
		follow_hand = chest + Vector2(42.0 * -side, 33.0)
		follow_head = follow_hand + Vector2(46.0 * -side, 30.0)
	var hand := ready_hand
	var head := ready_head
	if windup > 0.0:
		hand = hand.lerp(windup_hand, windup)
		head = head.lerp(windup_head, windup)
	if commit > 0.0:
		hand = hand.lerp(hit_hand, commit)
		head = head.lerp(hit_head, commit)
	if follow > 0.0:
		hand = hand.lerp(follow_hand, follow * 0.86)
		head = head.lerp(follow_head, follow * 0.86)
	return {"hand": hand, "head": head}


func _rig_palette(side: int, base_color: Color, ghost: bool) -> Dictionary:
	var alpha := base_color.a
	if side == PLAYER_SIDE:
		return {
			"skin": Color(0.96, 0.74, 0.48, alpha),
			"cloth": Color(0.98, 0.78, 0.14, alpha),
			"accent": Color(0.08, 0.30, 0.76, alpha),
			"dark": Color(0.04, 0.06, 0.11, alpha),
			"line": Color(0.88, 0.96, 1.0, alpha),
		}
	return {
		"skin": Color(0.86, 0.55, 0.43, alpha),
		"cloth": Color(0.86, 0.05, 0.08, alpha),
		"accent": Color(0.08, 0.08, 0.09, alpha),
		"dark": Color(0.02, 0.015, 0.02, alpha),
		"line": Color(1.0, 0.84, 0.78, alpha),
	}


func _draw_limb(a: Vector2, b: Vector2, c: Vector2, color: Color, joint_color: Color, width_a: float, width_b: float) -> void:
	draw_line(a, b, color, width_a)
	draw_line(b, c, color, width_b)
	draw_circle(b, width_b * 0.56, joint_color)
	draw_circle(c, width_b * 0.62, joint_color)


func _draw_bone(a: Vector2, b: Vector2, c: Vector2, color: Color, joint_color: Color, width: float) -> void:
	draw_line(a, b, color, width)
	draw_line(b, c, color, width)
	draw_circle(a, width * 0.82, joint_color)
	draw_circle(b, width * 0.92, joint_color)
	draw_circle(c, width * 0.98, joint_color)


func _draw_torso(hip: Vector2, chest: Vector2, side: int, cloth: Color, accent: Color, line: Color) -> void:
	var normal := (chest - hip).normalized().orthogonal()
	var points := PackedVector2Array([
		chest + normal * 30.0,
		chest - normal * 25.0,
		hip - normal * 22.0,
		hip + normal * 26.0,
	])
	draw_colored_polygon(points, cloth)
	draw_line(chest + normal * 21.0, hip - normal * 12.0, accent, 8.0)
	draw_line(chest - normal * 20.0, hip + normal * 19.0, line, 2.0)


func _draw_head(head: Vector2, side: int, skin: Color, dark: Color, accent: Color) -> void:
	if side == PLAYER_SIDE:
		draw_circle(head, 20.0, skin)
		draw_circle(head + Vector2(6.0 * side, -9.0), 14.0, dark)
		draw_line(head + Vector2(9.0 * side, 1.0), head + Vector2(22.0 * side, 2.0), dark, 2.0)
	else:
		draw_circle(head, 21.0, Color(0.95, 0.92, 0.88, skin.a))
		draw_circle(head + Vector2(5.0 * side, 1.0), 8.0, dark)
		draw_line(head + Vector2(-9.0, -20.0), head + Vector2(-22.0, -34.0), accent, 5.0)
		draw_line(head + Vector2(9.0, -20.0), head + Vector2(23.0, -32.0), accent, 5.0)


func _draw_racket(hand: Vector2, head: Vector2, side: int, line: Color, accent: Color, ghost: bool) -> void:
	draw_line(hand, head, Color(0.95, 0.78, 0.26, line.a), 4.0)
	var rim_center := head + Vector2(13.0 * -side, -7.0)
	draw_arc(rim_center, 18.0, -0.7, 2.7, 24, line, 3.0)
	draw_line(rim_center + Vector2(-13.0, -4.0), rim_center + Vector2(13.0, 4.0), Color(line.r, line.g, line.b, line.a * 0.45), 1.2)
	draw_line(rim_center + Vector2(-8.0, 10.0), rim_center + Vector2(8.0, -10.0), Color(line.r, line.g, line.b, line.a * 0.45), 1.2)


func _draw_player_shape(pos: Vector2, color: Color, side: int, speed: float, swing_timer: float, ghost: bool = false, swing_type: String = "") -> void:
	var swing_amount := clampf(swing_timer / SWING_TIME, 0.0, 1.0)
	var lean := clampf(speed / 360.0, 0.0, 1.0) * 8.0 * side
	var skin := Color(0.95, 0.82, 0.56, color.a)
	var dark := Color(0.05, 0.05, 0.07, color.a)
	var arm_raise := Vector2(0, -20.0 * swing_amount)
	var racket_hand := pos + Vector2(48 * side, -28) + arm_raise + Vector2(34 * side * swing_amount, -20.0 * swing_amount)
	var racket_head := racket_hand + Vector2(18 * side, -16 - 18.0 * swing_amount)

	draw_line(pos + Vector2(-14 * side + lean * 0.25, 4), pos + Vector2(-26 * side, 44), skin, 7.0)
	draw_line(pos + Vector2(10 * side + lean * 0.25, 4), pos + Vector2(24 * side, 42), skin, 7.0)
	draw_circle(pos + Vector2(lean * 0.18, -36), 18.0, Color(0.98, 0.78, 0.52, color.a))
	draw_circle(pos + Vector2(lean * 0.35, -4), 28.0, color)
	draw_line(pos + Vector2(14 * side + lean * 0.2, -10), racket_hand, skin, 7.0)
	draw_line(racket_hand, racket_head, Color(0.85, 0.9, 1.0, color.a), 3.0)
	draw_arc(racket_head + Vector2(10 * side, -8), 18.0, -0.6 + swing_amount * 0.6, 2.6 + swing_amount * 0.6, 22, Color(0.9, 0.95, 1.0, color.a), 3.0)
	draw_circle(pos + Vector2(-10 * side, 18), 7.0, dark)
	draw_circle(pos + Vector2(20 * side, 18), 7.0, dark)
	if swing_amount > 0.0 and not ghost:
		var arc_color := Color(0.8, 1.0, 0.92, 0.36 * swing_amount)
		if swing_type == "skill":
			arc_color = Color(0.38, 1.0, 0.88, 0.58 * swing_amount)
		draw_arc(racket_head + Vector2(4 * side, -4), 34.0 + 18.0 * swing_amount, -0.8, 1.9, 24, arc_color, 5.0)


func _draw_court_fx(front_layer: bool) -> void:
	for fx in court_fx:
		var kind: String = fx["type"]
		if front_layer and kind == "step":
			continue
		if not front_layer and kind == "hit":
			continue

		var age: float = fx["age"]
		var life: float = fx["life"]
		var t := clampf(age / life, 0.0, 1.0)
		var pos: Vector2 = fx["pos"]
		var color: Color = fx["color"]
		var alpha := 1.0 - t

		if kind == "step":
			_draw_ellipse(pos, Vector2(10.0 + 32.0 * t, 4.0 + 10.0 * t), Color(color.r, color.g, color.b, 0.22 * alpha))
		elif kind == "hit":
			var is_skill: bool = fx.get("skill", false)
			var radius := (24.0 if is_skill else 14.0) + 38.0 * t
			draw_circle(pos, radius * 0.42, Color(color.r, color.g, color.b, 0.20 * alpha))
			draw_arc(pos, radius, 0.0, TAU, 28, Color(color.r, color.g, color.b, 0.78 * alpha), 3.0 if not is_skill else 5.0)
			for i in range(6 if is_skill else 4):
				var angle := TAU * float(i) / float(6 if is_skill else 4) + t * 1.5
				var inner := pos + Vector2(cos(angle), sin(angle)) * radius * 0.28
				var outer := pos + Vector2(cos(angle), sin(angle)) * radius
				draw_line(inner, outer, Color(color.r, color.g, color.b, 0.55 * alpha), 2.0)


func _draw_shuttle() -> void:
	for i in range(shuttle_trail.size()):
		var alpha := (0.48 if shuttle_is_skill else 0.30) * (1.0 - float(i) / float(shuttle_trail.size()))
		var radius := 8.0 if shuttle_is_skill else 5.0
		draw_circle(shuttle_trail[i], radius, Color(shuttle_power_color.r, shuttle_power_color.g, shuttle_power_color.b, alpha))

	var ground_pos := shuttle_pos
	var visual_pos := shuttle_pos - Vector2(0.0, shuttle_z * 0.38)
	_draw_ellipse(ground_pos, Vector2(15.0, 5.0), Color(0.0, 0.0, 0.0, 0.30))
	if shuttle_is_skill:
		draw_circle(visual_pos, 18.0, Color(shuttle_power_color.r, shuttle_power_color.g, shuttle_power_color.b, 0.18))
		draw_arc(visual_pos, 24.0, shuttle_spin, shuttle_spin + PI * 1.4, 18, Color(0.9, 1.0, 1.0, 0.72), 3.0)
	draw_circle(visual_pos, 7.0, Color(0.93, 1.0, 0.92))
	var angle := shuttle_spin
	var feather_a := visual_pos + Vector2(cos(angle), sin(angle)) * 16.0
	var feather_b := visual_pos + Vector2(cos(angle + 2.2), sin(angle + 2.2)) * 14.0
	var feather_c := visual_pos + Vector2(cos(angle - 2.2), sin(angle - 2.2)) * 14.0
	draw_line(visual_pos, feather_a, shuttle_power_color, 4.0)
	draw_line(visual_pos, feather_b, shuttle_power_color, 3.0)
	draw_line(visual_pos, feather_c, shuttle_power_color, 3.0)


func _draw_feedback() -> void:
	if feedback_timer <= 0.0 or feedback_text.is_empty():
		return
	var t := feedback_timer / FEEDBACK_TIME
	var pos := feedback_pos + Vector2(0.0, -34.0 * (1.0 - t))
	var font := ThemeDB.fallback_font
	var font_size := 30
	var text_size := font.get_string_size(feedback_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var color := Color(feedback_color.r, feedback_color.g, feedback_color.b, t)
	draw_string(font, pos - Vector2(text_size.x * 0.5 - 2, -2), feedback_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.55 * t))
	draw_string(font, pos - Vector2(text_size.x * 0.5, 0), feedback_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_match_overlay() -> void:
	var font := ThemeDB.fallback_font
	_draw_panel(Rect2(132, 18, 340, 54), Color(0.06, 0.08, 0.11, 0.86), Color(0.23, 0.52, 0.9, 0.55))
	_draw_panel(Rect2(808, 18, 340, 54), Color(0.06, 0.08, 0.11, 0.86), Color(0.95, 0.28, 0.22, 0.55))
	draw_circle(Vector2(157, 45), 18, Color(0.22, 0.48, 1.0))
	draw_circle(Vector2(1123, 45), 18, Color(1.0, 0.25, 0.21))
	draw_string(font, Vector2(188, 54), "PLAYER", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.85, 0.93, 1.0))
	draw_string(font, Vector2(1010, 54), "RIVAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.88, 0.84))
	draw_string(font, Vector2(596, 118), "RALLY %d" % rally_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.78, 0.93, 1.0, 0.78))

	_draw_energy_meter(Rect2(170, 58, 280, 8), player_energy, Color(0.36, 1.0, 0.86))
	_draw_energy_meter(Rect2(830, 58, 280, 8), ai_energy, Color(1.0, 0.42, 0.58))
	if player_energy >= MAX_ENERGY:
		draw_string(font, Vector2(935, 622), "SKILL READY", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.5, 1.0, 0.88))


func _draw_move_pad(center: Vector2) -> void:
	_draw_action_button(center, move_icon, "", false, 76.0)
	var font := ThemeDB.fallback_font
	var labels := {
		"W": center + Vector2(0, -45),
		"S": center + Vector2(0, 47),
		"A": center + Vector2(-47, 3),
		"D": center + Vector2(47, 3),
	}
	for key in labels:
		var pos: Vector2 = labels[key]
		var size := font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
		draw_string(font, pos - Vector2(size.x * 0.5, -5), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.92, 0.98, 1.0, 0.76))


func _draw_action_button(center: Vector2, texture: Texture2D, label: String, active: bool = false, radius: float = 42.0) -> void:
	var pulse := 0.0
	if active:
		pulse = 8.0 + sin(Time.get_ticks_msec() * 0.006) * 3.0
		draw_circle(center, radius + pulse, Color(0.35, 1.0, 0.84, 0.16))
		draw_arc(center, radius + pulse + 4.0, 0.0, TAU, 48, Color(0.42, 1.0, 0.86, 0.62), 3.0)
	if texture != null:
		var size := Vector2(radius * 2.26, radius * 2.26)
		draw_texture_rect(texture, Rect2(center - size * 0.5, size), false, Color(1, 1, 1, 0.94))
	else:
		_draw_key(center, label, active)
	if not label.is_empty():
		var font := ThemeDB.fallback_font
		var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
		var badge := Rect2(center + Vector2(radius * 0.26, radius * 0.18), Vector2(25, 20))
		draw_circle(badge.position + badge.size * 0.5, 14.0, Color(0.02, 0.03, 0.04, 0.66))
		draw_string(font, badge.position + Vector2((badge.size.x - text_size.x) * 0.5, 14), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.93, 0.98, 1.0, 0.92))


func _draw_key(center: Vector2, label: String, active: bool = false) -> void:
	var font := ThemeDB.fallback_font
	var rect := Rect2(center - Vector2(23, 20), Vector2(46, 40))
	var fill := Color(0.13, 0.14, 0.16, 0.74)
	var stroke := Color(0.82, 0.9, 1.0, 0.22)
	if active:
		fill = Color(0.08, 0.32, 0.30, 0.86)
		stroke = Color(0.4, 1.0, 0.86, 0.8)
		draw_circle(center, 34.0, Color(0.35, 1.0, 0.84, 0.12))
	_draw_panel(rect, fill, stroke)
	var size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
	draw_string(font, center - Vector2(size.x * 0.5, -7), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.92, 0.98, 1.0))


func _draw_energy_meter(rect: Rect2, value: float, color: Color) -> void:
	draw_rect(rect, Color(0.02, 0.03, 0.04, 0.82))
	var filled := Rect2(rect.position, Vector2(rect.size.x * clampf(value / MAX_ENERGY, 0.0, 1.0), rect.size.y))
	draw_rect(filled, color)
	draw_line(rect.position, Vector2(rect.end.x, rect.position.y), Color(color.r, color.g, color.b, 0.4), 1.0)


func _draw_hit_window() -> void:
	if state != "rally" or shuttle_pos.x > NET_X + 20.0:
		return
	var visual_shuttle := shuttle_pos - Vector2(0.0, shuttle_z * 0.38)
	var distance := absf(player_pos.x - visual_shuttle.x)
	if distance > HIT_RADIUS * 1.35:
		return
	var quality := 1.0 - clampf(distance / HIT_RADIUS, 0.0, 1.0)
	var color := _quality_color(clampf(0.36 + quality * 0.82, 0.36, 1.18))
	draw_arc(player_pos, HIT_RADIUS, -0.55 * PI, 0.55 * PI, 32, Color(color.r, color.g, color.b, 0.46), 4.0)
	draw_arc(player_pos, HIT_RADIUS * 0.58, -0.42 * PI, 0.42 * PI, 28, Color(color.r, color.g, color.b, 0.25), 2.0)
	draw_line(player_pos, visual_shuttle, Color(color.r, color.g, color.b, 0.24), 2.0)


func _draw_panel(rect: Rect2, fill: Color, stroke: Color) -> void:
	draw_rect(rect, fill)
	draw_line(rect.position, Vector2(rect.end.x, rect.position.y), stroke, 2.0)
	draw_line(Vector2(rect.end.x, rect.position.y), rect.end, stroke, 2.0)
	draw_line(rect.end, Vector2(rect.position.x, rect.end.y), stroke, 2.0)
	draw_line(Vector2(rect.position.x, rect.end.y), rect.position, stroke, 2.0)


func _draw_crowd_band(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)
	for i in range(38):
		var x := rect.position.x + 18.0 + float(i) * 34.0
		var y := rect.position.y + 18.0 + float(i % 3) * 9.0
		draw_circle(Vector2(x, y), 4.0, Color(0.55, 0.72, 0.82, 0.22))


func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points: PackedVector2Array = []
	for i in range(24):
		var angle := TAU * float(i) / 24.0
		points.push_back(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)

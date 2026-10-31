extends CharacterBody3D
## GRAVITY BREAKER — auto-running four-surface runner.
## The player always runs toward world +Z. A/D strafe relative to the current
## surface, Space jumps, and Q rotates gravity to an adjacent surface.

const MOVE_SPEED: float = 9.0 # Faster default cruise speed at the start of the course.
const CRUISE_SPEED_END: float = 14.0 # Cruise speed at 1500 m (a gradual 56% increase).
const MIN_RUN_SPEED: float = 4.0
const MAX_RUN_SPEED: float = 22.0 # Hard cap for W boost near the end of the course.
const BOOST_MULTIPLIER: float = 1.65 # Boost scales with the current sector cruise speed.
const BOOST_ACCELERATION: float = 11.0
const BRAKE_DECELERATION: float = 13.0
const CRUISE_RETURN_RATE: float = 7.0
const MAX_STAMINA: float = 100.0
const BOOST_STAMINA_DRAIN: float = 23.0 # A full tank gives about 4.3 seconds of boost.
const STAMINA_RECOVERY: float = 18.0
const STRAFE_SPEED: float = 6.0
const JUMP_VELOCITY: float = 8.0
const GRAVITY: float = 24.0
const ROTATE_SPEED: float = 8.0
const GRAVITY_FLIP_COOLDOWN: float = 2.0
const SHAFT_CENTER_Y: float = 5.0
const SHAFT_AXIS: Vector3 = Vector3.BACK # +Z

const FINISH_Z: float = 1500.0
const SECTOR_LENGTH: float = 300.0
const SECTOR_COUNT: int = 5
const CHECKPOINT_ZS: Array[float] = [300.0, 600.0, 900.0, 1200.0]
const POINTS_PER_METER: int = 10
const CHECKPOINT_BONUS: int = 500
const FINISH_BONUS: int = 1000
const STARTING_LIVES: int = 3
const PROJECTILE_INTERVAL: float = 3.8
const PROJECTILE_SPEED: float = 10.0
# End-of-course limits for the gradual enemy attack ramp.
const PROJECTILE_INTERVAL_LATE: float = 3.0
const PROJECTILE_SPEED_LATE: float = 11.5
const PROJECTILE_SPAWN_AHEAD: float = 24.0
# Short, readable telegraph before each enemy attack. The attack cadence
# remains unchanged because the warning is included in the interval.
const ATTACK_WARNING_DURATION: float = 0.62
const ATTACK_WARNING_AHEAD: float = 8.0
const BOSS_START_Z: float = 1280.0
const BOSS_GATE_Z: float = 1500.0
const BOSS_MAX_HEALTH: int = 3
const BOSS_CORE_REWARD: int = 750
const SAVE_PATH: String = "user://gravity_breaker_save.cfg"
const BOUNDS_X: float = 6.0 # walls should stop the player; this is only a failsafe outside the square shaft
const BOUNDS_Y_MIN: float = -2.0
const BOUNDS_Y_MAX: float = 12.0
const BOUNDS_Z_MIN: float = -12.0
const CAMERA_MIN_Z: float = -9.0
# Chase-camera tuning: give the player more preview distance before hazards.
const CAMERA_BACK_DISTANCE: float = 7.0 # One small step closer after the v13/v14 camera feedback.
const CAMERA_HEIGHT: float = 2.20
const CAMERA_AIM_HEIGHT: float = 0.55
const CAMERA_LOOK_AHEAD_MIN: float = 23.0
const CAMERA_LOOK_AHEAD_MAX: float = 36.0
const CAMERA_FOV_BASE: float = 71.5 # Slightly tighter framing; still preserves peripheral hazard visibility.
const CAMERA_FOV_BOOST: float = 79.5 # Keeps boost readable without making the runner too small.
const CAMERA_FOV_BLEND_RATE: float = 4.5
const CAMERA_FOLLOW_RATE: float = 8.0

# Imported model fit. The collision capsule remains unchanged in player.tscn.
const MODEL_NODE_NAME: String = "Sketchfab_Scene"
const CAPSULE_HEIGHT: float = 1.8
const MODEL_REFERENCE_HEIGHT: float = 64.0
const MODEL_PIVOT_X: float = 5.4
const MODEL_PIVOT_Z: float = 2.3
const MODEL_YAW_DEGREES: float = 90.0
const MODEL_FOOT_OFFSET: float = 0.04
const RUN_ANIMATION: StringName = &""

# Visual runner markings are created once under Level.
const MARKINGS_NODE_NAME: String = "GeneratedRunnerMarkings"
const GRID_CELL_SIZE: float = 2.0
const GRID_MAJOR_EVERY_CELLS: int = 5 # 10 m major grid lines.
const GRID_ACCENT_EVERY_CELLS: int = 10 # 20 m restrained accent lines.
const OBSTACLE_ROOT_NAME: String = "GeneratedHazards"

var _quarter_turns: int = 0
var _roll: float = 0.0
var _roll_target: float = 0.0
var _last_flip_dir: int = -1
var _has_flip_action: bool = false
var _spawn_position: Vector3
var _checkpoint_position: Vector3
var _checkpoint_index: int = 0
var _score: int = 0
var _bonus_score: int = 0
var _best_score: int = 0
var _max_progress_z: float = 0.0
var _checkpoint_message_timer: float = 0.0
var _sector_index: int = -1
var _sector_banner_timer: float = 0.0
var _run_time: float = 0.0
var _current_run_speed: float = MOVE_SPEED
var _stamina: float = MAX_STAMINA
var _boost_locked: bool = false
var _gravity_flip_cooldown: float = 0.0
var _flip_denied_timer: float = 0.0
var _lives: int = STARTING_LIVES
var _projectile_cooldown: float = 2.0
var _projectile_pattern_index: int = 0
var _burst_shots_remaining: int = 0
var _burst_shot_timer: float = 0.0
var _burst_lane_offset: float = 0.0
var _attack_warning_timer: float = 0.0
var _attack_warning_elapsed: float = 0.0
var _attack_warning_lanes: Array = []
var _attack_warning_markers: Array[Node3D] = []
var _attack_warning_root: Node3D
var _attack_warning_label: Label
var _projectile_root: Node3D
var _game_over: bool = false
var _game_over_banner: Label
var _audio_players: Dictionary = {}
var _feedback_layer: CanvasLayer
var _game_started: bool = false
var _menu_overlay: Control
var _menu_title: Label
var _menu_subtitle: Label
var _menu_primary_button: Button
var _menu_secondary_button: Button
var _menu_tertiary_button: Button
var _menu_quaternary_button: Button
var _menu_quinary_button: Button
var _menu_mode: String = "main"
var _settings_return_mode: String = "main"
var _settings_container: VBoxContainer
var _master_volume_slider: HSlider
var _music_volume_slider: HSlider
var _fullscreen_check: CheckButton
var _master_volume: float = 0.85
var _music_volume: float = 0.20
var _fullscreen_enabled: bool = true
var _paused: bool = false

var _camera: Camera3D
var _camera_follow_position: Vector3 = Vector3.ZERO
var _camera_follow_basis: Basis = Basis.IDENTITY
var _camera_initialized: bool = false
var _anim: AnimationPlayer
var _hud_label: Label
var _stamina_bar: ProgressBar
var _flip_status_label: Label
var _flip_cooldown_bar: ProgressBar
var _finish_banner: Label
var _checkpoint_label: Label
var _sector_banner_label: Label
var _sector_subtitle_label: Label
var _boss_status_label: Label
var _boss_health_bar: ProgressBar
var _boss_announcement_label: Label
var _boss_announcement_timer: float = 0.0
var _boss_encounter_root: Node3D
var _boss_visual_root: Node3D
var _boss_core_visual: MeshInstance3D
var _boss_weakpoints_root: Node3D
var _boss_weakpoints: Array[Area3D] = []
var _boss_health: int = BOSS_MAX_HEALTH
var _boss_started: bool = false
var _boss_defeated: bool = false
var _finished: bool = false
# Prevent stale contact with the previous surface from cancelling gravity after a flip.
var _surface_change_grace: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	up_direction = Vector3.UP
	_load_best_score()
	_spawn_position = global_position
	_checkpoint_position = _spawn_position
	_max_progress_z = global_position.z
	_has_flip_action = InputMap.has_action("flip_gravity")
	if not _has_flip_action:
		push_error("Input action 'flip_gravity' is missing. Add Q in Project Settings > Input Map.")

	_setup_audio()
	_apply_master_volume()
	_apply_music_volume()
	_apply_window_mode()
	_setup_model()
	# Defer grid creation until the Main/Level hierarchy has fully entered the tree.
	_create_runner_markings.call_deferred()
	_create_hud()
	# Generate runtime nodes after the scene tree has completed its initial _ready pass.
	_create_obstacles.call_deferred()
	print("GRAVITY BREAKER ready: cruise speed rises from %.1f to %.1f units/s; HOLD W boosts up to %.1f, HOLD S brakes to %.1f; A/D strafe, Space jump, Q gravity flip (%.1f s cooldown)." % [MOVE_SPEED, CRUISE_SPEED_END, MAX_RUN_SPEED, MIN_RUN_SPEED, GRAVITY_FLIP_COOLDOWN])


func _process(delta: float) -> void:
	if _menu_mode == "settings" and Input.is_action_just_pressed("ui_cancel"):
		_show_menu(_settings_return_mode)
		return
	if (_menu_mode == "controls" or _menu_mode == "credits") and Input.is_action_just_pressed("ui_cancel"):
		_show_menu(_settings_return_mode)
		return
	if _paused:
		if Input.is_action_just_pressed("ui_cancel"):
			_resume_game()
		return
	if _game_started and not _game_over and not _finished and Input.is_action_just_pressed("ui_cancel"):
		_pause_game()
		return
	_checkpoint_message_timer = maxf(0.0, _checkpoint_message_timer - delta)
	if _checkpoint_label != null:
		_checkpoint_label.visible = _checkpoint_message_timer > 0.0
	_sector_banner_timer = maxf(0.0, _sector_banner_timer - delta)
	_boss_announcement_timer = maxf(0.0, _boss_announcement_timer - delta)
	if _boss_announcement_label != null:
		_boss_announcement_label.visible = _boss_announcement_timer > 0.0
		_boss_announcement_label.modulate.a = clampf(_boss_announcement_timer / 0.45, 0.0, 1.0)
	if _boss_core_visual != null and is_instance_valid(_boss_core_visual):
		_boss_core_visual.rotate_z(delta * 1.15)
	if _boss_visual_root != null and is_instance_valid(_boss_visual_root) and _boss_started and not _boss_defeated:
		_boss_visual_root.position.y = 5.0 + sin(_run_time * 1.8) * 0.08
		_boss_visual_root.rotation.y = sin(_run_time * 0.42) * 0.045
	if _sector_banner_label != null:
		_sector_banner_label.visible = _sector_banner_timer > 0.0
		_sector_subtitle_label.visible = _sector_banner_timer > 0.0
		var banner_alpha: float = clampf(_sector_banner_timer / 0.45, 0.0, 1.0)
		_sector_banner_label.modulate.a = banner_alpha
		_sector_subtitle_label.modulate.a = banner_alpha
	# Animate generated hazards from the Player script itself. This avoids
	# attaching a script to Area3D nodes after they have entered the scene tree.
	for node in get_tree().get_nodes_in_group("moving_hazards"):
		if not is_instance_valid(node) or not node is Node3D:
			continue
		var hazard := node as Node3D
		if hazard.has_meta("motion_origin"):
			var origin: Vector3 = hazard.get_meta("motion_origin")
			var axis: Vector3 = hazard.get_meta("motion_axis")
			var amplitude: float = float(hazard.get_meta("motion_amplitude"))
			var speed: float = float(hazard.get_meta("motion_speed"))
			var phase: float = float(hazard.get_meta("motion_phase"))
			var offset: Vector3 = axis * sin(_run_time * speed + phase) * amplitude
			if hazard.has_meta("motion_axis_secondary"):
				var secondary_axis: Vector3 = hazard.get_meta("motion_axis_secondary")
				var secondary_amplitude: float = float(hazard.get_meta("motion_amplitude_secondary"))
				var secondary_speed: float = float(hazard.get_meta("motion_speed_secondary"))
				var secondary_phase: float = float(hazard.get_meta("motion_phase_secondary"))
				offset += secondary_axis * sin(_run_time * secondary_speed + secondary_phase) * secondary_amplitude
			hazard.position = origin + offset
	for node in get_tree().get_nodes_in_group("rotating_hazards"):
		if is_instance_valid(node) and node is Node3D:
			var rotor := node as Node3D
			rotor.rotate_object_local(Vector3.UP, float(rotor.get_meta("spin_speed", 1.0)) * delta)
	_update_attack_warning_visuals(delta)


func _physics_process(delta: float) -> void:
	if _paused:
		return
	if _game_over:
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_R):
			_restart_run()
		return
	if _finished:
		if Input.is_key_pressed(KEY_R):
			_restart_run()
		return
	if not _game_started:
		return

	_surface_change_grace = maxf(0.0, _surface_change_grace - delta)
	_gravity_flip_cooldown = maxf(0.0, _gravity_flip_cooldown - delta)
	_flip_denied_timer = maxf(0.0, _flip_denied_timer - delta)
	_run_time += delta
	_update_run_speed(delta)
	_update_score_and_checkpoints()
	_update_sector_progress()
	_update_boss_encounter()
	_update_projectiles(delta)

	if global_position.z >= FINISH_Z:
		if _boss_defeated:
			_finish_run()
		else:
			_boss_announcement_label.text = "GUARDIAN SHIELDED // RETURN TO THE CORE TARGETS"
			_boss_announcement_timer = 2.3
			_boss_announcement_label.visible = true
			_take_hit("Guardian overload")
		return

	if _is_out_of_bounds():
		_respawn("out of bounds")
		return

	# Smooth quarter-turn around the shaft axis. Do not call move_and_slide()
	# with zero velocity while rotating: that can cause collision recovery to
	# shove the capsule into a neighbouring wall.
	if _is_rotating():
		_roll = move_toward(_roll, _roll_target, ROTATE_SPEED * delta)
		global_transform = Transform3D(Basis(SHAFT_AXIS, _roll), global_position)
		velocity = Vector3.ZERO
		if not _is_rotating():
			_wrap_roll_state()
			global_transform = Transform3D(Basis(SHAFT_AXIS, _roll), global_position)
			_surface_change_grace = 0.18
		_update_camera(delta)
		_update_hud()
		return

	if _has_flip_action and Input.is_action_just_pressed("flip_gravity"):
		if _start_flip():
			velocity = Vector3.ZERO
			_update_camera(delta)
			_update_hud()
			return
		_update_hud()

	var surface: Basis = Basis(SHAFT_AXIS, _roll)
	# Keep the same screen-relative lateral direction as the camera rolls.
	var right: Vector3 = -surface.x
	var forward: Vector3 = surface.z.normalized() # always world +Z

	var lateral_input: float = Input.get_axis("move_left", "move_right")
	var lateral_velocity: Vector3 = right * lateral_input * STRAFE_SPEED
	var forward_velocity: Vector3 = forward * _current_run_speed

	# Jump/gravity are measured along the current surface normal.
	var vertical_speed: float = velocity.dot(up_direction)
	var supported: bool = is_on_floor() and _surface_change_grace <= 0.0
	if supported:
		vertical_speed = 0.0
		if Input.is_action_just_pressed("jump"):
			vertical_speed = JUMP_VELOCITY
	else:
		vertical_speed -= GRAVITY * delta

	velocity = forward_velocity + lateral_velocity + up_direction * vertical_speed
	move_and_slide()

	_update_camera(delta)
	_update_hud()
	_set_run_animation_active(true)


func _cruise_speed_for_z(z_value: float) -> float:
	# The default auto-run pace rises continuously with course progress.
	# This yields approximately 9 / 10 / 11 / 12 / 13 / 14 units/s at
	# 0 / 300 / 600 / 900 / 1200 / 1500 metres respectively.
	var progress: float = clampf(z_value / FINISH_Z, 0.0, 1.0)
	return lerpf(MOVE_SPEED, CRUISE_SPEED_END, progress)


func _update_run_speed(delta: float) -> void:
	# W is the primary boost control; SHIFT remains as an alternate. S brakes,
	# with CTRL retained as an alternate. Normal cruise speed rises with distance.
	var cruise_target: float = _cruise_speed_for_z(global_position.z)
	var accelerate: bool = Input.is_action_pressed("move_forward") or Input.is_key_pressed(KEY_SHIFT)
	var brake: bool = Input.is_action_pressed("move_back") or Input.is_key_pressed(KEY_CTRL)
	if brake:
		_current_run_speed = move_toward(_current_run_speed, MIN_RUN_SPEED, BRAKE_DECELERATION * delta)
	elif accelerate:
		if _stamina > 0.0 and not _boost_locked:
			var boost_target: float = minf(MAX_RUN_SPEED, cruise_target * BOOST_MULTIPLIER)
			_current_run_speed = move_toward(_current_run_speed, boost_target, BOOST_ACCELERATION * delta)
			_stamina = maxf(0.0, _stamina - BOOST_STAMINA_DRAIN * delta)
			if _stamina <= 0.0:
				_boost_locked = true
		else:
			# Keep W from auto-cycling boost after the tank empties. Release it
			# to recharge, then boost again once enough stamina has returned.
			_current_run_speed = move_toward(_current_run_speed, cruise_target, CRUISE_RETURN_RATE * delta)
	else:
		_current_run_speed = move_toward(_current_run_speed, cruise_target, CRUISE_RETURN_RATE * delta)
	if not accelerate or brake:
		_stamina = minf(MAX_STAMINA, _stamina + STAMINA_RECOVERY * delta)
		if _boost_locked and _stamina >= 30.0:
			_boost_locked = false
	_current_run_speed = clampf(_current_run_speed, MIN_RUN_SPEED, MAX_RUN_SPEED)

func _is_rotating() -> bool:
	return not is_equal_approx(_roll, _roll_target)


func _wrap_roll_state() -> void:
	_quarter_turns = posmod(_quarter_turns, 4)
	_roll_target = float(_quarter_turns) * PI / 2.0
	_roll = _roll_target


func _is_out_of_bounds() -> bool:
	var p: Vector3 = global_position
	return (
		absf(p.x) > BOUNDS_X
		or p.y < BOUNDS_Y_MIN
		or p.y > BOUNDS_Y_MAX
		or p.z < BOUNDS_Z_MIN
	)


func _respawn(reason: String) -> void:
	_clear_attack_warning()
	print("RESPAWN (", reason, ") from ", global_position)
	var target_position: Vector3 = _checkpoint_position
	if reason == "finish":
		# Completing the course starts a fresh run, while keeping the best score.
		_best_score = maxi(_best_score, _score)
		_score = 0
		_bonus_score = 0
		_checkpoint_index = 0
		_checkpoint_position = _spawn_position
		_lives = STARTING_LIVES
		target_position = _spawn_position
		_run_time = 0.0
		_current_run_speed = MOVE_SPEED
		_stamina = MAX_STAMINA
		_boost_locked = false
		_max_progress_z = _spawn_position.z

	# Resume at the normal cruise pace for the selected checkpoint/start position.
	# Later checkpoints retain the speed progression already earned on the course.
	_current_run_speed = _cruise_speed_for_z(target_position.z)

	_quarter_turns = 0
	_roll = 0.0
	_roll_target = 0.0
	_last_flip_dir = -1
	_gravity_flip_cooldown = 0.0
	_flip_denied_timer = 0.0
	_surface_change_grace = 0.0
	up_direction = Vector3.UP
	velocity = Vector3.ZERO
	global_transform = Transform3D(Basis.IDENTITY, target_position)
	if reason != "finish" and reason != "restart":
		_stamina = minf(MAX_STAMINA, _stamina + 30.0)
		if _stamina >= 30.0:
			_boost_locked = false
	_finished = false
	_checkpoint_message_timer = 0.0
	if _checkpoint_label:
		_checkpoint_label.visible = false
	_sector_banner_timer = 0.0
	if _sector_banner_label:
		_sector_banner_label.visible = false
	if _sector_subtitle_label:
		_sector_subtitle_label.visible = false
	if _finish_banner:
		_finish_banner.visible = false

	# Snap the chase camera to the selected spawn/checkpoint pose.
	if _camera != null and _camera_initialized:
		var camera_pose: Transform3D = _build_camera_pose()
		_camera_follow_position = camera_pose.origin
		_camera_follow_basis = camera_pose.basis
		_camera.fov = CAMERA_FOV_BASE
		_apply_camera()

	_update_sector_progress()
	_update_hud()


func _start_flip() -> bool:
	if _gravity_flip_cooldown > 0.0:
		# A rejected input gives brief HUD feedback but does not interrupt movement
		# or replay the gravity-flip sound/effects.
		_flip_denied_timer = 0.55
		return false
	_gravity_flip_cooldown = GRAVITY_FLIP_COOLDOWN
	_flip_denied_timer = 0.0
	_spawn_pulse_effect(Color(0.05, 0.9, 1.0), 2.6)
	_screen_flash(Color(0.02, 0.55, 1.0), 0.18, 0.14)
	_play_sound("gravity_flip")
	# A/D chooses which adjacent surface to move onto. With no lateral input,
	# alternate direction so Q remains useful and never accumulates turns.
	var lateral: float = Input.get_axis("move_left", "move_right")
	if lateral > 0.1:
		_last_flip_dir = -1
	elif lateral < -0.1:
		_last_flip_dir = 1
	else:
		_last_flip_dir *= -1

	_quarter_turns += _last_flip_dir
	_roll_target = float(_quarter_turns) * PI / 2.0
	up_direction = Vector3.UP.rotated(SHAFT_AXIS, _roll_target).round()
	print("FLIP -> surface ", _surface_name(), " target up=", up_direction)
	return true


func _camera_speed_ratio() -> float:
	return clampf((_current_run_speed - MOVE_SPEED) / maxf(0.01, MAX_RUN_SPEED - MOVE_SPEED), 0.0, 1.0)


func _build_camera_pose() -> Transform3D:
	# Keep the camera behind the runner and offset along the active gravity-up
	# direction so it remains a conventional chase camera on all four surfaces.
	var gravity_rotation: Basis = Basis(SHAFT_AXIS, _roll)
	var surface_up: Vector3 = (gravity_rotation * Vector3.UP).normalized()
	var forward: Vector3 = SHAFT_AXIS.normalized()
	var speed_ratio: float = _camera_speed_ratio()
	var look_ahead: float = lerpf(CAMERA_LOOK_AHEAD_MIN, CAMERA_LOOK_AHEAD_MAX, speed_ratio)
	var camera_position: Vector3 = global_position + surface_up * CAMERA_HEIGHT - forward * CAMERA_BACK_DISTANCE
	var aim_position: Vector3 = global_position + forward * look_ahead + surface_up * CAMERA_AIM_HEIGHT
	var view_direction: Vector3 = (aim_position - camera_position).normalized()
	var camera_basis: Basis = Basis.looking_at(view_direction, surface_up)
	return Transform3D(camera_basis, camera_position)


func _update_camera(delta: float) -> void:
	# Find the active camera lazily: it may not be current during _ready().
	if _camera == null or not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()
		if _camera == null:
			return

	if not _camera_initialized:
		_camera_initialized = true
		_camera_follow_position = _camera.global_position
		_camera_follow_basis = _camera.global_basis
		_camera.fov = CAMERA_FOV_BASE

	# The look-ahead increases with speed, giving earlier sight of projectiles,
	# laser gates and Guardian cores. FOV widens gently during boost for speed feel.
	var camera_pose: Transform3D = _build_camera_pose()
	var weight: float = 1.0 - exp(-CAMERA_FOLLOW_RATE * delta)
	_camera_follow_position = _camera_follow_position.lerp(camera_pose.origin, weight)
	_camera_follow_basis = _camera_follow_basis.slerp(camera_pose.basis, weight).orthonormalized()
	var target_fov: float = lerpf(CAMERA_FOV_BASE, CAMERA_FOV_BOOST, _camera_speed_ratio())
	_camera.fov = lerpf(_camera.fov, target_fov, 1.0 - exp(-CAMERA_FOV_BLEND_RATE * delta))
	_apply_camera()


func _apply_camera() -> void:
	if _camera == null or not _camera_initialized:
		return
	_camera.global_transform = Transform3D(
		_camera_follow_basis,
		_camera_follow_position
	)


func _setup_audio() -> void:
	# These sound assets are included in res://assets/audio/.
	var sound_files: Dictionary = {
		"gravity_flip": "res://assets/audio/gravity_flip.wav",
		"checkpoint": "res://assets/audio/checkpoint.wav",
		"damage": "res://assets/audio/damage.wav",
		"projectile": "res://assets/audio/projectile.wav",
		"warning": "res://assets/audio/warning_charge.wav",
		"victory": "res://assets/audio/victory.wav",
		"game_over": "res://assets/audio/game_over.wav",
		"music": "res://assets/audio/ambient_loop.wav"
	}
	for sound_name in sound_files:
		var audio_player := AudioStreamPlayer.new()
		audio_player.name = "Audio_" + str(sound_name)
		audio_player.process_mode = Node.PROCESS_MODE_PAUSABLE
		audio_player.volume_db = -8.0
		if sound_name == "music":
			audio_player.volume_db = -24.0
		elif sound_name == "warning":
			audio_player.volume_db = -10.0
		var audio_stream: AudioStream = load(sound_files[sound_name]) as AudioStream
		if audio_stream == null:
			push_warning("Could not load audio asset: " + str(sound_files[sound_name]))
			continue
		if sound_name == "music" and audio_stream is AudioStreamWAV:
			(audio_stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		audio_player.stream = audio_stream
		add_child(audio_player)
		_audio_players[sound_name] = audio_player
	var music_player: AudioStreamPlayer = _audio_players.get("music") as AudioStreamPlayer
	if music_player != null:
		music_player.play()


func _play_sound(sound_name: String) -> void:
	var audio_player: AudioStreamPlayer = _audio_players.get(sound_name) as AudioStreamPlayer
	if audio_player == null:
		return
	audio_player.stop()
	audio_player.play()


func _setup_model() -> void:
	var model := get_node_or_null(MODEL_NODE_NAME) as Node3D
	if model == null:
		push_warning("No child named '%s' found; model fit skipped." % MODEL_NODE_NAME)
		return

	var fit: float = CAPSULE_HEIGHT / MODEL_REFERENCE_HEIGHT
	var yaw_basis := Basis(Vector3.UP, deg_to_rad(MODEL_YAW_DEGREES))
	var pivot_local: Vector3 = yaw_basis * Vector3(MODEL_PIVOT_X * fit, 0.0, MODEL_PIVOT_Z * fit)
	model.transform = Transform3D.IDENTITY
	model.rotation_degrees.y = MODEL_YAW_DEGREES
	model.scale = Vector3.ONE * fit
	model.position = Vector3(
		-pivot_local.x,
		-CAPSULE_HEIGHT * 0.5 + MODEL_FOOT_OFFSET,
		-pivot_local.z
	)
	print("MODEL: scale=%.5f yaw=%.0f position=%s" % [fit, MODEL_YAW_DEGREES, model.position])

	var players := model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		push_warning("No AnimationPlayer found under imported character.")
		return

	var anim := players[0] as AnimationPlayer
	anim.process_mode = Node.PROCESS_MODE_PAUSABLE
	var names: PackedStringArray = anim.get_animation_list()
	print("MODEL animations: ", names)
	var chosen: StringName = RUN_ANIMATION
	if chosen == &"":
		var candidates: Array[StringName] = []
		for name in names:
			if name != "RESET":
				candidates.append(StringName(name))
		if candidates.size() == 1:
			chosen = candidates[0]

	if chosen != &"" and anim.has_animation(chosen):
		anim.get_animation(chosen).loop_mode = Animation.LOOP_LINEAR
		anim.play(chosen)
		_anim = anim
		print("MODEL playing animation: ", chosen)
	else:
		push_warning("Could not select a run animation. Check the MODEL animations output.")


func _set_run_animation_active(active: bool) -> void:
	if _anim != null:
		if active:
			# Keep the ninja's stride cadence aligned with the faster movement.
			_anim.speed_scale = clampf(_current_run_speed / MOVE_SPEED, 0.65, 2.0)
		else:
			_anim.speed_scale = 0.0


func _create_runner_markings() -> void:
	# Resolve Level from the active scene first. The Player scene is instanced
	# under Level, but _ready() order can vary while nested scenes initialize.
	var scene := get_tree().current_scene
	var level := scene.get_node_or_null("Level") as Node3D if scene != null else null
	if level == null:
		level = get_parent() as Node3D
	if level == null:
		push_error("GRAPH GRID: cannot create markings because Level was not found.")
		return
	_create_runner_markings_for_level(level)


func _create_runner_markings_for_level(level: Node3D) -> void:
	if level.get_node_or_null(MARKINGS_NODE_NAME) != null:
		print("GRAPH GRID: GeneratedRunnerMarkings already exists; skipping duplicate generation.")
		return

	var root := Node3D.new()
	root.name = MARKINGS_NODE_NAME
	root.visible = true
	level.add_child(root)
	_create_track_panel_batches(root)
	var face_count := root.get_child_count()
	if face_count != 4:
		push_error("GRAPH GRID: expected 4 face meshes, generated %d." % face_count)
	else:
		print("GRAPH GRID READY: GeneratedRunnerMarkings under %s with Floor, Ceiling, LeftWall and RightWall meshes." % level.get_path())


func _create_track_panel_batches(root: Node3D) -> void:
	# A restrained graph-paper grid made from actual mesh strips. Each cell is
	# 2 m x 2 m; the 10 m major lines and 20 m accents preserve readability
	# down the long perspective view without creating dense visual noise.
	var grid_material := StandardMaterial3D.new()
	grid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	grid_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	grid_material.vertex_color_use_as_albedo = true
	grid_material.albedo_color = Color.WHITE
	grid_material.roughness = 1.0

	_add_box_grid_surface(root, "Floor_BoxGrid", Vector3(0.0, 0.025, 745.0),
		Vector3.RIGHT, Vector3.FORWARD, Vector3.UP, -5.0, 5.0, -755.0, 755.0, grid_material)
	_add_box_grid_surface(root, "Ceiling_BoxGrid", Vector3(0.0, 9.975, 745.0),
		Vector3.RIGHT, Vector3.FORWARD, Vector3.DOWN, -5.0, 5.0, -755.0, 755.0, grid_material)
	_add_box_grid_surface(root, "LeftWall_BoxGrid", Vector3(4.975, 5.0, 745.0),
		Vector3.UP, Vector3.FORWARD, Vector3.LEFT, -5.0, 5.0, -755.0, 755.0, grid_material)
	_add_box_grid_surface(root, "RightWall_BoxGrid", Vector3(-4.975, 5.0, 745.0),
		Vector3.UP, Vector3.FORWARD, Vector3.RIGHT, -5.0, 5.0, -755.0, 755.0, grid_material)


func _get_grid_line_style(line_index: int, total_cells: int) -> Dictionary:
	# End borders are major lines. Every fifth cell is a stronger cyan line;
	# every tenth cell gets a muted violet accent. Minor lines stay subtle.
	if line_index == 0 or line_index == total_cells:
		return {"color": Color(0.060, 0.24, 0.31, 1.0), "width": 0.040}
	if line_index % GRID_ACCENT_EVERY_CELLS == 0:
		return {"color": Color(0.17, 0.13, 0.27, 1.0), "width": 0.050}
	if line_index % GRID_MAJOR_EVERY_CELLS == 0:
		return {"color": Color(0.060, 0.24, 0.31, 1.0), "width": 0.036}
	return {"color": Color(0.035, 0.10, 0.13, 1.0), "width": 0.020}


func _add_box_grid_surface(parent: Node3D, node_name: String, origin: Vector3,
		u_axis: Vector3, v_axis: Vector3, normal: Vector3,
		u_min: float, u_max: float, v_min: float, v_max: float,
		grid_material: StandardMaterial3D) -> void:
	var vertices: Array[Vector3] = []
	var normals: Array[Vector3] = []
	var colors: Array[Color] = []
	var indices: Array[int] = []
	var u_cell_count: int = int(round((u_max - u_min) / GRID_CELL_SIZE))
	var v_cell_count: int = int(round((v_max - v_min) / GRID_CELL_SIZE))

	# Longitudinal lines divide the face into 2 m-wide lanes.
	for line_index in range(u_cell_count + 1):
		var u_coord: float = u_min + float(line_index) * GRID_CELL_SIZE
		var style: Dictionary = _get_grid_line_style(line_index, u_cell_count)
		var line_width: float = float(style["width"])
		var line_color: Color = style["color"]
		_append_grid_quad(vertices, normals, colors, indices,
			origin + u_axis * (u_coord - line_width * 0.5) + v_axis * v_min,
			origin + u_axis * (u_coord + line_width * 0.5) + v_axis * v_min,
			origin + u_axis * (u_coord + line_width * 0.5) + v_axis * v_max,
			origin + u_axis * (u_coord - line_width * 0.5) + v_axis * v_max,
			normal, line_color)

	# Cross-lines close 2 m x 2 m graph cells along the 1500 m track.
	for line_index in range(v_cell_count + 1):
		var v_coord: float = v_min + float(line_index) * GRID_CELL_SIZE
		var style: Dictionary = _get_grid_line_style(line_index, v_cell_count)
		var line_width: float = float(style["width"])
		var line_color: Color = style["color"]
		_append_grid_quad(vertices, normals, colors, indices,
			origin + u_axis * u_min + v_axis * (v_coord - line_width * 0.5),
			origin + u_axis * u_max + v_axis * (v_coord - line_width * 0.5),
			origin + u_axis * u_max + v_axis * (v_coord + line_width * 0.5),
			origin + u_axis * u_min + v_axis * (v_coord + line_width * 0.5),
			normal, line_color)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(vertices)
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(normals)
	arrays[Mesh.ARRAY_COLOR] = PackedColorArray(colors)
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(indices)
	var grid_mesh := ArrayMesh.new()
	grid_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	grid_mesh.surface_set_material(0, grid_material)

	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = grid_mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)

func _append_grid_quad(vertices: Array[Vector3], normals: Array[Vector3],
		colors: Array[Color], indices: Array[int], p0: Vector3, p1: Vector3,
		p2: Vector3, p3: Vector3, normal: Vector3, color: Color) -> void:
	var base_index: int = vertices.size()
	vertices.append(p0)
	vertices.append(p1)
	vertices.append(p2)
	vertices.append(p3)
	for _i in range(4):
		normals.append(normal)
		colors.append(color)
	indices.append(base_index)
	indices.append(base_index + 1)
	indices.append(base_index + 2)
	indices.append(base_index)
	indices.append(base_index + 2)
	indices.append(base_index + 3)


func _sector_index_for_z(z_value: float) -> int:
	# Checkpoints respawn the player 5 m before their marker. Shifting the
	# logical sector boundary by the same amount keeps the HUD/zone state stable
	# after a checkpoint respawn instead of briefly reverting to the prior zone.
	var adjusted_z: float = maxf(0.0, z_value + 5.0)
	return clampi(int(floor(adjusted_z / SECTOR_LENGTH)), 0, SECTOR_COUNT - 1)


func _sector_name(sector: int) -> String:
	match clampi(sector, 0, SECTOR_COUNT - 1):
		0: return "TRAINING ZONE"
		1: return "LASER MATRIX"
		2: return "MECHANICAL SECTOR"
		3: return "REACTOR CORE"
		4: return "FINAL GAUNTLET"
	return "TRAINING ZONE"


func _sector_subtitle(sector: int) -> String:
	match clampi(sector, 0, SECTOR_COUNT - 1):
		0: return "Learn the route. Read the hazards. Master the flip."
		1: return "Synchronized laser sweeps cross the four surfaces."
		2: return "Heavy pistons and rotating machinery control the lanes."
		3: return "Energy mines and enemy fire destabilize the reactor route."
		4: return "Every hazard family returns. Keep moving and reach the core."
	return "Stay alert, ninja."


func _sector_color(sector: int) -> Color:
	match clampi(sector, 0, SECTOR_COUNT - 1):
		0: return Color(0.12, 0.48, 0.58)
		1: return Color(0.12, 0.39, 0.78)
		2: return Color(0.78, 0.40, 0.12)
		3: return Color(0.52, 0.28, 0.78)
		4: return Color(0.82, 0.20, 0.25)
	return Color(0.12, 0.48, 0.58)


func _update_sector_progress(force_announce: bool = false) -> void:
	var next_sector: int = _sector_index_for_z(global_position.z)
	if next_sector == _sector_index:
		return
	_sector_index = next_sector
	print("SECTOR %02d ENTERED: %s | z=%.1f" % [_sector_index + 1, _sector_name(_sector_index), global_position.z])
	if _game_started or force_announce:
		_show_sector_announcement(_sector_index)


func _show_sector_announcement(sector: int) -> void:
	if _sector_banner_label == null or _sector_subtitle_label == null:
		return
	_sector_banner_label.text = "SECTOR %02d  //  %s" % [sector + 1, _sector_name(sector)]
	_sector_subtitle_label.text = _sector_subtitle(sector)
	var accent: Color = _sector_color(sector)
	_sector_banner_label.add_theme_color_override("font_color", accent.lightened(0.20))
	_sector_banner_timer = 3.2
	_sector_banner_label.visible = true
	_sector_subtitle_label.visible = true
	_sector_banner_label.modulate.a = 1.0
	_sector_subtitle_label.modulate.a = 1.0


func _create_sector_gates(level: Node3D) -> void:
	var old_root := level.get_node_or_null("GeneratedSectorGates")
	if old_root != null:
		old_root.queue_free()
	var root := Node3D.new()
	root.name = "GeneratedSectorGates"
	level.add_child(root)
	for sector in range(SECTOR_COUNT):
		var gate_z: float = float(sector) * SECTOR_LENGTH + 8.0
		var accent: Color = _sector_color(sector)
		var material := StandardMaterial3D.new()
		material.albedo_color = accent.darkened(0.28)
		material.metallic = 0.68
		material.roughness = 0.34
		material.emission_enabled = true
		material.emission = accent
		material.emission_energy_multiplier = 0.65
		var gate := Node3D.new()
		gate.name = "SectorGate_%02d_%s" % [sector + 1, _sector_name(sector).replace(" ", "_")]
		gate.position.z = gate_z
		root.add_child(gate)
		_add_sector_gate_bar(gate, "LeftPillar", Vector3(0.16, 9.5, 0.16), Vector3(-4.82, 5.0, 0.0), material)
		_add_sector_gate_bar(gate, "RightPillar", Vector3(0.16, 9.5, 0.16), Vector3(4.82, 5.0, 0.0), material)
		_add_sector_gate_bar(gate, "UpperBeam", Vector3(9.6, 0.16, 0.16), Vector3(0.0, 9.76, 0.0), material)
		_add_sector_gate_bar(gate, "LowerBeam", Vector3(9.6, 0.16, 0.16), Vector3(0.0, 0.24, 0.0), material)
		# A pair of short signal blocks makes the zone identity visible before the arch.
		_add_sector_gate_bar(gate, "SignalLeft", Vector3(0.48, 0.22, 0.12), Vector3(-3.85, 8.85, -0.12), material)
		_add_sector_gate_bar(gate, "SignalRight", Vector3(0.48, 0.22, 0.12), Vector3(3.85, 8.85, -0.12), material)
	print("SECTOR GATES: generated %d themed entry arches." % SECTOR_COUNT)


func _add_sector_gate_bar(parent: Node3D, node_name: String, size: Vector3,
		bar_position: Vector3, material: Material) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = bar_position
	mesh_instance.material_override = material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh_instance)


func _add_energy_shard(root: Node3D, index: int, shard_position: Vector3, accent: Color) -> void:
	var shard := Area3D.new()
	shard.name = "EnergyShard_%02d" % index
	shard.collision_layer = 0
	shard.collision_mask = 1
	shard.monitoring = true
	shard.monitorable = false
	shard.position = shard_position
	shard.set_meta("collected", false)
	shard.set_meta("spin_speed", 1.15 + float(index) * 0.08)
	shard.add_to_group("rotating_hazards")
	root.add_child(shard)
	shard.body_entered.connect(_on_energy_shard_collected.bind(shard))
	var shard_material := StandardMaterial3D.new()
	shard_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shard_material.albedo_color = accent.lightened(0.18)
	shard_material.emission_enabled = true
	shard_material.emission = accent
	shard_material.emission_energy_multiplier = 1.35
	var crystal := MeshInstance3D.new()
	crystal.name = "ShardCrystal"
	var crystal_mesh := BoxMesh.new()
	crystal_mesh.size = Vector3(0.36, 0.72, 0.24)
	crystal.mesh = crystal_mesh
	crystal.rotation_degrees = Vector3(0.0, 45.0, 45.0)
	crystal.material_override = shard_material
	shard.add_child(crystal)
	var ring := MeshInstance3D.new()
	ring.name = "ShardRing"
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.48
	ring_mesh.outer_radius = 0.55
	ring_mesh.rings = 20
	ring_mesh.ring_segments = 8
	ring.mesh = ring_mesh
	ring.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	ring.material_override = shard_material
	shard.add_child(ring)
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.95
	collision.shape = sphere
	shard.add_child(collision)


func _reset_energy_shards() -> void:
	var scene := get_tree().current_scene
	var level := scene.get_node_or_null("Level") as Node3D if scene != null else null
	if level == null:
		return
	var hazard_root := level.get_node_or_null(OBSTACLE_ROOT_NAME) as Node3D
	if hazard_root == null:
		return
	for child in hazard_root.get_children():
		if child is Area3D and str(child.name).begins_with("EnergyShard_"):
			var shard := child as Area3D
			shard.set_meta("collected", false)
			shard.monitoring = true
			shard.visible = true


func _on_energy_shard_collected(body: Node3D, shard: Area3D) -> void:
	if body != self or not is_instance_valid(shard) or bool(shard.get_meta("collected", false)):
		return
	shard.set_meta("collected", true)
	shard.monitoring = false
	_stamina = minf(MAX_STAMINA, _stamina + 30.0)
	if _boost_locked and _stamina >= 30.0:
		_boost_locked = false
	_bonus_score += 250
	_score += 250
	if _score > _best_score:
		_best_score = _score
		_save_best_score()
	_spawn_pulse_effect(_sector_color(_sector_index), 1.45)
	_play_sound("checkpoint")
	print("ENERGY SHARD %s collected | stamina=%.0f | score=%d" % [shard.name, _stamina, _score])
	shard.visible = false
	_update_hud()


func _create_obstacles() -> void:
	# Build visible, collidable hazards directly under Level so their world
	# positions remain fixed while the player and camera rotate around the shaft.
	var scene := get_tree().current_scene
	var level := scene.get_node_or_null("Level") as Node3D if scene != null else null
	if level == null:
		level = get_parent() as Node3D
	if level == null:
		push_error("Cannot create hazards: Level node was not found.")
		return

	# Generate the grid from the same deferred setup path that successfully
	# creates GeneratedHazards. This guarantees both visual systems use the
	# exact same resolved Level node.
	_create_runner_markings_for_level(level)
	_create_sector_gates(level)

	var old_root := level.get_node_or_null(OBSTACLE_ROOT_NAME)
	if old_root != null:
		old_root.queue_free()

	var root := Node3D.new()
	root.name = OBSTACLE_ROOT_NAME
	root.visible = true
	level.add_child(root)

	var spike_material := StandardMaterial3D.new()
	spike_material.albedo_color = Color(1.0, 0.025, 0.06)
	spike_material.emission_enabled = true
	spike_material.emission = Color(1.0, 0.0, 0.025)
	spike_material.emission_energy_multiplier = 2.2
	spike_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var spike_base_material := StandardMaterial3D.new()
	spike_base_material.albedo_color = Color(0.12, 0.16, 0.23)
	spike_base_material.metallic = 0.7
	spike_base_material.roughness = 0.3

	var laser_material := StandardMaterial3D.new()
	laser_material.albedo_color = Color(1.0, 0.32, 0.025)
	laser_material.emission_enabled = true
	laser_material.emission = Color(1.0, 0.12, 0.01)
	laser_material.emission_energy_multiplier = 4.0
	laser_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var laser_core_material := StandardMaterial3D.new()
	laser_core_material.albedo_color = Color(1.0, 0.88, 0.55)
	laser_core_material.emission_enabled = true
	laser_core_material.emission = Color(1.0, 0.55, 0.12)
	laser_core_material.emission_energy_multiplier = 5.0
	laser_core_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Each spike is attached to one of the four running surfaces. Surface IDs:
	# 0=floor, 1=+X wall, 2=ceiling, 3=-X wall.
	var spikes: Array[Dictionary] = [
		{"z": 18.0, "surface": 0, "lane": 0},
		{"z": 48.0, "surface": 0, "lane": 2},
		{"z": 78.0, "surface": 1, "lane": 1},
		{"z": 108.0, "surface": 0, "lane": 1},
		{"z": 138.0, "surface": 2, "lane": 2},
		{"z": 168.0, "surface": 3, "lane": 0}
	]

	# Sector-aware spike lanes. The training area is deliberately spacious;
	# later sectors change both spacing and surface sequence instead of repeating
	# one identical obstacle rhythm for the entire 1500 m course.
	var generated_spike_z: float = 190.0
	var generated_spike_index: int = 0
	while generated_spike_z < FINISH_Z - 22.0:
		var spike_sector: int = _sector_index_for_z(generated_spike_z)
		var spike_surface: int = generated_spike_index % 4
		var spike_lane: int = (generated_spike_index * 2 + 1) % 3
		var spike_step: float = 27.0
		match spike_sector:
			0:
				spike_step = 28.0 if generated_spike_index % 2 == 0 else 31.0
				spike_surface = [0, 0, 1, 0, 2, 0, 3][generated_spike_index % 7]
				spike_lane = [0, 2, 1, 0, 2, 1, 2][generated_spike_index % 7]
			1:
				spike_step = 30.0 if generated_spike_index % 2 == 0 else 33.0
				spike_surface = [0, 2, 1, 3][generated_spike_index % 4]
			2:
				spike_step = 21.0 if generated_spike_index % 3 == 0 else 24.0
				spike_surface = (generated_spike_index * 3 + 1) % 4
				spike_lane = [0, 2, 0, 1, 2, 1][generated_spike_index % 6]
			3:
				spike_step = 24.0 if generated_spike_index % 2 == 0 else 27.0
				spike_surface = [2, 1, 0, 3, 2, 0, 1][generated_spike_index % 7]
			4:
				spike_step = 19.0 if generated_spike_index % 3 == 0 else 22.0
				spike_surface = (generated_spike_index * 3 + 2) % 4
				spike_lane = [0, 2, 1, 2, 0, 1][generated_spike_index % 6]
		spikes.append({"z": generated_spike_z, "surface": spike_surface, "lane": spike_lane})
		generated_spike_index += 1
		generated_spike_z += spike_step

	for i in range(spikes.size()):
		var data: Dictionary = spikes[i]
		var surface_id := int(data["surface"])
		var lane := int(data["lane"])
		var z_pos := float(data["z"])
		var surface_position := Vector3.ZERO
		var inward_normal := Vector3.UP
		match surface_id:
			0:
				surface_position = Vector3([-2.8, 0.0, 2.8][lane], 0.01, z_pos)
				inward_normal = Vector3.UP
			1:
				surface_position = Vector3(4.99, [2.5, 5.0, 7.5][lane], z_pos)
				inward_normal = Vector3.LEFT
			2:
				surface_position = Vector3([-2.8, 0.0, 2.8][lane], 9.99, z_pos)
				inward_normal = Vector3.DOWN
			3:
				surface_position = Vector3(-4.99, [2.5, 5.0, 7.5][lane], z_pos)
				inward_normal = Vector3.RIGHT
		# A few spikes slide along their current surface to add timing challenges.
		var spike_sector_for_hazard: int = _sector_index_for_z(z_pos)
		var moving_spike: bool = false
		match spike_sector_for_hazard:
			0: moving_spike = i % 7 == 4
			1: moving_spike = i % 4 == 2
			2: moving_spike = i % 3 == 1
			3: moving_spike = i % 3 != 0
			4: moving_spike = i % 2 == 0
		var spike_motion_axis: Vector3 = Vector3.RIGHT if surface_id == 0 or surface_id == 2 else Vector3.UP
		var spike_scale: float = lerpf(1.35, 2.25, clampf(z_pos / FINISH_Z, 0.0, 1.0))
		_add_spike_hazard(
			root, i + 1, surface_position, inward_normal, spike_material, spike_base_material,
			spike_motion_axis if moving_spike else Vector3.ZERO,
			1.25 + 0.45 * clampf(z_pos / FINISH_Z, 0.0, 1.0) if moving_spike else 0.0,
			1.25 + float(i % 3) * 0.18,
			float(i) * 0.83,
			spike_scale
		)

	# Laser gates are deliberately spaced between spike sections. They span
	# the usable width of their surface, making a jump or gravity flip useful.
	var lasers: Array[Dictionary] = [
		{"z": 36.0, "surface": 0},
		{"z": 92.0, "surface": 1},
		{"z": 154.0, "surface": 2},
		{"z": 220.0, "surface": 3}
	]
	var generated_laser_z: float = 259.0
	var generated_laser_index: int = 0
	while generated_laser_z < FINISH_Z - 18.0:
		var laser_sector: int = _sector_index_for_z(generated_laser_z)
		var laser_surface: int = (generated_laser_index + 1) % 4
		var laser_step: float = 52.0
		match laser_sector:
			0:
				laser_step = 52.0 if generated_laser_index % 2 == 0 else 56.0
				laser_surface = [0, 1, 0, 2, 0, 3][generated_laser_index % 6]
			1:
				laser_step = 28.0 if generated_laser_index % 2 == 0 else 32.0
				laser_surface = [0, 1, 2, 3][generated_laser_index % 4]
			2:
				laser_step = 47.0 if generated_laser_index % 2 == 0 else 50.0
				laser_surface = (generated_laser_index * 3 + 2) % 4
			3:
				laser_step = 35.0 if generated_laser_index % 2 == 0 else 39.0
				laser_surface = [2, 1, 3, 0][generated_laser_index % 4]
			4:
				laser_step = 25.0 if generated_laser_index % 2 == 0 else 29.0
				laser_surface = [0, 2, 1, 3, 0, 3][generated_laser_index % 6]
		lasers.append({"z": generated_laser_z, "surface": laser_surface})
		generated_laser_index += 1
		generated_laser_z += laser_step

	for i in range(lasers.size()):
		var data: Dictionary = lasers[i]
		var surface_id := int(data["surface"])
		var z_pos := float(data["z"])
		var surface_position := Vector3.ZERO
		var inward_normal := Vector3.UP
		match surface_id:
			0:
				surface_position = Vector3(0.0, 0.01, z_pos)
				inward_normal = Vector3.UP
			1:
				surface_position = Vector3(4.99, 5.0, z_pos)
				inward_normal = Vector3.LEFT
			2:
				surface_position = Vector3(0.0, 9.99, z_pos)
				inward_normal = Vector3.DOWN
			3:
				surface_position = Vector3(-4.99, 5.0, z_pos)
				inward_normal = Vector3.RIGHT
		# Two gates sweep across the playable surface instead of moving along +Z.
		# Floor/ceiling gates slide across X; wall gates slide vertically along Y.
		# Three out of every four gates sweep. Floor/ceiling gates travel in X
		# and bob in Y; wall gates travel in Y and drift in X.
		var laser_sector_for_hazard: int = _sector_index_for_z(z_pos)
		var moving_laser: bool = laser_sector_for_hazard == 1 or laser_sector_for_hazard >= 3 or i % 4 != 0
		var laser_motion_axis: Vector3 = Vector3.UP if surface_id == 1 or surface_id == 3 else Vector3.RIGHT
		var laser_secondary_axis: Vector3 = Vector3.RIGHT if surface_id == 1 or surface_id == 3 else Vector3.UP
		var laser_motion_amplitude: float = 1.55
		var laser_motion_speed: float = 1.15
		match laser_sector_for_hazard:
			1:
				laser_motion_amplitude = 2.10
				laser_motion_speed = 1.35
			2:
				laser_motion_amplitude = 1.75
				laser_motion_speed = 1.10
			3:
				laser_motion_amplitude = 2.25
				laser_motion_speed = 1.45
			4:
				laser_motion_amplitude = 2.45
				laser_motion_speed = 1.60
		var laser_scale: float = lerpf(1.0, 1.85, clampf(z_pos / FINISH_Z, 0.0, 1.0))
		_add_laser_hazard(
			root, i + 1, surface_position, inward_normal, laser_material, laser_core_material,
			laser_motion_axis if moving_laser else Vector3.ZERO,
			laser_motion_amplitude if moving_laser else 0.0,
			laser_motion_speed if moving_laser else 0.0,
			float(i) * 1.7,
			laser_scale,
			laser_secondary_axis if moving_laser else Vector3.ZERO,
			0.55 if moving_laser else 0.0,
			1.65 if moving_laser else 0.0,
			float(i) * 0.9
		)

	# New obstacle families break up the spike/laser rhythm: heavy piston
	# crushers, rotating triple-blade fans, and floating energy mines.
	var special_obstacles: Array[Dictionary] = [
		# TRAINING ZONE: one large, clearly telegraphed introduction.
		{"type": "crusher", "z": 245.0, "surface": 0, "lane": 1},
		# LASER MATRIX: laser density is the main challenge; one fan guards the exit.
		{"type": "rotor", "z": 565.0, "surface": 2, "lane": 1},
		# MECHANICAL SECTOR: alternating crushers and rotating machinery.
		{"type": "crusher", "z": 625.0, "surface": 0, "lane": 1},
		{"type": "rotor", "z": 685.0, "surface": 1, "lane": 1},
		{"type": "crusher", "z": 745.0, "surface": 2, "lane": 1},
		{"type": "rotor", "z": 805.0, "surface": 3, "lane": 1},
		{"type": "crusher", "z": 865.0, "surface": 0, "lane": 0},
		# REACTOR CORE: volatile mines and machinery mixed with projectile pressure.
		{"type": "mine", "z": 925.0, "surface": 0, "lane": 2},
		{"type": "mine", "z": 985.0, "surface": 1, "lane": 0},
		{"type": "rotor", "z": 1045.0, "surface": 2, "lane": 1},
		{"type": "mine", "z": 1105.0, "surface": 3, "lane": 2},
		{"type": "crusher", "z": 1165.0, "surface": 0, "lane": 1},
		# FINAL GAUNTLET: combined hazard families, with a short but fair rhythm.
		{"type": "crusher", "z": 1225.0, "surface": 0, "lane": 1},
		{"type": "rotor", "z": 1270.0, "surface": 1, "lane": 1},
		{"type": "mine", "z": 1315.0, "surface": 2, "lane": 0},
		{"type": "rotor", "z": 1360.0, "surface": 3, "lane": 1},
		{"type": "crusher", "z": 1405.0, "surface": 0, "lane": 1},
		{"type": "mine", "z": 1450.0, "surface": 2, "lane": 2}
	]
	for i in range(special_obstacles.size()):
		var data: Dictionary = special_obstacles[i]
		var special_surface_id: int = int(data["surface"])
		var special_lane: int = int(data["lane"])
		var special_z: float = float(data["z"])
		var special_position: Vector3 = Vector3.ZERO
		var special_normal: Vector3 = Vector3.UP
		match special_surface_id:
			0:
				special_position = Vector3([-2.8, 0.0, 2.8][special_lane], 0.01, special_z)
				special_normal = Vector3.UP
			1:
				special_position = Vector3(4.99, [2.5, 5.0, 7.5][special_lane], special_z)
				special_normal = Vector3.LEFT
			2:
				special_position = Vector3([-2.8, 0.0, 2.8][special_lane], 9.99, special_z)
				special_normal = Vector3.DOWN
			3:
				special_position = Vector3(-4.99, [2.5, 5.0, 7.5][special_lane], special_z)
				special_normal = Vector3.RIGHT
		var special_progress: float = clampf(special_z / FINISH_Z, 0.0, 1.0)
		var special_sector: int = _sector_index_for_z(special_z)
		match str(data["type"]):
			"crusher":
				var crusher_scale: float = 1.05 + special_progress * 0.28
				var crusher_travel: float = 1.10 + special_progress * 0.45
				if special_sector == 4:
					crusher_scale += 0.10
					crusher_travel += 0.20
				_add_crusher_hazard(root, i + 1, special_position, special_normal,
					crusher_scale, special_normal, crusher_travel, 1.25 + special_progress * 0.25, float(i) * 1.1)
			"rotor":
				var rotor_speed: float = 1.05 + special_progress * 0.45
				if special_sector >= 3:
					rotor_speed += 0.18
				_add_rotating_blade_hazard(root, i + 1, special_position, special_normal, 1.0 + special_progress * 0.25, rotor_speed)
			"mine":
				_add_energy_mine_hazard(root, i + 1, special_position, special_normal, 1.0 + special_progress * 0.25)

	# Optional energy shards reward exploration and restore boost stamina. Each
	# sector contains one shard on a different surface, so gravity switching
	# becomes a route choice rather than only an emergency response.
	var shard_positions: Array[Vector3] = [
		Vector3(2.8, 0.82, 180.0),
		Vector3(4.12, 7.4, 500.0),
		Vector3(-2.8, 9.15, 820.0),
		Vector3(-4.12, 2.6, 1120.0),
		Vector3(0.0, 0.82, 1375.0)
	]
	for shard_index in range(shard_positions.size()):
		_add_energy_shard(root, shard_index + 1, shard_positions[shard_index], _sector_color(shard_index))

	_create_boss_encounter(level)
	print("HAZARDS: created %d spikes, %d laser gates, %d special obstacles and %d energy shards across %.0f m." % [spikes.size(), lasers.size(), special_obstacles.size(), shard_positions.size(), FINISH_Z])




func _create_boss_encounter(level: Node3D) -> void:
	var previous := level.get_node_or_null("GeneratedTowerGuardian")
	if previous != null:
		previous.queue_free()
	_boss_encounter_root = Node3D.new()
	_boss_encounter_root.name = "GeneratedTowerGuardian"
	level.add_child(_boss_encounter_root)

	_boss_visual_root = Node3D.new()
	_boss_visual_root.name = "TowerGuardianVisual"
	_boss_visual_root.position = Vector3(0.0, 5.0, 1485.0)
	_boss_encounter_root.add_child(_boss_visual_root)
	_boss_visual_root.visible = false

	var armour := _make_guardian_material(Color(0.075, 0.12, 0.20), Color(0.10, 0.28, 0.42), 0.82)
	var trim := _make_guardian_material(Color(0.16, 0.22, 0.31), Color(0.08, 0.42, 0.62), 1.15)
	var core_material := _make_guardian_material(Color(0.08, 0.62, 0.78), Color(0.04, 0.82, 1.0), 2.2)
	var eye_material := _make_guardian_material(Color(0.95, 0.24, 0.12), Color(1.0, 0.08, 0.025), 2.0)

	_add_guardian_box(_boss_visual_root, "Torso", Vector3(3.0, 3.8, 1.55), Vector3(0.0, 0.0, 0.0), armour)
	_add_guardian_box(_boss_visual_root, "ChestPlate", Vector3(2.45, 2.55, 0.22), Vector3(0.0, 0.0, -0.88), trim)
	_add_guardian_box(_boss_visual_root, "LeftShoulder", Vector3(1.35, 2.05, 1.45), Vector3(-2.15, 0.42, 0.0), trim)
	_add_guardian_box(_boss_visual_root, "RightShoulder", Vector3(1.35, 2.05, 1.45), Vector3(2.15, 0.42, 0.0), trim)
	_add_guardian_box(_boss_visual_root, "LeftForearm", Vector3(0.92, 1.65, 1.15), Vector3(-3.18, -0.72, -0.05), armour)
	_add_guardian_box(_boss_visual_root, "RightForearm", Vector3(0.92, 1.65, 1.15), Vector3(3.18, -0.72, -0.05), armour)
	_add_guardian_sphere(_boss_visual_root, "Head", 0.82, Vector3(0.0, 2.35, -0.02), armour)
	_add_guardian_box(_boss_visual_root, "Visor", Vector3(1.35, 0.24, 0.18), Vector3(0.0, 2.42, -0.75), eye_material)
	_add_guardian_sphere(_boss_visual_root, "LeftEye", 0.13, Vector3(-0.38, 2.43, -0.86), eye_material)
	_add_guardian_sphere(_boss_visual_root, "RightEye", 0.13, Vector3(0.38, 2.43, -0.86), eye_material)
	_boss_core_visual = _add_guardian_sphere(_boss_visual_root, "ReactorCore", 0.62, Vector3(0.0, -0.12, -1.03), core_material)
	var core_ring := MeshInstance3D.new()
	core_ring.name = "ReactorCoreRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.78
	torus.outer_radius = 0.92
	torus.rings = 28
	torus.ring_segments = 10
	core_ring.mesh = torus
	core_ring.rotation.x = PI * 0.5
	core_ring.position = Vector3(0.0, -0.12, -1.02)
	core_ring.material_override = core_material
	_boss_visual_root.add_child(core_ring)
	_boss_visual_root.visible = false

	_boss_weakpoints_root = Node3D.new()
	_boss_weakpoints_root.name = "GuardianWeakpoints"
	_boss_encounter_root.add_child(_boss_weakpoints_root)
	_boss_weakpoints.clear()
	_add_boss_weakpoint(1, Vector3(0.0, 0.90, 1328.0), 0, Color(0.10, 0.82, 1.0))
	_add_boss_weakpoint(2, Vector3(4.15, 5.0, 1392.0), 1, Color(1.0, 0.48, 0.12))
	_add_boss_weakpoint(3, Vector3(0.0, 9.12, 1458.0), 2, Color(0.72, 0.35, 1.0))
	_reset_boss_encounter()
	print("BOSS: Tower Guardian created with three surface-specific core targets.")


func _make_guardian_material(base_color: Color, glow_color: Color, glow_energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = base_color
	material.metallic = 0.78
	material.roughness = 0.32
	material.emission_enabled = true
	material.emission = glow_color
	material.emission_energy_multiplier = glow_energy
	return material


func _add_guardian_box(parent: Node3D, node_name: String, size: Vector3, part_position: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = part_position
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance


func _add_guardian_sphere(parent: Node3D, node_name: String, radius: float, part_position: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 20
	mesh.rings = 12
	instance.mesh = mesh
	instance.position = part_position
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance


func _add_boss_weakpoint(phase_index: int, weakpoint_position: Vector3, surface_id: int, accent: Color) -> void:
	var area := Area3D.new()
	area.name = "GuardianCoreTarget_%02d" % phase_index
	area.position = weakpoint_position
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = false
	area.monitorable = false
	var sphere := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.65
	sphere.shape = shape
	area.add_child(sphere)
	area.body_entered.connect(_on_boss_weakpoint_body_entered.bind(phase_index, area))
	_boss_weakpoints_root.add_child(area)

	var orb := MeshInstance3D.new()
	orb.name = "CoreOrb"
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.95
	orb_mesh.height = 1.90
	orb_mesh.radial_segments = 32
	orb_mesh.rings = 16
	orb.mesh = orb_mesh
	var orb_material := _make_guardian_material(accent.darkened(0.16), accent, 2.8)
	orb.material_override = orb_material
	area.add_child(orb)

	var ring := MeshInstance3D.new()
	ring.name = "TargetRing"
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 1.16
	ring_mesh.outer_radius = 1.36
	ring_mesh.rings = 32
	ring_mesh.ring_segments = 12
	ring.mesh = ring_mesh
	if surface_id == 1:
		ring.rotation.z = PI * 0.5
	elif surface_id == 2:
		ring.rotation.x = PI
	ring.material_override = orb_material
	area.add_child(ring)

	var light := OmniLight3D.new()
	light.name = "TargetGlow"
	light.light_color = accent
	light.light_energy = 1.0
	light.omni_range = 6.0
	light.shadow_enabled = false
	area.add_child(light)
	_boss_weakpoints.append(area)


func _update_boss_encounter() -> void:
	if not _boss_started and global_position.z >= BOSS_START_Z:
		_boss_started = true
		_boss_visual_root.visible = true
		for weakpoint in _boss_weakpoints:
			if is_instance_valid(weakpoint) and not bool(weakpoint.get_meta("collected", false)):
				weakpoint.visible = true
				weakpoint.set_deferred("monitoring", true)
		_boss_announcement_label.text = "TOWER GUARDIAN // TARGET ACQUIRED"
		_boss_announcement_timer = 3.2
		_boss_announcement_label.visible = true
		_play_sound("warning")
		_screen_flash(Color(0.18, 0.55, 1.0), 0.28, 0.12)
		print("BOSS: Tower Guardian encounter started at z=%.1f." % global_position.z)
	_update_boss_hud()


func _update_boss_hud() -> void:
	if _boss_status_label == null or _boss_health_bar == null:
		return
	_boss_status_label.visible = _boss_started
	_boss_health_bar.visible = _boss_started
	if _boss_defeated:
		_boss_status_label.text = "GUARDIAN DEFEATED // FINISH UNLOCKED"
	else:
		var next_target: String = _next_boss_target_name()
		var distance_to_core: float = _next_boss_target_distance()
		_boss_status_label.text = "GUARDIAN | CORES %d/%d | NEXT: %s | CORE IN %.0f m" % [_boss_health, BOSS_MAX_HEALTH, next_target, distance_to_core]
	_boss_health_bar.value = _boss_health


func _next_boss_target_distance() -> float:
	var target_z: float = BOSS_GATE_Z
	match _boss_health:
		3:
			target_z = 1328.0
		2:
			target_z = 1392.0
		1:
			target_z = 1458.0
	return maxf(0.0, target_z - global_position.z)


func _next_boss_target_name() -> String:
	match _boss_health:
		3:
			return "FLOOR"
		2:
			return "LEFT WALL (A+Q)"
		1:
			return "CEILING (A+Q)"
	return "COMPLETE"


func _on_boss_weakpoint_body_entered(body: Node3D, phase_index: int, weakpoint: Area3D) -> void:
	if body != self or _game_over or _finished or _boss_defeated or not _boss_started:
		return
	if not is_instance_valid(weakpoint) or bool(weakpoint.get_meta("collected", false)):
		return
	weakpoint.set_meta("collected", true)
	weakpoint.set_deferred("monitoring", false)
	weakpoint.visible = false
	_boss_health = maxi(0, _boss_health - 1)
	_bonus_score += BOSS_CORE_REWARD
	_score += BOSS_CORE_REWARD
	_stamina = minf(MAX_STAMINA, _stamina + 18.0)
	if _boost_locked and _stamina >= 30.0:
		_boost_locked = false
	if _boss_health <= 0:
		_boss_defeated = true
		_boss_visual_root.visible = false
		_boss_announcement_label.text = "GUARDIAN CORE DESTROYED // TOWER UNLOCKED"
		_boss_announcement_timer = 3.0
		_play_sound("victory")
		_spawn_pulse_effect(Color(0.35, 0.95, 1.0), 4.2)
		_screen_flash(Color(0.10, 0.70, 1.0), 0.55, 0.24)
	else:
		_boss_announcement_label.text = "CORE PHASE %d CLEARED // %s CORE NEXT" % [phase_index, _next_boss_target_name()]
		_boss_announcement_timer = 2.4
		_play_sound("checkpoint")
		_spawn_pulse_effect(Color(0.25, 0.84, 1.0), 2.8)
		_screen_flash(Color(0.12, 0.72, 1.0), 0.24, 0.14)
	_boss_announcement_label.visible = true
	_update_boss_hud()
	_update_hud()
	print("BOSS: core phase %d hit; guardian integrity %d/%d." % [phase_index, _boss_health, BOSS_MAX_HEALTH])


func _reset_boss_encounter() -> void:
	_boss_health = BOSS_MAX_HEALTH
	_boss_started = false
	_boss_defeated = false
	_boss_announcement_timer = 0.0
	if is_instance_valid(_boss_visual_root):
		_boss_visual_root.visible = false
	for weakpoint in _boss_weakpoints:
		if is_instance_valid(weakpoint):
			weakpoint.set_meta("collected", false)
			weakpoint.visible = false
			weakpoint.set_deferred("monitoring", false)
	if _boss_status_label != null:
		_boss_status_label.visible = false
	if _boss_health_bar != null:
		_boss_health_bar.value = BOSS_MAX_HEALTH
		_boss_health_bar.visible = false
	if _boss_announcement_label != null:
		_boss_announcement_label.visible = false

func _add_spike_hazard(root: Node3D, index: int, surface_position: Vector3,
		inward_normal: Vector3, spike_material: Material, base_material: Material,
		motion_axis: Vector3 = Vector3.ZERO, motion_amplitude: float = 0.0,
		motion_speed: float = 0.0, motion_phase: float = 0.0, size_scale: float = 1.0) -> void:
	var area := Area3D.new()
	area.name = "StationarySpike_%02d" % index
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = true
	area.monitorable = false
	area.add_to_group("stationary_hazards")
	area.transform = Transform3D(Basis(Quaternion(Vector3.UP, inward_normal)), surface_position)
	root.add_child(area)
	area.body_entered.connect(_on_hazard_body_entered)

	# A short dark metal socket makes the spike read clearly against the shaft.
	var socket_mesh := MeshInstance3D.new()
	socket_mesh.name = "SpikeSocketMesh"
	var socket := BoxMesh.new()
	socket.size = Vector3(0.82, 0.10, 0.82) * size_scale
	socket_mesh.mesh = socket
	socket_mesh.position = Vector3(0.0, 0.055 * size_scale, 0.0)
	socket_mesh.material_override = base_material
	area.add_child(socket_mesh)

	var spike_mesh_instance := MeshInstance3D.new()
	spike_mesh_instance.name = "SpikeMesh"
	var spike := CylinderMesh.new()
	spike.top_radius = 0.035 * size_scale
	spike.bottom_radius = 0.36 * size_scale
	spike.height = 0.82 * size_scale
	spike.radial_segments = 8
	spike.rings = 2
	spike_mesh_instance.mesh = spike
	spike_mesh_instance.position = Vector3(0.0, 0.51 * size_scale, 0.0)
	spike_mesh_instance.material_override = spike_material
	spike_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	area.add_child(spike_mesh_instance)

	var collision_node := CollisionShape3D.new()
	collision_node.name = "SpikeCollision"
	var collision_shape := CylinderShape3D.new()
	collision_shape.radius = 0.36 * size_scale
	collision_shape.height = 0.82 * size_scale
	collision_node.shape = collision_shape
	collision_node.position = Vector3(0.0, 0.51 * size_scale, 0.0)
	area.add_child(collision_node)
	if motion_amplitude > 0.0 and motion_axis.length_squared() > 0.0:
		_configure_moving_hazard(area, motion_axis, motion_amplitude, motion_speed, motion_phase)


func _add_laser_hazard(root: Node3D, index: int, surface_position: Vector3,
		inward_normal: Vector3, laser_material: Material, core_material: Material,
		motion_axis: Vector3 = Vector3.ZERO, motion_amplitude: float = 0.0,
		motion_speed: float = 0.0, motion_phase: float = 0.0, size_scale: float = 1.0,
		secondary_axis: Vector3 = Vector3.ZERO, secondary_amplitude: float = 0.0,
		secondary_speed: float = 0.0, secondary_phase: float = 0.0) -> void:
	var area := Area3D.new()
	area.name = "LaserGate_%02d" % index
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = true
	area.monitorable = false
	area.add_to_group("stationary_hazards")
	area.transform = Transform3D(Basis(Quaternion(Vector3.UP, inward_normal)), surface_position)
	root.add_child(area)
	area.body_entered.connect(_on_hazard_body_entered)

	# The local X axis spans the surface: across X on floor/ceiling, and across
	# Y on either wall after the Area3D basis is aligned to the surface normal.
	var beam_mesh := MeshInstance3D.new()
	beam_mesh.name = "LaserBeamMesh"
	var beam := BoxMesh.new()
	beam.size = Vector3(8.6, 0.18 * size_scale, 0.22 * size_scale)
	beam_mesh.mesh = beam
	beam_mesh.position = Vector3(0.0, 0.20 * size_scale, 0.0)
	beam_mesh.material_override = laser_material
	beam_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	area.add_child(beam_mesh)

	var core_mesh := MeshInstance3D.new()
	core_mesh.name = "LaserCoreMesh"
	var core := BoxMesh.new()
	core.size = Vector3(8.6, 0.045 * size_scale, 0.06 * size_scale)
	core_mesh.mesh = core
	core_mesh.position = Vector3(0.0, 0.20 * size_scale, 0.0)
	core_mesh.material_override = core_material
	core_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	area.add_child(core_mesh)

	var collision_node := CollisionShape3D.new()
	collision_node.name = "LaserCollision"
	var collision_shape := BoxShape3D.new()
	collision_shape.size = Vector3(8.6, 0.24 * size_scale, 0.28 * size_scale)
	collision_node.shape = collision_shape
	collision_node.position = Vector3(0.0, 0.20 * size_scale, 0.0)
	area.add_child(collision_node)
	if motion_amplitude > 0.0 and motion_axis.length_squared() > 0.0:
		_configure_moving_hazard(area, motion_axis, motion_amplitude, motion_speed, motion_phase,
			secondary_axis, secondary_amplitude, secondary_speed, secondary_phase)


func _add_crusher_hazard(root: Node3D, index: int, surface_position: Vector3,
		inward_normal: Vector3, size_scale: float, motion_axis: Vector3,
		motion_amplitude: float, motion_speed: float, motion_phase: float) -> void:
	var area := Area3D.new()
	area.name = "PistonCrusher_%02d" % index
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = true
	area.monitorable = false
	area.add_to_group("stationary_hazards")
	area.transform = Transform3D(Basis(Quaternion(Vector3.UP, inward_normal)), surface_position)
	root.add_child(area)
	area.body_entered.connect(_on_hazard_body_entered)

	var base_mesh := MeshInstance3D.new()
	var base_cylinder := CylinderMesh.new()
	base_cylinder.top_radius = 1.45 * size_scale
	base_cylinder.bottom_radius = 1.58 * size_scale
	base_cylinder.height = 0.18
	base_mesh.mesh = base_cylinder
	base_mesh.position.y = 0.10
	var base_material := StandardMaterial3D.new()
	base_material.albedo_color = Color(0.035, 0.09, 0.16)
	base_material.metallic = 0.82
	base_material.roughness = 0.24
	base_mesh.material_override = base_material
	area.add_child(base_mesh)

	var crusher_mesh := MeshInstance3D.new()
	var crusher_box := BoxMesh.new()
	crusher_box.size = Vector3(2.8, 2.8, 2.5) * size_scale
	crusher_mesh.mesh = crusher_box
	crusher_mesh.position.y = 1.50 * size_scale
	var crusher_material := StandardMaterial3D.new()
	crusher_material.albedo_color = Color(0.15, 0.20, 0.29)
	crusher_material.metallic = 0.9
	crusher_material.roughness = 0.22
	crusher_material.emission_enabled = true
	crusher_material.emission = Color(0.95, 0.12, 0.025)
	crusher_material.emission_energy_multiplier = 0.95
	crusher_mesh.material_override = crusher_material
	area.add_child(crusher_mesh)

	var warning_strip := MeshInstance3D.new()
	var strip_box := BoxMesh.new()
	strip_box.size = Vector3(2.88, 0.12, 0.12) * size_scale
	warning_strip.mesh = strip_box
	warning_strip.position = Vector3(0.0, 1.50 * size_scale, 1.26 * size_scale)
	var strip_material := StandardMaterial3D.new()
	strip_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	strip_material.albedo_color = Color(1.0, 0.3, 0.025)
	strip_material.emission_enabled = true
	strip_material.emission = Color(1.0, 0.12, 0.0)
	strip_material.emission_energy_multiplier = 3.0
	warning_strip.material_override = strip_material
	area.add_child(warning_strip)

	var collision := CollisionShape3D.new()
	var collision_box := BoxShape3D.new()
	collision_box.size = Vector3(2.8, 2.8, 2.5) * size_scale
	collision.shape = collision_box
	collision.position.y = 1.50 * size_scale
	area.add_child(collision)
	_configure_moving_hazard(area, motion_axis, motion_amplitude, motion_speed, motion_phase)


func _add_rotating_blade_hazard(root: Node3D, index: int, surface_position: Vector3,
		inward_normal: Vector3, size_scale: float, spin_speed: float) -> void:
	var area := Area3D.new()
	area.name = "RotatingBladeFan_%02d" % index
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = true
	area.monitorable = false
	area.add_to_group("stationary_hazards")
	area.add_to_group("rotating_hazards")
	area.transform = Transform3D(Basis(Quaternion(Vector3.UP, inward_normal)), surface_position)
	area.set_meta("spin_speed", spin_speed)
	root.add_child(area)
	area.body_entered.connect(_on_hazard_body_entered)

	var hub := MeshInstance3D.new()
	var hub_mesh := SphereMesh.new()
	hub_mesh.radius = 0.58 * size_scale
	hub_mesh.height = 1.16 * size_scale
	hub.mesh = hub_mesh
	hub.position.y = 1.05 * size_scale
	var hub_material := StandardMaterial3D.new()
	hub_material.albedo_color = Color(0.04, 0.75, 1.0)
	hub_material.emission_enabled = true
	hub_material.emission = Color(0.0, 0.55, 1.0)
	hub_material.emission_energy_multiplier = 3.2
	hub_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hub.material_override = hub_material
	area.add_child(hub)

	var blade_material := StandardMaterial3D.new()
	blade_material.albedo_color = Color(0.17, 0.22, 0.31)
	blade_material.metallic = 0.88
	blade_material.roughness = 0.2
	blade_material.emission_enabled = true
	blade_material.emission = Color(0.45, 0.04, 0.9)
	blade_material.emission_energy_multiplier = 1.5
	for blade_index in range(3):
		var angle: float = float(blade_index) * TAU / 3.0
		var blade_mesh := MeshInstance3D.new()
		var blade_box := BoxMesh.new()
		blade_box.size = Vector3(2.35, 0.20, 0.62) * size_scale
		blade_mesh.mesh = blade_box
		var radial_offset := Vector3(cos(angle) * 1.08 * size_scale, 1.05 * size_scale, -sin(angle) * 1.08 * size_scale)
		blade_mesh.position = radial_offset
		blade_mesh.rotation.y = angle
		blade_mesh.material_override = blade_material
		area.add_child(blade_mesh)
		var blade_collision := CollisionShape3D.new()
		var blade_shape := BoxShape3D.new()
		blade_shape.size = Vector3(2.35, 0.24, 0.68) * size_scale
		blade_collision.shape = blade_shape
		blade_collision.position = radial_offset
		blade_collision.rotation.y = angle
		area.add_child(blade_collision)


func _add_energy_mine_hazard(root: Node3D, index: int, surface_position: Vector3,
		inward_normal: Vector3, size_scale: float) -> void:
	var area := Area3D.new()
	area.name = "FloatingEnergyMine_%02d" % index
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = true
	area.monitorable = false
	area.add_to_group("stationary_hazards")
	area.add_to_group("rotating_hazards")
	area.transform = Transform3D(Basis(Quaternion(Vector3.UP, inward_normal)), surface_position + inward_normal * 1.15)
	area.set_meta("spin_speed", 0.8 + 0.25 * size_scale)
	root.add_child(area)
	area.body_entered.connect(_on_hazard_body_entered)

	var orb := MeshInstance3D.new()
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.78 * size_scale
	orb_mesh.height = 1.56 * size_scale
	orb.mesh = orb_mesh
	var orb_material := StandardMaterial3D.new()
	orb_material.albedo_color = Color(0.08, 0.95, 0.76)
	orb_material.emission_enabled = true
	orb_material.emission = Color(0.0, 1.0, 0.62)
	orb_material.emission_energy_multiplier = 3.8
	orb_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	orb.material_override = orb_material
	area.add_child(orb)

	for ring_index in range(2):
		var ring := MeshInstance3D.new()
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 0.88 * size_scale
		ring_mesh.outer_radius = 1.02 * size_scale
		ring_mesh.rings = 24
		ring_mesh.ring_segments = 12
		ring.mesh = ring_mesh
		ring.rotation.x = PI * 0.5 * float(ring_index)
		var ring_material := StandardMaterial3D.new()
		ring_material.albedo_color = Color(0.18, 0.55, 1.0)
		ring_material.emission_enabled = true
		ring_material.emission = Color(0.0, 0.4, 1.0)
		ring_material.emission_energy_multiplier = 2.5
		ring.material_override = ring_material
		area.add_child(ring)

	var collision := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = 0.84 * size_scale
	collision.shape = sphere_shape
	area.add_child(collision)


func _configure_moving_hazard(area: Area3D, axis: Vector3, amplitude: float, speed: float, phase: float,
		secondary_axis: Vector3 = Vector3.ZERO, secondary_amplitude: float = 0.0,
		secondary_speed: float = 0.0, secondary_phase: float = 0.0) -> void:
	# Store original local position and motion settings as metadata.
	# The Player script animates these nodes every rendered frame.
	area.set_meta("motion_origin", area.position)
	area.set_meta("motion_axis", axis.normalized())
	area.set_meta("motion_amplitude", amplitude)
	area.set_meta("motion_speed", speed)
	area.set_meta("motion_phase", phase)
	if secondary_amplitude > 0.0 and secondary_axis.length_squared() > 0.0:
		area.set_meta("motion_axis_secondary", secondary_axis.normalized())
		area.set_meta("motion_amplitude_secondary", secondary_amplitude)
		area.set_meta("motion_speed_secondary", secondary_speed)
		area.set_meta("motion_phase_secondary", secondary_phase)
	area.name = "Moving_" + area.name
	area.add_to_group("moving_hazards")
	if OS.is_debug_build():
		print("MOVING HAZARD configured: %s axis=%s amplitude=%.2f speed=%.2f secondary=%s" % [
			area.name, str(axis.normalized()), amplitude, speed, str(secondary_axis.normalized()) if secondary_amplitude > 0.0 else "none"
		])

func _on_hazard_body_entered(body: Node3D) -> void:
	if body != self or _finished or _game_over:
		return
	_take_hit("hazard")


func _on_projectile_body_entered(body: Node3D, projectile: Area3D) -> void:
	if body != self or _finished or _game_over:
		return
	if is_instance_valid(projectile):
		projectile.queue_free()
	_take_hit("enemy projectile")


func _take_hit(reason: String) -> void:
	_clear_attack_warning()
	_lives -= 1
	print("HIT by %s | lives remaining: %d" % [reason, _lives])
	_spawn_pulse_effect(Color(1.0, 0.12, 0.18), 2.0)
	_screen_flash(Color(1.0, 0.025, 0.06), 0.28, 0.30)
	_play_sound("damage")
	if _lives <= 0:
		_play_sound("game_over")
		_game_over = true
		velocity = Vector3.ZERO
		_set_run_animation_active(false)
		if _game_over_banner:
			_game_over_banner.visible = false
		_show_menu("game_over")
		_update_hud()
		return
	_respawn(reason)


func _update_projectiles(delta: float) -> void:
	if _game_over or _finished:
		return

	# Telegraph first, then fire. Subtracting the warning duration from the
	# cooldown keeps the fire-to-fire cadence at the existing difficulty value.
	if _attack_warning_timer > 0.0:
		_attack_warning_timer = maxf(0.0, _attack_warning_timer - delta)
		if _attack_warning_timer <= 0.0:
			_fire_enemy_projectile_pattern()
			_projectile_cooldown = maxf(0.1, _current_projectile_interval() - ATTACK_WARNING_DURATION)
	else:
		_projectile_cooldown -= delta
		if _projectile_cooldown <= 0.0:
			_start_enemy_attack_warning()

	# The rapid-burst pattern fires three shots in quick succession.
	if _burst_shots_remaining > 0:
		_burst_shot_timer -= delta
		if _burst_shot_timer <= 0.0:
			_spawn_enemy_projectile(_burst_lane_offset)
			_burst_shots_remaining -= 1
			_burst_shot_timer = 0.16

	# Move each projectile toward the player, then clean up missed shots.
	if _projectile_root != null:
		for child in _projectile_root.get_children():
			if not child is Node3D:
				continue
			var projectile := child as Node3D
			# Keep the speed assigned at spawn; an in-flight shot never accelerates.
			var velocity_z: float = float(projectile.get_meta("velocity_z", -PROJECTILE_SPEED))
			projectile.position.z += velocity_z * delta
			if projectile.position.z < global_position.z - 12.0:
				projectile.queue_free()


func _difficulty_progress() -> float:
	# Returns a zone-weighted value for other systems that use a 0..1 difficulty.
	var sector: int = _sector_index_for_z(global_position.z)
	var local_progress: float = clampf((global_position.z - float(sector) * SECTOR_LENGTH) / SECTOR_LENGTH, 0.0, 1.0)
	return clampf((float(sector) + local_progress) / float(SECTOR_COUNT), 0.0, 1.0)


func _current_projectile_interval() -> float:
	if _boss_started and not _boss_defeated:
		var boss_phase: int = BOSS_MAX_HEALTH - _boss_health
		return 2.55 - float(boss_phase) * 0.20
	var sector: int = _sector_index_for_z(global_position.z)
	var local_progress: float = clampf((global_position.z - float(sector) * SECTOR_LENGTH) / SECTOR_LENGTH, 0.0, 1.0)
	var interval_starts: Array[float] = [4.5, 4.0, 3.65, 3.25, 2.95]
	var interval_ends: Array[float] = [4.0, 3.65, 3.25, 2.95, 2.55]
	return lerpf(interval_starts[sector], interval_ends[sector], local_progress)


func _current_projectile_speed() -> float:
	if _boss_started and not _boss_defeated:
		var boss_phase: int = BOSS_MAX_HEALTH - _boss_health
		return 12.0 + float(boss_phase) * 0.45
	var sector: int = _sector_index_for_z(global_position.z)
	var local_progress: float = clampf((global_position.z - float(sector) * SECTOR_LENGTH) / SECTOR_LENGTH, 0.0, 1.0)
	var speed_starts: Array[float] = [9.5, 10.0, 10.4, 10.8, 11.2]
	var speed_ends: Array[float] = [10.0, 10.4, 10.8, 11.2, 11.8]
	return lerpf(speed_starts[sector], speed_ends[sector], local_progress)


func _start_enemy_attack_warning() -> void:
	# Pick the exact lane(s) before showing the warning so the cue is honest:
	# the incoming shot will use the positions highlighted on the current surface.
	_clear_attack_warning()
	match _projectile_pattern_index:
		0:
			_attack_warning_lanes = [float([-1.8, 0.0, 1.8][randi_range(0, 2)])]
			_attack_warning_label.text = "INCOMING SHOT"
		1:
			_attack_warning_lanes = [float([-1.8, 0.0, 1.8][randi_range(0, 2)])]
			_attack_warning_label.text = "BURST INCOMING"
		2:
			_attack_warning_lanes = [-2.8, -1.4, 0.0, 1.4, 2.8]
			_attack_warning_label.text = "SPREAD INCOMING"

	if _boss_started and not _boss_defeated:
		_attack_warning_label.text = "GUARDIAN // " + _attack_warning_label.text
	_attack_warning_timer = ATTACK_WARNING_DURATION
	_attack_warning_elapsed = 0.0
	_attack_warning_label.visible = true
	_attack_warning_label.modulate.a = 1.0
	for lane_offset in _attack_warning_lanes:
		_create_attack_warning_marker(float(lane_offset))
	_play_sound("warning")
	_screen_flash(Color(0.0, 0.72, 1.0), 0.16, 0.10)
	print("ENEMY WARNING: %s | %.2f seconds" % [_attack_warning_label.text, ATTACK_WARNING_DURATION])


func _fire_enemy_projectile_pattern() -> void:
	# Fire using the lane selection that was shown during the warning phase.
	var firing_lanes: Array = _attack_warning_lanes.duplicate()
	if firing_lanes.is_empty():
		firing_lanes = [0.0]
	match _projectile_pattern_index:
		0:
			print("ENEMY PATTERN: cyan single shot")
			_spawn_enemy_projectile(float(firing_lanes[0]))
		1:
			print("ENEMY PATTERN: cyan rapid three-shot burst")
			_burst_lane_offset = float(firing_lanes[0])
			_burst_shots_remaining = 3
			_burst_shot_timer = 0.0
		2:
			print("ENEMY PATTERN: cyan five-lane spread")
			for lane_offset in firing_lanes:
				_spawn_enemy_projectile(float(lane_offset))

	_projectile_pattern_index = posmod(_projectile_pattern_index + 1, 3)
	_clear_attack_warning()


func _get_enemy_lane_position(lane_offset: float, ahead_distance: float) -> Vector3:
	# Shared lane calculation keeps each warning marker aligned with the shot.
	var lane_position := global_position
	lane_position.z = global_position.z + ahead_distance
	match posmod(_quarter_turns, 4):
		0: # floor
			lane_position.y = 0.72
			lane_position.x = clampf(global_position.x + lane_offset, -3.4, 3.4)
		1: # left wall
			lane_position.x = 4.25
			lane_position.y = clampf(global_position.y + lane_offset, 1.0, 9.0)
		2: # ceiling
			lane_position.y = 9.28
			lane_position.x = clampf(global_position.x + lane_offset, -3.4, 3.4)
		3: # right wall
			lane_position.x = -4.25
			lane_position.y = clampf(global_position.y + lane_offset, 1.0, 9.0)
	return lane_position


func _get_attack_warning_position(lane_offset: float) -> Vector3:
	# Place a glowing reticle on the player's active surface, eight metres ahead.
	var warning_position := global_position
	warning_position.z = global_position.z + ATTACK_WARNING_AHEAD
	match posmod(_quarter_turns, 4):
		0: # floor
			warning_position.y = 0.07
			warning_position.x = clampf(global_position.x + lane_offset, -3.4, 3.4)
		1: # left wall (inner face at x = +5)
			warning_position.x = 4.88
			warning_position.y = clampf(global_position.y + lane_offset, 1.0, 9.0)
		2: # ceiling (inner face at y = 10)
			warning_position.y = 9.88
			warning_position.x = clampf(global_position.x + lane_offset, -3.4, 3.4)
		3: # right wall (inner face at x = -5)
			warning_position.x = -4.88
			warning_position.y = clampf(global_position.y + lane_offset, 1.0, 9.0)
	return warning_position


func _create_attack_warning_marker(lane_offset: float) -> void:
	var scene := get_tree().current_scene
	var level := scene.get_node_or_null("Level") as Node3D if scene != null else null
	if level == null:
		level = get_parent() as Node3D
	if level == null:
		return
	if _attack_warning_root == null or not is_instance_valid(_attack_warning_root):
		_attack_warning_root = level.get_node_or_null("GeneratedAttackWarnings") as Node3D
		if _attack_warning_root == null:
			_attack_warning_root = Node3D.new()
			_attack_warning_root.name = "GeneratedAttackWarnings"
			level.add_child(_attack_warning_root)

	var marker := Node3D.new()
	marker.name = "CyanAttackTelegraph"
	marker.set_meta("lane_offset", lane_offset)
	_attack_warning_root.add_child(marker)
	marker.global_transform = Transform3D(Basis(SHAFT_AXIS, _roll), _get_attack_warning_position(lane_offset))

	var ring_mesh := MeshInstance3D.new()
	ring_mesh.name = "WarningRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.48
	torus.outer_radius = 0.60
	torus.rings = 24
	torus.ring_segments = 10
	ring_mesh.mesh = torus
	var ring_material := StandardMaterial3D.new()
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.albedo_color = Color(0.05, 0.82, 1.0, 0.88)
	ring_material.emission_enabled = true
	ring_material.emission = Color(0.0, 0.72, 1.0)
	ring_material.emission_energy_multiplier = 3.0
	ring_mesh.material_override = ring_material
	marker.add_child(ring_mesh)

	var center_mesh := MeshInstance3D.new()
	center_mesh.name = "WarningCore"
	var core_sphere := SphereMesh.new()
	core_sphere.radius = 0.10
	core_sphere.height = 0.20
	center_mesh.mesh = core_sphere
	var core_material := StandardMaterial3D.new()
	core_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_material.albedo_color = Color(0.5, 0.95, 1.0)
	core_material.emission_enabled = true
	core_material.emission = Color(0.1, 0.82, 1.0)
	core_material.emission_energy_multiplier = 4.0
	center_mesh.material_override = core_material
	marker.add_child(center_mesh)
	_attack_warning_markers.append(marker)


func _update_attack_warning_visuals(delta: float) -> void:
	if _attack_warning_timer <= 0.0:
		return
	_attack_warning_elapsed += delta
	var pulse: float = 0.88 + 0.15 * (0.5 + 0.5 * sin(_attack_warning_elapsed * 18.0))
	var glow: float = 2.4 + 1.8 * (0.5 + 0.5 * sin(_attack_warning_elapsed * 18.0))
	for marker in _attack_warning_markers:
		if not is_instance_valid(marker):
			continue
		var lane_offset: float = float(marker.get_meta("lane_offset", 0.0))
		# Track the active gravity surface and current player lane while the cue is visible.
		marker.global_transform = Transform3D(Basis(SHAFT_AXIS, _roll), _get_attack_warning_position(lane_offset))
		marker.scale = Vector3.ONE * pulse
		var ring_mesh := marker.get_node_or_null("WarningRing") as MeshInstance3D
		if ring_mesh != null and ring_mesh.material_override is StandardMaterial3D:
			(ring_mesh.material_override as StandardMaterial3D).emission_energy_multiplier = glow
	if _attack_warning_label != null:
		_attack_warning_label.modulate.a = 0.72 + 0.28 * (0.5 + 0.5 * sin(_attack_warning_elapsed * 20.0))


func _clear_attack_warning() -> void:
	_attack_warning_timer = 0.0
	_attack_warning_elapsed = 0.0
	_attack_warning_lanes.clear()
	for marker in _attack_warning_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	_attack_warning_markers.clear()
	if _attack_warning_label != null:
		_attack_warning_label.visible = false
		_attack_warning_label.modulate.a = 1.0


func _spawn_enemy_projectile(lane_offset: float = 999.0) -> void:
	var scene := get_tree().current_scene
	var level := scene.get_node_or_null("Level") as Node3D if scene != null else null
	if level == null:
		level = get_parent() as Node3D
	if level == null:
		return
	if _projectile_root == null or not is_instance_valid(_projectile_root):
		_projectile_root = level.get_node_or_null("GeneratedEnemyProjectiles") as Node3D
		if _projectile_root == null:
			_projectile_root = Node3D.new()
			_projectile_root.name = "GeneratedEnemyProjectiles"
			level.add_child(_projectile_root)

	# Shoot along -Z from ahead, aligned to the player's current running surface.
	# The lane is identical to the one highlighted by the warning reticle.
	var side_offset: float
	if is_equal_approx(lane_offset, 999.0):
		side_offset = float([-1.8, 0.0, 1.8][randi_range(0, 2)])
	else:
		side_offset = lane_offset
	var projectile_position := _get_enemy_lane_position(side_offset, PROJECTILE_SPAWN_AHEAD)

	var projectile := Area3D.new()
	projectile.name = "EnemyEnergyProjectile"
	projectile.collision_layer = 0
	projectile.collision_mask = 1
	projectile.monitoring = true
	projectile.monitorable = false
	projectile.position = projectile_position
	projectile.set_meta("velocity_z", -_current_projectile_speed())
	projectile.body_entered.connect(_on_projectile_body_entered.bind(projectile))
	_projectile_root.add_child(projectile)

	var orb_mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.32
	sphere.height = 0.64
	orb_mesh.mesh = sphere
	var orb_material := StandardMaterial3D.new()
	orb_material.albedo_color = Color(0.2, 0.95, 1.0)
	orb_material.emission_enabled = true
	orb_material.emission = Color(0.0, 0.65, 1.0)
	orb_material.emission_energy_multiplier = 3.0
	orb_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	orb_mesh.material_override = orb_material
	projectile.add_child(orb_mesh)

	var collision := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = 0.42
	collision.shape = sphere_shape
	projectile.add_child(collision)
	_play_sound("projectile")
	print("ENEMY PROJECTILE spawned at z=%.1f" % projectile_position.z)


func _restart_run() -> void:
	if _paused:
		_paused = false
		get_tree().paused = false
	_clear_attack_warning()
	if _score > _best_score:
		_best_score = _score
		_save_best_score()
	_score = 0
	_bonus_score = 0
	_lives = STARTING_LIVES
	_checkpoint_index = 0
	_checkpoint_position = _spawn_position
	_max_progress_z = _spawn_position.z
	_run_time = 0.0
	_current_run_speed = MOVE_SPEED
	_stamina = MAX_STAMINA
	_boost_locked = false
	_projectile_cooldown = 2.0
	_projectile_pattern_index = 0
	_attack_warning_timer = 0.0
	_attack_warning_elapsed = 0.0
	_burst_shots_remaining = 0
	_burst_shot_timer = 0.0
	_burst_lane_offset = 0.0
	_game_over = false
	_finished = false
	_game_started = true
	_sector_index = -1
	_sector_banner_timer = 0.0
	if _game_over_banner:
		_game_over_banner.visible = false
	if _menu_overlay:
		_menu_overlay.visible = false
	if _projectile_root != null and is_instance_valid(_projectile_root):
		_projectile_root.queue_free()
	_projectile_root = null
	_reset_energy_shards()
	_reset_boss_encounter()
	_respawn("restart")
	_update_sector_progress(true)
	_update_hud()


func _show_main_menu() -> void:
	if _paused:
		_paused = false
		get_tree().paused = false
	_clear_attack_warning()
	if _game_started or _game_over or _finished:
		_restart_run()
	_game_started = false
	_game_over = false
	_finished = false
	if _projectile_root != null and is_instance_valid(_projectile_root):
		_projectile_root.queue_free()
	_projectile_root = null
	_show_menu("main")


func _show_menu(mode: String) -> void:
	_menu_mode = mode
	if _menu_overlay == null:
		return
	_menu_overlay.visible = true
	_settings_container.visible = mode == "settings"
	_menu_secondary_button.visible = mode != "controls" and mode != "credits"
	_menu_tertiary_button.visible = false
	_menu_quaternary_button.visible = false
	_menu_quinary_button.visible = false
	match mode:
		"main":
			_menu_title.text = "GRAVITY BREAKER"
			_menu_subtitle.text = "DEFY GRAVITY. SURVIVE THE TOWER.\n\nA / D Move     SPACE Jump     Q Flip Gravity\nA + Q advances surfaces; D + Q reverses.\nW / SHIFT Boost     S / CTRL Brake\nAuto-run rises from 9 to 14 units/s. Boost uses stamina.\n\n5 sectors  •  1500 metres  •  3 Guardian cores\nALL-TIME BEST SCORE  %06d" % _best_score
			_menu_primary_button.text = "PLAY"
			_menu_secondary_button.text = "HOW TO PLAY"
			_menu_tertiary_button.text = "SETTINGS"
			_menu_tertiary_button.visible = true
			_menu_quaternary_button.text = "CREDITS"
			_menu_quaternary_button.visible = true
			_menu_quinary_button.text = "QUIT"
			_menu_quinary_button.visible = true
		"pause":
			_menu_title.text = "PAUSED"
			_menu_subtitle.text = "The tower is on hold. Take a breath, ninja.\n\nESC  Resume\nA / D  Strafe     SPACE  Jump     Q  Flip Gravity\nA + Q advances FLOOR > LEFT WALL > CEILING; D + Q reverses.\nW  Boost     S  Brake"
			_menu_primary_button.text = "RESUME"
			_menu_secondary_button.text = "MAIN MENU"
			_menu_tertiary_button.text = "SETTINGS"
			_menu_tertiary_button.visible = true
			_menu_quaternary_button.text = "HOW TO PLAY"
			_menu_quaternary_button.visible = true
		"settings":
			_menu_title.text = "SETTINGS"
			_menu_subtitle.text = "Adjust the game before returning to the tower."
			_menu_primary_button.text = "BACK"
			_menu_secondary_button.text = "RESET DEFAULTS"
		"controls":
			_menu_title.text = "HOW TO PLAY"
			_menu_subtitle.text = "MOVEMENT\nA / D  Strafe across the current surface\nSPACE  Jump\n\nGRAVITY\nQ  Flip to an adjacent surface (2-second cooldown)\nA + Q  Advance: FLOOR > LEFT WALL > CEILING\nD + Q  Reverse the surface order\n\nSPEED & STAMINA\nW / SHIFT  Boost while stamina remains\nS / CTRL  Brake; release to return to cruise speed\nCruise speed increases from 9 to 14 units/s over 1500 m.\nEnergy shards restore stamina and award bonus points.\n\nOBJECTIVE\nClear five sectors, activate checkpoints, destroy the three Guardian cores, then reach 1500 m."
			_menu_primary_button.text = "BACK"
		"credits":
			_menu_title.text = "CREDITS & ATTRIBUTION"
			_menu_subtitle.text = "CHARACTER MODEL\n[Project Catnip] Voxel Ninja Run by Raushen\nSketchfab asset; licensed under Creative Commons Attribution 4.0 (CC BY 4.0).\nFull source link and attribution are included in CREDITS.md.\n\nORIGINAL PROJECT WORK\nTunnel, grid, sector gates, hazards, Guardian, UI, icon and gameplay code were created for GRAVITY BREAKER.\n\nAUDIO\nAudio redistribution permissions are still being confirmed. Public release must wait until all audio rights are verified.\nSee CREDITS.md and ASSET_LICENSE_AUDIT.md for full details."
			_menu_primary_button.text = "BACK"
		"game_over":
			_menu_title.text = "GAME OVER"
			_menu_subtitle.text = "SCORE  %06d\nDISTANCE  %03.0f%%\n\nYou ran out of lives. Ready for another attempt?" % [_score, clampf(global_position.z / FINISH_Z, 0.0, 1.0) * 100.0]
			_menu_primary_button.text = "RETRY"
			_menu_secondary_button.text = "MAIN MENU"
		"victory":
			_menu_title.text = "TOWER CLEARED!"
			_menu_subtitle.text = "FINAL SCORE  %06d\nBEST SCORE  %06d\nTIME  %.1f seconds\n\nALL FIVE SECTORS CLEARED.\nTHE TOWER GUARDIAN HAS BEEN DEFEATED.\nExcellent run, ninja." % [_score, _best_score, _run_time]
			_menu_primary_button.text = "PLAY AGAIN"
			_menu_secondary_button.text = "MAIN MENU"


func _pause_game() -> void:
	if _paused or not _game_started or _game_over or _finished:
		return
	_paused = true
	get_tree().paused = true
	_show_menu("pause")


func _resume_game() -> void:
	_paused = false
	get_tree().paused = false
	if _menu_overlay != null:
		_menu_overlay.visible = false
	_update_hud()


func _on_menu_primary_pressed() -> void:
	match _menu_mode:
		"pause":
			_resume_game()
		"settings", "controls", "credits":
			_show_menu(_settings_return_mode)
		_:
			_restart_run()


func _on_menu_secondary_pressed() -> void:
	match _menu_mode:
		"main":
			_settings_return_mode = "main"
			_show_menu("controls")
		"settings":
			_reset_settings_to_defaults()
		_:
			_show_main_menu()


func _on_menu_tertiary_pressed() -> void:
	if _menu_mode == "settings":
		return
	_settings_return_mode = _menu_mode
	_show_menu("settings")


func _on_menu_quaternary_pressed() -> void:
	if _menu_mode == "main":
		_settings_return_mode = "main"
		_show_menu("credits")
	elif _menu_mode == "pause":
		_settings_return_mode = "pause"
		_show_menu("controls")


func _on_menu_quinary_pressed() -> void:
	if _menu_mode == "main":
		get_tree().quit()


func _on_master_volume_changed(value: float) -> void:
	_master_volume = clampf(value, 0.0, 1.0)
	_apply_master_volume()
	_save_settings()


func _on_music_volume_changed(value: float) -> void:
	_music_volume = clampf(value, 0.0, 1.0)
	_apply_music_volume()
	_save_settings()


func _on_fullscreen_toggled(enabled: bool) -> void:
	_fullscreen_enabled = enabled
	_apply_window_mode()
	_save_settings()


func _apply_master_volume() -> void:
	var master_bus: int = AudioServer.get_bus_index("Master")
	if master_bus < 0:
		master_bus = 0
	AudioServer.set_bus_volume_linear(master_bus, _master_volume)


func _apply_music_volume() -> void:
	var music_player: AudioStreamPlayer = _audio_players.get("music") as AudioStreamPlayer
	if music_player == null:
		return
	var linear_music: float = maxf(_music_volume, 0.0001)
	music_player.volume_db = linear_to_db(linear_music) - 10.0


func _apply_window_mode() -> void:
	if _fullscreen_enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _save_settings() -> void:
	var save_data := ConfigFile.new()
	var load_error: Error = save_data.load(SAVE_PATH)
	if load_error != OK:
		save_data = ConfigFile.new()
	save_data.set_value("settings", "master_volume", _master_volume)
	save_data.set_value("settings", "music_volume", _music_volume)
	save_data.set_value("settings", "fullscreen", _fullscreen_enabled)
	save_data.set_value("settings", "fullscreen_default_v15_applied", true)
	var save_error: Error = save_data.save(SAVE_PATH)
	if save_error != OK:
		push_warning("Could not save settings (error %d)." % save_error)


func _reset_settings_to_defaults() -> void:
	_master_volume = 0.85
	_music_volume = 0.20
	_fullscreen_enabled = true
	_master_volume_slider.value = _master_volume
	_music_volume_slider.value = _music_volume
	_fullscreen_check.button_pressed = _fullscreen_enabled
	_apply_master_volume()
	_apply_music_volume()
	_apply_window_mode()
	_save_settings()



func _spawn_pulse_effect(effect_color: Color, end_scale: float) -> void:
	# Expanding emissive ring for gravity flips, hits, and checkpoint events.
	var effect_parent: Node = get_tree().current_scene
	if effect_parent == null:
		effect_parent = get_parent()
	if effect_parent == null:
		return

	var ring := MeshInstance3D.new()
	ring.name = "TemporaryNeonPulse"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.88
	torus.outer_radius = 1.0
	torus.rings = 24
	torus.ring_segments = 8
	ring.mesh = torus

	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.albedo_color = Color(effect_color.r, effect_color.g, effect_color.b, 0.9)
	glow.emission_enabled = true
	glow.emission = effect_color
	glow.emission_energy_multiplier = 2.5
	ring.material_override = glow
	ring.scale = Vector3.ONE * 0.15

	effect_parent.add_child(ring)
	ring.global_position = global_position
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3.ONE * end_scale, 0.42)
	tween.tween_property(glow, "albedo_color", Color(effect_color.r, effect_color.g, effect_color.b, 0.0), 0.42)
	tween.chain().tween_callback(ring.queue_free)


func _screen_flash(flash_color: Color, duration: float, peak_alpha: float) -> void:
	if _feedback_layer == null:
		return
	var flash := ColorRect.new()
	flash.name = "TemporaryScreenFlash"
	flash.color = Color(flash_color.r, flash_color.g, flash_color.b, 1.0)
	flash.modulate.a = peak_alpha
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_feedback_layer.add_child(flash)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	tween.tween_callback(flash.queue_free)


func _create_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "RunnerHUD"
	add_child(layer)

	_feedback_layer = CanvasLayer.new()
	_feedback_layer.name = "FeedbackEffects"
	_feedback_layer.layer = 5
	add_child(_feedback_layer)

	_attack_warning_label = Label.new()
	_attack_warning_label.name = "AttackWarningLabel"
	_attack_warning_label.text = "INCOMING SHOT"
	_attack_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_attack_warning_label.add_theme_font_size_override("font_size", 24)
	_attack_warning_label.add_theme_color_override("font_color", Color(0.25, 0.92, 1.0))
	_attack_warning_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.18, 0.28, 0.95))
	_attack_warning_label.add_theme_constant_override("shadow_offset_x", 2)
	_attack_warning_label.add_theme_constant_override("shadow_offset_y", 2)
	_attack_warning_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_attack_warning_label.position = Vector2(-210.0, 220.0)
	_attack_warning_label.size = Vector2(420.0, 38.0)
	_attack_warning_label.visible = false
	_feedback_layer.add_child(_attack_warning_label)

	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	var hud_panel_style := StyleBoxFlat.new()
	hud_panel_style.bg_color = Color(0.012, 0.024, 0.048, 0.90)
	hud_panel_style.border_color = Color(0.08, 0.38, 0.52, 0.72)
	hud_panel_style.border_width_left = 1
	hud_panel_style.border_width_top = 1
	hud_panel_style.border_width_right = 1
	hud_panel_style.border_width_bottom = 1
	hud_panel_style.corner_radius_top_left = 8
	hud_panel_style.corner_radius_top_right = 8
	hud_panel_style.corner_radius_bottom_left = 8
	hud_panel_style.corner_radius_bottom_right = 8
	hud_panel_style.content_margin_left = 12.0
	hud_panel_style.content_margin_top = 8.0
	hud_panel_style.content_margin_right = 12.0
	hud_panel_style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", hud_panel_style)
	layer.add_child(panel)

	var column := VBoxContainer.new()
	panel.add_child(column)

	_hud_label = Label.new()
	_hud_label.add_theme_font_size_override("font_size", 16)
	_hud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hud_label.custom_minimum_size = Vector2(920.0, 0.0)
	column.add_child(_hud_label)

	var controls := Label.new()
	controls.text = "A / D Move   SPACE Jump   Q Gravity Flip (2s cooldown)   HOLD W Boost   HOLD S Brake"
	controls.add_theme_font_size_override("font_size", 14)
	column.add_child(controls)
	var stamina_caption := Label.new()
	stamina_caption.text = "BOOST STAMINA"
	stamina_caption.add_theme_font_size_override("font_size", 11)
	stamina_caption.add_theme_color_override("font_color", Color(0.25, 0.88, 1.0))
	column.add_child(stamina_caption)
	_stamina_bar = ProgressBar.new()
	_stamina_bar.custom_minimum_size = Vector2(250, 12)
	_stamina_bar.min_value = 0.0
	_stamina_bar.max_value = MAX_STAMINA
	_stamina_bar.value = _stamina
	_stamina_bar.show_percentage = false
	column.add_child(_stamina_bar)

	_flip_status_label = Label.new()
	_flip_status_label.text = "GRAVITY FLIP READY"
	_flip_status_label.add_theme_font_size_override("font_size", 11)
	_flip_status_label.add_theme_color_override("font_color", Color(0.30, 0.82, 1.0))
	column.add_child(_flip_status_label)
	_flip_cooldown_bar = ProgressBar.new()
	_flip_cooldown_bar.custom_minimum_size = Vector2(250, 8)
	_flip_cooldown_bar.min_value = 0.0
	_flip_cooldown_bar.max_value = GRAVITY_FLIP_COOLDOWN
	_flip_cooldown_bar.value = GRAVITY_FLIP_COOLDOWN
	_flip_cooldown_bar.show_percentage = false
	var flip_bar_background := StyleBoxFlat.new()
	flip_bar_background.bg_color = Color(0.025, 0.045, 0.075, 0.95)
	flip_bar_background.corner_radius_top_left = 3
	flip_bar_background.corner_radius_top_right = 3
	flip_bar_background.corner_radius_bottom_left = 3
	flip_bar_background.corner_radius_bottom_right = 3
	var flip_bar_fill := StyleBoxFlat.new()
	flip_bar_fill.bg_color = Color(0.10, 0.53, 0.70, 1.0)
	flip_bar_fill.corner_radius_top_left = 3
	flip_bar_fill.corner_radius_top_right = 3
	flip_bar_fill.corner_radius_bottom_left = 3
	flip_bar_fill.corner_radius_bottom_right = 3
	_flip_cooldown_bar.add_theme_stylebox_override("background", flip_bar_background)
	_flip_cooldown_bar.add_theme_stylebox_override("fill", flip_bar_fill)
	column.add_child(_flip_cooldown_bar)

	_checkpoint_label = Label.new()
	_checkpoint_label.text = "CHECKPOINT ACTIVATED!  +500"
	_checkpoint_label.add_theme_font_size_override("font_size", 20)
	_checkpoint_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.55))
	_checkpoint_label.visible = false
	layer.add_child(_checkpoint_label)
	_checkpoint_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_checkpoint_label.position.y = 72.0

	_sector_banner_label = Label.new()
	_sector_banner_label.name = "SectorAnnouncement"
	_sector_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sector_banner_label.add_theme_font_size_override("font_size", 26)
	_sector_banner_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	_sector_banner_label.add_theme_constant_override("shadow_offset_x", 2)
	_sector_banner_label.add_theme_constant_override("shadow_offset_y", 2)
	_sector_banner_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_sector_banner_label.position = Vector2(-340.0, 156.0)
	_sector_banner_label.size = Vector2(680.0, 36.0)
	_sector_banner_label.visible = false
	layer.add_child(_sector_banner_label)

	_sector_subtitle_label = Label.new()
	_sector_subtitle_label.name = "SectorSubtitle"
	_sector_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sector_subtitle_label.add_theme_font_size_override("font_size", 14)
	_sector_subtitle_label.add_theme_color_override("font_color", Color(0.78, 0.85, 0.93))
	_sector_subtitle_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_sector_subtitle_label.position = Vector2(-360.0, 191.0)
	_sector_subtitle_label.size = Vector2(720.0, 24.0)
	_sector_subtitle_label.visible = false
	layer.add_child(_sector_subtitle_label)

	_boss_status_label = Label.new()
	_boss_status_label.name = "GuardianStatus"
	_boss_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_status_label.add_theme_font_size_override("font_size", 17)
	_boss_status_label.add_theme_color_override("font_color", Color(0.48, 0.86, 1.0))
	_boss_status_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_boss_status_label.position = Vector2(-420.0, 156.0)
	_boss_status_label.size = Vector2(840.0, 28.0)
	_boss_status_label.visible = false
	layer.add_child(_boss_status_label)

	_boss_health_bar = ProgressBar.new()
	_boss_health_bar.name = "GuardianHealth"
	_boss_health_bar.min_value = 0.0
	_boss_health_bar.max_value = BOSS_MAX_HEALTH
	_boss_health_bar.value = BOSS_MAX_HEALTH
	_boss_health_bar.show_percentage = false
	_boss_health_bar.custom_minimum_size = Vector2(520.0, 12.0)
	_boss_health_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_boss_health_bar.position = Vector2(-260.0, 184.0)
	_boss_health_bar.visible = false
	layer.add_child(_boss_health_bar)

	_boss_announcement_label = Label.new()
	_boss_announcement_label.name = "GuardianAnnouncement"
	_boss_announcement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_announcement_label.add_theme_font_size_override("font_size", 25)
	_boss_announcement_label.add_theme_color_override("font_color", Color(0.48, 0.86, 1.0))
	_boss_announcement_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	_boss_announcement_label.add_theme_constant_override("shadow_offset_x", 2)
	_boss_announcement_label.add_theme_constant_override("shadow_offset_y", 2)
	_boss_announcement_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_boss_announcement_label.position = Vector2(-390.0, 264.0)
	_boss_announcement_label.size = Vector2(780.0, 40.0)
	_boss_announcement_label.visible = false
	layer.add_child(_boss_announcement_label)

	_finish_banner = Label.new()
	_finish_banner.text = "FINISH REACHED!  +%d POINTS  |  SCORE %d" % [FINISH_BONUS, _score]
	_finish_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_finish_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_finish_banner.add_theme_font_size_override("font_size", 30)
	_finish_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_finish_banner.visible = false
	layer.add_child(_finish_banner)

	# One reusable overlay powers the title, game-over, and victory screens.
	_menu_overlay = Control.new()
	_menu_overlay.name = "GameMenuOverlay"
	_menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(_menu_overlay)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.015, 0.025, 0.07, 0.90)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_overlay.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu_overlay.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(660, 560)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.012, 0.022, 0.052, 0.97)
	card_style.border_color = Color(0.10, 0.48, 0.64, 0.88)
	card_style.border_width_left = 1
	card_style.border_width_top = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 1
	card_style.corner_radius_top_left = 12
	card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_left = 12
	card_style.corner_radius_bottom_right = 12
	card_style.content_margin_left = 22.0
	card_style.content_margin_top = 18.0
	card_style.content_margin_right = 22.0
	card_style.content_margin_bottom = 18.0
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var menu_column := VBoxContainer.new()
	menu_column.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_column.add_theme_constant_override("separation", 8)
	card.add_child(menu_column)

	_menu_title = Label.new()
	_menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_title.add_theme_font_size_override("font_size", 36)
	_menu_title.add_theme_color_override("font_color", Color(0.25, 0.9, 1.0))
	menu_column.add_child(_menu_title)

	_menu_subtitle = Label.new()
	_menu_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_menu_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu_subtitle.add_theme_font_size_override("font_size", 16)
	_menu_subtitle.add_theme_color_override("font_color", Color(0.82, 0.88, 0.96))
	_menu_subtitle.custom_minimum_size = Vector2(590.0, 0.0)
	menu_column.add_child(_menu_subtitle)

	_settings_container = VBoxContainer.new()
	_settings_container.name = "SettingsControls"
	_settings_container.add_theme_constant_override("separation", 7)
	_settings_container.visible = false
	menu_column.add_child(_settings_container)
	var volume_label := Label.new()
	volume_label.text = "MASTER VOLUME"
	volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_settings_container.add_child(volume_label)
	_master_volume_slider = HSlider.new()
	_master_volume_slider.min_value = 0.0
	_master_volume_slider.max_value = 1.0
	_master_volume_slider.step = 0.05
	_master_volume_slider.custom_minimum_size = Vector2(330.0, 24.0)
	_master_volume_slider.value = _master_volume
	_master_volume_slider.value_changed.connect(_on_master_volume_changed)
	_settings_container.add_child(_master_volume_slider)
	var music_label := Label.new()
	music_label.text = "MUSIC VOLUME"
	music_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_settings_container.add_child(music_label)
	_music_volume_slider = HSlider.new()
	_music_volume_slider.min_value = 0.0
	_music_volume_slider.max_value = 1.0
	_music_volume_slider.step = 0.05
	_music_volume_slider.custom_minimum_size = Vector2(330.0, 24.0)
	_music_volume_slider.value = _music_volume
	_music_volume_slider.value_changed.connect(_on_music_volume_changed)
	_settings_container.add_child(_music_volume_slider)
	_fullscreen_check = CheckButton.new()
	_fullscreen_check.text = "FULLSCREEN MODE"
	_fullscreen_check.button_pressed = _fullscreen_enabled
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_settings_container.add_child(_fullscreen_check)

	_menu_primary_button = Button.new()
	_menu_primary_button.custom_minimum_size = Vector2(250, 48)
	_menu_primary_button.add_theme_font_size_override("font_size", 20)
	_menu_primary_button.pressed.connect(_on_menu_primary_pressed)
	menu_column.add_child(_menu_primary_button)

	_menu_secondary_button = Button.new()
	_menu_secondary_button.custom_minimum_size = Vector2(250, 42)
	_menu_secondary_button.add_theme_font_size_override("font_size", 17)
	_menu_secondary_button.pressed.connect(_on_menu_secondary_pressed)
	menu_column.add_child(_menu_secondary_button)

	_menu_tertiary_button = Button.new()
	_menu_tertiary_button.custom_minimum_size = Vector2(250, 38)
	_menu_tertiary_button.add_theme_font_size_override("font_size", 16)
	_menu_tertiary_button.pressed.connect(_on_menu_tertiary_pressed)
	_menu_tertiary_button.visible = false
	menu_column.add_child(_menu_tertiary_button)

	_menu_quaternary_button = Button.new()
	_menu_quaternary_button.custom_minimum_size = Vector2(250, 38)
	_menu_quaternary_button.add_theme_font_size_override("font_size", 16)
	_menu_quaternary_button.pressed.connect(_on_menu_quaternary_pressed)
	_menu_quaternary_button.visible = false
	menu_column.add_child(_menu_quaternary_button)

	_menu_quinary_button = Button.new()
	_menu_quinary_button.custom_minimum_size = Vector2(250, 38)
	_menu_quinary_button.add_theme_font_size_override("font_size", 16)
	_menu_quinary_button.pressed.connect(_on_menu_quinary_pressed)
	_menu_quinary_button.visible = false
	menu_column.add_child(_menu_quinary_button)

	_game_over_banner = Label.new()
	_game_over_banner.visible = false
	layer.add_child(_game_over_banner)

	_show_menu("main")
	_update_hud()


func _update_score_and_checkpoints() -> void:
	# Score is based on the furthest distance reached, so dying cannot subtract
	# points or let repeated checkpoint respawns farm distance points.
	_max_progress_z = maxf(_max_progress_z, global_position.z)
	_score = int(maxf(0.0, _max_progress_z - _spawn_position.z) * float(POINTS_PER_METER)) + _checkpoint_index * CHECKPOINT_BONUS + _bonus_score

	while _checkpoint_index < CHECKPOINT_ZS.size() and global_position.z >= CHECKPOINT_ZS[_checkpoint_index]:
		_checkpoint_position = Vector3(0.0, _spawn_position.y, CHECKPOINT_ZS[_checkpoint_index] - 5.0)
		_checkpoint_index += 1
		_score += CHECKPOINT_BONUS
		_checkpoint_message_timer = 2.5
		_spawn_pulse_effect(Color(0.2, 1.0, 0.45), 3.0)
		_screen_flash(Color(0.1, 1.0, 0.42), 0.32, 0.16)
		_play_sound("checkpoint")
		if _checkpoint_label:
			_checkpoint_label.text = "CHECKPOINT %d ACTIVATED!  +%d" % [_checkpoint_index, CHECKPOINT_BONUS]
			_checkpoint_label.visible = true
		print("CHECKPOINT %d activated at z=%.1f | score=%d" % [
			_checkpoint_index, CHECKPOINT_ZS[_checkpoint_index - 1], _score
		])
		_score = int(maxf(0.0, _max_progress_z - _spawn_position.z) * float(POINTS_PER_METER)) + _checkpoint_index * CHECKPOINT_BONUS + _bonus_score

	if _score > _best_score:
		_best_score = _score
		_save_best_score()


func _load_best_score() -> void:
	var save_data := ConfigFile.new()
	var error: Error = save_data.load(SAVE_PATH)
	if error == OK:
		_best_score = maxi(0, int(save_data.get_value("records", "best_score", 0)))
		_master_volume = clampf(float(save_data.get_value("settings", "master_volume", 0.85)), 0.0, 1.0)
		_music_volume = clampf(float(save_data.get_value("settings", "music_volume", 0.20)), 0.0, 1.0)
		# v0.15: migrate existing installs to fullscreen once, then respect the player's choice.
		var fullscreen_migrated: bool = bool(save_data.get_value("settings", "fullscreen_default_v15_applied", false))
		if not fullscreen_migrated:
			_fullscreen_enabled = true
			save_data.set_value("settings", "fullscreen", true)
			save_data.set_value("settings", "fullscreen_default_v15_applied", true)
			var migration_error: Error = save_data.save(SAVE_PATH)
			if migration_error != OK:
				push_warning("Could not save fullscreen default migration (error %d)." % migration_error)
		else:
			_fullscreen_enabled = bool(save_data.get_value("settings", "fullscreen", true))
	else:
		_best_score = 0
		_fullscreen_enabled = true


func _save_best_score() -> void:
	var save_data := ConfigFile.new()
	var load_error: Error = save_data.load(SAVE_PATH)
	# Preserve any other settings already stored in this config file.
	if load_error != OK:
		save_data = ConfigFile.new()
	save_data.set_value("records", "best_score", _best_score)
	var save_error: Error = save_data.save(SAVE_PATH)
	if save_error != OK:
		push_warning("Could not save best score (error %d)." % save_error)


func _update_hud() -> void:
	if _hud_label == null:
		return
	var progress: float = clampf(global_position.z / FINISH_Z, 0.0, 1.0) * 100.0
	var visible_sector: int = _sector_index if _sector_index >= 0 else _sector_index_for_z(global_position.z)
	_hud_label.text = "GRAVITY BREAKER  |  SECTOR %02d: %s  |  %s  |  %03.0f%%\nSPEED %.1f  |  BOOST %.0f%%  |  SCORE %06d  |  LIVES %d  |  BEST %06d" % [
		visible_sector + 1, _sector_name(visible_sector), _surface_name(), progress, _current_run_speed, _stamina, _score, _lives, _best_score
	]
	if _stamina_bar != null:
		_stamina_bar.value = _stamina
	if _flip_status_label != null:
		if _flip_denied_timer > 0.0:
			_flip_status_label.text = "GRAVITY LOCKED  |  WAIT %.1fs" % _gravity_flip_cooldown
			_flip_status_label.add_theme_color_override("font_color", Color(1.0, 0.63, 0.24))
		elif _gravity_flip_cooldown > 0.0:
			_flip_status_label.text = "GRAVITY RECHARGING  |  %.1fs" % _gravity_flip_cooldown
			_flip_status_label.add_theme_color_override("font_color", Color(0.90, 0.73, 0.38))
		else:
			_flip_status_label.text = "GRAVITY FLIP READY"
			_flip_status_label.add_theme_color_override("font_color", Color(0.30, 0.82, 1.0))
	if _flip_cooldown_bar != null:
		_flip_cooldown_bar.value = GRAVITY_FLIP_COOLDOWN - _gravity_flip_cooldown
	_update_boss_hud()


func _surface_name() -> String:
	match posmod(_quarter_turns, 4):
		0: return "FLOOR"
		1: return "LEFT WALL"
		2: return "CEILING"
		3: return "RIGHT WALL"
	return "FLOOR"


func _finish_run() -> void:
	_clear_attack_warning()
	_finished = true
	_spawn_pulse_effect(Color(0.2, 1.0, 0.5), 4.0)
	_screen_flash(Color(0.12, 1.0, 0.42), 0.55, 0.22)
	_play_sound("victory")
	_score += FINISH_BONUS
	if _score > _best_score:
		_best_score = _score
		_save_best_score()
	velocity = Vector3.ZERO
	_set_run_animation_active(false)
	if _finish_banner:
		_finish_banner.visible = false
	print("FINISH! Run time: %.1f seconds | score=%d" % [_run_time, _score])
	_show_menu("victory")
	_update_hud()
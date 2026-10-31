extends CharacterBody3D
## GRAVITY BREAKER — auto-running four-surface runner.
## The player always runs toward world +Z. A/D strafe relative to the current
## surface, Space jumps, and Q rotates gravity to an adjacent surface.

const MOVE_SPEED: float = 6.0
const STRAFE_SPEED: float = 5.0
const JUMP_VELOCITY: float = 8.0
const GRAVITY: float = 24.0
const ROTATE_SPEED: float = 8.0
const SHAFT_CENTER_Y: float = 5.0
const SHAFT_AXIS: Vector3 = Vector3.BACK # +Z

const FINISH_Z: float = 240.0
const CHECKPOINT_ZS: Array[float] = [60.0, 120.0, 180.0]
const POINTS_PER_METER: int = 10
const CHECKPOINT_BONUS: int = 500
const FINISH_BONUS: int = 1000
const STARTING_LIVES: int = 3
const PROJECTILE_INTERVAL: float = 3.8
const PROJECTILE_SPEED: float = 10.0
const PROJECTILE_SPAWN_AHEAD: float = 24.0
const SAVE_PATH: String = "user://gravity_breaker_save.cfg"
const BOUNDS_X: float = 6.0 # walls should stop the player; this is only a failsafe outside the square shaft
const BOUNDS_Y_MIN: float = -2.0
const BOUNDS_Y_MAX: float = 12.0
const BOUNDS_Z_MIN: float = -12.0
const CAMERA_MIN_Z: float = -9.0
const CAMERA_FOLLOW_RATE: float = 10.0

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
const MARKING_COUNT: int = 32
const MARKING_SPACING: float = 8.0
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
var _best_score: int = 0
var _max_progress_z: float = 0.0
var _checkpoint_message_timer: float = 0.0
var _run_time: float = 0.0
var _lives: int = STARTING_LIVES
var _projectile_cooldown: float = 2.0
var _projectile_root: Node3D
var _game_over: bool = false
var _game_over_banner: Label
var _game_started: bool = false
var _menu_overlay: Control
var _menu_title: Label
var _menu_subtitle: Label
var _menu_primary_button: Button
var _menu_secondary_button: Button
var _menu_mode: String = "main"

var _camera: Camera3D
var _camera_base: Transform3D
var _camera_offset: Vector3 = Vector3.ZERO
var _camera_follow_position: Vector3 = Vector3.ZERO
var _camera_follow_basis: Basis = Basis.IDENTITY
var _camera_initialized: bool = false
var _anim: AnimationPlayer
var _hud_label: Label
var _finish_banner: Label
var _checkpoint_label: Label
var _finished: bool = false
# Prevent stale contact with the previous surface from cancelling gravity after a flip.
var _surface_change_grace: float = 0.0


func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	up_direction = Vector3.UP
	_load_best_score()
	_spawn_position = global_position
	_checkpoint_position = _spawn_position
	_max_progress_z = global_position.z
	_has_flip_action = InputMap.has_action("flip_gravity")
	if not _has_flip_action:
		push_error("Input action 'flip_gravity' is missing. Add Q in Project Settings > Input Map.")

	_setup_model()
	_create_runner_markings()
	_create_hud()
	# Generate runtime nodes after the scene tree has completed its initial _ready pass.
	_create_obstacles.call_deferred()
	print("GRAVITY BREAKER ready: auto-run +Z at %.1f units/s; A/D strafe, Space jump, Q gravity flip." % MOVE_SPEED)


func _process(delta: float) -> void:
	_checkpoint_message_timer = maxf(0.0, _checkpoint_message_timer - delta)
	if _checkpoint_label != null:
		_checkpoint_label.visible = _checkpoint_message_timer > 0.0
	# Animate generated hazards from the Player script itself. This avoids
	# attaching a script to Area3D nodes after they have entered the scene tree.
	for node in get_tree().get_nodes_in_group("moving_hazards"):
		if not is_instance_valid(node) or not node is Node3D:
			continue
		var hazard := node as Node3D
		if not hazard.has_meta("motion_origin"):
			continue
		var origin: Vector3 = hazard.get_meta("motion_origin")
		var axis: Vector3 = hazard.get_meta("motion_axis")
		var amplitude: float = float(hazard.get_meta("motion_amplitude"))
		var speed: float = float(hazard.get_meta("motion_speed"))
		var phase: float = float(hazard.get_meta("motion_phase"))
		hazard.position = origin + axis * sin(_run_time * speed + phase) * amplitude


func _physics_process(delta: float) -> void:
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
	_run_time += delta
	_update_score_and_checkpoints()
	_update_projectiles(delta)

	if global_position.z >= FINISH_Z:
		_finish_run()
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
		_start_flip()
		velocity = Vector3.ZERO
		_update_camera(delta)
		_update_hud()
		return

	var surface: Basis = Basis(SHAFT_AXIS, _roll)
	# Keep the same screen-relative lateral direction as the camera rolls.
	var right: Vector3 = -surface.x
	var forward: Vector3 = surface.z.normalized() # always world +Z

	var lateral_input: float = Input.get_axis("move_left", "move_right")
	var lateral_velocity: Vector3 = right * lateral_input * STRAFE_SPEED
	var forward_velocity: Vector3 = forward * MOVE_SPEED

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
	print("RESPAWN (", reason, ") from ", global_position)
	var target_position: Vector3 = _checkpoint_position
	if reason == "finish":
		# Completing the course starts a fresh run, while keeping the best score.
		_best_score = maxi(_best_score, _score)
		_score = 0
		_checkpoint_index = 0
		_checkpoint_position = _spawn_position
		_lives = STARTING_LIVES
		target_position = _spawn_position
		_run_time = 0.0
		_max_progress_z = _spawn_position.z

	_quarter_turns = 0
	_roll = 0.0
	_roll_target = 0.0
	_last_flip_dir = -1
	_surface_change_grace = 0.0
	up_direction = Vector3.UP
	velocity = Vector3.ZERO
	global_transform = Transform3D(Basis.IDENTITY, target_position)
	_finished = false
	_checkpoint_message_timer = 0.0
	if _checkpoint_label:
		_checkpoint_label.visible = false
	if _finish_banner:
		_finish_banner.visible = false

	# Snap the camera to the selected spawn/checkpoint pose.
	if _camera != null and _camera_initialized:
		_camera_follow_position = target_position + _camera_offset
		_camera_follow_basis = _camera_base.basis
		_apply_camera()

	_update_hud()


func _start_flip() -> void:
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


func _update_camera(delta: float) -> void:
	# Find the active camera lazily: it may not be current during _ready().
	if _camera == null or not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()
		if _camera == null:
			return

	if not _camera_initialized:
		_camera_base = _camera.global_transform
		# Store the original camera offset relative to the player, not relative
		# to the world origin. This keeps the follow distance stable as the
		# player moves forward and sideways.
		_camera_offset = _camera.global_position - global_position
		_camera_follow_position = _camera.global_position
		_camera_follow_basis = _camera.global_basis
		_camera_initialized = true

	# Rotate both the camera offset and its orientation with the same smooth
	# gravity roll used by the player. This works on all four surfaces.
	var gravity_rotation: Basis = Basis(SHAFT_AXIS, _roll)
	var target_position: Vector3 = global_position + gravity_rotation * _camera_offset
	var target_basis: Basis = gravity_rotation * _camera_base.basis

	# Exponential smoothing is frame-rate independent. Position follows on all
	# three axes; basis slerp prevents abrupt camera snapping during Q flips.
	var weight: float = 1.0 - exp(-CAMERA_FOLLOW_RATE * delta)
	_camera_follow_position = _camera_follow_position.lerp(target_position, weight)
	_camera_follow_basis = _camera_follow_basis.slerp(target_basis, weight).orthonormalized()
	_apply_camera()


func _apply_camera() -> void:
	if _camera == null or not _camera_initialized:
		return
	_camera.global_transform = Transform3D(
		_camera_follow_basis,
		_camera_follow_position
	)


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
		_anim.speed_scale = 1.0 if active else 0.0


func _create_runner_markings() -> void:
	var level := get_parent()
	if level == null or level.get_node_or_null(MARKINGS_NODE_NAME) != null:
		return

	var root := Node3D.new()
	root.name = MARKINGS_NODE_NAME
	level.add_child(root)

	var cyan := StandardMaterial3D.new()
	cyan.albedo_color = Color(0.02, 0.75, 0.95)
	cyan.emission_enabled = true
	cyan.emission = Color(0.0, 0.45, 0.8)
	cyan.emission_energy_multiplier = 1.5
	var dim := StandardMaterial3D.new()
	dim.albedo_color = Color(0.08, 0.18, 0.28)
	dim.emission_enabled = true
	dim.emission = Color(0.02, 0.12, 0.2)
	dim.emission_energy_multiplier = 0.8

	for i in range(MARKING_COUNT):
		var z: float = -4.0 + float(i) * MARKING_SPACING
		# Floor: short cross-lane bars; the repeated pattern makes forward motion obvious.
		_add_box_mark(root, "FloorStripe_%02d" % i, Vector3(0.0, 0.012, z),
			Vector3(8.8, 0.018, 0.10), cyan)
		# Side-wall markers, inset from the collision surface.
		_add_box_mark(root, "LeftWallLight_%02d" % i, Vector3(4.985, 5.0, z),
			Vector3(0.025, 8.8, 0.08), dim)
		_add_box_mark(root, "RightWallLight_%02d" % i, Vector3(-4.985, 5.0, z),
			Vector3(0.025, 8.8, 0.08), dim)
		# Ceiling strip, inset below the underside.
		_add_box_mark(root, "CeilingStripe_%02d" % i, Vector3(0.0, 9.985, z),
			Vector3(8.8, 0.018, 0.10), dim)


func _add_box_mark(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, material: Material) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.material_override = material
	mesh_instance.position = pos
	parent.add_child(mesh_instance)


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
		{"z": 14.0, "surface": 0, "lane": 0},
		{"z": 24.0, "surface": 0, "lane": 2},
		{"z": 34.0, "surface": 0, "lane": 1},
		{"z": 44.0, "surface": 1, "lane": 0},
		{"z": 54.0, "surface": 0, "lane": 2},
		{"z": 64.0, "surface": 2, "lane": 1},
		{"z": 74.0, "surface": 0, "lane": 0},
		{"z": 84.0, "surface": 3, "lane": 2},
		{"z": 94.0, "surface": 0, "lane": 1},
		{"z": 104.0, "surface": 1, "lane": 2},
		{"z": 114.0, "surface": 0, "lane": 0},
		{"z": 124.0, "surface": 2, "lane": 1},
		{"z": 134.0, "surface": 0, "lane": 2},
		{"z": 144.0, "surface": 3, "lane": 0},
		{"z": 154.0, "surface": 0, "lane": 1},
		{"z": 164.0, "surface": 1, "lane": 0}
	]

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
		var moving_spike: bool = i == 2 or i == 5 or i == 7 or i == 11 or i == 13 or i == 15
		var spike_motion_axis: Vector3 = Vector3.RIGHT if surface_id == 0 or surface_id == 2 else Vector3.UP
		_add_spike_hazard(
			root, i + 1, surface_position, inward_normal, spike_material, spike_base_material,
			spike_motion_axis if moving_spike else Vector3.ZERO,
			1.25 if moving_spike else 0.0,
			1.25 + float(i % 3) * 0.18,
			float(i) * 0.83
		)

	# Laser gates are deliberately spaced between spike sections. They span
	# the usable width of their surface, making a jump or gravity flip useful.
	var lasers: Array[Dictionary] = [
		{"z": 29.0, "surface": 0},
		{"z": 59.0, "surface": 1},
		{"z": 89.0, "surface": 2},
		{"z": 119.0, "surface": 3},
		{"z": 149.0, "surface": 0},
		{"z": 179.0, "surface": 1},
		{"z": 209.0, "surface": 2},
		{"z": 229.0, "surface": 3}
	]
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
		var moving_laser: bool = i == 1 or i == 5
		var laser_motion_axis: Vector3 = Vector3.UP if surface_id == 1 or surface_id == 3 else Vector3.RIGHT
		_add_laser_hazard(
			root, i + 1, surface_position, inward_normal, laser_material, laser_core_material,
			laser_motion_axis if moving_laser else Vector3.ZERO,
			1.35 if moving_laser else 0.0,
			1.15 if moving_laser else 0.0,
			float(i) * 1.7
		)

	print("HAZARDS: created %d visible spikes and %d laser gates under %s." % [spikes.size(), lasers.size(), root.get_path()])


func _add_spike_hazard(root: Node3D, index: int, surface_position: Vector3,
		inward_normal: Vector3, spike_material: Material, base_material: Material,
		motion_axis: Vector3 = Vector3.ZERO, motion_amplitude: float = 0.0,
		motion_speed: float = 0.0, motion_phase: float = 0.0) -> void:
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
	socket.size = Vector3(0.82, 0.10, 0.82)
	socket_mesh.mesh = socket
	socket_mesh.position = Vector3(0.0, 0.055, 0.0)
	socket_mesh.material_override = base_material
	area.add_child(socket_mesh)

	var spike_mesh_instance := MeshInstance3D.new()
	spike_mesh_instance.name = "SpikeMesh"
	var spike := CylinderMesh.new()
	spike.top_radius = 0.035
	spike.bottom_radius = 0.36
	spike.height = 0.82
	spike.radial_segments = 8
	spike.rings = 2
	spike_mesh_instance.mesh = spike
	spike_mesh_instance.position = Vector3(0.0, 0.51, 0.0)
	spike_mesh_instance.material_override = spike_material
	spike_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	area.add_child(spike_mesh_instance)

	var collision_node := CollisionShape3D.new()
	collision_node.name = "SpikeCollision"
	var collision_shape := CylinderShape3D.new()
	collision_shape.radius = 0.36
	collision_shape.height = 0.82
	collision_node.shape = collision_shape
	collision_node.position = Vector3(0.0, 0.51, 0.0)
	area.add_child(collision_node)
	if motion_amplitude > 0.0 and motion_axis.length_squared() > 0.0:
		_configure_moving_hazard(area, motion_axis, motion_amplitude, motion_speed, motion_phase)


func _add_laser_hazard(root: Node3D, index: int, surface_position: Vector3,
		inward_normal: Vector3, laser_material: Material, core_material: Material,
		motion_axis: Vector3 = Vector3.ZERO, motion_amplitude: float = 0.0,
		motion_speed: float = 0.0, motion_phase: float = 0.0) -> void:
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
	beam.size = Vector3(8.6, 0.18, 0.22)
	beam_mesh.mesh = beam
	beam_mesh.position = Vector3(0.0, 0.20, 0.0)
	beam_mesh.material_override = laser_material
	beam_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	area.add_child(beam_mesh)

	var core_mesh := MeshInstance3D.new()
	core_mesh.name = "LaserCoreMesh"
	var core := BoxMesh.new()
	core.size = Vector3(8.6, 0.045, 0.06)
	core_mesh.mesh = core
	core_mesh.position = Vector3(0.0, 0.20, 0.0)
	core_mesh.material_override = core_material
	core_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	area.add_child(core_mesh)

	var collision_node := CollisionShape3D.new()
	collision_node.name = "LaserCollision"
	var collision_shape := BoxShape3D.new()
	collision_shape.size = Vector3(8.6, 0.24, 0.28)
	collision_node.shape = collision_shape
	collision_node.position = Vector3(0.0, 0.20, 0.0)
	area.add_child(collision_node)
	if motion_amplitude > 0.0 and motion_axis.length_squared() > 0.0:
		_configure_moving_hazard(area, motion_axis, motion_amplitude, motion_speed, motion_phase)


func _configure_moving_hazard(area: Area3D, axis: Vector3, amplitude: float, speed: float, phase: float) -> void:
	# Store original local position and motion settings as metadata.
	# The Player script animates these nodes every rendered frame.
	area.set_meta("motion_origin", area.position)
	area.set_meta("motion_axis", axis.normalized())
	area.set_meta("motion_amplitude", amplitude)
	area.set_meta("motion_speed", speed)
	area.set_meta("motion_phase", phase)
	area.name = "Moving_" + area.name
	area.add_to_group("moving_hazards")
	print("MOVING HAZARD configured: %s axis=%s amplitude=%.2f speed=%.2f" % [
		area.name, str(axis.normalized()), amplitude, speed
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
	_lives -= 1
	print("HIT by %s | lives remaining: %d" % [reason, _lives])
	if _lives <= 0:
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
	_projectile_cooldown -= delta
	if _projectile_cooldown <= 0.0:
		_spawn_enemy_projectile()
		_projectile_cooldown = PROJECTILE_INTERVAL
	# Move each projectile toward the player, then clean up missed shots.
	if _projectile_root != null:
		for child in _projectile_root.get_children():
			if not child is Node3D:
				continue
			var projectile := child as Node3D
			projectile.position.z -= PROJECTILE_SPEED * delta
			if projectile.position.z < global_position.z - 12.0:
				projectile.queue_free()


func _spawn_enemy_projectile() -> void:
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
	# Small lane offsets make the projectile dodgeable instead of perfectly tracking.
	var projectile_position := global_position
	projectile_position.z = global_position.z + PROJECTILE_SPAWN_AHEAD
	var side_offset: float = [-1.8, 0.0, 1.8][randi_range(0, 2)]
	match posmod(_quarter_turns, 4):
		0: # floor
			projectile_position.y = 0.72
			projectile_position.x = clampf(global_position.x + side_offset, -3.4, 3.4)
		1: # left wall
			projectile_position.x = 4.25
			projectile_position.y = clampf(global_position.y + side_offset, 1.0, 9.0)
		2: # ceiling
			projectile_position.y = 9.28
			projectile_position.x = clampf(global_position.x + side_offset, -3.4, 3.4)
		3: # right wall
			projectile_position.x = -4.25
			projectile_position.y = clampf(global_position.y + side_offset, 1.0, 9.0)

	var projectile := Area3D.new()
	projectile.name = "EnemyEnergyProjectile"
	projectile.collision_layer = 0
	projectile.collision_mask = 1
	projectile.monitoring = true
	projectile.monitorable = false
	projectile.position = projectile_position
	projectile.set_meta("velocity_z", -PROJECTILE_SPEED)
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
	print("ENEMY PROJECTILE spawned at z=%.1f" % projectile_position.z)


func _restart_run() -> void:
	if _score > _best_score:
		_best_score = _score
		_save_best_score()
	_score = 0
	_lives = STARTING_LIVES
	_checkpoint_index = 0
	_checkpoint_position = _spawn_position
	_max_progress_z = _spawn_position.z
	_run_time = 0.0
	_projectile_cooldown = 2.0
	_game_over = false
	_finished = false
	_game_started = true
	if _game_over_banner:
		_game_over_banner.visible = false
	if _menu_overlay:
		_menu_overlay.visible = false
	if _projectile_root != null and is_instance_valid(_projectile_root):
		_projectile_root.queue_free()
	_projectile_root = null
	_respawn("restart")
	_update_hud()


func _show_main_menu() -> void:
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
	match mode:
		"main":
			_menu_title.text = "GRAVITY BREAKER"
			_menu_subtitle.text = "DEFY GRAVITY. SURVIVE THE TOWER.\n\nA / D  Move     SPACE  Jump     Q  Flip Gravity\nDodge moving hazards and energy projectiles.\nReach the finish at 240m. Checkpoints grant +500.\n\nALL-TIME BEST SCORE  %06d" % _best_score
			_menu_primary_button.text = "PLAY"
			_menu_secondary_button.text = "QUIT"
		"game_over":
			_menu_title.text = "GAME OVER"
			_menu_subtitle.text = "SCORE  %06d\nDISTANCE  %03.0f%%\n\nYou ran out of lives. Ready for another attempt?" % [_score, clampf(global_position.z / FINISH_Z, 0.0, 1.0) * 100.0]
			_menu_primary_button.text = "RETRY"
			_menu_secondary_button.text = "MAIN MENU"
		"victory":
			_menu_title.text = "TOWER CLEARED!"
			_menu_subtitle.text = "FINAL SCORE  %06d\nBEST SCORE  %06d\nTIME  %.1f seconds\n\nExcellent run, ninja. The tower is yours." % [_score, _best_score, _run_time]
			_menu_primary_button.text = "PLAY AGAIN"
			_menu_secondary_button.text = "MAIN MENU"


func _on_menu_primary_pressed() -> void:
	_restart_run()


func _on_menu_secondary_pressed() -> void:
	if _menu_mode == "main":
		get_tree().quit()
	else:
		_show_main_menu()


func _create_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "RunnerHUD"
	add_child(layer)

	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	layer.add_child(panel)

	var column := VBoxContainer.new()
	panel.add_child(column)

	_hud_label = Label.new()
	_hud_label.add_theme_font_size_override("font_size", 18)
	column.add_child(_hud_label)

	var controls := Label.new()
	controls.text = "A / D Move   SPACE Jump   Q Gravity Flip   R Restart after Game Over"
	controls.add_theme_font_size_override("font_size", 14)
	column.add_child(controls)

	_checkpoint_label = Label.new()
	_checkpoint_label.text = "CHECKPOINT ACTIVATED!  +500"
	_checkpoint_label.add_theme_font_size_override("font_size", 20)
	_checkpoint_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.55))
	_checkpoint_label.visible = false
	layer.add_child(_checkpoint_label)
	_checkpoint_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_checkpoint_label.position.y = 72.0

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
	card.custom_minimum_size = Vector2(540, 400)
	center.add_child(card)

	var menu_column := VBoxContainer.new()
	menu_column.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_column.add_theme_constant_override("separation", 16)
	card.add_child(menu_column)

	_menu_title = Label.new()
	_menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_title.add_theme_font_size_override("font_size", 38)
	_menu_title.add_theme_color_override("font_color", Color(0.25, 0.9, 1.0))
	menu_column.add_child(_menu_title)

	_menu_subtitle = Label.new()
	_menu_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_menu_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu_subtitle.add_theme_font_size_override("font_size", 17)
	menu_column.add_child(_menu_subtitle)

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

	_game_over_banner = Label.new()
	_game_over_banner.visible = false
	layer.add_child(_game_over_banner)

	_show_menu("main")
	_update_hud()


func _update_score_and_checkpoints() -> void:
	# Score is based on the furthest distance reached, so dying cannot subtract
	# points or let repeated checkpoint respawns farm distance points.
	_max_progress_z = maxf(_max_progress_z, global_position.z)
	_score = int(maxf(0.0, _max_progress_z - _spawn_position.z) * float(POINTS_PER_METER)) + _checkpoint_index * CHECKPOINT_BONUS

	while _checkpoint_index < CHECKPOINT_ZS.size() and global_position.z >= CHECKPOINT_ZS[_checkpoint_index]:
		_checkpoint_position = Vector3(0.0, _spawn_position.y, CHECKPOINT_ZS[_checkpoint_index] - 5.0)
		_checkpoint_index += 1
		_score += CHECKPOINT_BONUS
		_checkpoint_message_timer = 2.5
		if _checkpoint_label:
			_checkpoint_label.text = "CHECKPOINT %d ACTIVATED!  +%d" % [_checkpoint_index, CHECKPOINT_BONUS]
			_checkpoint_label.visible = true
		print("CHECKPOINT %d activated at z=%.1f | score=%d" % [
			_checkpoint_index, CHECKPOINT_ZS[_checkpoint_index - 1], _score
		])
		_score = int(maxf(0.0, _max_progress_z - _spawn_position.z) * float(POINTS_PER_METER)) + _checkpoint_index * CHECKPOINT_BONUS

	if _score > _best_score:
		_best_score = _score
		_save_best_score()


func _load_best_score() -> void:
	var save_data := ConfigFile.new()
	var error: Error = save_data.load(SAVE_PATH)
	if error == OK:
		_best_score = maxi(0, int(save_data.get_value("records", "best_score", 0)))
	else:
		_best_score = 0


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
	_hud_label.text = "GRAVITY BREAKER  |  %s  |  %03.0f%%  |  SCORE %06d  |  LIVES %d  |  BEST %06d" % [
		_surface_name(), progress, _score, _lives, _best_score
	]


func _surface_name() -> String:
	match posmod(_quarter_turns, 4):
		0: return "FLOOR"
		1: return "LEFT WALL"
		2: return "CEILING"
		3: return "RIGHT WALL"
	return "FLOOR"


func _finish_run() -> void:
	_finished = true
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

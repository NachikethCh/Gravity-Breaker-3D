extends CharacterBody3D
## GRAVITY BREAKER — auto-running four-surface runner.
## The player always runs toward world +Z. A/D strafe relative to the current
## surface, Space jumps, and Q rotates gravity to an adjacent surface.

const MOVE_SPEED: float = 6.0
const STRAFE_SPEED: float = 5.0
const JUMP_VELOCITY: float = 8.0
const GRAVITY: float = 24.0
const ROTATE_SPEED: float = 8.0
const SHAFT_CENTER_Y: float = 3.0
const SHAFT_AXIS: Vector3 = Vector3.BACK # +Z

const FINISH_Z: float = 240.0
const BOUNDS_X: float = 4.35 # keep capsule centre inside walls at x ~= +/-5
const BOUNDS_Y_MIN: float = -1.0
const BOUNDS_Y_MAX: float = 7.0
const BOUNDS_Z_MIN: float = -12.0
const CAMERA_MIN_Z: float = -9.0
const CAMERA_FOLLOW_RATE: float = 10.0

# Imported model fit. The collision capsule remains unchanged in player.tscn.
const MODEL_NODE_NAME: String = "Sketchfab_Scene"
const CAPSULE_HEIGHT: float = 1.8
const MODEL_REFERENCE_HEIGHT: float = 64.0
const MODEL_PIVOT_X: float = 5.4
const MODEL_PIVOT_Z: float = 2.3
const MODEL_YAW_DEGREES: float = -90.0
const MODEL_FOOT_OFFSET: float = 0.04
const RUN_ANIMATION: StringName = &""

# Visual runner markings are created once under Level.
const MARKINGS_NODE_NAME: String = "GeneratedRunnerMarkings"
const MARKING_COUNT: int = 32
const MARKING_SPACING: float = 8.0

var _quarter_turns: int = 0
var _roll: float = 0.0
var _roll_target: float = 0.0
var _last_flip_dir: int = -1
var _has_flip_action: bool = false
var _spawn_position: Vector3
var _run_time: float = 0.0

var _camera: Camera3D
var _camera_base: Transform3D
var _camera_z_offset: float = 0.0
var _cam_z: float = 0.0
var _anim: AnimationPlayer
var _hud_label: Label
var _finish_banner: Label
var _finished: bool = false


func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	up_direction = Vector3.UP
	_spawn_position = global_position
	_has_flip_action = InputMap.has_action("flip_gravity")
	if not _has_flip_action:
		push_error("Input action 'flip_gravity' is missing. Add Q in Project Settings > Input Map.")

	_setup_model()
	_create_runner_markings()
	_create_hud()
	print("GRAVITY BREAKER ready: auto-run +Z at %.1f units/s; A/D strafe, Space jump, Q gravity flip." % MOVE_SPEED)


func _physics_process(delta: float) -> void:
	if _finished:
		return

	_run_time += delta

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
		_update_camera(delta)
		_update_hud()
		return

	if _has_flip_action and Input.is_action_just_pressed("flip_gravity"):
		_start_flip()
		velocity = Vector3.ZERO
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
	if is_on_floor():
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
	_quarter_turns = 0
	_roll = 0.0
	_roll_target = 0.0
	_last_flip_dir = -1
	up_direction = Vector3.UP
	velocity = Vector3.ZERO
	global_transform = Transform3D(Basis.IDENTITY, _spawn_position)
	_run_time = 0.0
	_finished = false
	if _finish_banner:
		_finish_banner.visible = false
	if _camera != null:
		_cam_z = maxf(_spawn_position.z + _camera_z_offset, CAMERA_MIN_Z)
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
	if _camera == null:
		_camera = get_viewport().get_camera_3d()
		if _camera == null:
			return
		_camera_base = _camera.global_transform
		_camera_z_offset = _camera_base.origin.z - global_position.z
		_cam_z = _camera_base.origin.z

	var target_z: float = maxf(global_position.z + _camera_z_offset, CAMERA_MIN_Z)
	_cam_z = lerpf(_cam_z, target_z, 1.0 - exp(-CAMERA_FOLLOW_RATE * delta))
	_apply_camera()


func _apply_camera() -> void:
	var rot: Basis = Basis(SHAFT_AXIS, _roll)
	var pivot: Vector3 = Vector3(0.0, SHAFT_CENTER_Y, 0.0)
	var base_origin: Vector3 = Vector3(_camera_base.origin.x, _camera_base.origin.y, _cam_z)
	_camera.global_transform = Transform3D(
		rot * _camera_base.basis,
		pivot + rot * (base_origin - pivot)
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
		_add_box_mark(root, "LeftWallLight_%02d" % i, Vector3(4.985, 3.0, z),
			Vector3(0.025, 4.8, 0.08), dim)
		_add_box_mark(root, "RightWallLight_%02d" % i, Vector3(-4.985, 3.0, z),
			Vector3(0.025, 4.8, 0.08), dim)
		# Ceiling strip, inset below the underside.
		_add_box_mark(root, "CeilingStripe_%02d" % i, Vector3(0.0, 5.985, z),
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
	controls.text = "A / D  Move     SPACE  Jump     Q  Gravity Flip"
	controls.add_theme_font_size_override("font_size", 14)
	column.add_child(controls)

	_finish_banner = Label.new()
	_finish_banner.text = "FINISH REACHED!  RUN COMPLETE"
	_finish_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_finish_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_finish_banner.add_theme_font_size_override("font_size", 30)
	_finish_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_finish_banner.visible = false
	layer.add_child(_finish_banner)
	_update_hud()


func _update_hud() -> void:
	if _hud_label == null:
		return
	var progress: float = clampf(global_position.z / FINISH_Z, 0.0, 1.0) * 100.0
	_hud_label.text = "GRAVITY BREAKER   |   %s   |   %03.0f%%" % [_surface_name(), progress]


func _surface_name() -> String:
	match posmod(_quarter_turns, 4):
		0: return "FLOOR"
		1: return "LEFT WALL"
		2: return "CEILING"
		3: return "RIGHT WALL"
	return "FLOOR"


func _finish_run() -> void:
	_finished = true
	velocity = Vector3.ZERO
	_set_run_animation_active(false)
	if _finish_banner:
		_finish_banner.visible = true
	print("FINISH! Run time: %.1f seconds" % _run_time)
	# Return to the start after a short celebration so the game remains replayable.
	await get_tree().create_timer(2.5).timeout
	if is_inside_tree():
		_respawn("finish")
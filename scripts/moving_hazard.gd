extends Area3D
## Smooth, deterministic world-space motion for generated hazards.
## The Area3D and its visual/collision children move together.

@export var motion_axis: Vector3 = Vector3.RIGHT
@export_range(0.1, 5.0, 0.1) var motion_amplitude: float = 1.0
@export_range(0.1, 5.0, 0.1) var motion_speed: float = 1.0
@export var motion_phase: float = 0.0

var _start_position: Vector3 = Vector3.ZERO
var _elapsed: float = 0.0
var _motion_initialized: bool = false


func _ready() -> void:
	_initialize_motion()


func _initialize_motion() -> void:
	if _motion_initialized:
		return
	_start_position = global_position
	_elapsed = motion_phase
	_motion_initialized = true


func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	_initialize_motion()
	_elapsed += delta
	var axis: Vector3 = motion_axis.normalized()
	global_position = _start_position + axis * sin(_elapsed * motion_speed) * motion_amplitude

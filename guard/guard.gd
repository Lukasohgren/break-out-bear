extends CharacterBody3D

@export var patrol_route: Node3D

@export_group("Patrol")
@export_range(0.0, 5.0, 0.1, "or_greater", "suffix:m/s")
var patrol_speed: float = 1.0
@export_range(0.0, 1080.0, 10.0, "or_greater", "suffix:deg/s")
var rotation_speed: float = 360.0
@export_range(0.05, 1.0, 0.01, "or_greater", "suffix:m")
var patrol_point_tolerance: float = 0.18

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var patrol_points: Array[Marker3D] = []
var patrol_point_index: int = 0
var _target_started: bool = false
var _gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))


func _ready() -> void:
	if patrol_route == null:
		push_error("Guard needs a Patrol Route reference in the Inspector.")
		set_physics_process(false)
		return
	for child in patrol_route.get_children():
		if child is Marker3D:
			patrol_points.append(child)
	if patrol_points.size() < 2:
		push_error("Guard patrol route needs at least two Marker3D children.")
		set_physics_process(false)
		return
	navigation_agent.target_desired_distance = patrol_point_tolerance


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or not is_multiplayer_authority():
		return

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta

	# The navigation map needs a physics tick to synchronize after scene load.
	if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	if not _target_started:
		_target_started = true
		if _horizontal_distance_to(patrol_points[0].global_position) <= patrol_point_tolerance:
			patrol_point_index = 1
		_set_patrol_target()
	elif _horizontal_distance_to(patrol_points[patrol_point_index].global_position) <= patrol_point_tolerance:
		patrol_point_index = (patrol_point_index + 1) % patrol_points.size()
		_set_patrol_target()

	var next_position: Vector3 = navigation_agent.get_next_path_position()
	var direction: Vector3 = next_position - global_position
	direction.y = 0.0
	if navigation_agent.is_navigation_finished() or direction.is_zero_approx():
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var speed: float = minf(patrol_speed, direction.length() / delta)
		var movement_direction: Vector3 = direction.normalized()
		velocity.x = movement_direction.x * speed
		velocity.z = movement_direction.z * speed

	move_and_slide()
	_rotate_toward_movement(delta)


func _set_patrol_target() -> void:
	navigation_agent.target_position = patrol_points[patrol_point_index].global_position


func _horizontal_distance_to(target: Vector3) -> float:
	var offset: Vector3 = target - global_position
	offset.y = 0.0
	return offset.length()


func _rotate_toward_movement(delta: float) -> void:
	var movement: Vector3 = get_real_velocity()
	movement.y = 0.0
	if movement.is_zero_approx():
		return
	var target_yaw: float = atan2(-movement.x, -movement.z)
	rotation.y = rotate_toward(rotation.y, target_yaw, deg_to_rad(rotation_speed) * delta)

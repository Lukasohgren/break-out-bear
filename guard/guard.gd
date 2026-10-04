extends CharacterBody3D

const WORLD_VISION_MASK: int = 1

@export var patrol_route: Node3D

@export_group("Patrol")
@export_range(0.0, 5.0, 0.1, "or_greater", "suffix:m/s")
var patrol_speed: float = 1.0
@export_range(0.0, 1080.0, 10.0, "or_greater", "suffix:deg/s")
var rotation_speed: float = 360.0
@export_range(0.05, 1.0, 0.01, "or_greater", "suffix:m")
var patrol_point_tolerance: float = 0.18

@export_group("Vision")
@export_range(0.1, 20.0, 0.1, "or_greater", "suffix:m")
var vision_range: float = 3.5
## Full horizontal width of the vision cone, in degrees.
@export_range(1.0, 179.0, 1.0, "suffix:deg")
var vision_angle_degrees: float = 70.0

@export_group("Vision Debug")
@export var show_vision_debug: bool = true:
	set(value):
		show_vision_debug = value
		if is_node_ready():
			_update_vision_debug()

## Peer IDs currently visible to this Guard; replicated from the host for debugging.
@export var visible_player_peer_ids: PackedInt32Array = PackedInt32Array():
	set(value):
		visible_player_peer_ids = value
		if is_node_ready():
			_update_vision_debug()

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var vision_origin: Marker3D = $VisionOrigin
@onready var flashlight: SpotLight3D = $VisionOrigin/SpotLight3D
@onready var facing_marker: MeshInstance3D = $FacingMarker

var patrol_points: Array[Marker3D] = []
var patrol_point_index: int = 0
var _target_started: bool = false
var _gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var _detected_material: StandardMaterial3D = StandardMaterial3D.new()


func _ready() -> void:
	flashlight.spot_range = vision_range
	flashlight.spot_angle = vision_angle_degrees * 0.5
	_detected_material.albedo_color = Color(1.0, 0.1, 0.1)
	_detected_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_update_vision_debug()

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
	_update_visible_players()


func _update_visible_players() -> void:
	var currently_visible := PackedInt32Array()
	for node in get_tree().get_nodes_in_group("players"):
		var player: CharacterBody3D = node as CharacterBody3D
		if player == null or player.is_queued_for_deletion():
			continue
		var target: Marker3D = player.get_node_or_null("VisionTarget") as Marker3D
		if target == null:
			continue
		if _can_see_target(target.global_position):
			currently_visible.append(player.get_multiplayer_authority())
	currently_visible.sort()
	if currently_visible != visible_player_peer_ids:
		visible_player_peer_ids = currently_visible


func _can_see_target(target_position: Vector3) -> bool:
	var origin: Vector3 = vision_origin.global_position
	var to_target: Vector3 = target_position - origin
	if to_target.length_squared() > vision_range * vision_range:
		return false

	var horizontal_direction: Vector3 = to_target
	horizontal_direction.y = 0.0
	if not horizontal_direction.is_zero_approx():
		var forward: Vector3 = -global_basis.z
		forward.y = 0.0
		var minimum_dot: float = cos(deg_to_rad(vision_angle_degrees * 0.5))
		if forward.normalized().dot(horizontal_direction.normalized()) < minimum_dot:
			return false

	var query := PhysicsRayQueryParameters3D.create(origin, target_position, WORLD_VISION_MASK)
	# The forward-mounted origin can overlap a wall when the Guard stands close to it.
	query.hit_from_inside = true
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _update_vision_debug() -> void:
	facing_marker.material_override = (
		_detected_material if show_vision_debug and not visible_player_peer_ids.is_empty() else null
	)


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

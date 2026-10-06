extends CharacterBody3D

const WORLD_VISION_MASK: int = 1
const CHASE_REPATH_DISTANCE: float = 0.2
const UNREACHABLE_REPATH_DISTANCE: float = 0.5
const CHASE_REPATH_HEIGHT: float = 0.45

enum GuardState { PATROL, CHASE, RETURN_TO_PATROL }

@export var patrol_route: Node3D

@export_group("Patrol")
@export_range(0.0, 5.0, 0.1, "or_greater", "suffix:m/s")
var patrol_speed: float = 1.0
@export_range(0.0, 1080.0, 10.0, "or_greater", "suffix:deg/s")
var rotation_speed: float = 360.0
@export_range(0.05, 1.0, 0.01, "or_greater", "suffix:m")
var patrol_point_tolerance: float = 0.18

@export_group("Chase")
@export_range(0.0, 10.0, 0.1, "or_greater", "suffix:m/s")
var chase_speed: float = 1.8
@export_range(0.2, 2.0, 0.01, "or_greater", "suffix:m")
var chase_stop_distance: float = 0.45

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

@export_group("State Debug")
@export var current_state: GuardState = GuardState.PATROL:
	set(value):
		current_state = value
		if is_node_ready():
			_update_vision_debug()
## Zero means no Player is currently being chased.
@export var chase_target_peer_id: int = 0

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var vision_origin: Marker3D = $VisionOrigin
@onready var flashlight: SpotLight3D = $VisionOrigin/SpotLight3D
@onready var facing_marker: MeshInstance3D = $FacingMarker

var patrol_points: Array[Marker3D] = []
var patrol_point_index: int = 0
var _target_started: bool = false
var _gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var _detected_material: StandardMaterial3D = StandardMaterial3D.new()
var _returning_material: StandardMaterial3D = StandardMaterial3D.new()


func _ready() -> void:
	flashlight.spot_range = vision_range
	flashlight.spot_angle = vision_angle_degrees * 0.5
	_detected_material.albedo_color = Color(1.0, 0.1, 0.1)
	_detected_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_returning_material.albedo_color = Color(0.1, 0.8, 1.0)
	_returning_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
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

	_update_visible_players()
	var chase_target: CharacterBody3D = _update_state_and_target()
	_move_along_path(delta, chase_target)
	move_and_slide()
	if (
		chase_target != null
		and (
			_horizontal_distance_to(chase_target.global_position) <= chase_stop_distance
			or navigation_agent.is_navigation_finished()
		)
	):
		_rotate_toward_direction(chase_target.global_position - global_position, delta)
	else:
		_rotate_toward_movement(delta)


func _update_state_and_target() -> CharacterBody3D:
	var visible_target: CharacterBody3D
	match current_state:
		GuardState.PATROL:
			visible_target = _find_nearest_visible_player()
			if visible_target != null:
				_enter_chase(visible_target)
			else:
				_advance_patrol_if_needed()
		GuardState.CHASE:
			visible_target = _find_visible_player_by_peer_id(chase_target_peer_id)
			if visible_target == null:
				visible_target = _find_nearest_visible_player()
			if visible_target == null:
				_enter_return_to_patrol()
			elif visible_target.get_multiplayer_authority() != chase_target_peer_id:
				_enter_chase(visible_target)
			else:
				_update_chase_destination(visible_target)
		GuardState.RETURN_TO_PATROL:
			visible_target = _find_nearest_visible_player()
			if visible_target != null:
				_enter_chase(visible_target)
			elif (
				_horizontal_distance_to(patrol_points[patrol_point_index].global_position)
				<= patrol_point_tolerance
			):
				_resume_patrol()
	return visible_target if current_state == GuardState.CHASE else null


func _advance_patrol_if_needed() -> void:
	if not _target_started:
		_target_started = true
		if _horizontal_distance_to(patrol_points[0].global_position) <= patrol_point_tolerance:
			patrol_point_index = 1
		_set_patrol_target()
	elif _horizontal_distance_to(patrol_points[patrol_point_index].global_position) <= patrol_point_tolerance:
		patrol_point_index = (patrol_point_index + 1) % patrol_points.size()
		_set_patrol_target()


func _enter_chase(target: CharacterBody3D) -> void:
	chase_target_peer_id = target.get_multiplayer_authority()
	current_state = GuardState.CHASE
	navigation_agent.target_position = target.global_position


func _update_chase_destination(target: CharacterBody3D) -> void:
	# Repath after meaningful movement instead of resetting the path every physics tick.
	var target_offset: Vector3 = target.global_position - navigation_agent.target_position
	var height_change: float = absf(target_offset.y)
	target_offset.y = 0.0
	var repath_distance: float = CHASE_REPATH_DISTANCE
	if not navigation_agent.is_target_reachable() and navigation_agent.is_navigation_finished():
		repath_distance = UNREACHABLE_REPATH_DISTANCE
	if (
		target_offset.length_squared() >= repath_distance * repath_distance
		or height_change >= CHASE_REPATH_HEIGHT
	):
		navigation_agent.target_position = target.global_position


func _enter_return_to_patrol() -> void:
	chase_target_peer_id = 0
	var nearest_distance_squared: float = INF
	for index in range(patrol_points.size()):
		var offset: Vector3 = patrol_points[index].global_position - global_position
		offset.y = 0.0
		var distance_squared: float = offset.length_squared()
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			patrol_point_index = index
	current_state = GuardState.RETURN_TO_PATROL
	_set_patrol_target()


func _resume_patrol() -> void:
	patrol_point_index = (patrol_point_index + 1) % patrol_points.size()
	_target_started = true
	current_state = GuardState.PATROL
	_set_patrol_target()


func _move_along_path(delta: float, chase_target: CharacterBody3D) -> void:
	var chase_distance: float = INF
	if chase_target != null:
		chase_distance = _horizontal_distance_to(chase_target.global_position)
		if chase_distance <= chase_stop_distance:
			velocity.x = 0.0
			velocity.z = 0.0
			return
	if navigation_agent.is_navigation_finished():
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var next_position: Vector3 = navigation_agent.get_next_path_position()
	var direction: Vector3 = next_position - global_position
	direction.y = 0.0
	if navigation_agent.is_navigation_finished() or direction.is_zero_approx():
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var movement_speed: float = chase_speed if current_state == GuardState.CHASE else patrol_speed
		var speed: float = minf(movement_speed, direction.length() / delta)
		if chase_target != null:
			speed = minf(speed, (chase_distance - chase_stop_distance) / delta)
		var movement_direction: Vector3 = direction.normalized()
		velocity.x = movement_direction.x * speed
		velocity.z = movement_direction.z * speed


func _find_visible_player_by_peer_id(peer_id: int) -> CharacterBody3D:
	if peer_id == 0 or not visible_player_peer_ids.has(peer_id):
		return null
	for node in get_tree().get_nodes_in_group("players"):
		var player: CharacterBody3D = node as CharacterBody3D
		if (
			player != null
			and not player.is_queued_for_deletion()
			and player.get_multiplayer_authority() == peer_id
		):
			return player
	return null


func _find_nearest_visible_player() -> CharacterBody3D:
	var nearest_player: CharacterBody3D
	var nearest_distance_squared: float = INF
	for node in get_tree().get_nodes_in_group("players"):
		var player: CharacterBody3D = node as CharacterBody3D
		if player == null or player.is_queued_for_deletion():
			continue
		if not visible_player_peer_ids.has(player.get_multiplayer_authority()):
			continue
		var distance_squared: float = global_position.distance_squared_to(player.global_position)
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest_player = player
	return nearest_player


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
	if not show_vision_debug:
		facing_marker.material_override = null
	elif current_state == GuardState.RETURN_TO_PATROL:
		facing_marker.material_override = _returning_material
	elif current_state == GuardState.CHASE or not visible_player_peer_ids.is_empty():
		facing_marker.material_override = _detected_material
	else:
		facing_marker.material_override = null


func _set_patrol_target() -> void:
	navigation_agent.target_position = patrol_points[patrol_point_index].global_position


func _horizontal_distance_to(target: Vector3) -> float:
	var offset: Vector3 = target - global_position
	offset.y = 0.0
	return offset.length()


func _rotate_toward_movement(delta: float) -> void:
	_rotate_toward_direction(get_real_velocity(), delta)


func _rotate_toward_direction(direction: Vector3, delta: float) -> void:
	direction.y = 0.0
	if direction.is_zero_approx():
		return
	var target_yaw: float = atan2(-direction.x, -direction.z)
	rotation.y = rotate_toward(rotation.y, target_yaw, deg_to_rad(rotation_speed) * delta)

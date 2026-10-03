class_name CarryableObject
extends RigidBody3D

const DROP_CONTACT_TOLERANCE: float = 0.005

@export var item_id: StringName = &""
@export var holder_peer_id: int = 0
@export var is_consumed: bool = false
# The host sends the accepted transform for both carried and free objects.
@export_storage var network_transform: Transform3D = Transform3D.IDENTITY
var is_carried: bool:
	get:
		return holder_peer_id != 0

var _network_session_active: bool = false
var _server_simulates_physics: bool = true
var _players: Node3D
var _carry_point: Marker3D
var _world_collision_layer: int
var _world_collision_mask: int
var _world_freeze: bool
var _applied_holder_peer_id: int = -1
var _applied_is_consumed: bool = false
var _drop_requested: bool = false

@onready var _collision_shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	if _collision_shape == null or _collision_shape.shape == null:
		push_error("CarryableObject needs a CollisionShape3D with a shape.")
	_world_collision_layer = collision_layer
	_world_collision_mask = collision_mask
	_world_freeze = freeze
	network_transform = global_transform
	_apply_physics_state()
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	if _applied_holder_peer_id != holder_peer_id or _applied_is_consumed != is_consumed:
		_carry_point = null
		_apply_physics_state()

	if is_consumed:
		return
	if is_carried:
		if _network_session_active and not _server_simulates_physics:
			global_transform = network_transform
		else:
			if not is_instance_valid(_carry_point):
				_carry_point = _find_holder_carry_point()
			if is_instance_valid(_carry_point):
				_follow_carry_point()
			if _drop_requested:
				_drop_requested = false
				_finish_drop_if_safe()
	elif _network_session_active and not _server_simulates_physics:
		global_transform = network_transform

	if not _network_session_active or _server_simulates_physics:
		network_transform = global_transform


func begin_network_session(players: Node3D, server_simulates_physics: bool) -> void:
	_players = players
	_network_session_active = true
	_server_simulates_physics = server_simulates_physics
	network_transform = global_transform
	_apply_physics_state()
	set_physics_process(true)


func end_network_session() -> void:
	holder_peer_id = 0
	_carry_point = null
	_drop_requested = false
	_players = null
	_network_session_active = false
	_server_simulates_physics = true
	_apply_physics_state()
	network_transform = global_transform
	set_physics_process(false)


func pick_up(carry_point: Marker3D, peer_id: int) -> bool:
	if not is_multiplayer_authority() or is_consumed or is_carried or not is_instance_valid(carry_point):
		return false
	if peer_id <= 0 or _collision_shape == null or _collision_shape.shape == null:
		return false

	holder_peer_id = peer_id
	_carry_point = carry_point
	_drop_requested = false
	_apply_physics_state()
	network_transform = global_transform
	set_physics_process(true)
	return true


func drop() -> void:
	if not is_multiplayer_authority() or not is_carried:
		return
	# Finish in _physics_process so the space query is safe even on disconnect.
	_drop_requested = true


func consume() -> bool:
	if not is_multiplayer_authority() or is_consumed:
		return false

	holder_peer_id = 0
	_carry_point = null
	_drop_requested = false
	is_consumed = true
	_apply_physics_state()
	set_physics_process(_network_session_active)
	return true


func _apply_physics_state() -> void:
	_applied_holder_peer_id = holder_peer_id
	_applied_is_consumed = is_consumed
	visible = not is_consumed
	if is_consumed or is_carried:
		freeze = true
		collision_layer = 0
		collision_mask = 0
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
	else:
		collision_layer = _world_collision_layer
		collision_mask = _world_collision_mask
		# Free objects use host physics; clients display the host's transform.
		freeze = _world_freeze or (_network_session_active and not _server_simulates_physics)
		if not freeze:
			sleeping = false


func _follow_carry_point() -> void:
	var desired_transform: Transform3D = _carry_point.global_transform
	var start_transform := Transform3D(desired_transform.basis, global_position)
	if not _is_position_clear(start_transform, true):
		start_transform = global_transform
	global_transform = _sweep_carry_shape(start_transform, desired_transform)


func get_safe_holder_motion(carry_point: Marker3D, motion: Vector3) -> Vector3:
	if not is_carried or not is_instance_valid(carry_point) or motion.is_zero_approx():
		return motion
	# The owner checks its next step before move_and_slide(), using the same shape
	# that the host sweeps when it places the carried object.
	_carry_point = carry_point
	var start_transform: Transform3D = carry_point.global_transform
	if not _is_position_clear(start_transform, true):
		start_transform = global_transform
	var desired_transform := Transform3D(start_transform.basis, start_transform.origin + motion)
	return _sweep_carry_shape(start_transform, desired_transform).origin - start_transform.origin


func _sweep_carry_shape(
	start_transform: Transform3D, desired_transform: Transform3D
) -> Transform3D:

	var motion: Vector3 = desired_transform.origin - start_transform.origin
	var query: PhysicsShapeQueryParameters3D = _make_shape_query(start_transform, true)
	query.motion = motion
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var safe_fractions: PackedFloat32Array = space_state.cast_motion(query)
	var safe_fraction: float = safe_fractions[0] if not safe_fractions.is_empty() else 0.0
	var candidate := Transform3D(
		start_transform.basis, start_transform.origin + motion * safe_fraction
	)
	if not _is_position_clear(candidate, true):
		return start_transform
	if safe_fraction < 1.0 and safe_fractions.size() > 1 and not motion.is_zero_approx():
		# Use the contact normal to keep following sideways along a wall.
		var probe_fraction: float = minf(
			1.0, safe_fractions[1] + 0.01 / motion.length()
		)
		var impact_transform := Transform3D(
			start_transform.basis, start_transform.origin + motion * probe_fraction
		)
		var impact_query: PhysicsShapeQueryParameters3D = _make_shape_query(
			impact_transform, true
		)
		var impact: Dictionary = space_state.get_rest_info(impact_query)
		if not impact.is_empty():
			var obstacle_normal: Vector3 = impact["normal"]
			var remaining_motion: Vector3 = desired_transform.origin - candidate.origin
			var slide_motion: Vector3 = remaining_motion.slide(obstacle_normal)
			var slide_query: PhysicsShapeQueryParameters3D = _make_shape_query(
				candidate, true
			)
			slide_query.motion = slide_motion
			var slide_fractions: PackedFloat32Array = space_state.cast_motion(slide_query)
			if not slide_fractions.is_empty():
				var slide_candidate := Transform3D(
					candidate.basis, candidate.origin + slide_motion * slide_fractions[0]
				)
				if _is_position_clear(slide_candidate, true):
					candidate = slide_candidate

	var rotated_candidate := Transform3D(desired_transform.basis, candidate.origin)
	if _is_position_clear(rotated_candidate, true):
		candidate = rotated_candidate

	return candidate


func _finish_drop_if_safe() -> void:
	# The holder was excluded while carrying; validate the accepted pose against
	# the world and other objects, allowing a tiny numerical contact tolerance.
	if not _is_position_clear(global_transform, true, DROP_CONTACT_TOLERANCE):
		return

	network_transform = global_transform
	holder_peer_id = 0
	_carry_point = null
	_apply_physics_state()
	set_physics_process(_network_session_active)


func _is_position_clear(
	root_transform: Transform3D, exclude_holder: bool, contact_tolerance: float = 0.0
) -> bool:
	if _collision_shape == null or _collision_shape.shape == null:
		return false
	var query: PhysicsShapeQueryParameters3D = _make_shape_query(root_transform, exclude_holder)
	if contact_tolerance > 0.0 and query.shape is BoxShape3D:
		var box_shape: BoxShape3D = query.shape as BoxShape3D
		var contact_shape := BoxShape3D.new()
		contact_shape.size = box_shape.size - Vector3.ONE * (2.0 * contact_tolerance)
		query.shape = contact_shape
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func _make_shape_query(
	root_transform: Transform3D, exclude_holder: bool
) -> PhysicsShapeQueryParameters3D:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _collision_shape.shape
	query.transform = root_transform * _collision_shape.transform
	query.collision_mask = _world_collision_mask
	var excluded_bodies: Array[RID] = [get_rid()]
	if exclude_holder and is_instance_valid(_carry_point):
		var holder: CollisionObject3D = _carry_point.get_parent() as CollisionObject3D
		if holder != null:
			excluded_bodies.append(holder.get_rid())
	query.exclude = excluded_bodies
	return query


func _find_holder_carry_point() -> Marker3D:
	if _players == null:
		return null
	var player: Node = _players.get_node_or_null(str(holder_peer_id))
	if player == null:
		return null
	return player.get_node_or_null("CarryPoint") as Marker3D

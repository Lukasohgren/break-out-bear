class_name CarryableObject
extends RigidBody3D

@export var holder_peer_id: int = 0
# The host sends this transform; clients apply it only while the object is free.
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


func _ready() -> void:
	_world_collision_layer = collision_layer
	_world_collision_mask = collision_mask
	_world_freeze = freeze
	network_transform = global_transform
	_apply_physics_state()
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	if _applied_holder_peer_id != holder_peer_id:
		_carry_point = null
		_apply_physics_state()

	if is_carried:
		if not is_instance_valid(_carry_point):
			_carry_point = _find_holder_carry_point()
		if is_instance_valid(_carry_point):
			global_transform = _carry_point.global_transform
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
	if is_carried and is_instance_valid(_carry_point):
		global_transform = _carry_point.global_transform
	holder_peer_id = 0
	_carry_point = null
	_players = null
	_network_session_active = false
	_server_simulates_physics = true
	_apply_physics_state()
	network_transform = global_transform
	set_physics_process(false)


func pick_up(carry_point: Marker3D, peer_id: int) -> bool:
	if not is_multiplayer_authority() or is_carried or not is_instance_valid(carry_point):
		return false
	if peer_id <= 0:
		return false

	holder_peer_id = peer_id
	_carry_point = carry_point
	_apply_physics_state()
	global_transform = _carry_point.global_transform
	network_transform = global_transform
	set_physics_process(true)
	return true


func drop() -> void:
	if not is_multiplayer_authority() or not is_carried:
		return
	if is_instance_valid(_carry_point):
		global_transform = _carry_point.global_transform

	network_transform = global_transform
	holder_peer_id = 0
	_carry_point = null
	_apply_physics_state()
	set_physics_process(_network_session_active)


func _apply_physics_state() -> void:
	_applied_holder_peer_id = holder_peer_id
	if is_carried:
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


func _find_holder_carry_point() -> Marker3D:
	if _players == null:
		return null
	var player: Node = _players.get_node_or_null(str(holder_peer_id))
	if player == null:
		return null
	return player.get_node_or_null("CarryPoint") as Marker3D

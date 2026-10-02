extends Area3D

@export_range(0.1, 3.0, 0.05, "or_greater", "suffix:m")
var max_interaction_distance: float = 1.1

@onready var carry_point: Marker3D = $"../CarryPoint"


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if not Input.is_action_just_pressed("interact"):
		return

	var peer_id: int = get_multiplayer_authority()
	if _find_held_object(peer_id) != null:
		if multiplayer.is_server():
			_server_try_drop(peer_id)
		else:
			_request_drop.rpc_id(1)
		return

	var nearest_object: CarryableObject = _find_nearest_object()
	if nearest_object == null:
		return
	var object_path: String = str(get_tree().current_scene.get_path_to(nearest_object))
	if multiplayer.is_server():
		_server_try_pickup(peer_id, object_path)
	else:
		_request_pickup.rpc_id(1, object_path)


@rpc("any_peer", "call_remote", "reliable")
func _request_pickup(object_path: String) -> void:
	if multiplayer.is_server():
		_server_try_pickup(multiplayer.get_remote_sender_id(), object_path)


@rpc("any_peer", "call_remote", "reliable")
func _request_drop() -> void:
	if multiplayer.is_server():
		_server_try_drop(multiplayer.get_remote_sender_id())


func _server_try_pickup(peer_id: int, object_path: String) -> void:
	if not multiplayer.is_server() or not _is_valid_requester(peer_id):
		return
	if _find_held_object(peer_id) != null:
		return

	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	var object: CarryableObject = scene.get_node_or_null(NodePath(object_path)) as CarryableObject
	if (
		object == null
		or object.is_queued_for_deletion()
		or not scene.is_ancestor_of(object)
		or not object.is_in_group("carryables")
	):
		return
	if object.is_carried or global_position.distance_to(object.global_position) > max_interaction_distance:
		return

	object.pick_up(carry_point, peer_id)


func _server_try_drop(peer_id: int) -> void:
	if not multiplayer.is_server() or not _is_valid_requester(peer_id):
		return
	var object: CarryableObject = _find_held_object(peer_id)
	if object != null:
		object.drop()


func _is_valid_requester(peer_id: int) -> bool:
	var player: CharacterBody3D = get_parent() as CharacterBody3D
	return (
		peer_id > 0
		and player != null
		and player.is_inside_tree()
		and not player.is_queued_for_deletion()
		and player.is_in_group("players")
		and player.get_multiplayer_authority() == peer_id
		and get_multiplayer_authority() == peer_id
	)


func _find_held_object(peer_id: int) -> CarryableObject:
	for node in get_tree().get_nodes_in_group("carryables"):
		var object: CarryableObject = node as CarryableObject
		if object != null and not object.is_queued_for_deletion() and object.holder_peer_id == peer_id:
			return object
	return null


func _find_nearest_object() -> CarryableObject:
	var nearest_object: CarryableObject
	var nearest_distance_squared: float = INF
	for body in get_overlapping_bodies():
		var candidate: CarryableObject = body as CarryableObject
		if candidate == null or candidate.is_carried or not candidate.is_in_group("carryables"):
			continue
		var distance_squared: float = global_position.distance_squared_to(
			candidate.global_position
		)
		if distance_squared < nearest_distance_squared:
			nearest_object = candidate
			nearest_distance_squared = distance_squared

	return nearest_object

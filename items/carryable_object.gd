class_name CarryableObject
extends RigidBody3D

var is_carried: bool = false

var _world_parent: Node
var _world_collision_layer: int
var _world_collision_mask: int
var _world_freeze: bool


func pick_up(carry_point: Marker3D) -> bool:
	if is_carried or carry_point == null:
		return false

	_world_parent = get_parent()
	_world_collision_layer = collision_layer
	_world_collision_mask = collision_mask
	_world_freeze = freeze
	is_carried = true
	freeze = true
	collision_layer = 0
	collision_mask = 0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	reparent(carry_point, false)
	transform = Transform3D.IDENTITY
	return true


func drop() -> void:
	if not is_carried:
		return
	if not is_instance_valid(_world_parent):
		push_error("Cannot drop a carryable object without its original world parent.")
		return

	reparent(_world_parent, true)
	collision_layer = _world_collision_layer
	collision_mask = _world_collision_mask
	freeze = _world_freeze
	if not freeze:
		sleeping = false
	is_carried = false
	_world_parent = null

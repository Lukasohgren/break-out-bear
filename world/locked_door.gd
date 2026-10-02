class_name LockedDoor
extends StaticBody3D

@export var required_item_id: StringName = &"shelf_key"
@export var open_offset: Vector3 = Vector3(1.1, 0.0, 0.0)
@export var is_open: bool = false:
	set(value):
		is_open = value
		if _has_closed_position:
			_apply_open_state()

var _closed_position: Vector3
var _has_closed_position: bool = false


func _ready() -> void:
	_closed_position = position
	_has_closed_position = true
	_apply_open_state()


func try_unlock(player: CharacterBody3D, held_object: CarryableObject) -> void:
	if not multiplayer.is_server() or not is_multiplayer_authority() or is_open:
		return
	if player == null or not is_instance_valid(held_object):
		return
	if (
		held_object.is_consumed
		or held_object.holder_peer_id != player.get_multiplayer_authority()
		or held_object.item_id != required_item_id
	):
		return
	if held_object.consume():
		is_open = true


func _apply_open_state() -> void:
	position = _closed_position + open_offset if is_open else _closed_position

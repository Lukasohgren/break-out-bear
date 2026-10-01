extends Node3D

@export_range(0.0, 20.0, 0.1, "or_greater")
var follow_speed: float = 5.0


func _process(delta: float) -> void:
	var summed_positions: Vector3 = Vector3.ZERO
	var player_count: int = 0

	for node in get_tree().get_nodes_in_group("players"):
		var player: Node3D = node as Node3D
		if player == null or player.is_queued_for_deletion():
			continue
		summed_positions += player.global_position
		player_count += 1

	if player_count == 0:
		return

	var group_center: Vector3 = summed_positions / float(player_count)
	var target_position: Vector3 = Vector3(
		group_center.x, global_position.y, group_center.z
	)
	var blend: float = 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(target_position, blend)

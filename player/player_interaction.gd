extends Area3D

@onready var carry_point: Marker3D = $"../CarryPoint"

var carried_object: CarryableObject


func _physics_process(_delta: float) -> void:
	if not Input.is_action_just_pressed("interact"):
		return

	if is_instance_valid(carried_object):
		carried_object.drop()
		if not carried_object.is_carried:
			carried_object = null
		return

	var nearest_object: CarryableObject
	var nearest_distance_squared: float = INF
	for body in get_overlapping_bodies():
		var candidate: CarryableObject = body as CarryableObject
		if candidate == null or candidate.is_carried:
			continue
		var distance_squared: float = global_position.distance_squared_to(
			candidate.global_position
		)
		if distance_squared < nearest_distance_squared:
			nearest_object = candidate
			nearest_distance_squared = distance_squared

	if nearest_object != null and nearest_object.pick_up(carry_point):
		carried_object = nearest_object

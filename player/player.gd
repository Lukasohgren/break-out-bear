extends CharacterBody3D

@export var movement_camera: Camera3D

@export_group("Movement")
@export_range(0.0, 10.0, 0.1, "or_greater", "suffix:m/s")
var move_speed: float = 1.5
## Maximum turning speed in degrees per second. The player's forward axis is -Z.
@export_range(0.0, 1080.0, 10.0, "or_greater", "suffix:deg/s")
var rotation_speed: float = 540.0

@export_group("Jumping")
@export_range(0.0, 10.0, 0.1, "or_greater", "suffix:m/s")
var jump_velocity: float = 3.0

@export_group("Gravity")
@export_range(0.0, 50.0, 0.1, "or_greater", "suffix:m/s²")
var gravity: float = 9.8
@export_range(0.1, 50.0, 0.1, "or_greater", "suffix:m/s")
var maximum_fall_speed: float = 20.0


func _ready() -> void:
	if movement_camera == null:
		push_error("Player needs a Movement Camera reference in the Inspector.")
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	var input_vector: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_backward"
	)
	var movement_direction: Vector3 = _get_movement_direction(input_vector)
	velocity.x = movement_direction.x * move_speed
	velocity.z = movement_direction.z * move_speed

	if is_on_floor():
		velocity.y = 0.0
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
	else:
		velocity.y = maxf(velocity.y - gravity * delta, -maximum_fall_speed)

	# move_and_slide() applies the physics timestep to velocity itself.
	move_and_slide()

	if not input_vector.is_zero_approx():
		_rotate_toward_movement(delta)


func _get_movement_direction(input_vector: Vector2) -> Vector3:
	var camera_right: Vector3 = movement_camera.global_basis.x
	var camera_backward: Vector3 = movement_camera.global_basis.z
	# Flatten and normalize each axis so camera pitch cannot change walking speed.
	camera_right.y = 0.0
	camera_backward.y = 0.0
	var direction: Vector3 = (
		camera_right.normalized() * input_vector.x
		+ camera_backward.normalized() * input_vector.y
	)
	# Keep Input.get_vector()'s capped strength, including partial analog input.
	return direction.normalized() * input_vector.length()


func _rotate_toward_movement(delta: float) -> void:
	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	if horizontal_velocity.is_zero_approx():
		return

	var target_yaw: float = atan2(-horizontal_velocity.x, -horizontal_velocity.z)
	global_rotation.y = rotate_toward(
		global_rotation.y, target_yaw, deg_to_rad(rotation_speed) * delta
	)

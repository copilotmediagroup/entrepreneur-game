extends CharacterBody3D

const SPEED := 6.0
const ACCEL := 18.0
const GRAVITY := 20.0
const MIN_X := -19.0
const MAX_X := 19.0
const MIN_Z := -15.0
const MAX_Z := 15.0

func _physics_process(delta):
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input.x, 0.0, input.y)
	var target := direction * SPEED
	velocity.x = move_toward(velocity.x, target.x, ACCEL * delta)
	velocity.z = move_toward(velocity.z, target.z, ACCEL * delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	if direction.length() > 0.05:
		$Mesh.rotation.y = lerp_angle($Mesh.rotation.y, atan2(direction.x, direction.z), 10.0 * delta)
	move_and_slide()
	global_position.x = clamp(global_position.x, MIN_X, MAX_X)
	global_position.z = clamp(global_position.z, MIN_Z, MAX_Z)
	if global_position.y < -2.0:
		global_position = Vector3(-4, 1.0, 7)
		velocity = Vector3.ZERO

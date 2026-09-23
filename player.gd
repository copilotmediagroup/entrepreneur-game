extends CharacterBody3D

const SPEED := 6.0
const ACCEL := 18.0
const GRAVITY := 20.0

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
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), 10.0 * delta)
	move_and_slide()

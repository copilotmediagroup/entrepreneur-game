extends CharacterBody3D

const WALK_SPEED := 6.0
const WALK_ACCEL := 24.0
const GRAVITY := 20.0
const ENGINE_ACCEL := 15.0
const BRAKE_ACCEL := 25.0
const MAX_FORWARD_SPEED := 19.0
const MAX_REVERSE_SPEED := 7.0
const ROLLING_FRICTION := 7.0
const STEER_RATE := 1.8
const COAST_STEER_RATE := 1.35
const WORLD_LIMIT := 38.0

var driving := false
var car_speed := 0.0
var old_car: MeshInstance3D
var camera: Camera3D


func _ready() -> void:
	old_car = get_node("../OldCar")
	camera = $Camera


func _physics_process(delta: float) -> void:
	if driving:
		_drive(delta)
	else:
		_walk(delta)
	_apply_bounds()
	_update_camera(delta)


func _walk(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var target := Vector3(input.x, 0, input.y) * WALK_SPEED
	velocity.x = move_toward(velocity.x, target.x, WALK_ACCEL * delta)
	velocity.z = move_toward(velocity.z, target.z, WALK_ACCEL * delta)
	velocity.y = -GRAVITY if not is_on_floor() else 0.0
	if input.length() > 0.05:
		$Mesh.rotation.y = lerp_angle($Mesh.rotation.y, atan2(input.x, input.y), 10.0 * delta)
	move_and_slide()


func _drive(delta: float) -> void:
	var throttle := Input.get_axis("move_back", "move_forward")
	if throttle > 0.0:
		car_speed = move_toward(car_speed, MAX_FORWARD_SPEED, ENGINE_ACCEL * throttle * delta)
	elif throttle < 0.0:
		var rate := BRAKE_ACCEL if car_speed > 0.0 else ENGINE_ACCEL
		car_speed = move_toward(car_speed, -MAX_REVERSE_SPEED, rate * -throttle * delta)
	else:
		car_speed = move_toward(car_speed, 0.0, ROLLING_FRICTION * delta)
	var steering := Input.get_axis("move_left", "move_right")
	var steer_strength: float = clamp(abs(car_speed) / 5.0, 0.15, 1.0)
	if abs(car_speed) > 0.15:
		var steer_rate := STEER_RATE if abs(car_speed) < 12.0 else COAST_STEER_RATE
		old_car.rotation.y -= steering * steer_rate * steer_strength * sign(car_speed) * delta
	var forward := Vector3(-sin(old_car.rotation.y), 0, -cos(old_car.rotation.y))
	velocity = forward * car_speed
	move_and_slide()
	# Collisions should scrub speed instead of letting the car push forever.
	if get_slide_collision_count() > 0:
		car_speed *= 0.72
	old_car.global_position = Vector3(global_position.x, 0.7, global_position.z)
	$Mesh.visible = false


func _apply_bounds() -> void:
	global_position.x = clamp(global_position.x, -WORLD_LIMIT, WORLD_LIMIT)
	global_position.z = clamp(global_position.z, -WORLD_LIMIT, WORLD_LIMIT)
	if global_position.y < -2.0:
		global_position = Vector3(-4, 1, 7)
		velocity = Vector3.ZERO
		car_speed = 0.0


func _update_camera(delta: float) -> void:
	var yaw: float = old_car.rotation.y if driving else $Mesh.rotation.y
	var distance := 10.5 if driving else 8.0
	var desired := Vector3(sin(yaw) * distance, 6.0 if driving else 5.5, cos(yaw) * distance)
	camera.position = camera.position.lerp(desired, min(1.0, delta * 6.0))
	camera.look_at(global_position + Vector3(0, 1, 0), Vector3.UP)


func toggle_vehicle() -> bool:
	if driving:
		driving = false
		car_speed = 0.0
		global_position += Vector3(cos(old_car.rotation.y), 0, -sin(old_car.rotation.y)) * 2.2
		$Mesh.visible = true
		return true
	if global_position.distance_to(old_car.global_position) < 5.0:
		driving = true
		global_position = Vector3(old_car.global_position.x, 1, old_car.global_position.z)
		return true
	return false


func is_driving() -> bool:
	return driving


func force_exit_vehicle() -> void:
	if driving:
		toggle_vehicle()
		velocity = Vector3.ZERO


func speed_mph() -> int:
	return int(abs(car_speed) * 2.2)


func set_parked_car(pos: Vector3, yaw: float) -> void:
	old_car.global_position = Vector3(pos.x, 0.7, pos.z)
	old_car.rotation.y = yaw

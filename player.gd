extends CharacterBody3D

const WALK_SPEED=6.0
const DRIVE_SPEED=13.0
const ACCEL=18.0
const GRAVITY=20.0
const MIN_X=-19.0
const MAX_X=19.0
const MIN_Z=-15.0
const MAX_Z=15.0
var driving=false
var old_car:MeshInstance3D
var f_was_down=false

func _ready():
 old_car=get_node("../OldCar")

func _physics_process(delta):
 var input=Input.get_vector("move_left","move_right","move_forward","move_back")
 var speed=DRIVE_SPEED if driving else WALK_SPEED
 var direction=Vector3(input.x,0,input.y)
 var target=direction*speed
 velocity.x=move_toward(velocity.x,target.x,ACCEL*delta)
 velocity.z=move_toward(velocity.z,target.z,ACCEL*delta)
 if not is_on_floor():velocity.y-=GRAVITY*delta
 else:velocity.y=0
 if direction.length()>.05:$Mesh.rotation.y=lerp_angle($Mesh.rotation.y,atan2(direction.x,direction.z),10*delta)
 move_and_slide()
 global_position.x=clamp(global_position.x,MIN_X,MAX_X)
 global_position.z=clamp(global_position.z,MIN_Z,MAX_Z)
 if driving:
  old_car.global_position=Vector3(global_position.x,.7,global_position.z);$Mesh.visible=false
 else:$Mesh.visible=true
 if global_position.y < -2:global_position=Vector3(-4,1,7);velocity=Vector3.ZERO
 var f_down=Input.is_key_pressed(KEY_F)
 if f_down and not f_was_down:_toggle_vehicle()
 f_was_down=f_down

func _toggle_vehicle():
 if driving:
  driving=false;global_position+=Vector3(2,0,0)
 elif global_position.distance_to(old_car.global_position)<3.0:
  driving=true;global_position=Vector3(old_car.global_position.x,1,old_car.global_position.z)

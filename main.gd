extends Node3D

@onready var player = $Player
@onready var cash_label = $HUD/Cash
@onready var job_panel = $HUD/JobPanel
@onready var status_label = $HUD/Status

var cash := 300
var job_state := 0
var wash_amount := 0.0
var marker: MeshInstance3D
var customer_car: MeshInstance3D
var objective: Label
var wash_bar: ProgressBar

func _ready():
	cash_label.text = "CASH: $%d" % cash
	_build_gameplay_nodes()
	objective.text = "OBJECTIVE: Accept your first detailing job"
	wash_bar.visible = false

func _build_gameplay_nodes():
	marker = MeshInstance3D.new()
	marker.name = "CustomerMarker"
	var marker_mesh = CylinderMesh.new()
	marker_mesh.top_radius = 0.8
	marker_mesh.bottom_radius = 0.8
	marker_mesh.height = 0.12
	var marker_material = StandardMaterial3D.new()
	marker_material.albedo_color = Color(0.1, 0.7, 1.0)
	marker_material.emission_enabled = true
	marker_material.emission = Color(0.1, 0.55, 1.0)
	marker_material.emission_energy_multiplier = 3.0
	marker_mesh.material = marker_material
	marker.mesh = marker_mesh
	marker.position = Vector3(8, 0.25, -8)
	add_child(marker)

	customer_car = MeshInstance3D.new()
	customer_car.name = "CustomerBMW"
	var car_mesh = BoxMesh.new()
	car_mesh.size = Vector3(2.2, 1.2, 4.5)
	var car_material = StandardMaterial3D.new()
	car_material.albedo_color = Color(0.12, 0.22, 0.42)
	car_mesh.material = car_material
	customer_car.mesh = car_mesh
	customer_car.position = Vector3(10, 0.7, -8)
	customer_car.rotation_degrees = Vector3(0, 90, 0)
	add_child(customer_car)

	objective = Label.new()
	objective.position = Vector2(24, 112)
	objective.add_theme_font_size_override("font_size", 20)
	$HUD.add_child(objective)

	wash_bar = ProgressBar.new()
	wash_bar.position = Vector2(440, 610)
	wash_bar.size = Vector2(400, 32)
	wash_bar.max_value = 100
	$HUD.add_child(wash_bar)

func _process(delta):
	if job_state == 1:
		var distance = player.global_position.distance_to(marker.global_position)
		status_label.text = "Jessica's BMW • %.0f m away" % distance
		if distance < 3.5:
			job_state = 2
			objective.text = "OBJECTIVE: Hold E to detail the BMW"
			wash_bar.visible = true
	elif job_state == 2 and Input.is_key_pressed(KEY_E):
		wash_amount = min(100.0, wash_amount + 30.0 * delta)
		wash_bar.value = wash_amount
		status_label.text = "Detailing... %d%%" % int(wash_amount)
		if wash_amount >= 100.0:
			_complete_job()

func _on_accept_pressed():
	job_state = 1
	job_panel.visible = false
	objective.text = "OBJECTIVE: Walk to the glowing blue customer marker"
	status_label.text = "FIRST JOB ACCEPTED • Jessica R. • $85"

func _complete_job():
	job_state = 3
	cash += 85
	cash_label.text = "CASH: $%d" % cash
	objective.text = "JOB COMPLETE! You earned $85"
	status_label.text = "5-STAR REVIEW • Jessica loved the detail"
	wash_bar.visible = false
	marker.visible = false

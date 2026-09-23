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
var wash_label: Label
var equipment_label: Label

func _ready():
	cash_label.text = "CASH: $%d" % cash
	_build_gameplay_nodes()
	objective.text = "OBJECTIVE: Accept your first detailing job"
	wash_bar.visible = false
	wash_label.visible = false

func _make_material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	return mat

func _build_gameplay_nodes():
	marker = MeshInstance3D.new()
	var marker_mesh = CylinderMesh.new()
	marker_mesh.top_radius = 0.8
	marker_mesh.bottom_radius = 0.8
	marker_mesh.height = 0.12
	var marker_mat = _make_material(Color(0.1, 0.7, 1.0))
	marker_mat.emission_enabled = true
	marker_mat.emission = Color(0.1, 0.55, 1.0)
	marker_mat.emission_energy_multiplier = 3.0
	marker_mesh.material = marker_mat
	marker.mesh = marker_mesh
	marker.position = Vector3(8, 0.25, -8)
	add_child(marker)

	customer_car = MeshInstance3D.new()
	var car_mesh = BoxMesh.new()
	car_mesh.size = Vector3(2.2, 1.2, 4.5)
	car_mesh.material = _make_material(Color(0.28, 0.20, 0.12))
	customer_car.mesh = car_mesh
	customer_car.position = Vector3(10, 0.7, -8)
	customer_car.rotation_degrees = Vector3(0, 90, 0)
	add_child(customer_car)

	objective = Label.new()
	objective.position = Vector2(24, 112)
	objective.add_theme_font_size_override("font_size", 20)
	$HUD.add_child(objective)

	equipment_label = Label.new()
	equipment_label.position = Vector2(24, 155)
	equipment_label.text = "EQUIPMENT: Bucket + Basic Wash Kit"
	equipment_label.add_theme_font_size_override("font_size", 17)
	$HUD.add_child(equipment_label)

	wash_label = Label.new()
	wash_label.position = Vector2(440, 575)
	wash_label.text = "DIRT: 100%   •   HOLD E TO WASH"
	wash_label.add_theme_font_size_override("font_size", 18)
	$HUD.add_child(wash_label)

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
			objective.text = "OBJECTIVE: Wash Jessica's dirty BMW"
			wash_bar.visible = true
			wash_label.visible = true
	elif job_state == 2:
		if Input.is_key_pressed(KEY_E):
			wash_amount = min(100.0, wash_amount + 24.0 * delta)
			wash_bar.value = wash_amount
			var dirt = 100 - int(wash_amount)
			wash_label.text = "DIRT: %d%%   •   WASHED: %d%%" % [dirt, int(wash_amount)]
			status_label.text = "Scrubbing exterior..."
			var dirty = Color(0.28, 0.20, 0.12)
			var clean = Color(0.08, 0.32, 0.70)
			customer_car.mesh.material.albedo_color = dirty.lerp(clean, wash_amount / 100.0)
			if wash_amount >= 100.0:
				_complete_job()
		else:
			status_label.text = "Hold E to use your Basic Wash Kit"

func _on_accept_pressed():
	job_state = 1
	job_panel.visible = false
	objective.text = "OBJECTIVE: Walk to the glowing blue customer marker"
	status_label.text = "FIRST JOB ACCEPTED • Jessica R. • $85"

func _complete_job():
	job_state = 3
	cash += 85
	cash_label.text = "CASH: $%d" % cash
	objective.text = "JOB COMPLETE • $85 earned • ★★★★★"
	status_label.text = "Jessica: Great job! I'll recommend you."
	wash_bar.visible = false
	wash_label.visible = false
	marker.visible = false
	equipment_label.text = "NEXT GOAL: Earn $500 to unlock better equipment"

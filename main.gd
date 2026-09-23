extends Node3D

@onready var player = $Player
@onready var cash_label = $HUD/Cash
@onready var job_panel = $HUD/JobPanel
@onready var status_label = $HUD/Status
@onready var job_text = $HUD/JobPanel/JobText

var cash := 300
var reputation := 0
var jobs_completed := 0
var current_job := -1
var job_state := 0
var wash_amount := 0.0
var equipment_level := 0

var marker: MeshInstance3D
var customer_car: MeshInstance3D
var customer_npc: MeshInstance3D
var objective: Label
var wash_bar: ProgressBar
var wash_label: Label
var equipment_label: Label
var stats_label: Label
var next_job_button: Button
var upgrade_button: Button

var jobs = [
	{"name":"Jessica R.","car":"BMW 328i","pay":85,"pos":Vector3(8,0.25,-8),"color":Color(0.08,0.32,0.70)},
	{"name":"Marcus T.","car":"Ford F-150","pay":110,"pos":Vector3(-14,0.25,10),"color":Color(0.55,0.08,0.06)},
	{"name":"Denise W.","car":"Mercedes C300","pay":125,"pos":Vector3(13,0.25,8),"color":Color(0.12,0.12,0.14)}
]

func _ready():
	_build_gameplay_nodes()
	_update_hud()
	_offer_next_job()

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
	var marker_mat = _make_material(Color(0.1,0.7,1.0))
	marker_mat.emission_enabled = true
	marker_mat.emission = Color(0.1,0.55,1.0)
	marker_mat.emission_energy_multiplier = 3.0
	marker_mesh.material = marker_mat
	marker.mesh = marker_mesh
	add_child(marker)

	customer_car = MeshInstance3D.new()
	var car_mesh = BoxMesh.new()
	car_mesh.size = Vector3(2.2,1.2,4.5)
	car_mesh.material = _make_material(Color(0.28,0.20,0.12))
	customer_car.mesh = car_mesh
	add_child(customer_car)

	customer_npc = MeshInstance3D.new()
	var npc_mesh = CapsuleMesh.new()
	npc_mesh.radius = 0.45
	npc_mesh.height = 1.7
	npc_mesh.material = _make_material(Color(0.8,0.55,0.25))
	customer_npc.mesh = npc_mesh
	add_child(customer_npc)

	objective = Label.new()
	objective.position = Vector2(24,112)
	objective.add_theme_font_size_override("font_size",20)
	$HUD.add_child(objective)

	equipment_label = Label.new()
	equipment_label.position = Vector2(24,150)
	equipment_label.add_theme_font_size_override("font_size",17)
	$HUD.add_child(equipment_label)

	stats_label = Label.new()
	stats_label.position = Vector2(24,185)
	stats_label.add_theme_font_size_override("font_size",16)
	$HUD.add_child(stats_label)

	wash_label = Label.new()
	wash_label.position = Vector2(440,570)
	wash_label.add_theme_font_size_override("font_size",18)
	$HUD.add_child(wash_label)

	wash_bar = ProgressBar.new()
	wash_bar.position = Vector2(440,605)
	wash_bar.size = Vector2(400,32)
	wash_bar.max_value = 100
	$HUD.add_child(wash_bar)

	next_job_button = Button.new()
	next_job_button.text = "NEXT CUSTOMER"
	next_job_button.position = Vector2(1000,610)
	next_job_button.size = Vector2(210,48)
	next_job_button.pressed.connect(_offer_next_job)
	$HUD.add_child(next_job_button)

	upgrade_button = Button.new()
	upgrade_button.text = "BUY PRESSURE WASHER - $200"
	upgrade_button.position = Vector2(950,550)
	upgrade_button.size = Vector2(270,48)
	upgrade_button.pressed.connect(_buy_upgrade)
	$HUD.add_child(upgrade_button)

func _update_hud():
	cash_label.text = "CASH: $%d" % cash
	stats_label.text = "JOBS: %d   •   REPUTATION: %d ★" % [jobs_completed,reputation]
	equipment_label.text = "EQUIPMENT: %s" % ("Pressure Washer" if equipment_level == 1 else "Bucket + Basic Wash Kit")
	upgrade_button.visible = equipment_level == 0 and cash >= 500

func _offer_next_job():
	current_job = (current_job + 1) % jobs.size()
	var job = jobs[current_job]
	job_state = 0
	wash_amount = 0.0
	job_panel.visible = true
	next_job_button.visible = false
	wash_bar.visible = false
	wash_label.visible = false
	marker.visible = false
	customer_car.visible = false
	customer_npc.visible = false
	objective.text = "OBJECTIVE: Build your detailing business"
	job_text.text = "%s\n%s\nExterior + Interior\nOffer: $%d" % [job.name,job.car,job.pay]
	status_label.text = "New customer lead received"

func _on_accept_pressed():
	var job = jobs[current_job]
	job_state = 1
	job_panel.visible = false
	marker.position = job.pos
	customer_car.position = job.pos + Vector3(2,0.45,0)
	customer_npc.position = job.pos + Vector3(-1.5,0.85,0)
	marker.visible = true
	customer_car.visible = true
	customer_npc.visible = true
	customer_car.mesh.material.albedo_color = Color(0.28,0.20,0.12)
	objective.text = "OBJECTIVE: Go to %s's vehicle" % job.name
	status_label.text = "JOB ACCEPTED • %s • $%d" % [job.car,job.pay]

func _process(delta):
	if job_state == 1:
		var distance = player.global_position.distance_to(marker.global_position)
		status_label.text = "%s's %s • %.0f m away" % [jobs[current_job].name,jobs[current_job].car,distance]
		if distance < 3.5:
			job_state = 2
			objective.text = "OBJECTIVE: Detail the %s" % jobs[current_job].car
			wash_bar.visible = true
			wash_label.visible = true
	elif job_state == 2:
		if Input.is_key_pressed(KEY_E):
			var rate = 55.0 if equipment_level == 1 else 24.0
			wash_amount = min(100.0,wash_amount + rate * delta)
			wash_bar.value = wash_amount
			wash_label.text = "DIRT: %d%%   •   CLEAN: %d%%" % [100-int(wash_amount),int(wash_amount)]
			var dirty = Color(0.28,0.20,0.12)
			customer_car.mesh.material.albedo_color = dirty.lerp(jobs[current_job].color,wash_amount/100.0)
			status_label.text = "Pressure washing..." if equipment_level == 1 else "Scrubbing by hand..."
			if wash_amount >= 100.0:
				_complete_job()
		else:
			status_label.text = "Hold E to clean the vehicle"

func _complete_job():
	job_state = 3
	var job = jobs[current_job]
	cash += job.pay
	jobs_completed += 1
	reputation += 1
	_update_hud()
	objective.text = "JOB COMPLETE • $%d earned • ★★★★★" % job.pay
	status_label.text = "%s: Great work! I'll recommend you." % job.name
	wash_bar.visible = false
	wash_label.visible = false
	marker.visible = false
	next_job_button.visible = true
	if cash >= 500 and equipment_level == 0:
		status_label.text += "  Pressure washer unlocked!"

func _buy_upgrade():
	if cash >= 200 and equipment_level == 0:
		cash -= 200
		equipment_level = 1
		_update_hud()
		status_label.text = "UPGRADE PURCHASED • Jobs now clean more than twice as fast."

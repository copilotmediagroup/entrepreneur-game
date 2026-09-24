extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var cash_label: Label = $HUD/Cash
@onready var job_panel: Panel = $HUD/JobPanel
@onready var status_label: Label = $HUD/Status
@onready var job_text: Label = $HUD/JobPanel/JobText
@onready var job_title: Label = $HUD/JobPanel/JobTitle
@onready var hint: Label = $HUD/Hint

const BusinessSystemScript = preload("res://business_system.gd")
const EconomySystemScript = preload("res://economy_system.gd")
const PressureBusinessScript = preload("res://pressure_business.gd")

var business = BusinessSystemScript.new()
var economy = EconomySystemScript.new()
var pressure = PressureBusinessScript.new()

var cash := 300
var reputation := 0
var jobs_completed := 0
var current_job := -1
var job_state := 0 # 0 offer, 1 travel, 2 working, 3 complete
var service := "detail"
var detailing_equipment := 0
var home_tier := 0
var vehicle_tier := 0
var day := 1
var jobs_today := 0
var fuel := 100.0
var negotiated_bonus := 0
var zone_index := 0
var zone_progress := 0.0
var last_player_pos := Vector3.ZERO
var current_contract: Dictionary = {}

var marker: MeshInstance3D
var customer_car: Node3D
var customer_car_body: MeshInstance3D
var customer_npc: Node3D
var customer_sign: Label3D
var dirt_panels: Array[MeshInstance3D] = []
var zone_marker: MeshInstance3D
var gas_marker: MeshInstance3D
var supply_marker: MeshInstance3D
var objective: Label
var progress_bar: ProgressBar
var progress_label: Label
var equipment_label: Label
var stats_label: Label
var business_label: Label
var branch_label: Label
var context_label: Label
var next_job_button: Button
var pressure_button: Button
var negotiate_button: Button
var skip_button: Button
var reset_button: Button
var waypoint_label: Label
var guide_label: Label
var customer_met := false
var save_notice_time := 0.0
var phone_open := false
var phone_button: Button
var phone_header: Label
var dialogue_panel: Panel
var dialogue_label: Label
var toast_panel: Panel
var toast_label: Label
var toast_time := 0.0
var work_tool: Node3D
var ambient_people: Array[Node3D] = []
var ambient_origins: Array[Vector3] = []

const DETAIL_JOBS := [
	{"name":"Jessica R.", "car":"BMW 328i", "pay":85, "pos":Vector3(19,.25,-12), "color":Color(.08,.32,.70)},
	{"name":"Marcus T.", "car":"Ford F-150", "pay":110, "pos":Vector3(-19,.25,12), "color":Color(.55,.08,.06)},
	{"name":"Denise W.", "car":"Mercedes C300", "pay":125, "pos":Vector3(20,.25,12), "color":Color(.12,.12,.14)},
	{"name":"Andre B.", "car":"Dodge Charger", "pay":140, "pos":Vector3(-20,.25,-12), "color":Color(.18,.18,.55)},
	{"name":"Tasha M.", "car":"Honda Accord", "pay":95, "pos":Vector3(19,.25,-27), "color":Color(.72,.72,.75)},
	{"name":"Carlos G.", "car":"Toyota Camry", "pay":90, "pos":Vector3(-19,.25,27), "color":Color(.12,.48,.32)},
	{"name":"Nicole P.", "car":"Lexus ES", "pay":135, "pos":Vector3(20,.25,27), "color":Color(.58,.58,.62)},
	{"name":"Derrick S.", "car":"Chevy Tahoe", "pay":155, "pos":Vector3(-20,.25,-27), "color":Color(.08,.08,.09)}
]


func _ready() -> void:
	add_child(business)
	add_child(economy)
	add_child(pressure)
	_build_neighborhood()
	_build_ui()
	_load_game()
	last_player_pos = player.global_position
	_update_hud()
	_offer_detail_job(false)


func _mat(color: Color, emission := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if emission:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 2.0
	return material


func _box(size: Vector3, pos: Vector3, color: Color, collision := false) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _mat(color)
	mesh_node.mesh = mesh
	mesh_node.position = pos
	add_child(mesh_node)
	if collision:
		var body := StaticBody3D.new()
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		body.position = pos
		body.add_child(shape_node)
		add_child(body)
	return mesh_node


func _part(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _mat(color)
	node.mesh = mesh
	node.position = pos
	parent.add_child(node)
	return node


func _build_car(parent: Node3D, color: Color, worn := false) -> MeshInstance3D:
	var body := _part(parent, Vector3(2.15,.65,4.25),Vector3(0,.35,0),color)
	_part(parent,Vector3(1.8,.62,2.05),Vector3(0,.88,.15),Color(.10,.16,.2))
	_part(parent,Vector3(1.88,.08,.12),Vector3(0,.63,-2.14),Color(.9,.12,.08,1.0))
	_part(parent,Vector3(1.88,.08,.12),Vector3(0,.63,2.14),Color(1,.88,.55))
	for x in [-1.08,1.08]:
		for z in [-1.35,1.35]:
			_part(parent,Vector3(.24,.72,.72),Vector3(x,.2,z),Color(.025,.025,.03))
	if worn:
		# Primer patch, faded door and crooked bumper sell the barely-running starter car.
		_part(parent,Vector3(.7,.03,.5),Vector3(.45,.69,-.7),Color(.24,.18,.12))
		_part(parent,Vector3(.06,.48,1.1),Vector3(-1.09,.46,.35),Color(.48,.45,.38))
		var bumper := _part(parent,Vector3(1.65,.13,.16),Vector3(.12,.25,2.18),Color(.3,.3,.28))
		bumper.rotation.z = .06
	return body


func _build_person(parent: Node3D, shirt: Color) -> void:
	_part(parent,Vector3(.8,1.0,.42),Vector3(0,1.15,0),shirt)
	_part(parent,Vector3(.28,.85,.3),Vector3(-.23,.38,0),Color(.12,.14,.18))
	_part(parent,Vector3(.28,.85,.3),Vector3(.23,.38,0),Color(.12,.14,.18))
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = .32
	sphere.height = .64
	sphere.material = _mat(Color(.55,.31,.18))
	head.mesh = sphere
	head.position = Vector3(0,1.95,0)
	parent.add_child(head)


func _world_sign(text: String, pos: Vector3, color: Color) -> void:
	var sign := Label3D.new()
	sign.text = text
	sign.font_size = 54
	sign.modulate = color
	sign.outline_size = 10
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.position = pos
	add_child(sign)


func _make_marker(color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.35
	mesh.bottom_radius = 1.35
	mesh.height = 2.8
	mesh.material = _mat(color, true)
	node.mesh = mesh
	add_child(node)
	return node


func _build_neighborhood() -> void:
	# A connected cross-town road grid, sidewalks, and recognizable destinations.
	_box(Vector3(76,.08,12), Vector3(0,.14,0), Color(.075,.08,.09))
	_box(Vector3(12,.08,76), Vector3(0,.15,0), Color(.075,.08,.09))
	for offset in [-7.0, 7.0]:
		_box(Vector3(76,.12,1.2), Vector3(0,.19,offset), Color(.58,.58,.56))
		_box(Vector3(1.2,.12,76), Vector3(offset,.2,0), Color(.58,.58,.56))
	for x in [-30.0,-18.0,18.0,30.0]:
		_box(Vector3(.18,.03,3), Vector3(x,.2,0), Color(.95,.78,.12))
	for z in [-30.0,-18.0,18.0,30.0]:
		_box(Vector3(3,.03,.18), Vector3(0,.21,z), Color(.95,.78,.12))
	# Homes define the customer properties without blocking their driveways.
	for x in [-29.0, 29.0]:
		for z in [-27.0,-12.0,12.0,27.0]:
			_box(Vector3(9,4.5,7), Vector3(x,2.25,z), Color(.64 + z/300.0,.58,.48 + abs(x)/300.0), true)
			_box(Vector3(4,.05,7), Vector3(x + (-6.5 if x < 0 else 6.5),.22,z), Color(.45,.45,.43))
	# Apartment, gas canopy/pumps, and business supply warehouse.
	_box(Vector3(13,6,8), Vector3(-18,3,-34), Color(.52,.58,.63), true)
	_box(Vector3(3.2,.12,8), Vector3(-10,.24,-34), Color(.48,.48,.46))
	_box(Vector3(2,3,.2), Vector3(-11.4,1.5,-29.9), Color(.16,.28,.38))
	_box(Vector3(13,.6,9), Vector3(20,4.5,-32), Color(.86,.16,.1), true)
	_box(Vector3(1,3,1), Vector3(17,1.5,-32), Color(.82,.12,.08), true)
	_box(Vector3(1,3,1), Vector3(23,1.5,-32), Color(.82,.12,.08), true)
	_box(Vector3(14,6,9), Vector3(-21,3,32), Color(.18,.34,.48), true)
	_box(Vector3(8,2.4,.3), Vector3(-21,5.5,27.4), Color(.95,.68,.1))
	_world_sign("CITY APARTMENTS",Vector3(-18,6.8,-29.8),Color(.75,.9,1))
	_world_sign("YOUR APARTMENT",Vector3(-12,5.8,-.8),Color(.75,.9,1))
	_world_sign("QUICKFUEL",Vector3(20,6,-27.2),Color(1,.82,.25))
	_world_sign("BIZ SUPPLY",Vector3(-21,7,27.2),Color(.35,.85,1))
	# Small commercial strip and a pocket park give each side of town its own identity.
	_box(Vector3(16,4.5,7),Vector3(27,2.25,4),Color(.62,.38,.22),true)
	_box(Vector3(15,.06,10),Vector3(26,.22,12),Color(.22,.23,.24))
	_world_sign("SUNRISE CAFE",Vector3(27,5.3,.4),Color(1,.72,.26))
	_box(Vector3(11,4,7),Vector3(-28,2,-3),Color(.32,.42,.48),true)
	_world_sign("BAY AUTO",Vector3(-28,5,-6.6),Color(.95,.35,.22))
	_box(Vector3(16,.05,14),Vector3(-25,.22,9),Color(.18,.19,.2))
	_box(Vector3(12,.05,9),Vector3(21,.22,20),Color(.38,.48,.28))
	_world_sign("MAPLE POCKET PARK",Vector3(21,2.2,15),Color(.72,1,.66))
	# Lane markings, crosswalks, lamps, mailboxes, parked cars and neighbors add street life.
	for x in range(-34,35,6):
		_box(Vector3(2.6,.025,.12),Vector3(x,.205,0),Color(.94,.78,.18))
	for z in range(-34,35,6):
		_box(Vector3(.12,.025,2.6),Vector3(0,.215,z),Color(.94,.78,.18))
	for stripe in [-4.5,-3.0,-1.5,1.5,3.0,4.5]:
		_box(Vector3(.55,.03,2.0),Vector3(stripe,.23,8),Color(.88,.88,.82))
	for lamp_pos in [Vector3(-8,0,-18),Vector3(8,0,-18),Vector3(-8,0,18),Vector3(8,0,18)]:
		_box(Vector3(.16,4,.16),lamp_pos + Vector3(0,2,0),Color(.18,.2,.22))
		_box(Vector3(.65,.25,.65),lamp_pos + Vector3(0,4,0),Color(1,.86,.55))
	# Trees and curbs make the blocks readable at driving speed.
	for x in [-34.0,-11.0,11.0,34.0]:
		for z in [-20.0,20.0]:
			_box(Vector3(.7,3,.7), Vector3(x,1.5,z), Color(.26,.18,.09), true)
			var crown := _box(Vector3(3,3,3), Vector3(x,3.5,z), Color(.12,.36,.13))
			crown.rotation_degrees = Vector3(0,20,0)
	for car_data in [[Vector3(25,.45,10),Color(.7,.7,.74),PI/2.0],[Vector3(-25,.45,10),Color(.12,.18,.25),PI/2.0],[Vector3(15,.45,-21),Color(.56,.12,.1),0.0]]:
		var parked := Node3D.new()
		parked.position = car_data[0]
		parked.rotation.y = car_data[2]
		add_child(parked)
		_build_car(parked,car_data[1])
	for person_data in [[Vector3(11,.2,15),Color(.18,.56,.76)],[Vector3(-11,.2,-20),Color(.68,.24,.42)],[Vector3(31,.2,20),Color(.25,.58,.32)],[Vector3(-30,.2,20),Color(.75,.55,.16)]]:
		var neighbor := Node3D.new()
		neighbor.position = person_data[0]
		add_child(neighbor)
		_build_person(neighbor,person_data[1])
		ambient_people.append(neighbor)
		ambient_origins.append(neighbor.position)
	marker = _make_marker(Color(.1,.7,1))
	zone_marker = _make_marker(Color(.98,.74,.08))
	gas_marker = _make_marker(Color(.95,.18,.1))
	gas_marker.position = Vector3(20,.24,-27)
	supply_marker = _make_marker(Color(.2,.7,1))
	supply_marker.position = Vector3(-21,.24,26)
	# Replace prototype blocks with readable, multi-part vehicles and people.
	$OldCar.mesh = null
	_build_car($OldCar,Color(.26,.32,.38),true)
	customer_car = Node3D.new()
	add_child(customer_car)
	customer_car_body = _build_car(customer_car,Color(.28,.2,.12))
	dirt_panels.append(_part(customer_car,Vector3(2.2,.3,.7),Vector3(0,.48,1.25),Color(.30,.22,.12)))
	dirt_panels.append(_part(customer_car,Vector3(2.2,.3,.7),Vector3(0,.48,-1.25),Color(.30,.22,.12)))
	dirt_panels.append(_part(customer_car,Vector3(.08,.42,2.2),Vector3(1.09,.55,0),Color(.30,.22,.12)))
	dirt_panels.append(_part(customer_car,Vector3(.08,.42,2.2),Vector3(-1.09,.55,0),Color(.30,.22,.12)))
	customer_npc = Node3D.new()
	_build_person(customer_npc,Color(.88,.47,.16))
	add_child(customer_npc)
	customer_sign = Label3D.new()
	customer_sign.font_size = 44
	customer_sign.outline_size = 9
	customer_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(customer_sign)
	marker.visible = false
	zone_marker.visible = false
	customer_car.visible = false
	customer_npc.visible = false
	customer_sign.visible = false
	_build_work_tool()


func _build_work_tool() -> void:
	work_tool = Node3D.new()
	add_child(work_tool)
	_part(work_tool,Vector3(.45,.7,.45),Vector3(0,.35,0),Color(.92,.58,.08))
	_part(work_tool,Vector3(.12,.12,1.8),Vector3(0,.75,-.75),Color(.08,.1,.11))
	_part(work_tool,Vector3(.08,.08,.7),Vector3(0,.72,-1.9),Color(.25,.28,.3))
	work_tool.visible = false


func _label(pos: Vector2, size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	$HUD.add_child(label)
	return label


func _button(text: String, pos: Vector2, size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = size
	$HUD.add_child(button)
	return button


func _build_ui() -> void:
	$HUD/Title.text = "TONY MOBILE"
	$HUD/Title.add_theme_color_override("font_color",Color(.96,.72,.22))
	cash_label.position = Vector2(24,55)
	business_label = _label(Vector2(24,91),15)
	objective = _label(Vector2(24,124),19)
	objective.size = Vector2(650,32)
	equipment_label = _label(Vector2(24,160),14)
	stats_label = _label(Vector2(24,188),14)
	branch_label = _label(Vector2(24,216),14)
	context_label = _label(Vector2(440,530),18)
	context_label.size = Vector2(500,60)
	context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	waypoint_label = _label(Vector2(440,24),22)
	waypoint_label.size = Vector2(400,42)
	waypoint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide_label = _label(Vector2(24,250),14)
	guide_label.size = Vector2(330,90)
	progress_label = _label(Vector2(440,585),18)
	progress_bar = ProgressBar.new()
	progress_bar.position = Vector2(440,615)
	progress_bar.size = Vector2(400,28)
	progress_bar.max_value = 100
	$HUD.add_child(progress_bar)
	next_job_button = _button("NEXT DETAIL CUSTOMER",Vector2(990,610),Vector2(230,45))
	next_job_button.pressed.connect(_offer_detail_job)
	pressure_button = _button("PRESSURE CONTRACT",Vector2(990,555),Vector2(230,45))
	pressure_button.pressed.connect(_offer_pressure_contract)
	negotiate_button = _button("NEGOTIATE +$20",Vector2(880,300),Vector2(180,42))
	negotiate_button.pressed.connect(_negotiate)
	skip_button = _button("DECLINE LEAD",Vector2(880,350),Vector2(180,38))
	skip_button.pressed.connect(_decline_lead)
	reset_button = _button("NEW GAME",Vector2(1100,665),Vector2(120,34))
	reset_button.pressed.connect(_new_game)
	phone_button = _button("PHONE  [Q]",Vector2(1090,22),Vector2(150,42))
	phone_button.pressed.connect(_toggle_phone)
	job_panel.position = Vector2(410,115)
	job_panel.size = Vector2(460,430)
	job_title.position = Vector2(28,55)
	job_title.size = Vector2(404,40)
	job_text.position = Vector2(28,115)
	job_text.size = Vector2(404,150)
	$HUD/JobPanel/Accept.position = Vector2(28,330)
	$HUD/JobPanel/Accept.size = Vector2(190,56)
	negotiate_button.reparent(job_panel)
	negotiate_button.position = Vector2(28,270)
	skip_button.reparent(job_panel)
	skip_button.position = Vector2(240,330)
	skip_button.size = Vector2(190,56)
	phone_header = Label.new()
	phone_header.text = "JOBS  •  INCOMING LEAD"
	phone_header.position = Vector2(28,18)
	phone_header.add_theme_font_size_override("font_size",16)
	phone_header.add_theme_color_override("font_color",Color(.35,.82,1))
	job_panel.add_child(phone_header)
	dialogue_panel = Panel.new()
	dialogue_panel.position = Vector2(330,510)
	dialogue_panel.size = Vector2(620,100)
	dialogue_label = Label.new()
	dialogue_label.position = Vector2(20,14)
	dialogue_label.size = Vector2(580,72)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_font_size_override("font_size",18)
	dialogue_panel.add_child(dialogue_label)
	$HUD.add_child(dialogue_panel)
	dialogue_panel.visible = false
	toast_panel = Panel.new()
	toast_panel.position = Vector2(430,70)
	toast_panel.size = Vector2(420,58)
	toast_label = Label.new()
	toast_label.position = Vector2(15,13)
	toast_label.size = Vector2(390,35)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size",18)
	toast_panel.add_child(toast_label)
	$HUD.add_child(toast_panel)
	toast_panel.visible = false
	$HUD/Status.position = Vector2(24,670)
	$HUD/Hint.position = Vector2(24,638)


func _toggle_phone() -> void:
	if job_state != 0:
		_toast("No new leads while a job is active")
		return
	phone_open = not phone_open
	job_panel.visible = phone_open


func _toast(message: String) -> void:
	toast_label.text = message
	toast_panel.visible = true
	toast_time = 3.0


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("phone"):
		_toggle_phone()
	_handle_vehicle_and_fuel()
	_handle_world_interactions()
	if job_state == 1:
		var distance := player.global_position.distance_to(marker.global_position)
		status_label.text = "%s • %.0f m away" % [_active_customer_name(), distance]
		if distance < 5.0:
			if player.is_driving():
				status_label.text = "Park and press F to exit your car"
			elif not customer_met and service == "detail":
				status_label.text = "Meet the customer • Walk up and press E"
			elif service == "pressure" or (customer_met and player.global_position.distance_to(customer_car.global_position) < 2.8):
				_start_service()
			elif customer_met:
				status_label.text = "Customer authorized the work • Approach the highlighted car"
	elif job_state == 2:
		_service_process(delta)
	_update_context()
	_update_hud()
	_update_waypoint()
	_update_ambient_life(delta)
	if toast_time > 0.0:
		toast_time -= delta
		toast_panel.visible = true
	else:
		toast_panel.visible = false
	if save_notice_time > 0.0:
		save_notice_time -= delta
	last_player_pos = player.global_position


func _update_ambient_life(delta: float) -> void:
	var time := Time.get_ticks_msec() / 1000.0
	for index in ambient_people.size():
		var neighbor := ambient_people[index]
		var origin := ambient_origins[index]
		neighbor.position.x = origin.x + sin(time * .35 + index * 1.7) * 2.5
		neighbor.rotation.y = cos(time * .35 + index * 1.7) * .5


func _handle_vehicle_and_fuel() -> void:
	if Input.is_action_just_pressed("vehicle"):
		if fuel <= 0.0 and not player.is_driving():
			status_label.text = "The tank is empty. Walk to the gas station marker."
		else:
			player.toggle_vehicle()
	var moved := player.global_position.distance_to(last_player_pos)
	if player.is_driving() and moved > .01:
		fuel = max(0.0, fuel - moved * .045)
		if fuel <= 0.0:
			player.force_exit_vehicle()
			status_label.text = "OUT OF FUEL • Visit QuickFuel on the northeast block"


func _handle_world_interactions() -> void:
	if not Input.is_action_just_pressed("interact") or job_state == 2:
		return
	if job_state == 1 and service == "detail" and not customer_met and player.global_position.distance_to(customer_npc.global_position) < 3.5:
		customer_met = true
		dialogue_label.text = "%s\n“Thanks for coming. The car has had a rough week—please take care of all four sections.”" % _active_customer_name()
		dialogue_panel.visible = true
		status_label.text = "Permission received • Approach the vehicle"
		objective.text = "OBJECTIVE: Walk to the car to begin the detail"
		_toast("CUSTOMER GREETED  •  Work authorized")
	elif player.global_position.distance_to(gas_marker.global_position) < 3.5:
		_refuel()
	elif player.global_position.distance_to(supply_marker.global_position) < 3.5:
		_use_supply_store()


func _update_context() -> void:
	var text := ""
	if job_state == 1 and service == "detail" and not customer_met and player.global_position.distance_to(customer_npc.global_position) < 4.5:
		text = "%s • Press E to greet customer" % _active_customer_name().to_upper()
	elif player.global_position.distance_to(gas_marker.global_position) < 4.5:
		text = "QUICKFUEL • Press E to fill tank ($25)"
	elif player.global_position.distance_to(supply_marker.global_position) < 4.5:
		if detailing_equipment == 0:
			text = "BIZ SUPPLY • E: buy detailing pressure washer ($200)"
		elif not pressure.unlocked(cash, reputation):
			text = "BIZ SUPPLY • Pressure branch requires $2,500 + 12 REP"
		elif pressure.equipment_level < 3:
			text = "BIZ SUPPLY • E: buy %s ($%d)" % [pressure.next_equipment_name(), pressure.equipment_cost()]
		else:
			text = "BIZ SUPPLY • E: hire crew member ($%d)" % pressure.hire_cost()
	elif not player.is_driving() and player.global_position.distance_to($OldCar.global_position) < 5.0:
		text = "STARTER CAR AHEAD • Press F to enter"
	context_label.text = text


func _update_waypoint() -> void:
	if job_state != 1 or not marker.visible:
		waypoint_label.text = ""
		return
	var delta := marker.global_position - player.global_position
	var direction := "N" if abs(delta.z) > abs(delta.x) and delta.z < 0 else "S" if abs(delta.z) > abs(delta.x) else "E" if delta.x > 0 else "W"
	waypoint_label.text = "◆ %s  •  %.0f m  •  %s" % [_active_customer_name(),delta.length(),direction]


func _update_hud() -> void:
	business.level = business.calculate_level(cash, reputation, pressure.completed)
	cash_label.text = "CASH: $%d" % cash
	business_label.text = "%s  •  %s  •  BASEMENT STUDIO / '98 HATCHBACK" % ["TONY MOBILE SERVICES", business.title()]
	stats_label.text = "DAY %d  •  DETAIL %d  •  PRESSURE %d  •  REP %d★  •  NET $%d" % [day,jobs_completed,pressure.completed,reputation,economy.net()]
	equipment_label.text = "FUEL %d%%  •  %d MPH  •  %s  •  CREW %d" % [int(fuel),player.speed_mph(),pressure.equipment_name(),pressure.employees]
	if pressure.unlocked(cash,reputation):
		branch_label.text = "PRESSURE WASHING: ACTIVE • Supplies/job $%d • Payroll/day $%d" % [economy.pressure_supply_cost(pressure.equipment_level),pressure.daily_payroll()]
	else:
		branch_label.text = "NEXT BRANCH: Pressure Washing at $2,500 + 12 REP"
	var steps := [
		("✓ Start with your $300 budget"),
		("✓ Accept a detailing lead" if job_state > 0 else "1  Accept the lead at top-right"),
		("✓ Meet the customer" if customer_met or job_state >= 2 else "2  Drive ◆ waypoint, park, greet"),
		("✓ Finish all work zones" if job_state == 3 else "3  Hold E at each yellow zone"),
		("NEXT: Save $2,500 + earn 12 REP for pressure washing")
	]
	guide_label.text = "FIRST SHIFT\n" + "\n".join(steps.slice(1,4))
	pressure_button.visible = pressure.unlocked(cash,reputation) and pressure.equipment_level > 0 and job_state == 3


func _offer_detail_job(advance := true) -> void:
	service = "detail"
	if advance:
		current_job = (current_job + 1) % DETAIL_JOBS.size()
	elif current_job < 0 or current_job >= DETAIL_JOBS.size():
		current_job = 0
	job_state = 0
	customer_met = false
	negotiated_bonus = 0
	zone_index = 0
	zone_progress = 0
	_show_offer()
	var job: Dictionary = DETAIL_JOBS[current_job]
	job_title.text = "NEW DETAILING LEAD"
	job_text.text = "%s\nFull detail • %s\n%s neighborhood • about %d m away\nExpected pay: $%d" % [job.name,job.car,_district_for(job.pos),int(player.global_position.distance_to(job.pos)),job.pay]
	objective.text = "New detailing lead • Open PHONE [Q]"
	_toast("NEW JOB LEAD  •  %s  •  Open phone [Q]" % job.name)


func _offer_pressure_contract() -> void:
	if not pressure.unlocked(cash,reputation) or pressure.equipment_level == 0:
		status_label.text = "Buy a pressure rig at Biz Supply first"
		return
	service = "pressure"
	current_contract = pressure.next_contract()
	job_state = 0
	negotiated_bonus = 0
	zone_index = 0
	zone_progress = 0
	_show_offer()
	job_title.text = "PRESSURE CONTRACT"
	job_text.text = "%s\n%s • %d service zones\n%s neighborhood • about %d m away\nExpected pay: $%d" % [current_contract.name,current_contract.type,current_contract.difficulty,_district_for(current_contract.pos),int(player.global_position.distance_to(current_contract.pos)),current_contract.pay]
	negotiate_button.visible = false
	objective.text = "OBJECTIVE: Accept the pressure-washing contract"


func _show_offer() -> void:
	phone_open = false
	job_panel.visible = false
	next_job_button.visible = false
	pressure_button.visible = false
	progress_bar.visible = false
	progress_label.visible = false
	zone_marker.visible = false
	marker.visible = false
	customer_car.visible = false
	customer_npc.visible = false
	customer_sign.visible = false
	negotiate_button.visible = service == "detail"
	negotiate_button.disabled = false
	skip_button.visible = true
	status_label.text = "New lead waiting on your phone"
	hint.text = "WASD Move/Drive  •  F Car  •  E Interact  •  Q Phone"


func _on_accept_pressed() -> void:
	if job_state != 0:
		return
	job_state = 1
	phone_open = false
	job_panel.visible = false
	negotiate_button.visible = false
	skip_button.visible = false
	var pos: Vector3
	if service == "detail":
		var job: Dictionary = DETAIL_JOBS[current_job]
		pos = job.pos
		customer_car.position = pos + Vector3(2,.45,0)
		customer_npc.position = pos + Vector3(-1.5,.85,0)
		customer_sign.position = pos + Vector3(0,3.4,0)
		customer_sign.text = "%s • %s" % [job.name,job.car]
		customer_car.visible = true
		customer_npc.visible = true
		customer_sign.visible = true
		for panel in dirt_panels:
			panel.visible = true
			panel.scale = Vector3.ONE
		customer_car_body.material_override = _mat(job.color.darkened(.35))
		customer_met = false
		objective.text = "OBJECTIVE: Drive to %s's property" % job.name
	else:
		pos = current_contract.pos
		objective.text = "OBJECTIVE: Drive to %s • %s" % [current_contract.name,current_contract.type]
	marker.position = pos
	marker.visible = true
	status_label.text = "Job accepted • Follow the blue destination marker"
	_toast("JOB ACCEPTED  •  Route added")


func _start_service() -> void:
	job_state = 2
	dialogue_panel.visible = false
	marker.visible = false
	progress_bar.visible = true
	progress_label.visible = true
	zone_index = 0
	zone_progress = 0
	_position_zone()
	objective.text = "OBJECTIVE: Complete every %s zone" % service
	status_label.text = "Move to the yellow work point and hold E"
	_toast("WORK STARTED  •  Complete every section")


func _position_zone() -> void:
	var offsets := [Vector3(2,0,2.7),Vector3(2,0,-2.7),Vector3(3.3,0,0),Vector3(-3.3,0,0),Vector3(0,0,3.5)]
	var base: Vector3 = customer_car.global_position if service == "detail" else marker.global_position
	zone_marker.global_position = base + offsets[zone_index]
	work_tool.global_position = zone_marker.global_position + Vector3(.7,0,.2)
	work_tool.visible = true
	zone_marker.visible = true
	var count := _zone_count()
	progress_bar.value = float(zone_index) / count * 100.0
	progress_label.text = "%s: %d%% • Zone %d/%d" % [service.to_upper(),int(progress_bar.value),zone_index+1,count]


func _zone_count() -> int:
	return 4 if service == "detail" else int(current_contract.difficulty)


func _service_process(delta: float) -> void:
	if player.global_position.distance_to(zone_marker.global_position) > 2.2:
		status_label.text = "Move closer to the yellow work point"
		return
	if Input.is_action_pressed("interact"):
		var rate: float = (70.0 if detailing_equipment == 1 else 35.0) if service == "detail" else pressure.job_speed()
		zone_progress = min(100.0, zone_progress + rate * delta)
		if service == "detail" and zone_index < dirt_panels.size():
			# The grime visibly recedes throughout each hold, not only at completion.
			dirt_panels[zone_index].scale.x = max(.04,1.0-zone_progress/100.0)
		var total := (float(zone_index) + zone_progress / 100.0) / _zone_count() * 100.0
		progress_bar.value = total
		progress_label.text = "%s: %d%% • Zone %d/%d" % [service.to_upper(),int(total),zone_index+1,_zone_count()]
		status_label.text = "Pressure washing..." if service == "pressure" else "Cleaning vehicle section..."
		if zone_progress >= 100.0:
			if service == "detail" and zone_index < dirt_panels.size():
				dirt_panels[zone_index].visible = false
			zone_index += 1
			_toast("SECTION CLEAN  •  %d/%d complete" % [zone_index,_zone_count()])
			zone_progress = 0
			if zone_index >= _zone_count():
				_complete_service()
			else:
				_position_zone()
	else:
		status_label.text = "Hold E to work on this section"


func _complete_service() -> void:
	job_state = 3
	zone_marker.visible = false
	work_tool.visible = false
	progress_bar.visible = false
	progress_label.visible = false
	var payout := 0
	var expense := 0
	if service == "detail":
		var result: Dictionary = business.complete_customer(reputation)
		payout = int(DETAIL_JOBS[current_job].pay) + negotiated_bonus + int(result.quality_bonus)
		jobs_completed += 1
		customer_car_body.material_override = _mat(DETAIL_JOBS[current_job].color)
		status_label.text = "%s loved the detail%s" % [DETAIL_JOBS[current_job].name," • Referral earned!" if result.referral else ""]
	else:
		payout = int(current_contract.pay)
		expense = economy.pressure_supply_cost(pressure.equipment_level)
		pressure.complete_contract()
		status_label.text = "%s contract complete • Supplies -$%d" % [current_contract.type,expense]
	cash += economy.record_income(payout)
	if expense > 0:
		cash -= economy.record_expense(expense)
	reputation += 1
	jobs_today += 1
	if jobs_today >= 3:
		_advance_day()
	objective.text = "SERVICE COMPLETE • $%d gross • $%d net" % [payout,payout-expense]
	_toast("PAID +$%d  •  REPUTATION +1" % (payout-expense))
	next_job_button.visible = true
	pressure_button.visible = pressure.unlocked(cash,reputation) and pressure.equipment_level > 0
	_save_game()


func _advance_day() -> void:
	var overhead: int = economy.detailing_daily_overhead() + pressure.daily_payroll()
	cash -= economy.record_expense(overhead)
	day += 1
	jobs_today = 0
	status_label.text += " • Daily overhead/payroll -$%d" % overhead


func _negotiate() -> void:
	if job_state != 0 or service != "detail":
		return
	var chance: int = 55 + min(reputation * 5,30)
	negotiated_bonus = 20 if randi_range(1,100) <= chance else 0
	status_label.text = "SUCCESS • Customer accepted +$20" if negotiated_bonus else "Customer held firm at the original price"
	negotiate_button.disabled = true
	var job: Dictionary = DETAIL_JOBS[current_job]
	job_text.text = "%s\n%s\nFull Detail\nAgreed: $%d" % [job.name,job.car,job.pay+negotiated_bonus]


func _decline_lead() -> void:
	if job_state != 0:
		return
	if service == "detail":
		_offer_detail_job()
	else:
		_offer_pressure_contract()
	status_label.text = "Lead declined • A new opportunity is available"


func _refuel() -> void:
	if fuel >= 99.0:
		status_label.text = "Your tank is already full"
	elif cash < 25:
		status_label.text = "You need $25 to refuel"
	else:
		cash -= economy.record_expense(25)
		fuel = 100.0
		status_label.text = "QUICKFUEL • Tank filled • -$25"
		_save_game()


func _use_supply_store() -> void:
	if detailing_equipment == 0:
		if cash < 200:
			status_label.text = "You need $200 for the detailing pressure washer"
			return
		cash -= economy.record_expense(200)
		detailing_equipment = 1
		status_label.text = "DETAILING PRESSURE WASHER PURCHASED • Cleaning is twice as fast"
		_toast("EQUIPMENT UNLOCKED  •  Detail Washer")
		_save_game()
		return
	if not pressure.unlocked(cash,reputation):
		status_label.text = "Build $2,500 cash and 12 reputation to open this business branch"
		return
	if pressure.equipment_level < 3:
		var price: int = pressure.equipment_cost()
		if cash < price:
			status_label.text = "You need $%d for the next pressure-washing rig" % price
			return
		cash -= economy.record_expense(price)
		pressure.equipment_level += 1
		status_label.text = "EQUIPMENT PURCHASED • %s" % pressure.equipment_name()
		_toast("BUSINESS UPGRADE  •  %s" % pressure.equipment_name())
	else:
		var price: int = pressure.hire_cost()
		if not pressure.can_hire(cash):
			status_label.text = "Crew capacity reached or insufficient cash ($%d required)" % price
			return
		cash -= economy.record_expense(price)
		pressure.hire()
		status_label.text = "EMPLOYEE HIRED • Jobs are faster • Daily payroll increased"
		_toast("TEAM GROWTH  •  Crew member hired")
	_save_game()


func _district_for(pos: Vector3) -> String:
	if pos.z < -20:
		return "Northside"
	if pos.z > 20:
		return "Warehouse District"
	if pos.x > 0:
		return "Maple East"
	return "Bay Street"


func _active_customer_name() -> String:
	return DETAIL_JOBS[current_job].name if service == "detail" else str(current_contract.name)


func _save_game() -> void:
	var data := {
		"save_version": 3, "cash": cash, "reputation": reputation, "jobs": jobs_completed,
		"equipment": detailing_equipment, "home_tier": home_tier, "vehicle_tier": vehicle_tier,
		"day": day, "today": jobs_today, "fuel": fuel,
		"customer": current_job, "business": business.serialize(), "economy": economy.serialize(),
		"pressure": pressure.serialize(),
		# Legacy keys keep saves readable by earlier prototype builds.
		"earned": economy.earned, "expenses": economy.expenses, "referrals": business.referrals,
		"business_level": business.level, "streak": business.streak, "best_streak": business.best_streak,
		"pressure_unlocked": pressure.unlocked(cash,reputation), "pressure_jobs": pressure.completed,
		"lifetime_customers": business.lifetime_customers,
		"player_pos": [player.global_position.x,player.global_position.y,player.global_position.z],
		"car_pos": [$OldCar.global_position.x,$OldCar.global_position.y,$OldCar.global_position.z],
		"car_yaw": $OldCar.rotation.y
	}
	var file := FileAccess.open("user://savegame.tmp",FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		var save_path := ProjectSettings.globalize_path("user://savegame.json")
		var temp_path := ProjectSettings.globalize_path("user://savegame.tmp")
		var backup_path := ProjectSettings.globalize_path("user://savegame.backup.json")
		if FileAccess.file_exists("user://savegame.json"):
			DirAccess.copy_absolute(save_path,backup_path)
			DirAccess.remove_absolute(save_path)
		DirAccess.rename_absolute(temp_path,save_path)
		save_notice_time = 2.0


func _load_game() -> void:
	var data = _read_save("user://savegame.json")
	if typeof(data) != TYPE_DICTIONARY:
		data = _read_save("user://savegame.backup.json")
	if typeof(data) != TYPE_DICTIONARY:
		return
	cash = max(0,int(data.get("cash",300)))
	reputation = max(0,int(data.get("reputation",0)))
	jobs_completed = max(0,int(data.get("jobs",0)))
	detailing_equipment = clampi(int(data.get("equipment",0)),0,1)
	home_tier = max(0,int(data.get("home_tier",0)))
	vehicle_tier = max(0,int(data.get("vehicle_tier",0)))
	day = max(1,int(data.get("day",1)))
	jobs_today = clampi(int(data.get("today",0)),0,2)
	fuel = clampf(float(data.get("fuel",100)),0.0,100.0)
	current_job = int(data.get("customer",-1))
	business.restore(data.get("business",data))
	economy.restore(data.get("economy",data))
	pressure.restore(data.get("pressure",data))
	var car_pos = data.get("car_pos",[])
	if car_pos is Array and car_pos.size() == 3:
		player.set_parked_car(Vector3(clampf(float(car_pos[0]),-36,36),.7,clampf(float(car_pos[2]),-36,36)),float(data.get("car_yaw",0.0)))
	var saved_pos = data.get("player_pos",[])
	if saved_pos is Array and saved_pos.size() == 3:
		player.global_position = Vector3(clampf(float(saved_pos[0]),-36,36),max(1.0,float(saved_pos[1])),clampf(float(saved_pos[2]),-36,36))


func _read_save(path: String):
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path,FileAccess.READ)
	if not file:
		return null
	return JSON.parse_string(file.get_as_text())


func _new_game() -> void:
	cash = 300
	reputation = 0
	jobs_completed = 0
	current_job = -1
	detailing_equipment = 0
	home_tier = 0
	vehicle_tier = 0
	day = 1
	jobs_today = 0
	fuel = 100.0
	business.restore({})
	economy.restore({})
	pressure.restore({})
	player.global_position = Vector3(-4,1,7)
	player.set_parked_car(Vector3(-4,.7,1),0.0)
	_offer_detail_job(false)
	_save_game()

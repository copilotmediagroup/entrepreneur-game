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
var day := 1
var jobs_today := 0
var fuel := 100.0
var negotiated_bonus := 0
var zone_index := 0
var zone_progress := 0.0
var last_player_pos := Vector3.ZERO
var current_contract: Dictionary = {}

var marker: MeshInstance3D
var customer_car: MeshInstance3D
var customer_npc: MeshInstance3D
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
	_offer_detail_job()


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


func _make_marker(color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.1
	mesh.bottom_radius = 1.1
	mesh.height = 0.12
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
	_box(Vector3(13,.6,9), Vector3(20,4.5,-32), Color(.86,.16,.1), true)
	_box(Vector3(1,3,1), Vector3(17,1.5,-32), Color(.82,.12,.08), true)
	_box(Vector3(1,3,1), Vector3(23,1.5,-32), Color(.82,.12,.08), true)
	_box(Vector3(14,6,9), Vector3(-21,3,32), Color(.18,.34,.48), true)
	_box(Vector3(8,2.4,.3), Vector3(-21,5.5,27.4), Color(.95,.68,.1))
	# Trees and curbs make the blocks readable at driving speed.
	for x in [-34.0,-11.0,11.0,34.0]:
		for z in [-20.0,20.0]:
			_box(Vector3(.7,3,.7), Vector3(x,1.5,z), Color(.26,.18,.09), true)
			var crown := _box(Vector3(3,3,3), Vector3(x,3.5,z), Color(.12,.36,.13))
			crown.rotation_degrees = Vector3(0,20,0)
	marker = _make_marker(Color(.1,.7,1))
	zone_marker = _make_marker(Color(.98,.74,.08))
	gas_marker = _make_marker(Color(.95,.18,.1))
	gas_marker.position = Vector3(20,.24,-27)
	supply_marker = _make_marker(Color(.2,.7,1))
	supply_marker.position = Vector3(-21,.24,26)
	customer_car = _box(Vector3(2.2,1.2,4.5), Vector3.ZERO, Color(.28,.2,.12))
	customer_npc = MeshInstance3D.new()
	var npc_mesh := CapsuleMesh.new()
	npc_mesh.radius = .45
	npc_mesh.height = 1.7
	npc_mesh.material = _mat(Color(.8,.55,.25))
	customer_npc.mesh = npc_mesh
	add_child(customer_npc)
	marker.visible = false
	zone_marker.visible = false
	customer_car.visible = false
	customer_npc.visible = false


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
	business_label = _label(Vector2(24,105),20)
	objective = _label(Vector2(24,140),20)
	equipment_label = _label(Vector2(24,175),16)
	stats_label = _label(Vector2(24,205),16)
	branch_label = _label(Vector2(24,235),15)
	context_label = _label(Vector2(440,530),18)
	context_label.size = Vector2(500,60)
	context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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


func _process(delta: float) -> void:
	_handle_vehicle_and_fuel()
	_handle_world_interactions()
	if job_state == 1:
		var distance := player.global_position.distance_to(marker.global_position)
		status_label.text = "%s • %.0f m away" % [_active_customer_name(), distance]
		if distance < 5.0:
			if player.is_driving():
				status_label.text = "Park and press F to exit your car"
			else:
				_start_service()
	elif job_state == 2:
		_service_process(delta)
	_update_context()
	_update_hud()
	last_player_pos = player.global_position


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
	if player.global_position.distance_to(gas_marker.global_position) < 3.5:
		_refuel()
	elif player.global_position.distance_to(supply_marker.global_position) < 3.5:
		_use_supply_store()


func _update_context() -> void:
	var text := ""
	if player.global_position.distance_to(gas_marker.global_position) < 4.5:
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
	elif not player.is_driving() and player.global_position.distance_to($OldCar.global_position) < 3.5:
		text = "Press F to enter your starter car"
	context_label.text = text


func _update_hud() -> void:
	business.level = business.calculate_level(cash, reputation, pressure.completed)
	cash_label.text = "CASH: $%d" % cash
	business_label.text = "%s  •  %s" % ["TONY MOBILE SERVICES", business.title()]
	stats_label.text = "DAY %d  •  DETAIL %d  •  PRESSURE %d  •  REP %d★  •  NET $%d" % [day,jobs_completed,pressure.completed,reputation,economy.net()]
	equipment_label.text = "FUEL %d%%  •  %d MPH  •  %s  •  CREW %d" % [int(fuel),player.speed_mph(),pressure.equipment_name(),pressure.employees]
	if pressure.unlocked(cash,reputation):
		branch_label.text = "PRESSURE WASHING: ACTIVE • Supplies/job $%d • Payroll/day $%d" % [economy.pressure_supply_cost(pressure.equipment_level),pressure.daily_payroll()]
	else:
		branch_label.text = "NEXT BRANCH: Pressure Washing at $2,500 + 12 REP"
	pressure_button.visible = pressure.unlocked(cash,reputation) and pressure.equipment_level > 0 and job_state == 3


func _offer_detail_job() -> void:
	service = "detail"
	current_job = (current_job + 1) % DETAIL_JOBS.size()
	job_state = 0
	negotiated_bonus = 0
	zone_index = 0
	zone_progress = 0
	_show_offer()
	var job: Dictionary = DETAIL_JOBS[current_job]
	job_title.text = "NEW DETAILING LEAD"
	job_text.text = "%s\n%s\nFull Detail\nOffer: $%d" % [job.name,job.car,job.pay]
	objective.text = "OBJECTIVE: Review and accept the detailing lead"


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
	job_text.text = "%s\n%s • %d service zones\nContract: $%d" % [current_contract.name,current_contract.type,current_contract.difficulty,current_contract.pay]
	negotiate_button.visible = false
	objective.text = "OBJECTIVE: Accept the pressure-washing contract"


func _show_offer() -> void:
	job_panel.visible = true
	next_job_button.visible = false
	pressure_button.visible = false
	progress_bar.visible = false
	progress_label.visible = false
	zone_marker.visible = false
	marker.visible = false
	customer_car.visible = false
	customer_npc.visible = false
	negotiate_button.visible = service == "detail"
	negotiate_button.disabled = false
	skip_button.visible = true
	status_label.text = "NEW LEAD • Accept or decline"
	hint.text = "WASD Move/Drive • F Enter/Exit • E Interact/Work"


func _on_accept_pressed() -> void:
	if job_state != 0:
		return
	job_state = 1
	job_panel.visible = false
	negotiate_button.visible = false
	skip_button.visible = false
	var pos: Vector3
	if service == "detail":
		var job: Dictionary = DETAIL_JOBS[current_job]
		pos = job.pos
		customer_car.position = pos + Vector3(2,.45,0)
		customer_npc.position = pos + Vector3(-1.5,.85,0)
		customer_car.visible = true
		customer_npc.visible = true
		objective.text = "OBJECTIVE: Drive to %s's property" % job.name
	else:
		pos = current_contract.pos
		objective.text = "OBJECTIVE: Drive to %s • %s" % [current_contract.name,current_contract.type]
	marker.position = pos
	marker.visible = true
	status_label.text = "CONTRACT ACCEPTED • Follow the blue destination marker"


func _start_service() -> void:
	job_state = 2
	marker.visible = false
	progress_bar.visible = true
	progress_label.visible = true
	zone_index = 0
	zone_progress = 0
	_position_zone()
	objective.text = "OBJECTIVE: Complete every %s zone" % service
	status_label.text = "Move to the yellow work point and hold E"


func _position_zone() -> void:
	var offsets := [Vector3(2,0,2.7),Vector3(2,0,-2.7),Vector3(3.3,0,0),Vector3(-3.3,0,0),Vector3(0,0,3.5)]
	var base: Vector3 = customer_car.global_position if service == "detail" else marker.global_position
	zone_marker.global_position = base + offsets[zone_index]
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
		var total := (float(zone_index) + zone_progress / 100.0) / _zone_count() * 100.0
		progress_bar.value = total
		progress_label.text = "%s: %d%% • Zone %d/%d" % [service.to_upper(),int(total),zone_index+1,_zone_count()]
		status_label.text = "Pressure washing..." if service == "pressure" else "Cleaning vehicle section..."
		if zone_progress >= 100.0:
			zone_index += 1
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
	progress_bar.visible = false
	progress_label.visible = false
	var payout := 0
	var expense := 0
	if service == "detail":
		var result: Dictionary = business.complete_customer(reputation)
		payout = int(DETAIL_JOBS[current_job].pay) + negotiated_bonus + int(result.quality_bonus)
		jobs_completed += 1
		customer_car.mesh.material = _mat(DETAIL_JOBS[current_job].color)
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
	else:
		var price: int = pressure.hire_cost()
		if not pressure.can_hire(cash):
			status_label.text = "Crew capacity reached or insufficient cash ($%d required)" % price
			return
		cash -= economy.record_expense(price)
		pressure.hire()
		status_label.text = "EMPLOYEE HIRED • Jobs are faster • Daily payroll increased"
	_save_game()


func _active_customer_name() -> String:
	return DETAIL_JOBS[current_job].name if service == "detail" else str(current_contract.name)


func _save_game() -> void:
	var data := {
		"save_version": 2, "cash": cash, "reputation": reputation, "jobs": jobs_completed,
		"equipment": detailing_equipment, "day": day, "today": jobs_today, "fuel": fuel,
		"customer": current_job, "business": business.serialize(), "economy": economy.serialize(),
		"pressure": pressure.serialize(),
		# Legacy keys keep saves readable by earlier prototype builds.
		"earned": economy.earned, "expenses": economy.expenses, "referrals": business.referrals,
		"business_level": business.level, "streak": business.streak, "best_streak": business.best_streak,
		"pressure_unlocked": pressure.unlocked(cash,reputation), "pressure_jobs": pressure.completed,
		"lifetime_customers": business.lifetime_customers
	}
	var file := FileAccess.open("user://savegame.json",FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


func _load_game() -> void:
	if not FileAccess.file_exists("user://savegame.json"):
		return
	var file := FileAccess.open("user://savegame.json",FileAccess.READ)
	if not file:
		return
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	cash = int(data.get("cash",300))
	reputation = int(data.get("reputation",0))
	jobs_completed = int(data.get("jobs",0))
	detailing_equipment = int(data.get("equipment",0))
	day = int(data.get("day",1))
	jobs_today = int(data.get("today",0))
	fuel = float(data.get("fuel",100))
	current_job = int(data.get("customer",-1))
	business.restore(data.get("business",data))
	economy.restore(data.get("economy",data))
	pressure.restore(data.get("pressure",data))


func _new_game() -> void:
	cash = 300
	reputation = 0
	jobs_completed = 0
	current_job = -1
	detailing_equipment = 0
	day = 1
	jobs_today = 0
	fuel = 100.0
	business.restore({})
	economy.restore({})
	pressure.restore({})
	_save_game()
	_offer_detail_job()

extends Node
class_name PressureBusiness

const CONTRACTS := [
	{"name": "Miller Family", "type": "Driveway", "pay": 240, "difficulty": 3, "pos": Vector3(27, 0.25, -18)},
	{"name": "Sunrise Cafe", "type": "Storefront", "pay": 375, "difficulty": 4, "pos": Vector3(-27, 0.25, -18)},
	{"name": "Henderson Home", "type": "Patio", "pay": 290, "difficulty": 3, "pos": Vector3(27, 0.25, 16)},
	{"name": "Bay Auto", "type": "Commercial Lot", "pay": 525, "difficulty": 5, "pos": Vector3(-27, 0.25, 17)},
	{"name": "Riverside Offices", "type": "Walkway", "pay": 450, "difficulty": 5, "pos": Vector3(27, 0.25, 1)}
]

var completed := 0
var employees := 0
var equipment_level := 0
var contract_index := -1
var branch_unlocked := false


func unlocked(cash: int, reputation: int) -> bool:
	if cash >= 2500 and reputation >= 12:
		branch_unlocked = true
	return branch_unlocked


func next_contract() -> Dictionary:
	contract_index = (contract_index + 1) % CONTRACTS.size()
	return CONTRACTS[contract_index]


func current_contract() -> Dictionary:
	if contract_index < 0:
		return {}
	return CONTRACTS[contract_index]


func job_speed() -> float:
	return 22.0 + equipment_level * 9.0 + employees * 7.0


func equipment_cost() -> int:
	return [700, 1400, 2600][min(equipment_level, 2)]


func equipment_name() -> String:
	return ["No commercial rig", "Entry Pressure Rig", "Pro Surface Rig", "Fleet Trailer Rig"][equipment_level]


func next_equipment_name() -> String:
	return ["Entry Pressure Rig", "Pro Surface Rig", "Fleet Trailer Rig"][min(equipment_level, 2)]


func hire_cost() -> int:
	return 500 + employees * 250


func daily_payroll() -> int:
	return employees * 60


func can_hire(cash: int) -> bool:
	return equipment_level > 0 and cash >= hire_cost() and employees < 3


func hire() -> void:
	employees += 1


func complete_contract() -> void:
	completed += 1


func serialize() -> Dictionary:
	return {"completed": completed, "employees": employees, "equipment_level": equipment_level, "contract_index": contract_index, "branch_unlocked": branch_unlocked}


func restore(data: Dictionary) -> void:
	completed = max(0, int(data.get("completed", data.get("pressure_jobs", 0))))
	employees = clampi(int(data.get("employees", 0)), 0, 3)
	equipment_level = clampi(int(data.get("equipment_level", 0)), 0, 3)
	contract_index = clampi(int(data.get("contract_index", -1)), -1, CONTRACTS.size() - 1)
	branch_unlocked = bool(data.get("branch_unlocked", data.get("pressure_unlocked", false)))

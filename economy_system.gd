extends Node
class_name EconomySystem

var earned := 0
var expenses := 0


func record_income(amount: int) -> int:
	earned += amount
	return amount


func record_expense(amount: int) -> int:
	expenses += amount
	return amount


func net() -> int:
	return earned - expenses


func detailing_daily_overhead() -> int:
	return 35


func pressure_supply_cost(equipment_level: int = 1) -> int:
	return max(18, 42 - equipment_level * 7)


func pressure_job_net(gross: int, equipment_level: int = 1) -> int:
	return gross - pressure_supply_cost(equipment_level)


func serialize() -> Dictionary:
	return {"earned": earned, "expenses": expenses}


func restore(data: Dictionary) -> void:
	earned = max(0, int(data.get("earned", 0)))
	expenses = max(0, int(data.get("expenses", 0)))

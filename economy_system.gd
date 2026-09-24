extends Node
class_name EconomySystem

var earned := 0
var expenses := 0
var transactions: Array[Dictionary] = []


func record_income(amount: int, reason := "Service income", day := 1) -> int:
	earned += amount
	_add_transaction(amount, reason, day)
	return amount


func record_expense(amount: int, reason := "Business expense", day := 1) -> int:
	expenses += amount
	_add_transaction(-amount, reason, day)
	return amount


func _add_transaction(amount: int, reason: String, day: int) -> void:
	transactions.push_front({"amount": amount, "reason": reason.left(48), "day": max(1, day)})
	if transactions.size() > 16:
		transactions.resize(16)


func recent_text(limit := 7) -> String:
	if transactions.is_empty():
		return "No transactions yet. Your first customer can change that."
	var lines: Array[String] = []
	for index in min(limit, transactions.size()):
		var item: Dictionary = transactions[index]
		var amount := int(item.get("amount", 0))
		lines.append("Day %d  %s  %s$%d" % [int(item.get("day", 1)), str(item.get("reason", "Transaction")), "+" if amount >= 0 else "-", abs(amount)])
	return "\n".join(lines)


func net() -> int:
	return earned - expenses


func detailing_daily_overhead(home_tier := 0) -> int:
	# Rent allocation, food, phone and replenished detailing supplies.
	return [35, 60, 95][clampi(home_tier, 0, 2)]


func pressure_supply_cost(equipment_level: int = 1) -> int:
	return max(18, 42 - equipment_level * 7)


func pressure_job_net(gross: int, equipment_level: int = 1) -> int:
	return gross - pressure_supply_cost(equipment_level)


func serialize() -> Dictionary:
	return {"earned": earned, "expenses": expenses, "transactions": transactions}


func restore(data: Dictionary) -> void:
	earned = max(0, int(data.get("earned", 0)))
	expenses = max(0, int(data.get("expenses", 0)))
	transactions.clear()
	var restored = data.get("transactions", [])
	if restored is Array:
		for item in restored.slice(0, 16):
			if item is Dictionary:
				transactions.append({"amount": clampi(int(item.get("amount", 0)), -1000000, 1000000), "reason": str(item.get("reason", "Transaction")).left(48), "day": max(1, int(item.get("day", 1)))})

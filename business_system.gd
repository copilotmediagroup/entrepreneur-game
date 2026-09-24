extends Node
class_name BusinessSystem

var level := 1
var referrals := 0
var lifetime_customers := 0
var streak := 0
var best_streak := 0


func complete_customer(reputation: int) -> Dictionary:
	lifetime_customers += 1
	streak += 1
	best_streak = max(best_streak, streak)
	var referred := randi_range(1, 100) <= min(25 + reputation * 2, 70)
	if referred:
		referrals += 1
	return {"referral": referred, "quality_bonus": 10 if streak % 5 == 0 else 0}


func calculate_level(cash: int, reputation: int, pressure_completed: int = 0) -> int:
	if cash >= 10000 or pressure_completed >= 12:
		return 3
	if cash >= 2500 and reputation >= 12:
		return 2
	return 1


func title() -> String:
	if level >= 3:
		return "LOCAL BUSINESS OWNER"
	if level >= 2:
		return "GROWING OPERATOR"
	return "SOLO ENTREPRENEUR"


func serialize() -> Dictionary:
	return {
		"level": level, "referrals": referrals, "lifetime_customers": lifetime_customers,
		"streak": streak, "best_streak": best_streak
	}


func restore(data: Dictionary) -> void:
	level = int(data.get("level", data.get("business_level", 1)))
	referrals = int(data.get("referrals", 0))
	lifetime_customers = int(data.get("lifetime_customers", data.get("jobs", 0)))
	streak = int(data.get("streak", 0))
	best_streak = int(data.get("best_streak", streak))

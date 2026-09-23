extends Node
class_name EconomySystem

var earned=0
var expenses=0

func record_income(amount:int)->int:
 earned+=amount
 return amount

func record_expense(amount:int)->int:
 expenses+=amount
 return amount

func net()->int:
 return earned-expenses

func detailing_daily_overhead()->int:
 return 35

func pressure_supply_cost()->int:
 return 35

func pressure_job_net(gross:int)->int:
 return gross-pressure_supply_cost()

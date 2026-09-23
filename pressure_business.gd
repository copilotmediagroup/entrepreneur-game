extends Node
class_name PressureBusiness

var contracts=[
 {"name":"Miller Family","type":"Driveway","pay":240},
 {"name":"Sunrise Cafe","type":"Storefront","pay":375},
 {"name":"Henderson Home","type":"Patio","pay":290},
 {"name":"Bay Auto","type":"Commercial Lot","pay":525},
 {"name":"Riverside Offices","type":"Walkway","pay":450}
]
var completed=0
var employees=0
var contract_index=-1

func unlocked(cash:int,reputation:int)->bool:
 return cash>=2500 and reputation>=12

func next_contract()->Dictionary:
 contract_index=(contract_index+1)%contracts.size()
 return contracts[contract_index]

func job_speed()->float:
 return 18.0+employees*7.0

func hire_cost()->int:
 return 500

func daily_payroll()->int:
 return employees*60

func can_hire(cash:int)->bool:
 return cash>=hire_cost() and employees<3

func hire()->void:
 employees+=1

func complete_contract()->void:
 completed+=1

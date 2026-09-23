extends Node3D

@onready var cash_label: Label = $HUD/Cash
@onready var job_panel: Panel = $HUD/JobPanel
@onready var status_label: Label = $HUD/Status

var cash := 300

func _ready():
	cash_label.text = "CASH: $%d" % cash
	status_label.text = "Starter apartment • Old car • $300"
	job_panel.visible = true

func _on_accept_pressed():
	status_label.text = "FIRST JOB ACCEPTED — Jessica's BMW • $85"
	job_panel.visible = false

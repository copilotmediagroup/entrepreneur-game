extends Node3D

@onready var player=$Player
@onready var cash_label=$HUD/Cash
@onready var job_panel=$HUD/JobPanel
@onready var status_label=$HUD/Status
@onready var job_text=$HUD/JobPanel/JobText

var cash=300
var reputation=0
var jobs_completed=0
var current_job=-1
var job_state=0
var wash_amount=0.0
var equipment_level=0
var day=1
var jobs_today=0
var total_earned=0
var total_expenses=0

var marker:MeshInstance3D
var customer_car:MeshInstance3D
var customer_npc:MeshInstance3D
var objective:Label
var wash_bar:ProgressBar
var wash_label:Label
var equipment_label:Label
var stats_label:Label
var next_job_button:Button
var upgrade_button:Button
var save_label:Label

var jobs=[
 {"name":"Jessica R.","car":"BMW 328i","pay":85,"pos":Vector3(8,0.25,-8),"color":Color(0.08,0.32,0.70)},
 {"name":"Marcus T.","car":"Ford F-150","pay":110,"pos":Vector3(-14,0.25,10),"color":Color(0.55,0.08,0.06)},
 {"name":"Denise W.","car":"Mercedes C300","pay":125,"pos":Vector3(13,0.25,8),"color":Color(0.12,0.12,0.14)},
 {"name":"Andre B.","car":"Dodge Charger","pay":140,"pos":Vector3(-13,0.25,-11),"color":Color(0.18,0.18,0.55)}
]

func _ready():
 _build_ui_and_world()
 _load_game()
 _update_hud()
 _offer_next_job()

func _mat(c:Color)->StandardMaterial3D:
 var m=StandardMaterial3D.new();m.albedo_color=c;return m

func _build_ui_and_world():
 marker=MeshInstance3D.new()
 var mm=CylinderMesh.new();mm.top_radius=.8;mm.bottom_radius=.8;mm.height=.12
 var glow=_mat(Color(.1,.7,1));glow.emission_enabled=true;glow.emission=Color(.1,.55,1);glow.emission_energy_multiplier=3;mm.material=glow
 marker.mesh=mm;add_child(marker)
 customer_car=MeshInstance3D.new()
 var cm=BoxMesh.new();cm.size=Vector3(2.2,1.2,4.5);cm.material=_mat(Color(.28,.2,.12));customer_car.mesh=cm;add_child(customer_car)
 customer_npc=MeshInstance3D.new()
 var nm=CapsuleMesh.new();nm.radius=.45;nm.height=1.7;nm.material=_mat(Color(.8,.55,.25));customer_npc.mesh=nm;add_child(customer_npc)
 objective=Label.new();objective.position=Vector2(24,112);objective.add_theme_font_size_override("font_size",20);$HUD.add_child(objective)
 equipment_label=Label.new();equipment_label.position=Vector2(24,150);equipment_label.add_theme_font_size_override("font_size",17);$HUD.add_child(equipment_label)
 stats_label=Label.new();stats_label.position=Vector2(24,185);stats_label.add_theme_font_size_override("font_size",16);$HUD.add_child(stats_label)
 wash_label=Label.new();wash_label.position=Vector2(440,570);wash_label.add_theme_font_size_override("font_size",18);$HUD.add_child(wash_label)
 wash_bar=ProgressBar.new();wash_bar.position=Vector2(440,605);wash_bar.size=Vector2(400,32);wash_bar.max_value=100;$HUD.add_child(wash_bar)
 next_job_button=Button.new();next_job_button.text="NEXT CUSTOMER";next_job_button.position=Vector2(1000,610);next_job_button.size=Vector2(210,48);next_job_button.pressed.connect(_offer_next_job);$HUD.add_child(next_job_button)
 upgrade_button=Button.new();upgrade_button.text="BUY PRESSURE WASHER - $200";upgrade_button.position=Vector2(930,545);upgrade_button.size=Vector2(290,48);upgrade_button.pressed.connect(_buy_upgrade);$HUD.add_child(upgrade_button)
 save_label=Label.new();save_label.position=Vector2(1000,680);save_label.text="AUTOSAVE ON";$HUD.add_child(save_label)

func _update_hud():
 cash_label.text="CASH: $%d"%cash
 stats_label.text="DAY %d  •  JOBS %d  •  REP %d★  •  NET $%d"%[day,jobs_completed,reputation,total_earned-total_expenses]
 equipment_label.text="EQUIPMENT: "+("Pressure Washer" if equipment_level==1 else "Bucket + Basic Wash Kit")
 upgrade_button.visible=equipment_level==0 and cash>=500

func _offer_next_job():
 current_job=(current_job+1)%jobs.size()
 var j=jobs[current_job];job_state=0;wash_amount=0
 job_panel.visible=true;next_job_button.visible=false;wash_bar.visible=false;wash_label.visible=false
 marker.visible=false;customer_car.visible=false;customer_npc.visible=false
 objective.text="OBJECTIVE: Build your detailing business"
 job_text.text="%s\n%s\nExterior + Interior\nOffer: $%d"%[j.name,j.car,j.pay]
 status_label.text="New customer lead received"

func _on_accept_pressed():
 var j=jobs[current_job];job_state=1;job_panel.visible=false
 marker.position=j.pos;customer_car.position=j.pos+Vector3(2,.45,0);customer_npc.position=j.pos+Vector3(-1.5,.85,0)
 marker.visible=true;customer_car.visible=true;customer_npc.visible=true;customer_car.mesh.material.albedo_color=Color(.28,.2,.12)
 objective.text="OBJECTIVE: Go to %s's vehicle"%j.name;status_label.text="JOB ACCEPTED • %s • $%d"%[j.car,j.pay]

func _process(delta):
 if job_state==1:
  var dist=player.global_position.distance_to(marker.global_position)
  status_label.text="%s's %s • %.0f m away"%[jobs[current_job].name,jobs[current_job].car,dist]
  if dist<3.5:
   job_state=2;objective.text="OBJECTIVE: Detail the "+jobs[current_job].car;wash_bar.visible=true;wash_label.visible=true
 elif job_state==2:
  if Input.is_key_pressed(KEY_E):
   var rate=55.0 if equipment_level==1 else 24.0
   wash_amount=min(100.0,wash_amount+rate*delta);wash_bar.value=wash_amount
   wash_label.text="DIRT: %d%%  •  CLEAN: %d%%"%[100-int(wash_amount),int(wash_amount)]
   customer_car.mesh.material.albedo_color=Color(.28,.2,.12).lerp(jobs[current_job].color,wash_amount/100.0)
   status_label.text="Pressure washing..." if equipment_level==1 else "Scrubbing by hand..."
   if wash_amount>=100:_complete_job()
  else: status_label.text="Hold E to clean the vehicle"

func _complete_job():
 job_state=3
 var j=jobs[current_job];cash+=j.pay;total_earned+=j.pay;jobs_completed+=1;jobs_today+=1;reputation+=1
 var expense=0
 if jobs_today>=3:
  expense=35;cash-=expense;total_expenses+=expense;day+=1;jobs_today=0
 _update_hud();_save_game()
 objective.text="JOB COMPLETE • $%d earned • ★★★★★"%j.pay
 status_label.text=j.name+": Great work! I'll recommend you."
 if expense>0:status_label.text+="  End-of-day fuel/supplies: -$%d"%expense
 wash_bar.visible=false;wash_label.visible=false;marker.visible=false;next_job_button.visible=true

func _buy_upgrade():
 if cash>=200 and equipment_level==0:
  cash-=200;total_expenses+=200;equipment_level=1;_update_hud();_save_game()
  status_label.text="PRESSURE WASHER PURCHASED • Cleaning speed +129%"

func _save_game():
 var data={"cash":cash,"reputation":reputation,"jobs":jobs_completed,"equipment":equipment_level,"day":day,"today":jobs_today,"earned":total_earned,"expenses":total_expenses}
 var f=FileAccess.open("user://savegame.json",FileAccess.WRITE)
 if f:f.store_string(JSON.stringify(data))

func _load_game():
 if not FileAccess.file_exists("user://savegame.json"):return
 var f=FileAccess.open("user://savegame.json",FileAccess.READ)
 if not f:return
 var d=JSON.parse_string(f.get_as_text())
 if typeof(d)!=TYPE_DICTIONARY:return
 cash=int(d.get("cash",300));reputation=int(d.get("reputation",0));jobs_completed=int(d.get("jobs",0));equipment_level=int(d.get("equipment",0))
 day=int(d.get("day",1));jobs_today=int(d.get("today",0));total_earned=int(d.get("earned",0));total_expenses=int(d.get("expenses",0))

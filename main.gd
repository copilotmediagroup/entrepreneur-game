extends Node3D

@onready var player=$Player
@onready var cash_label=$HUD/Cash
@onready var job_panel=$HUD/JobPanel
@onready var status_label=$HUD/Status
@onready var job_text=$HUD/JobPanel/JobText
@onready var hint=$HUD/Hint

var cash=300
var reputation=0
var jobs_completed=0
var current_job=-1
var job_state=0
var equipment_level=0
var day=1
var jobs_today=0
var total_earned=0
var total_expenses=0
var fuel=100.0
var negotiated_bonus=0
var zone_index=0
var zone_progress=0.0
var last_player_pos=Vector3.ZERO
var referrals=0
var business_level=1
var business_name="Tony Mobile Detail"
var milestone_announced=false

var marker:MeshInstance3D
var customer_car:MeshInstance3D
var customer_npc:MeshInstance3D
var objective:Label
var progress_bar:ProgressBar
var progress_label:Label
var equipment_label:Label
var stats_label:Label
var milestone_label:Label
var next_job_button:Button
var upgrade_button:Button
var negotiate_button:Button
var refuel_button:Button
var zone_marker:MeshInstance3D
var business_label:Label
var referral_label:Label
var reset_button:Button
var skip_button:Button

var jobs=[
 {"name":"Jessica R.","car":"BMW 328i","pay":85,"pos":Vector3(8,.25,-8),"color":Color(.08,.32,.70)},
 {"name":"Marcus T.","car":"Ford F-150","pay":110,"pos":Vector3(-14,.25,10),"color":Color(.55,.08,.06)},
 {"name":"Denise W.","car":"Mercedes C300","pay":125,"pos":Vector3(13,.25,8),"color":Color(.12,.12,.14)},
 {"name":"Andre B.","car":"Dodge Charger","pay":140,"pos":Vector3(-13,.25,-11),"color":Color(.18,.18,.55)},
 {"name":"Tasha M.","car":"Honda Accord","pay":95,"pos":Vector3(14,.25,-10),"color":Color(.72,.72,.75)},
 {"name":"Carlos G.","car":"Toyota Camry","pay":90,"pos":Vector3(-10,.25,12),"color":Color(.12,.48,.32)},
 {"name":"Nicole P.","car":"Lexus ES","pay":135,"pos":Vector3(11,.25,11),"color":Color(.58,.58,.62)},
 {"name":"Derrick S.","car":"Chevy Tahoe","pay":155,"pos":Vector3(-15,.25,-7),"color":Color(.08,.08,.09)},
 {"name":"Monique A.","car":"Tesla Model 3","pay":150,"pos":Vector3(7,.25,12),"color":Color(.78,.12,.10)},
 {"name":"Brian K.","car":"Jeep Wrangler","pay":120,"pos":Vector3(-12,.25,-12),"color":Color(.18,.42,.12)}
]

func _ready():
 _build_world_details()
 _build_ui()
 _load_game()
 last_player_pos=player.global_position
 _update_hud()
 _offer_next_job()

func _mat(c:Color)->StandardMaterial3D:
 var m=StandardMaterial3D.new();m.albedo_color=c;return m

func _box(size:Vector3,pos:Vector3,color:Color):
 var n=MeshInstance3D.new();var m=BoxMesh.new();m.size=size;m.material=_mat(color);n.mesh=m;n.position=pos;add_child(n)

func _build_world_details():
 for z in [-13.0,-7.0,-1.0,5.0,11.0]:
  _box(Vector3(.18,.03,3.0),Vector3(0,.2,z),Color(.95,.8,.1))
 for x in [-16.0,16.0]:
  _box(Vector3(5,3.5,5),Vector3(x,1.75,-11),Color(.72,.62,.5))
  _box(Vector3(5,3.5,5),Vector3(x,1.75,3),Color(.62,.7,.76))
  _box(Vector3(5,3.5,5),Vector3(x,1.75,11),Color(.76,.7,.58))
 marker=MeshInstance3D.new();var mm=CylinderMesh.new();mm.top_radius=.8;mm.bottom_radius=.8;mm.height=.12
 var glow=_mat(Color(.1,.7,1));glow.emission_enabled=true;glow.emission=Color(.1,.55,1);glow.emission_energy_multiplier=3;mm.material=glow;marker.mesh=mm;add_child(marker)
 customer_car=MeshInstance3D.new();var cm=BoxMesh.new();cm.size=Vector3(2.2,1.2,4.5);cm.material=_mat(Color(.28,.2,.12));customer_car.mesh=cm;add_child(customer_car)
 customer_npc=MeshInstance3D.new();var nm=CapsuleMesh.new();nm.radius=.45;nm.height=1.7;nm.material=_mat(Color(.8,.55,.25));customer_npc.mesh=nm;add_child(customer_npc)
 zone_marker=MeshInstance3D.new();var zm=CylinderMesh.new();zm.top_radius=.55;zm.bottom_radius=.55;zm.height=.08;zm.material=_mat(Color(.95,.75,.08));zone_marker.mesh=zm;add_child(zone_marker)

func _label(pos:Vector2,size:int)->Label:
 var l=Label.new();l.position=pos;l.add_theme_font_size_override("font_size",size);$HUD.add_child(l);return l

func _button(text:String,pos:Vector2,size:Vector2)->Button:
 var b=Button.new();b.text=text;b.position=pos;b.size=size;$HUD.add_child(b);return b

func _build_ui():
 business_label=_label(Vector2(24,105),20);objective=_label(Vector2(24,140),20);equipment_label=_label(Vector2(24,150),17);stats_label=_label(Vector2(24,205),16);milestone_label=_label(Vector2(24,240),16);referral_label=_label(Vector2(24,275),15)
 progress_label=_label(Vector2(440,570),18);progress_bar=ProgressBar.new();progress_bar.position=Vector2(440,605);progress_bar.size=Vector2(400,32);progress_bar.max_value=100;$HUD.add_child(progress_bar)
 next_job_button=_button("NEXT CUSTOMER",Vector2(1000,610),Vector2(210,48));next_job_button.pressed.connect(_offer_next_job)
 upgrade_button=_button("BUY PRESSURE WASHER - $200",Vector2(930,545),Vector2(290,48));upgrade_button.pressed.connect(_buy_upgrade)
 negotiate_button=_button("NEGOTIATE +$20",Vector2(880,300),Vector2(180,42));negotiate_button.pressed.connect(_negotiate)
 refuel_button=_button("REFUEL $25",Vector2(1080,300),Vector2(140,42));refuel_button.pressed.connect(_refuel)
 skip_button=_button("DECLINE LEAD",Vector2(880,350),Vector2(180,38));skip_button.pressed.connect(_decline_lead)
 reset_button=_button("NEW GAME",Vector2(1100,665),Vector2(120,34));reset_button.pressed.connect(_new_game)

func _update_hud():
 cash_label.text="CASH: $%d"%cash
 business_label.text="%s  •  BUSINESS LEVEL %d"%[business_name,business_level]
 stats_label.text="DAY %d  •  JOBS %d  •  REP %d★  •  NET $%d  •  FUEL %d%%"%[day,jobs_completed,reputation,total_earned-total_expenses,int(fuel)]
 equipment_label.text="EQUIPMENT: "+("Pressure Washer" if equipment_level==1 else "Bucket + Basic Wash Kit")
 milestone_label.text="GOAL: $10,000 BUSINESS FUND  •  $%d / $10,000"%cash
 referral_label.text="REFERRALS: %d  •  NEXT UNLOCK: Pressure Washing at $2,500 + 12 REP"%referrals
 if cash>=2500 and reputation>=12: business_level=max(business_level,2)
 if cash>=10000 and not milestone_announced: milestone_announced=true; business_level=max(business_level,3)
 upgrade_button.visible=equipment_level==0 and cash>=500
 refuel_button.disabled=cash<25 or fuel>=99

func _offer_next_job():
 current_job=(current_job+1)%jobs.size();job_state=0;negotiated_bonus=0;zone_index=0;zone_progress=0
 var j=jobs[current_job];job_panel.visible=true;next_job_button.visible=false;progress_bar.visible=false;progress_label.visible=false;zone_marker.visible=false
 marker.visible=false;customer_car.visible=false;customer_npc.visible=false;negotiate_button.visible=true;negotiate_button.disabled=false;skip_button.visible=true
 objective.text="OBJECTIVE: Grow your mobile detailing business"
 job_text.text="%s\n%s\nFull Detail\nOffer: $%d"%[j.name,j.car,j.pay]
 status_label.text="NEW LEAD • Accept or negotiate before somebody else gets it"
 hint.text="WASD Walk  •  F Enter/Exit Car  •  E Detail"

func _on_accept_pressed():
 var j=jobs[current_job];job_state=1;job_panel.visible=false;negotiate_button.visible=false;skip_button.visible=false
 marker.position=j.pos;customer_car.position=j.pos+Vector3(2,.45,0);customer_npc.position=j.pos+Vector3(-1.5,.85,0)
 marker.visible=true;customer_car.visible=true;customer_npc.visible=true;customer_car.mesh.material=_mat(Color(.28,.2,.12))
 objective.text="OBJECTIVE: Drive to %s"%j.name;status_label.text="JOB ACCEPTED • %s • $%d"%[j.car,j.pay+negotiated_bonus]

func _process(delta):
 var moved=player.global_position.distance_to(last_player_pos)
 if player.is_driving() and moved>.01:
  fuel=max(0.0,fuel-moved*.035)
  if fuel<=0.0: player.force_exit_vehicle()
 last_player_pos=player.global_position
 if job_state==1:
  var dist=player.global_position.distance_to(marker.global_position)
  status_label.text="%s • %s • %.0f m away"%[jobs[current_job].name,jobs[current_job].car,dist]
  if dist<4:
   if player.is_driving():status_label.text="Park and press F to exit your car"
   else:_start_detail()
 elif job_state==2:
  _detail_process(delta)

func _start_detail():
 job_state=2;marker.visible=false;progress_bar.visible=true;progress_label.visible=true;zone_index=0;zone_progress=0;_position_zone()
 objective.text="OBJECTIVE: Clean all 4 vehicle zones";status_label.text="Move to the yellow service point and hold E"

func _position_zone():
 var offsets=[Vector3(2,0,2.7),Vector3(2,0,-2.7),Vector3(3.3,0,0),Vector3(.7,0,0)]
 zone_marker.global_position=customer_car.global_position+offsets[zone_index];zone_marker.visible=true
 progress_bar.value=zone_index*25;progress_label.text="DETAILING: %d%% • Zone %d/4"%[zone_index*25,zone_index+1]

func _detail_process(delta):
 var dist=player.global_position.distance_to(zone_marker.global_position)
 if dist>2:
  status_label.text="Move closer to the yellow service point";return
 if Input.is_key_pressed(KEY_E):
  var rate=70.0 if equipment_level==1 else 35.0
  zone_progress=min(100.0,zone_progress+rate*delta)
  var total=zone_index*25+zone_progress*.25;progress_bar.value=total;progress_label.text="DETAILING: %d%% • Zone %d/4"%[int(total),zone_index+1]
  status_label.text="Pressure washing..." if equipment_level==1 else "Cleaning section..."
  if zone_progress>=100:
   zone_index+=1;zone_progress=0
   if zone_index>=4:_complete_job()
   else:_position_zone()
 else:status_label.text="Hold E to clean this section"

func _complete_job():
 job_state=3;zone_marker.visible=false
 var j=jobs[current_job];var payout=j.pay+negotiated_bonus;cash+=payout;total_earned+=payout;jobs_completed+=1;jobs_today+=1;reputation+=1
 if randi_range(1,100)<=min(25+reputation*2,70): referrals+=1
 customer_car.mesh.material=_mat(j.color)
 var expense=0
 if jobs_today>=3:expense=35;cash-=expense;total_expenses+=expense;day+=1;jobs_today=0
 _update_hud();_save_game();objective.text="JOB COMPLETE • $%d earned • 5-STAR REVIEW"%payout
 status_label.text=j.name+": Great work! I'll recommend you."
 if expense>0:status_label.text+=" • Daily fuel/supplies -$%d"%expense
 progress_bar.visible=false;progress_label.visible=false;next_job_button.visible=true

func _negotiate():
 if job_state!=0:return
 var chance=55+min(reputation*5,30)
 if randi_range(1,100)<=chance:negotiated_bonus=20;status_label.text="SUCCESS • Customer accepted +$20"
 else:negotiated_bonus=0;status_label.text="Customer held firm at the original price"
 negotiate_button.disabled=true
 job_text.text="%s\n%s\nFull Detail\nAgreed: $%d"%[jobs[current_job].name,jobs[current_job].car,jobs[current_job].pay+negotiated_bonus]

func _buy_upgrade():
 if cash>=200 and equipment_level==0:
  cash-=200;total_expenses+=200;equipment_level=1;_update_hud();_save_game();status_label.text="PRESSURE WASHER PURCHASED • Cleaning is now twice as fast"

func _refuel():
 if cash>=25 and fuel<99:
  cash-=25;total_expenses+=25;fuel=100;_update_hud();_save_game();status_label.text="TANK FILLED • -$25"

func _save_game():
 var data={"cash":cash,"reputation":reputation,"jobs":jobs_completed,"equipment":equipment_level,"day":day,"today":jobs_today,"earned":total_earned,"expenses":total_expenses,"fuel":fuel,"customer":current_job,"referrals":referrals,"business_level":business_level}
 var f=FileAccess.open("user://savegame.json",FileAccess.WRITE)
 if f:f.store_string(JSON.stringify(data))

func _load_game():
 if not FileAccess.file_exists("user://savegame.json"):return
 var f=FileAccess.open("user://savegame.json",FileAccess.READ)
 if not f:return
 var d=JSON.parse_string(f.get_as_text())
 if typeof(d)!=TYPE_DICTIONARY:return
 cash=int(d.get("cash",300));reputation=int(d.get("reputation",0));jobs_completed=int(d.get("jobs",0));equipment_level=int(d.get("equipment",0))
 day=int(d.get("day",1));jobs_today=int(d.get("today",0));total_earned=int(d.get("earned",0));total_expenses=int(d.get("expenses",0));fuel=float(d.get("fuel",100));current_job=int(d.get("customer",-1));referrals=int(d.get("referrals",0));business_level=int(d.get("business_level",1))

func _decline_lead():
 if job_state!=0:return
 status_label.text="Lead declined • Looking for another customer"
 _offer_next_job()

func _new_game():
 cash=300;reputation=0;jobs_completed=0;current_job=-1;equipment_level=0;day=1;jobs_today=0;total_earned=0;total_expenses=0;fuel=100;referrals=0;business_level=1;milestone_announced=false
 _save_game();_update_hud();_offer_next_job()

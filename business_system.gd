extends Node
class_name BusinessSystem

var level=1
var referrals=0
var lifetime_customers=0
var streak=0
var best_streak=0

func complete_customer(reputation:int)->Dictionary:
 lifetime_customers+=1
 streak+=1
 best_streak=max(best_streak,streak)
 var referral=false
 if randi_range(1,100)<=min(25+reputation*2,70):
  referrals+=1
  referral=true
 var bonus=10 if streak%5==0 else 0
 return {"referral":referral,"quality_bonus":bonus}

func calculate_level(cash:int,reputation:int)->int:
 if cash>=10000:return 3
 if cash>=2500 and reputation>=12:return 2
 return 1

func title()->String:
 if level>=3:return "LOCAL BUSINESS OWNER"
 if level>=2:return "GROWING OPERATOR"
 return "SOLO ENTREPRENEUR"

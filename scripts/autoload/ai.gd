extends Node

var player = 1
var enemy = 0


func get_action():
	var action
	if (randf()<0.5):
		action = get_creature()
		if (action==null):
			action = get_spell()
	else:
		action = get_spell()
		if (action==null):
			action = get_creature()
	return action

# helper functions #
func get_num_creatures(p):
	var num = 0
	for card in Main.field[p]:
		num += int(card.owner==p)
	return num

func can_be_destroyed(target):
#	var p = target.owner
	var e = (target.owner+1)%2
	for t in Main.field[e]:
		if (t.type!="creature"):
			continue
		if (Main.can_attack(t,target)):
			return true
	return false

func can_destroy(target):
#	var p = target.owner
	var e = (target.owner+1)%2
	for t in Main.field[e]:
		if (t.type!="creature"):
			continue
		if (Main.can_attack(target,t)):
			return true
	return false

func has_indestructable_creature(pl):
	if (get_num_creatures(pl)==0):
		return false
	for c in Main.field[pl]:
		if (c.type=="creature" && can_be_destroyed(c)):
			return false
	return true


# determine card usefullness #
func get_creature():
	# Chose a creature card to play.
	var score = 2*get_num_creatures(player)-5
	var c
	for card in Main.hand[player]:
		if (card.type!="creature" || card.level>Main.mana[player]):
			continue
		
		var value = 5+abs(card.temperature)-card.level/2.0
		# Multiply the value with 0.5 if more enemies can destroy this card than it can destroy
		# or multiply with 1.5 if the other way round.
		# Do not consider equally strong cards.
		var v = 0
		for t in Main.field[enemy]:
			if (t.type!="creature"):
				continue
			if (abs(t.temperature)>abs(card.temperature) && sign(t.temperature)!=sign(card.temperature)):
				v -= 1
			elif (abs(t.temperature)<abs(card.temperature) && sign(t.temperature)!=sign(card.temperature)):
				v += 1
		v = clamp(v,-1,1)
		value *= 1.0+0.5*v
		if (value>score):
			score = value
			c = card
	
	if (c!=null):
		return {"card":c,"target":null}

func get_spell():
	# Chose a spell card to play.
	var score = 0
	var c
	var t
	for card in Main.hand[player]:
		if ((card.type!="spell" && card.type!="land") || card.level>Main.mana[player]):
			continue
		
		var value = 0.5*Main.mana[player]-card.level/2.0
		var rules = Cards.data[card.ID]["rules"]
		var base_rules = []
		var ammount = []
		base_rules.resize(rules.size())
		ammount.resize(rules.size())
		for i in range(rules.size()):
			var array = rules[i].split("-")
			base_rules[i] = array[0]
			if (array.size()>1):
				ammount[i] = int(array[1])
			
		
		for i in range(base_rules.size()):
			var e = base_rules[i]
			var a = ammount[i]
			match e:
				"inc_temp":
					for ally in Main.field[player]:
						if (ally.type!="creature" || ally.temperature<=0):
							continue
						
						var v = value+ally.temperature+2*a
						if (v>score):
							c = card
							t = ally
							score = v
					for tg in Main.field[enemy]:
						if (tg.type!="creature" || tg.temperature>=0):
							continue
						
						var v = value-tg.temperature+2*a
						if (v>score):
							c = card
							t = tg
							score = v
				"dec_temp":
					for ally in Main.field[player]:
						if (ally.type!="creature" || ally.temperature>=0):
							continue
						var v = value-ally.temperature+2*a
						if (v>score):
							c = card
							t = ally
							score = v
					for tg in Main.field[enemy]:
						if (tg.type!="creature" || tg.temperature<=0):
							continue
						var v = value+tg.temperature+2*a
						if (v>score):
							c = card
							t = tg
							score = v
				"neutralize_temp":
					for tg in Main.field[enemy]:
						if (tg.type!="creature" || tg.temperature==0):
							continue
						var v = value+abs(tg.temperature)+2*a
						if (v>score):
							c = card
							t = tg
							score = v
				"amplify_temp":
					for ally in Main.field[player]:
						if (ally.type!="creature" || ally.temperature==0):
							continue
						var v = value+abs(ally.temperature)+2*a
						if (v>score):
							c = card
							t = ally
							score = v
				"inc_ally_temp":
					for ally in Main.field[player]:
						if (ally.type!="creature" || ally.temperature<=0):
							continue
						var v = max(value+ally.temperature+2*a,1)
						if (v>score):
							c = card
							t = ally
							score = v
				"dec_ally_temp":
					for ally in Main.field[player]:
						if (ally.type!="creature" || ally.temperature>=0):
							continue
						var v = max(value-ally.temperature+2*a,1)
						if (v>score):
							c = card
							t = ally
							score = v
				"ice_armor":
					for ally in Main.field[player]:
						if (ally.type!="creature" || ally.temperature>=0):
							continue
						var v = value-ally.temperature+a
						if (v>score):
							c = card
							t = ally
							score = v
				"fire_armor":
					for ally in Main.field[player]:
						if (ally.type!="creature" || ally.temperature<=0):
							continue
						var v = value+ally.temperature+a
						if (v>score):
							c = card
							t = ally
							score = v
				"global_diffusion_all":
					var v = value
					var global_temp = (Main.get_player_temperature(Main.PLAYER1)+Main.get_player_temperature(Main.PLAYER2))/2
					for ally in Main.field[player]:
						if (ally.type!="creature"):
							continue
						v += abs(ally.temperature+a*sign(global_temp-ally.temperature))-abs(ally.temperature)
					for tg in Main.field[enemy]:
						if (tg.type!="creature"):
							continue
						v += abs(tg.temperature+a*sign(global_temp-tg.temperature))-abs(tg.temperature)
					if (v>score):
						c = card
						t = null
						score = v
				"dec_level":
					for tg in Main.field[enemy]:
						if (tg.type!="creature"):
							continue
						var v = value+tg.level+a
						if (v>score):
							c = card
							t = tg
							score = v
				"kill_hot":
					for tg in Main.field[enemy]:
						if (tg.type!="creature" || tg.temperature<=0 || tg.temperature>a):
							continue
						
						var v = value+2*tg.temperature
						if (v>score):
							c = card
							t = tg
							score = v
				"kill_cold":
					for tg in Main.field[enemy]:
						if (tg.type!="creature" || tg.temperature>=0 || -tg.temperature>a):
							continue
						
						var v = value-2*tg.temperature
						if (v>score):
							c = card
							t = tg
							score = v
				"kill_all_hot":
					var v = value
					var balance = 0
					for ally in Main.field[player]:
						if (ally.type!="creature" || ally.temperature<=0 || ally.temperature>a):
							continue
						balance -= 1
					for tg in Main.field[enemy]:
						if (tg.type!="creature" || tg.temperature<=0 || tg.temperature>a):
							continue
						balance += 1
						v += 2*tg.temperature
					
					v *= min(0.5*balance,2.0)
					if (v>score):
						c = card
						t = null
						score = v
				"kill_all_cold":
					var v = value
					for tg in Main.field[enemy]:
						if (tg.type!="creature" || tg.temperature>=0 || -tg.temperature>a):
							continue
						
						v -= 2*tg.temperature
					if (v>score):
						c = card
						t = null
						score = v
				"move_to_hand":
					for tg in Main.field[enemy]:
						if (tg.type!="creature"):
							continue
						var v = value+abs(tg.temperature)+tg.level
						if (v>score):
							c = card
							t = tg
							score = v
				"invert_temp":
					for ally in Main.field[player]:
						if (ally.type!="creature" || ally.temperature==0 || can_destroy(ally)):
							continue
						var v = value+0.5*ally.level
						if (v>score):
							c = card
							t = ally
							score = v
					for tg in Main.field[enemy]:
						if (tg.type!="creature" || tg.temperature==0 || can_be_destroyed(tg)):
							continue
						var v = value+0.5*tg.level
						if (v>score):
							c = card
							t = tg
							score = v
				"invert_ally_temp":
					var v = value
					for ally in Main.field[player]:
						if (ally.type!="creature" || ally.temperature==0):
							continue
						if (can_destroy(ally)):
							v += 0.5*ally.level
						else:
							v -= 0.5*ally.level
					if (v>score && v>value):
						c = card
						t = null
						score = v
				"explosion":
					for ally in Main.field[player]:
						var v = value-abs(ally.temperature)-0.5*ally.level
						var balance = -0.75
						var limit = abs(ally.temperature)
						for t2 in Main.field[player]:
							if (t2.type=="creature" && abs(t2.temperature)<limit):
								balance -= 1
						for t2 in Main.field[enemy]:
							if (t2.type=="creature" && abs(t2.temperature)<limit):
								balance += 1
								v += 0.25*abs(t2.temperature)*sqrt(abs(t2.temperature))
						v *= clamp(0.5*balance,0.0,2.0)
						if (v>0 && v>score):
							c = card
							t = ally
							score = v
				"draw":
					var v = value+max(5+Main.mana[player]-Main.hand[player].size(),1)
					if (v>score):
							c = card
							t = null
							score = v
				"no_attack_temp":
					for tg in Main.field[enemy]:
						if (tg.type!="creature"):
							continue
						var v = value+abs(tg.temperature)
						if (v>score):
							c = card
							t = tg
							score = v
				"ice_wall":
					var v = value-4+2*a
					for ally in Main.field[player]:
						if (ally.type=="creature" && ("ice" in Cards.data[ally.ID]["tags"])):
							v += abs(ally.temperature)
					if (v>score):
						c = card
						t = null
						score = v
				"destroy_all_lands":
					var v = value
					var num_lands = 0
					for land in Main.field[player]:
						if (land.type=="land"):
							value -= land.level
					for land in Main.field[enemy]:
						if (land.type=="land"):
							value += land.level
							num_lands += 1
					if (v>score && num_lands>0):
						c = card
						t = null
						score = v
				"cleanse":
					for ally in Main.field[player]:
						if (ally.type!="creature"):
							continue
						var v = 0
						v += abs(Cards.data[ally.ID]["temperature"])-abs(ally.temperature)
						v += abs(Cards.data[ally.ID]["level"])-abs(ally.level)
						for eq in ally.equiped:
							v += 2*(int("curse" in Cards.data[eq.ID]["tags"])-int("equipment" in Cards.data[eq.ID]["tags"]))
						if (v>0):
							v += value
							if (v>score):
								c = card
								t = ally
								score = v
					for tg in Main.field[enemy]:
						if (tg.type!="creature"):
							continue
						var v = 0
						v += abs(tg.temperature)-abs(Cards.data[tg.ID]["temperature"])
						v += abs(tg.level)-abs(Cards.data[tg.ID]["level"])
						for eq in tg.equiped:
							v += 2*(int("equipment" in Cards.data[eq.ID]["tags"])-int("curse" in Cards.data[eq.ID]["tags"]))
						if (v>0):
							v += value
							if (v>score):
								c = card
								t = tg
								score = v
				"remove_equipment":
					for tg in Main.field[enemy]:
						if (tg.type!="creature"):
							continue
						var v = 0
						for eq in tg.equiped:
							v += 2*int("equipment" in Cards.data[eq.ID]["tags"])
						if (v>0):
							v += value
							if (v>score):
								c = card
								t = tg
								score = v
				"no_attack_temp":
					if get_num_creatures(player)<=0:
						continue
					for tg in Main.field[enemy]:
						if (tg.type!="creature" || can_be_destroyed(tg)):
							continue
						var v = value+abs(tg.temperature)
						if (v>score):
							c = card
							t = tg
							score = v
				"damage_enemy":
					var v = value+2*a
					if (v>score):
						c = card
						t = null
						score = v
				"fire_attack_all_anneal":
					if !has_indestructable_creature(enemy):
						continue
					for ally in Main.field[player]:
						var v = value+1.5*abs(ally.temperature)-2*a
						if (ally.type=="creature" && ally.temperature!=0 && v>score):
							c = card
							t = ally
							score = v
				"heat_aura":
					var balance = 0
					var v = value+4*a
					for ally in Main.field[player]:
						if (ally.type!="creature"):
							continue
						v += sign(ally.temperature)
						if (ally.temperature>=0):
							balance += 1
						else:
							balance -= 1
					v *= clamp(1.0+0.25*balance,0.0,2.0)
					if (v>score):
						c = card
						t = null
						score = v
				"freeze":
					for tg in Main.field[enemy]:
						if (tg.type!="creature" || can_be_destroyed(tg)):
							continue
						var v = value+abs(tg.temperature)
						if (v>score):
							c = card
							t = tg
							score = v
				"freeze_attacker":
					var v = value
					for ally in Main.field[player]:
						if (ally.type=="creature" && "ice" in Cards.data[ally.ID]["tags"]):
							v += 2
					if (v>score):
						c = card
						t = null
						score = v
				"inc_mana":
					var v = value+2*a
					if (v>score):
						c = card
						t = null
						score = v
				"health_shield_temp":
					if (get_num_creatures(player)>0 && has_indestructable_creature(player)):
						continue
					var v = value+2*abs(Main.get_player_temperature(enemy))
					if (v>score):
						c = card
						t = null
						score = v
			
		
	
	if (c!=null):
		return {"card":c,"target":t}

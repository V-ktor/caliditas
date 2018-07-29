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
	var p = target.owner
	var e = (target.owner+1)%2
	for t in Main.field[e]:
		if (t.type!="creature" || sign(t.temperature)==sign(target.temperature)):
			continue
		if (abs(t.temperature)>=abs(target.temperature)):
			return true


# determine card usefullness #
func get_creature():
	# Chose a creature card to play.
	var score = 0
	var c
	for card in Main.hand[player]:
		if (card.type!="creature" || card.level>Main.mana[player]):
			continue
		
		var value = abs(card.temperature)-card.level/2.0
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
		if (card.type!="spell" || card.level>Main.mana[player]):
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
			if (e=="inc_temp"):
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
			elif (e=="dec_temp"):
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
			elif (e=="neutralize_temp"):
				for tg in Main.field[enemy]:
					var v = value+abs(tg.temperature)+2*a
					if (tg.type=="creature" && tg.temperature!=0 && v>score):
						c = card
						t = tg
						score = v
			elif (e=="amplify_temp"):
				for tg in Main.field[enemy]:
					var v = value+abs(tg.temperature)+2*a
					if (tg.type=="creature" && tg.temperature!=0 && v>score):
						c = card
						t = tg
						score = v
			elif (e=="inc_ally_temp"):
				for ally in Main.field[player]:
					if (ally.type!="creature" || ally.temperature<=0):
						continue
					
					var v = max(value+ally.temperature+2*a,1)
					if (v>score):
						c = card
						t = ally
						score = v
			elif (e=="kill_hot"):
				for tg in Main.field[enemy]:
					if (tg.type!="creature" || tg.temperature<=0 || tg.temperature>a):
						continue
					
					var v = value+2*tg.temperature
					if (v>score):
						c = card
						t = tg
						score = v
			elif (e=="kill_cold"):
				for tg in Main.field[enemy]:
					if (tg.type!="creature" || tg.temperature>=0 || -tg.temperature>a):
						continue
					
					var v = value-2*tg.temperature
					if (v>score):
						c = card
						t = tg
						score = v
			elif (e=="kill_all_hot"):
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
			elif (e=="kill_all_cold"):
				var v = value
				for tg in Main.field[enemy]:
					if (tg.type!="creature" || tg.temperature>=0 || -tg.temperature>a):
						continue
					
					v -= 2*tg.temperature
				if (v>score):
					c = card
					t = null
					score = v
			elif (e=="move_to_hand"):
				for tg in Main.field[enemy]:
					if (tg.type!="creature"):
						continue
					var v = value+abs(tg.temperature)+tg.level
					if (v>score):
						c = card
						t = tg
						score = v
			elif (e=="invert_temp"):
				for ally in Main.field[player]:
					if (ally.type!="creature"):
						continue
					var v = value+0.5*ally.level+randi()%6
					if (ally.temperature!=0 && v>score):
						c = card
						t = ally
						score = v
				for tg in Main.field[enemy]:
					if (tg.type!="creature"):
						continue
					var v = value+0.5*tg.level+randi()%6
					if (tg.temperature!=0 && v>score):
						c = card
						t = tg
						score = v
			elif (e=="explosion"):
				for ally in Main.field[player]:
					var v = value-abs(ally.temperature)-0.5*ally.level
					var balance = -0.75
					for t in Main.field[player]:
						if (t.type=="creature" && abs(t.temperature)<abs(ally.temperature)):
							balance -= 1
					for t in Main.field[enemy]:
						if (t.type=="creature" && abs(t.temperature)<abs(ally.temperature)):
							balance += 1
							v += 0.25*abs(t.temperature)*sqrt(abs(t.temperature))
					v *= min(0.5*balance,2.0)
					if (v>score):
						c = card
						t = ally
						score = v
			elif (e=="draw"):
				var v = value+max(5+Main.mana[player]-Main.hand[player].size(),1)
				if (v>score):
						c = card
						t = null
						score = v
			elif (e=="no_attack_temp"):
				for tg in Main.field[enemy]:
					if (tg.type!="creature"):
						continue
					var v = value+abs(tg.temperature)
					if (v>score):
						c = card
						t = tg
						score = v
			elif (e=="ice_wall"):
				var v = value-4
				for ally in Main.field[player]:
					if (ally.type=="creature" && ("ice" in Cards.data[ally.ID]["tags"])):
						v += abs(ally.temperature)
				if (v>score):
					c = card
					t = null
					score = v
			elif (e=="destroy_all_lands"):
				var v = 0.1*value
				for land in Main.field[player]:
					if (land.type=="land"):
						value -= land.level
				for land in Main.field[enemy]:
					if (land.type=="land"):
						value += land.level
				if (v>score):
					c = card
					t = null
					score = v
			elif (e=="cleanse"):
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
			elif (e=="remove_equipment"):
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
			elif (e=="no_attack_temp" && get_num_creatures(player)>0):
				for tg in Main.field[enemy]:
					if (tg.type!="creature" || can_be_destroyed(tg)):
						continue
					var v = value+abs(tg.temperature)
					if (v>score):
						c = card
						t = tg
						score = v
			elif (e=="damage_enemy"):
				var v = value+2*a
				if (v>score):
					c = card
					t = null
			
		
	
	if (c!=null):
		return {"card":c,"target":t}

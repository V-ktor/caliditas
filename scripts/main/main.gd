extends Node2D

enum {
	PLAYER1 = 0
	PLAYER2 = 1
}
const START_CARDS = 4
const DEATH_ANIMATIONS = {"neutral":"fizzle","fire":"burn","ice":"crack"}

var timer
var field = [[],[]]
var hand = [[],[]]
var graveyard = [[],[]]
var deck = [[],[]]
var mana = [0,0]
var mana_max = [0,0]
var health = [10,10]
var temperature = [0,0]
var inc_mana = [true,true]
var player_name = ["",""]
var player = -1
var turn = -1
var selected_card
var zoom = 1.0
var used_positions = [[],[]]
var attack_list = {}
var select = "none"
var state
var using_card = false
var ai = true
var is_multiplayer = false
var server = true
var animations = true

var text_temp = preload("res://scenes/main/text_temp.tscn")

signal card_played(player,card,target)
signal turn_started(player)
signal target_selected(target)
signal effect_used()
signal card_enlarged(card)


class Card:
	var ID
	var owner
	var type
	var level
	var temperature
	var last_temp
	var node
	var pos
	var in_game
	var equiped
	var arrow
	
	func _init(t,p,n,a=false):
		ID = t
		owner = p
		type = Cards.data[ID]["type"]
		level = Cards.data[ID]["level"]
		if (Cards.data[ID].has("temperature")):
			temperature = Cards.data[ID]["temperature"]
		else:
			temperature = 0
		last_temp = temperature
		node = n
		in_game = a
		equiped = []
	
	func update():
		node.get_node("Level").set_text(str(level))
		node.get_node("Temp").set_text(str(temperature))
		if (temperature>0):
			node.get_node("OverlayTemp").set_self_modulate(Cards.COLOR_HOT)
		elif (temperature<0):
			node.get_node("OverlayTemp").set_self_modulate(Cards.COLOR_COLD)
		else:
			node.get_node("OverlayTemp").set_self_modulate(Color(0.5,0.5,0.5))
		if (temperature!=last_temp && node.get_node("Temp").is_visible()):
			var text
			var ti = Main.text_temp.instance()
			if (temperature>last_temp):
				text = "+"
				ti.get_node("Label").add_color_override("font_color",Cards.COLOR_HOT)
			else:
				text = "-"
				ti.get_node("Label").add_color_override("font_color",Cards.COLOR_COLD)
			ti.get_node("Label").set_text(text+str(abs(temperature-last_temp)))
			ti.set_global_position(node.get_node("Temp").get_global_position()-Vector2(16,0))
			Main.add_child(ti)
			last_temp = temperature
		for i in range(equiped.size()):
			var card = equiped[i]
			var offset = min(75,200/equiped.size())
			var pos = node.get_global_position()+Vector2(0,offset*(i+1))*(1-2*owner)
			card.node._z = -i-1
			card.node.set_z_index(-i-1)
			card.node.pos = pos
			card.node.get_node("Tween").interpolate_property(card.node,"global_position",card.node.get_global_position(),pos,0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
			card.node.get_node("Tween").start()
	
	func remove_equipment():
		for c in []+equiped:
			c.destroy()
		equiped.clear()
	
	func destroy():
		var timer = Timer.new()
		var alignment = "neutral"
		node._z -= 1
		node.z_index -= 1
		node.type = "dead"
		if (pos!=null):
			Main.used_positions[owner].erase(pos)
		in_game = false
		Main.graveyard[owner].push_back(self)
		Main.field[owner].erase(self)
		if (Cards.data[ID].has("on_removed")):
			Main.apply_effect(self,"on_removed",self)
		for card in equiped:
			if (Cards.data[card.ID].has("on_removed")):
				Main.apply_effect(card,"on_removed",self)
		remove_equipment()
		timer.set_one_shot(true)
		timer.set_wait_time(0.5)
		node.add_child(timer)
		timer.start()
		yield(timer,"timeout")
		timer.queue_free()
		if (type!="spell"):
			if ("fire" in Cards.data[ID]["tags"] && !("ice" in Cards.data[ID]["tags"])):
				alignment = "fire"
			elif ("ice" in Cards.data[ID]["tags"] && !("fire" in Cards.data[ID]["tags"])):
				alignment = "ice"
		node.get_node("Animation").clear_queue()
		if (Main.animations):
			node.get_node("AnimationPlayer").play(Main.DEATH_ANIMATIONS[alignment])
		else:
			node.get_node("AnimationPlayer").play("fade_out")
		node.get_node("Tween").remove_all()
		node.get_node("Tween").interpolate_property(node,"global_position",node.get_global_position(),Main.get_node("Graveyard"+str(owner+1)).get_global_position(),0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,1.0)
		node.get_node("Tween").start()
		yield(node.get_node("Tween"),"tween_completed")
		Main.get_node("Graveyard"+str(owner+1)+"/Sprite").show()
		node.hide()
		node.get_node("Button").hide()

# Used for sorting arrays descending by absolute value of temperature.
class TemperatureSorter:
	static func sort_ascending(a,b):
		return abs(a.temperature)>abs(b.temperature)


func reset():
	# Reset to initial values and remove old cards.
	clear_attack_list()
	for card in get_node("Cards").get_children():
		card.queue_free()
	field = [[],[]]
	hand = [[],[]]
	graveyard = [[],[]]
	deck = [[],[]]
	mana = [2,3]
	mana_max = [2,3]
	health = [20,20]
	temperature = [0,0]
	inc_mana = [true,true]
	used_positions = [[-3],[3]]
	attack_list.clear()
	turn = -1
	player = -1
	selected_card = null
	ai = false
	is_multiplayer = false
	server = true
	if (has_node("/root/Menu")):
		animations = get_node("/root/Menu").animations
	select = "none"
	UI.get_node("Player1/VBoxContainer/Health/Bar").set_max(health[PLAYER1])
	UI.get_node("Player2/VBoxContainer/Health/Bar").set_max(health[PLAYER2])
	UI.get_node("Player1/VBoxContainer/ButtonC").show()
	UI.get_node("Player1/VBoxContainer/ButtonE").show()
	UI.get_node("Player1/VBoxContainer/ButtonD").show()
	get_node("Graveyard1/Sprite").hide()
	get_node("Graveyard2/Sprite").hide()
	Music.temperature = 0
	deselect()
	UI.get_node("VBoxContainer/LabelT").set_text("")
	UI.get_node("VBoxContainer/LabelP").set_text(tr("DRAWING_PHASE"))

func start():
	# Start a new match.
	timer.set_wait_time(2.0)
	UI.get_node("Player1").hide()
	UI.get_node("Player2").hide()
	UI.get_node("Player1/VBoxContainer/Name").set_text(player_name[PLAYER1])
	UI.get_node("Player2/VBoxContainer/Name").set_text(player_name[PLAYER2])
	UI.get_node("LabelVS").set_text(player_name[PLAYER1]+" VS "+player_name[PLAYER2])
	if (ai || is_multiplayer):
		UI.get_node("Player2/VBoxContainer/ButtonC").hide()
		UI.get_node("Player2/VBoxContainer/ButtonE").hide()
		UI.get_node("Player2/VBoxContainer/ButtonD").hide()
	UI.get_node("AnimationPlayer").play("vs")
	timer.start()
	yield(timer,"timeout")
	UI.get_node("Player1/Animation").play("show")
	UI.get_node("Player2/Animation").play("show")
	timer.set_wait_time(0.2)
	for i in range(START_CARDS):
		_draw_card(PLAYER1)
		_draw_card(PLAYER2)
		timer.start()
		yield(timer,"timeout")
	
	next_turn()

func game_over(lost=null):
	# Return to menu.
	if (lost==null):
		lost = player==PLAYER1
	timer.set_wait_time(1.0)
	timer.start()
	yield(timer,"timeout")
	get_node("/root/Menu").game_over(lost)

func hide():
	for card in get_node("Cards").get_children():
		card.get_node("AnimationPlayer").play("fade_out")

func find_empty_position(pl):
	var p = 0
	while (used_positions[pl].has(p)):
		p += 1
		if (!used_positions[pl].has(-p)):
			p *= -1
			break
	
	return p

func get_card_index(card):
	var dict = {}
	for p in range(2):
		for i in range(field[p].size()):
			if (field[p][i]==card):
				dict["index"] = i
				dict["player"] = p
	return dict

func get_player_temperature(player):
	var temp = temperature[player]
	for card in field[player]:
		temp += card.temperature
	return temp

func ai_turn(player):
	# Start the AI.
	var action = AI.get_creature()
	var counter = 0
	timer.set_wait_time(1.0)
	timer.start()
	yield(timer,"timeout")
	if (action==null):
		_draw_extra_card()
	while (action!=null):
		timer.set_wait_time(0.5)
		timer.start()
		yield(timer,"timeout")
		play_card(action["card"],player,action["target"])
		counter += 1
		if (counter>20):
			break
		else:
			action = AI.get_action()
			timer.set_wait_time(0.5)
			timer.start()
			yield(timer,"timeout")
	
	ai_set_attack(player)
	timer.set_wait_time(1.0)
	timer.start()
	yield(timer,"timeout")
	end_turn()

func ai_set_attack(player):
	var enemy = (player+1)%2
	var list = []+field[player]
	# Check if a creature or one of it's equiped cards has the no_attack special.
	for i in range(list.size()-1,-1,-1):
		var card = list[i]
		if (card.type!="creature" || (Cards.data[card.ID].has("no_attack") && Cards.data[card.ID]["no_attack"])):
			list.remove(i)
		else:
			for equiped in card.equiped:
				if (Cards.data[equiped.ID].has("no_attack") && Cards.data[equiped.ID]["no_attack"]):
					list.remove(i)
					break
	# Sort the creatures by abs(temperature).
	# As targets are chosen randomly this will prevent strong creatures defeating weak ones
	# and leaving only strong creatures that can't be killed by the weak ones.
	list.sort_custom(TemperatureSorter,"sort_ascending")
	UI.get_node("VBoxContainer/LabelP").set_text(tr("ATTACK_PHASE"))
	
	# Attack random enemies that can be defeated.
	for card in list:
		var targets = []
		for t in field[enemy]:
			if (can_attack(card,t) && abs(t.temperature)<abs(card.temperature)):
				targets.push_back(t)
		if (targets.size()==0):
			for t in field[enemy]:
				if (can_attack(card,t) && abs(t.temperature)==abs(card.temperature)):
					targets.push_back(t)
		if (targets.size()==0):
			continue
		
		var target = targets[randi()%targets.size()]
		set_attack(card,target)


# Send positions instead of classes to other players.
remote func _play_card(c,p,t):
	var target
	var player = (p+1)%2
	var card = hand[player][c]
	if (t.has("type")):
		if (t["type"]=="field"):
			target = field[(t["player"]+1)%2][t["ID"]]
		elif (t["type"]=="equiped"):
			target = field[(t["player"]+1)%2][t["ID"]].equiped[t["index"]]
		elif (t["type"]=="hand"):
			target = hand[(t["player"]+1)%2][t["ID"]]
	play_card(card,player,target)

func play_card(card,player,target=null):
	if (card.owner!=player || mana[player]<card.level || !(card in hand[player])):
		return
	
	var c
	print("Player "+str(player)+" plays card "+str(card.ID)+".")
	if (is_multiplayer && player==PLAYER1):
		for i in range(hand[player].size()):
			if (hand[player][i]==card):
				c = i
				break
	using_card = true
	get_node("SoundPlay").play()
	state = {"used":false}
	card.node.get_node("Animation").clear_queue()
	if (!card.node.get_node("Image").is_visible() || card.node.get_node("Animation").get_current_animation()=="hide"):
		card.node.get_node("Animation").play("show")
	if (card.type=="creature"):
		var p2
		var p1 = Vector2(card.node.get_global_position().x,0.5*card.node.get_global_position().y)
		spawn_creature(card,player)
		card.node.get_node("Tween").remove_all()
		card.node.get_node("Tween").interpolate_property(card.node,"global_position",card.node.get_global_position(),p1,0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		p2 = Vector2(225*card.pos,200*(1-2*player))
		card.node.get_node("TweenScale").interpolate_property(card.node,"scale",card.node.get_scale(),Vector2(0.15,0.15),0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,0.25)
		card.node.get_node("Tween").interpolate_property(card.node,"global_position",p1,p2,0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,0.25)
		card.node.get_node("Tween").start()
	elif (card.type=="spell" && Cards.data[card.ID].has("on_play")):
		var p = Vector2(card.node.get_global_position().x,0.5*card.node.get_global_position().y)
		card.node.get_node("Tween").interpolate_property(card.node,"global_position",card.node.get_global_position(),p,0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		card.node.get_node("Tween").start()
#		card.node.zoom()
		call_deferred("use_effect",card,"on_play",player,target)
		yield(self,"effect_used")
		if (state==null || !state["used"]):
			print("Invalid selection, break spell casting.")
			deselect(false)
			if ((ai || is_multiplayer) && player==PLAYER2):
				card.node.get_node("Animation").play("hide")
			return
		
		if (state.has("target") && state["target"]!=null && (state["target"] in field[PLAYER1]+field[PLAYER2])):
			var pos
			var offset
			var p2
			target = state["target"]
			pos = target.node.get_global_position()+Vector2(0,(100*(target.equiped.size()+3)-225*int(player==PLAYER2))*(1-2*target.owner))
			offset = min(75,200/(target.equiped.size()+1))
			p2 = target.node.get_global_position()+Vector2(0,offset*(target.equiped.size()+1))*(1-2*target.owner)
			card.node._z = -target.equiped.size()-1
			card.node.set_z_index(-target.equiped.size()-1)
			card.node.type = "equiped"
			card.node.pos = pos
			target.equiped.push_back(card)
			target.update()
			card.node.get_node("Tween").remove_all()
			card.node.get_node("TweenScale").interpolate_property(card.node,"scale",card.node.get_scale(),Vector2(0.15,0.15),0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
			if (card.node.get_global_position()==p):
				card.node.get_node("Tween").interpolate_property(card.node,"global_position",card.node.get_global_position(),pos,0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
				card.node.get_node("Tween").interpolate_property(card.node,"global_position",pos,p2,0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,0.25)
			else:
				card.node.get_node("Tween").interpolate_property(card.node,"global_position",p,pos,0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,0.25)
				card.node.get_node("Tween").interpolate_property(card.node,"global_position",pos,p2,0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,0.5)
			card.node.get_node("Tween").start()
			if (Cards.data[card.ID].has("animation") && animations):
				var pi = load("res://scenes/animations/"+Cards.data[card.ID]["animation"]+".tscn").instance()
				target.node.add_child(pi)
				pi.look_at(card.node.get_global_position())
				pi.rotate(PI)
		else:
			card.node.type = "dead"
			if (Cards.data[card.ID].has("animation") && animations):
				if (state.has("target") && state["target"]!=null):
					var pi
					target = state["target"]
					pi = load("res://scenes/animations/"+Cards.data[card.ID]["animation"]+".tscn").instance()
					target.node.add_child(pi)
					pi.look_at(card.node.get_global_position())
					pi.rotate(PI)
				else:
					var pi = load("res://scenes/animations/"+Cards.data[card.ID]["animation"]+".tscn").instance()
					card.node.add_child(pi)
			timer.set_wait_time(0.5)
			timer.start()
			yield(timer,"timeout")
			if (animations):
				card.node.get_node("AnimationPlayer").play("fizzle")
			else:
				card.node.get_node("AnimationPlayer").play("fade_out")
		graveyard[player].push_back(card)
		card.in_game = true
		hand[player].erase(card)
	elif (card.type=="land"):
		var p2
		var p1 = Vector2(card.node.get_global_position().x,0.5*card.node.get_global_position().y)
		spawn_creature(card,player,"land")
		card.node.get_node("Tween").remove_all()
		card.node.get_node("Tween").interpolate_property(card.node,"global_position",card.node.get_global_position(),p1,0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		p2 = Vector2(225*card.pos,200*(1-2*player))
		card.node.get_node("Tween").interpolate_property(card.node,"global_position",p1,p2,0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,0.25)
		card.node.get_node("Tween").start()
	
	if (is_multiplayer && player==PLAYER1):
		var t = {}
		if (state!=null && state.has("_target")):
			t = state["_target"]
		if (c!=null):
			rpc("_play_card",c,player,t)
	using_card = false
	mana[player] -= card.level
	deselect(false)
	update_stats()
	sort_hand(player)
	sort_cards()
	emit_signal("card_played",player,card,target)

func spawn_creature(card,player,type="creature"):
	var pID = find_empty_position(player)
	var pos = Vector2(225*pID,200*(1-2*player))
	used_positions[player].push_back(pID)
	card.pos = pID
	hand[player].erase(card)
	card.node.get_node("Tween").interpolate_property(card.node,"global_position",card.node.get_global_position(),pos,0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
	card.node.get_node("Tween").start()
	card.node._z = 0
	card.node.set_z_index(0)
	card.in_game = true
	card.node.type = type
	card.node.pos = pos
	if (Cards.data[card.ID].has("on_play")):
		apply_effect(card,"on_play")
	for p in range(2):
		for c in field[p]:
			if (Cards.data[c.ID].has("on_"+type+"_spawn")):
				apply_effect(c,"on_"+type+"_spawn",card)
	for c in field[player]:
		if (Cards.data[c.ID].has("on_ally_"+type+"_spawn")):
			apply_effect(c,"on_ally_"+type+"_spawn",card)
	for c in field[(player+1)%2]:
		if (Cards.data[c.ID].has("on_enemy_"+type+"_spawn")):
			apply_effect(c,"on_enemy_"+type+"_spawn",card)
	field[player].push_back(card)

func create_creature(type,player,pos):
	var node = Cards.create_card(type)
	var card = Card.new(type,player,node)
	node.card = card
	node.pos = pos
	node.set_global_position(pos)
	get_node("Cards").add_child(node)
	spawn_creature(card,player)

func create_equipment_card(type,player,parent,pos):
	var node = Cards.create_card(type)
	var card = Card.new(type,player,node)
	node.card = card
	node.pos = pos
	node.set_global_position(pos)
	get_node("Cards").add_child(node)
	return card

func add_equipment_card(type,player,parent,pos):
	# Add a equipment card to parent. The effects are applied.
	var card = create_equipment_card(type,player,parent,pos)
	var offset = min(75,200/(parent.equiped.size()+1))
	var p2 = parent.node.get_global_position()+Vector2(0,offset*(parent.equiped.size()+1))*(1-2*parent.owner)
	card.node._z = -parent.equiped.size()-1
	card.node.set_z_index(-parent.equiped.size()-1)
	card.node.type = "equiped"
	card.node.pos = pos
	parent.equiped.push_back(card)
	parent.update()
	card.node.get_node("Tween").interpolate_property(card.node,"global_position",card.node.get_global_position(),p2,0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
	card.node.get_node("Tween").start()
	apply_effect(card,"on_play",parent)
	return card

func can_target(card,effect,player,target):
	# Checks whether the target is a valid target for the cards effect or not.
	var data = Cards.data[card.ID]
	if (!data.has("target")):
		return false
	var type = data[effect]
	var enemy = (player+1)%2
	var target_type = data["target"].split("-")
	if (!((target.type in target_type) || (target.node.type=="hand" && ("hand" in target_type)) || ("any" in target_type)) || (target.node.type=="hand" && !("hand" in target_type)) || (("ally" in target_type) && target.owner!=player)):
		return false
	if (target_type.size()>1):
		var has_tag = true
		for i in range(1,target_type.size()):
			var tag = target_type[i]
			if !(tag in ["ally","enemy","any","creature","land","hand"]):
				has_tag = tag in Cards.data[target.ID]["tags"]
				if (has_tag):
					break
		if (!has_tag):
			return false
	var ammount = 0
	var s = type.split("-")
	if (s.size()==0):
		return true
	type = s[0]
	if (s.size()>1):
		ammount = int(s[1])
	
	if (type=="neutralize_temp"):
		if (target.temperature==0):
			return false
	elif (type=="kill_cold"):
		if (target.temperature>=0 || -target.temperature>ammount):
			return false
	elif (type=="kill_hot"):
		if (target.temperature<=0 || target.temperature>ammount):
			return false
	elif (type=="kill_level"):
		if (target.level>ammount):
			return false
	elif (type=="explosion"):
		var dmg = abs(target.temperature)
		if (dmg==0 || target.owner!=player):
			return false
	
	return true

func use_effect(card,effect,player,target=null):
	var data = Cards.data[card.ID]
	var type = data[effect]
	var s = type.split("-")
	var ammount = 0
	var enemy = (player+1)%2
	var target_type
	if (s.size()>1):
		type = s[0]
		ammount = int(s[1])
	
	if (data.has("target")):
		target_type = data["target"].split("-")
		if (target==null):
			select = target_type[0]
			if ("creature" in target_type):
				if (is_multiplayer && player!=PLAYER1):
					printt("Invalid target selected.")
					state = {"used":true}
					emit_signal("effect_used")
				if (player==PLAYER1):
					UI.get_node("Player1/VBoxContainer/ButtonC").set_text(tr("CANCEL"))
					UI.get_node("Player1/VBoxContainer/ButtonC").set_disabled(false)
				elif (player==PLAYER2 && !ai && !is_multiplayer):
					UI.get_node("Player2/VBoxContainer/ButtonC").set_text(tr("CANCEL"))
					UI.get_node("Player2/VBoxContainer/ButtonC").set_disabled(false)
				print("Please select a "+select+" card.")
				hint_valid_cards("creature",card,effect)
				yield(self,"target_selected")
				target = selected_card
		
		if (target!=null):
			if (("ally" in target_type) && target.owner!=player):
				target = null
		if (target==null):
			state = {"used":false}
			emit_signal("effect_used")
			return
	
	state = {"used":false}
	if (is_multiplayer && player==PLAYER1):
		var t = {}
		if (target!=null):
			for p in range(2):
				for i in range(field[p].size()):
					var _c = field[p][i]
					if (_c==target):
						t["ID"] = i
						t["player"] = p
						t["type"] = "field"
						break
					for j in range(_c.equiped.size()):
						if (_c.equiped[j]==target):
							t["ID"] = i
							t["player"] = p
							t["type"] = "equipment"
							t["index"] = j
							break
				for i in range(hand[p].size()):
					if (hand[p][i]==target):
						t["ID"] = i
						t["player"] = p
						t["type"] = "hand"
			if (t.size()>0):
				state["_target"] = t
	
	if (target!=null && !can_target(card,effect,player,target)):
		emit_signal("effect_used")
		return
	
	apply_effect(card,effect,target)
	
	state["used"] = true
	state["target"] = target
	emit_signal("effect_used")
	return

func apply_effect(card,event,target=null,arg=null):
	var args
	var effect = Cards.data[card.ID][event]
	var enemy = (card.owner+1)%2
	var array = Array(effect.split("-"))
	var base = array[0]
	if (array.size()>1):
		for i in range(1,array.size()):
			var num = int(array[i])
			if (num!=0):
				array[i] = num
	args = [card,target]
	if (array.size()>1):
		for i in range(1,array.size()):
			args.push_back(array[i])
	if (arg!=null):
		args.push_back(arg)
	
	if (Effects.has_method(base)):
		Effects.callv(base,args)
	
	if (health[player]<=0):
		game_over(player==PLAYER1)
	elif (health[enemy]<=0):
		game_over(enemy==PLAYER1)

# Send positions instead of classes to other players.
remote func _attack(a,t,no_counter=false):
	var attacker = field[(a["player"]+1)%2][a["index"]]
	var target = field[(t["player"]+1)%2][t["index"]]
	attack(attacker,target,no_counter)

func attack(attacker,target,counter=false):
	if (!can_attack(attacker,target,counter)):
		return
#	var counterattack = !counter && abs(target.temperature)>=abs(attacker.temperature) && sign(attacker.temperature)!=sign(target.temperature)
	var counterattack = !counter && can_attack(target,attacker,true)
	if (is_multiplayer && server):
		var a = get_card_index(attacker)
		var t = get_card_index(target)
		if (a.size()>0 && t.size()>0):
			rpc("_attack",a,t,counter)
	var pos_a = attacker.node.get_global_position()
	var pos = 0.75*attacker.node.get_global_position()+0.25*target.node.get_global_position()
	if (!counter):
		# on_attacked events for target
		if (Cards.data[target.ID].has("on_attacked")):
			apply_effect(target,"on_attacked",attacker,target)
		for equiped in target.equiped:
			if (Cards.data[equiped.ID].has("on_attacked")):
				apply_effect(equiped,"on_attacked",attacker,target)
		for land in field[target.owner]:
			if (land.type=="land" && Cards.data[land.ID].has("on_attacked")):
				apply_effect(land,"on_attacked",attacker,target)
		# on_attack events for attacker
		if (Cards.data[attacker.ID].has("on_attack")):
			apply_effect(attacker,"on_attack",target,attacker)
		for equiped in attacker.equiped:
			if (Cards.data[equiped.ID].has("on_attack")):
				apply_effect(equiped,"on_attack",target,attacker)
		for land in field[attacker.owner]:
			if (land.type=="land" && Cards.data[land.ID].has("on_attack")):
				apply_effect(land,"on_attack",target,attacker)
	if (Cards.data[attacker.ID].has("animation") && animations):
		var pi = load("res://scenes/animations/"+Cards.data[attacker.ID]["animation"]+".tscn").instance()
		pi.set_global_position(attacker.node.get_global_position())
		pi.scale *= 0.15
		add_child(pi)
		pi.look_at(target.node.get_global_position())
	if (Cards.data[target.ID].has("on_dead")):
		apply_effect(target,"on_dead",attacker)
	for equiped in target.equiped:
		if (Cards.data[equiped.ID].has("on_dead")):
			apply_effect(equiped,"on_dead",attacker)
	attacker.node.get_node("Tween").interpolate_property(attacker.node,"global_position",pos_a,pos,0.4,Tween.TRANS_BACK,Tween.EASE_IN_OUT)
	attacker.node.get_node("Tween").interpolate_property(attacker.node,"global_position",pos,pos_a,0.6,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,0.4)
	attacker.node.get_node("Tween").start()
	if (counterattack):
		attack(target,attacker,true)
	target.destroy()


func _draw_card(pl,ID=-1):
	if (server):
		ID = draw_card(pl,ID)
		if (is_multiplayer):
			rpc("draw_card",(pl+1)%2,ID)

remote func draw_card(pl,ID=-1):
	if (deck[pl].size()==0):
		print("Player "+str(pl)+" has no cards left!")
		return
	
	if (ID<0):
		ID = randi()%deck[pl].size()
	var node = Cards.create_card(deck[pl][ID])
	var p = hand[pl].size()
	var card = Card.new(deck[pl][ID],pl,node)
	var offset = min(200,(OS.get_window_size().x-100)/max(hand[pl].size(),1))
	var pos1 = Vector2(-250+500*pl,250-500*pl)
	var pos2 = Vector2((275+p*offset/zoom-OS.get_window_size().x/2.0)*(1-2*pl),OS.get_window_size().y/2.0*(1-2*pl))*zoom
	hand[pl].push_back(card)
	node.card = card
	node._z = 1
	node.set_z_index(1)
	node.set_position(get_node("Deck"+str(pl+1)).get_global_position())
	get_node("Cards").add_child(node)
	node.get_node("Tween").interpolate_property(node,"global_position",node.get_global_position(),pos1,0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
	node.get_node("Tween").interpolate_property(node,"global_position",pos1,pos2,0.5,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,0.25)
	node.get_node("Tween").start()
	node.pos = pos2
	deck[pl].remove(ID)
	update_stats()
	get_node("SoundDraw").play()
	if (ai || is_multiplayer):
		if (pl==PLAYER2):
			node.get_node("Animation").play("hide",-1,10.0)
	else:
		if (pl!=player):
			node.get_node("Animation").play("hide",-1,10.0)
	if (deck[pl].size()==0):
		get_node("Deck"+str(pl+1)+"/Sprite").hide()
	return ID

func _draw_extra_card():
	if (is_multiplayer):
		rpc("draw_extra_card",player)
	else:
		draw_extra_card(player)

sync func draw_extra_card(player):
	if (!inc_mana[player]):
		return
	
	_draw_card(player)
	deselect()
	inc_mana[player] = false
	UI.get_node("Player"+str(player+1)+"/VBoxContainer/ButtonD").set_disabled(true)


func sort_hand(player):
	# Shift the cards in hand to their right positions with offset depending on their number.
	# Therefore they all fit onto the screen.
	if (player<PLAYER1):
		return
	
	var ID = 0
	var offset = min(210/zoom,(OS.get_window_size().x-250)/max(hand[player].size(),1))
	for card in hand[player]:
		if (card.in_game):
			continue
		var pos = Vector2((275+ID*offset-OS.get_window_size().x/2.0)*(1-2*player),OS.get_window_size().y/2.0*(1-2*player))*zoom
		card.node.get_node("Tween").remove_all()
		card.node.get_node("Tween").interpolate_property(card.node,"global_position",card.node.get_global_position(),pos,0.5,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		card.node.get_node("Tween").start()
		card.node.pos = pos
		ID += 1

func sort_cards():
	# Sort the ordering of card nodes in the tree depending on z index.
	# That will ensure the Control nodes of the cards used for input overlap corresponding to the z index.
	# Does not work though.
	var z_min = 0
	for card in get_node("Cards").get_children():
		if (card.get_z_index()<z_min):
			z_min = card.get_z_index()
	
	for z in range(z_min,2):
		for card in get_node("Cards").get_children():
			if (card.get_z_index()==z):
				card.raise()
				card.get_node("Button").raise()

func hint_valid_cards(s=null,card=null,event="on_play"):
	if (s==null):
		s = select
	for node in get_node("Cards").get_children():
		if (node.get_node("Select").is_visible()):
			node.get_node("Animation").play("deselect")
	if (s=="hand" || s=="hand_creature"):
		if (player==PLAYER1 || (!ai && !is_multiplayer)):
			for card in hand[player]:
				if (card.level<=mana[player]):
					card.node.get_node("Animation").queue("blink")
	elif (s=="attack"):
		for t in field[(player+1)%2]:
			if (can_attack(card,t)):
				t.node.get_node("Animation").play("blink")
	elif (card!=null):
		for c in field[PLAYER1]+field[PLAYER2]+hand[PLAYER1]+hand[PLAYER2]:
			if (can_target(card,event,player,c)):
				c.node.get_node("Animation").play("blink")
	

# warning-ignore:function_conflicts_variable
func select(card,type):
	if ((ai || is_multiplayer) && player!=PLAYER1):
		return
	if (type!=select && !(select=="hand_creature" && type in ["hand","creature"])):
		deselect(false)
		emit_signal("target_selected",null)
		return
	
	var last_selected = selected_card
	hint_valid_cards()
	selected_card = card
	selected_card.node.get_node("Animation").play("select")
	if (type=="hand" || (select=="hand_creature" && !selected_card.in_game)):
		UI.get_node("Player"+str(player+1)+"/VBoxContainer/ButtonC").set_text(tr("PLAY"))
		UI.get_node("Player"+str(player+1)+"/VBoxContainer/ButtonC").set_disabled(false)
	elif (selected_card.type=="creature"):
		UI.get_node("Player"+str(player+1)+"/VBoxContainer/ButtonC").set_text(tr("CANCEL"))
		UI.get_node("Player"+str(player+1)+"/VBoxContainer/ButtonC").set_disabled(false)
	emit_signal("target_selected",card)
	if (selected_card==null):
		return
	
	if (select=="hand"):
		play_card(card,player)
	elif (select=="hand_creature"):
		if (selected_card.owner!=player):
			deselect(false)
		elif (!selected_card.in_game):
			play_card(card,player)
		elif (selected_card.type=="creature"):
			select = "creature"
			hint_valid_cards("attack",selected_card)
	elif (select=="creature"):
		set_attack(last_selected,selected_card)
		deselect(false)

func deselect(emit=true):
	if (selected_card!=null):
		selected_card.node.get_node("TweenScale").interpolate_property(selected_card.node,"scale",selected_card.node.get_scale(),Vector2(0.15,0.15),0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		selected_card.node.get_node("Animation").queue("deselect")
	selected_card = null
#	select = "hand"
	select = "hand_creature"
	using_card = false
	if (player>=0):
		UI.get_node("Player"+str(player+1)+"/VBoxContainer/ButtonC").set_disabled(true)
	sort_hand(player)
	hint_valid_cards()
	
	if (emit):
		state = null
		emit_signal("target_selected",null)
		emit_signal("effect_used")

func _confirm():
	if (using_card):
		deselect()
		return
	
	if (selected_card!=null):
		if (selected_card.type=="creature" && selected_card.in_game):
			clear_attack(selected_card)
			UI.get_node("Player"+str(player+1)+"/VBoxContainer/ButtonC").set_disabled(true)
		else:
			play_card(selected_card,player)


func end_turn():
	deselect()
	UI.get_node("Player1/VBoxContainer/ButtonE").set_disabled(true)
	UI.get_node("Player1/VBoxContainer/ButtonD").set_disabled(true)
	UI.get_node("Player1/VBoxContainer/ButtonC").set_disabled(true)
	UI.get_node("Player2/VBoxContainer/ButtonE").set_disabled(true)
	UI.get_node("Player2/VBoxContainer/ButtonD").set_disabled(true)
	UI.get_node("Player2/VBoxContainer/ButtonC").set_disabled(true)
	if (!is_multiplayer || server):
		attack_phase()
	else:
		rpc_id(1,"attack_phase")

func next_turn(draw=1):
	var enemy
	turn += 1
	player = turn%2
	enemy = (player+1)%2
	clear_attack_list()
	
	if (mana[player]==mana_max[player]):
		draw += 1
	if (inc_mana[player]):
		mana_max[player] += 1
	inc_mana[player] = true
	mana[player] = mana_max[player]
	if (server):
		for i in range(draw):
			_draw_card(player)
	
	deselect()
	
	for card in field[PLAYER1]+field[PLAYER2]:
		if (Cards.data[card.ID].has("on_new_turn")):
			apply_effect(card,"on_new_turn",card)
		for equiped in card.equiped:
			if (Cards.data[equiped.ID].has("on_new_turn")):
				apply_effect(equiped,"on_new_turn",card)
	
	selected_card = null
	select = "hand_creature"
	update_stats()
	UI.get_node("VBoxContainer/LabelT").set_text(tr("PLAYER_TURN")%player_name[player])
	UI.get_node("VBoxContainer/LabelP").set_text(tr("PLAYING_PHASE"))
	
	if (!ai && !is_multiplayer):
		for card in hand[player]:
			card.node.get_node("Animation").play("show")
		for card in hand[enemy]:
			card.node.get_node("Animation").play("hide")
	
	if (hand[PLAYER1].size()==0 && hand[PLAYER2].size()==0):
		game_over(health[PLAYER1]<=health[PLAYER2])
		return
	
	UI.get_node("Player"+str(player+1)+"/VBoxContainer/ButtonE").set_disabled(false)
	UI.get_node("Player"+str(player+1)+"/VBoxContainer/ButtonD").set_disabled(hand[player].size()==0)
	UI.get_node("Player"+str(enemy+1)+"/VBoxContainer/ButtonE").set_disabled(true)
	UI.get_node("Player"+str(enemy+1)+"/VBoxContainer/ButtonD").set_disabled(true)
	if (!ai && !is_multiplayer):
		UI.get_node("Player"+str(player+1)+"/VBoxContainer/ButtonC").show()
		UI.get_node("Player"+str(player+1)+"/VBoxContainer/ButtonE").show()
		UI.get_node("Player"+str(player+1)+"/VBoxContainer/ButtonD").show()
		UI.get_node("Player"+str(enemy+1)+"/VBoxContainer/ButtonC").hide()
		UI.get_node("Player"+str(enemy+1)+"/VBoxContainer/ButtonE").hide()
		UI.get_node("Player"+str(enemy+1)+"/VBoxContainer/ButtonD").hide()
	
	if (ai && player==PLAYER2):
		ai_turn(player)
	
	emit_signal("turn_started",player)

remote func attack_phase():
	if (!server):
		return
	
	var enemy = (player+1)%2
	for card in []+field[player]:
		if (!attack_list.has(card)):
			continue
		attack(card,attack_list[card])
		clear_attack(card)
		timer.set_wait_time(1.0)
		timer.start()
		yield(timer,"timeout")
		if (is_multiplayer):
			rpc("update_stats")
		else:
			update_stats()
	
	if (is_multiplayer):
		rpc("attack_phase_end")
	else:
		attack_phase_end()

sync func attack_phase_end():
	var enemy = (player+1)%2
	var draw = 1
	var num_enemy_creatures = 0
	for card in field[enemy]:
		num_enemy_creatures += int(card.type=="creature")
	if (turn>1-int(server) && num_enemy_creatures==0):
		# Deal damage to enemy.
		var temp = get_player_temperature(player)
		var dmg = min(abs(temp),10)
		if (dmg>0):
			health[enemy] -= dmg
			for c in field[PLAYER1]+field[PLAYER2]:
				if (Cards.data[c.ID].has("on_damaged")):
					apply_effect(c,"on_damaged",dmg)
			# Draw 2 cards if damaged.
			draw += 1
			if (temp>0):
				UI.get_node("Player"+str(enemy+1)+"/Animation").play("fire_damage")
			else:
				UI.get_node("Player"+str(enemy+1)+"/Animation").play("ice_damage")
			print("Deal "+str(dmg)+" damage to player "+str(enemy)+"!")
	
	if (health[enemy]<=0):
		update_stats()
		game_over()
	else:
		next_turn(draw)

func can_attack(attacker,target,counter=false):
	if (attacker.type!="creature" || target.type!="creature" || attacker.owner==target.owner || (!counter && Cards.data[attacker.ID].has("no_attack") && Cards.data[attacker.ID]["no_attack"])):
		return false
	var can_target_all = Cards.data[attacker.ID].has("can_target_all") && Cards.data[attacker.ID]["can_target_all"]
	for eq in attacker.equiped:
		if (!counter && Cards.data[eq.ID].has("no_attack") && Cards.data[eq.ID]["no_attack"]):
			return false
		if (Cards.data[eq.ID].has("can_target_all") && Cards.data[eq.ID]["can_target_all"]):
			can_target_all = true
	return abs(target.temperature)<=abs(attacker.temperature) && (can_target_all || sign(target.temperature)!=sign(attacker.temperature))

func is_targeted(target):
	return target in attack_list.values()

func _set_attack(attacker,target):
	if (is_multiplayer):
		var a = get_card_index(attacker)
		var t = get_card_index(target)
		rpc("remote_set_attack",a,t)
	set_attack(attacker,target)

remote func remote_set_attack(a,t):
	var attacker = field[(a["player"]+1)%2][a["index"]]
	var target = field[(t["player"]+1)%2][t["index"]]
	set_attack(attacker,target)

func set_attack(attacker,target):
	if (!(attacker in field[attacker.owner]) || !(target in field[target.owner]) || !can_attack(attacker,target) || is_targeted(target)):
		return
	var ai = get_node("ArrowAttack").duplicate()
	if (attack_list.has(attacker)):
		clear_attack(attacker)
	attack_list[attacker] = target
	attacker.arrow = ai
	ai.origin = attacker.node.get_global_position()
	ai.set_global_position(target.node.get_global_position())
	ai.show()
	add_child(ai)

func _clear_attack(attacker):
	if (is_multiplayer):
		var a = get_card_index(attacker)
		rpc("remote_clear_attack",a)
#	set_attack(attacker)
	attack_list[attacker] = null

remote func remote_clear_attack(a):
	var attacker = field[(a["player"]+1)%2][a["index"]]
	clear_attack(attacker)

func clear_attack(attacker):
	if (attacker.arrow!=null):
		attacker.arrow.queue_free()
	attack_list.erase(attacker)

func clear_attack_list():
	for attacker in attack_list.keys():
		if (attacker.arrow!=null):
			attacker.arrow.queue_free()
	attack_list.clear()


sync func update_stats():
	# Update GUI.
	for p in range(2):
		var temp = get_player_temperature(p)
		if (health[p]<=0):
			health[p] = 0
		UI.get_node("Player"+str(p+1)+"/VBoxContainer/Health/Label").set_text(tr("HEALTH")+": "+str(health[p]))
		UI.get_node("Player"+str(p+1)+"/VBoxContainer/Health/Bar").set_value(health[p])
		UI.get_node("Player"+str(p+1)+"/VBoxContainer/Mana/Label").set_text(tr("MANA")+": "+str(mana[p]))
		UI.get_node("Player"+str(p+1)+"/VBoxContainer/Mana/Bar").set_value(mana[p])
		UI.get_node("Player"+str(p+1)+"/VBoxContainer/Mana/Bar").set_max(mana_max[p])
		UI.get_node("Player"+str(p+1)+"/VBoxContainer/Temp/Label").set_text(tr("TEMPERATURE")+": "+str(temp))
		UI.get_node("Player"+str(p+1)+"/VBoxContainer/Temp/Bar").set_value(temp)
		UI.get_node("Player"+str(p+1)+"/VBoxContainer/Temp/Bar").get_material().set_shader_param("color",Cards.COLOR_COLD.linear_interpolate(Cards.COLOR_HOT,temp/10.0+0.5))
		UI.get_node("Player"+str(p+1)+"/VBoxContainer/Temp/Bar").get_material().set_shader_param("hot",max(temp/10.0,0.0))
		UI.get_node("Player"+str(p+1)+"/VBoxContainer/Temp/Top").get_material().set_shader_param("cold",max(-temp/10.0,0.0))
		UI.get_node("Player"+str(p+1)+"/VBoxContainer/Deck").set_text(tr("DECK")+": "+str(deck[p].size()))
	Music.temperature = get_player_temperature(player)+0.5*get_player_temperature((player+1)%2)


func _resize():
	zoom = max(1800.0/OS.get_window_size().x,1400.0/OS.get_window_size().y)
	get_node("Camera").make_current()
	get_node("Camera").set_zoom(zoom*Vector2(1,1))
	for p in range(2):
		sort_hand(p)

func _input(event):
	if (event is InputEventMouseButton && event.button_index==1 && !event.pressed):
		yield(get_tree(),"idle_frame")
		for card in hand[PLAYER1]+hand[PLAYER2]:
			if (abs(card.node.get_scale().x)>0.151 || card.node.get_scale().y>0.151):
				card.node.unzoom()
		hint_valid_cards("hand_creature")

func _ready():
	timer = Timer.new()
	timer.set_one_shot(true)
	add_child(timer)
	set_process_input(true)
	get_tree().connect("screen_resized",self,"_resize")
	_resize()
	get_node("Camera").make_current()

extends Node

# modify temperature #

func inc_temp(card,target,amount):
	target.temperature += amount
	target.update()

func dec_temp(card,target,amount):
	target.temperature -= amount
	target.update()

func neutralize_temp(card,target,amount):
	if (target.temperature>0):
		target.temperature -= amount
	elif (target.temperature<0):
		target.temperature += amount
	target.update()

func amplify_temp(card,target,amount):
	if (target.temperature>0):
		target.temperature += amount
	elif (target.temperature<0):
		target.temperature -= amount
	target.update()

func invert_temp(card,target):
	target.temperature *= -1
	target.update()

func invert_ally_temp(card,target):
	for c in Main.field[card.owner]:
		c.temperature *= -1
		c.update()

func invert_enemy_temp(card,target):
	for c in Main.field[(card.owner+1)%2]:
		c.temperature *= -1
		c.update()

func inc_ally_temp(card,target,amount):
	for c in Main.field[card.owner]:
		c.temperature += amount
		c.update()

func dec_ally_temp(card,target,amount):
	for c in Main.field[card.owner]:
			c.temperature -= amount
			c.update()

func ice_armor(card,target,amount):
	if (Main.player==card.owner):
		target.temperature += amount
	else:
		target.temperature -= amount
	target.update()

func fire_armor(card,target,amount):
	if (Main.player==target.owner):
		target.temperature -= amount
	else:
		target.temperature += amount
	target.update()

func ice_aura(card,target,amount):
	for c in Main.field[card.owner]:
		if ("ice" in Cards.data[c.ID]["tags"]):
			if (Main.player==c.owner):
				c.temperature += amount
			else:
				c.temperature -= amount
			c.update()

func fire_aura(card,target,amount):
	for c in Main.field[card.owner]:
		if ("fire" in Cards.data[c.ID]["tags"]):
			if (Main.player==c.owner):
				c.temperature += amount
			else:
				c.temperature -= amount
			c.update()

func global_diffusion(card,target,amount):
	var global_temp = (Main.get_player_temperature(Main.PLAYER1)+Main.get_player_temperature(Main.PLAYER2))/2
	target.temperature += amount*sign(global_temp-target.temperature)

func global_diffusion_all(card,target,amount):
	var global_temp = (Main.get_player_temperature(Main.PLAYER1)+Main.get_player_temperature(Main.PLAYER2))/2
	for c in Main.field[Main.PLAYER1]+Main.field[Main.PLAYER2]:
		if (c.type=="creature"):
			c.temperature += amount*sign(global_temp-c.temperature)

func inc_player_temp(card,target,amount):
	Main.temperature[card.owner] += amount

func dec_player_temp(card,target,amount):
	Main.temperature[card.owner] -= amount

# destroy cards #

func kill_cold(card,target,amount):
	if (target.temperature<0 && -target.temperature<=amount):
		target.destroy()

func kill_hot(card,target,amount):
	if (target.temperature>0 && target.temperature<=amount):
		target.destroy()

func kill_level(card,target,amount,attacked=null):
	if (target.level<=amount):
		target.destroy()

func kill_all_hot(card,target,amount):
	for c in Main.field[Main.PLAYER1]+Main.field[Main.PLAYER2]:
		if (c.type=="creature" && c.temperature>0 && c.temperature<=amount):
			c.destroy()

func kill_all_cold(card,target,amount):
	for c in Main.field[Main.PLAYER1]+Main.field[Main.PLAYER2]:
		if (c.type=="creature" && c.temperature<0 && -c.temperature<=amount):
			c.destroy()

func explosion(card,target):
	var dmg = abs(target.temperature)
	target.destroy()
	if (dmg>0):
		for c in Main.field[Main.PLAYER1]+Main.field[Main.PLAYER2]:
			if (c.type=="creature" && abs(c.temperature)<dmg):
				c.destroy()

func destroy_enemy_turn(card,target):
	if (card.owner!=Main.player):
		card.destroy()

func destroy_player_turn(card,target):
	if (card.owner==Main.player):
		card.destroy()

func cleanse(card,target):
	target.remove_equipment()
	target.temperature = Cards.data[target.ID]["temperature"]
	target.level = Cards.data[target.ID]["level"]
	target.update()
	card.destroy()

func destroy_all_lands(card,target):
	for c in Main.field[Main.PLAYER1]+Main.field[Main.PLAYER2]:
		if (c.type=="land"):
			c.destroy()

func melt(card,target,amount):
	if (Main.player!=card.owner):
		return
	card.temperature += amount
	card.update()
	if (card.temperature>=0):
		card.destroy()

func melt_target(card,target,amount):
	if (Main.player!=card.owner):
		return
	target.temperature += amount
	target.update()
	if (target.temperature>=0):
		target.destroy()

func anneal(card,target,amount):
	if (Main.player!=card.owner):
		return
	card.temperature -= amount
	card.update()
	if (card.temperature<=0):
		card.destroy()

func anneal_target(card,target,amount):
	if (Main.player!=card.owner):
		return
	target.temperature -= amount
	target.update()
	if (target.temperature<=0):
		target.destroy()

func move_to_hand(card,target):
	var enemy = (Main.player+1)%2
	Main.hand[target.owner].push_back(target)
	Main.field[target.owner].erase(target)
	target.remove_equipment()
	if (Cards.data[target.ID].has("on_removed")):
		Main.apply_effect(target,"on_removed",target)
	target.in_game = false
	target.node.type = "hand"
	target.temperature = Cards.data[target.ID]["temperature"]
	target.level = Cards.data[target.ID]["level"]
	target.update()
	Main.used_positions[enemy].erase(target.pos)
	Main.sort_hand(enemy)
	if (target.owner!=Main.player && target.owner!=Main.PLAYER1 && (Main.ai || Main.multiplayer)):
		yield(get_tree(),"idle_frame")
		target.node.get_node("Animation").play("hide")

# mana #

func inc_mana(card,target,amount):
	Main.mana_max[card.owner] += amount
	Main.update_stats()

func dec_mana(card,target,amount):
	Main.mana_max[card.owner] -= amount
	Main.update_stats()

# equip spell cards #

func equip(card,target,type,attacked=null):
	if (type!=""):
		Main.add_equipment_card(type,card.owner,target,card.node.get_global_position())

func equip_all(card,target,type):
	if (type==""):
		return
	for c in Main.field[Main.PLAYER1]+Main.field[Main.PLAYER2]:
		if (c.type=="creature"):
			Main.add_equipment_card(type,card.owner,c,card.node.get_global_position())

func equip_all_ally(card,target,type):
	if (type==""):
		return
	for c in Main.field[card.owner]:
		if (c.type=="creature"):
			Main.add_equipment_card(type,card.owner,c,card.node.get_global_position())

func equip_all_ally_ice(card,target,type):
	if (type==""):
		return
	for c in Main.field[card.owner]:
		if (("ice" in Cards.data[c.ID]["tags"]) && c.type=="creature"):
			Main.add_equipment_card(type,card.owner,c,card.node.get_global_position())

# direct damage #

func damage_enemy(card,target,amount):
	var enemy = (Main.player+1)%2
	if (card.owner==Main.player):
		Main.health[enemy] -= amount
		Main.update_stats()

func damage_player(card,target,amount):
	if (card.owner==Main.player):
		Main.health[Main.player] -= amount
		Main.update_stats()

func health_shield(card,amount):
	var enemy = (Main.player+1)%2
	if (card.owner==enemy):
		Main.health[card.owner] += amount

# special #

func draw(card,target,amount):
	var timer = Timer.new()
	timer.set_one_shot(true)
	add_child(timer)
	Main.get_node("SoundShuffle").play()
	for i in range(amount):
		Main._draw_card(card.owner)
		timer.set_wait_time(0.2)
		timer.start()
		yield(timer,"timeout")
	timer.set_wait_time(0.1)
	timer.start()
	yield(timer,"timeout")
	Main.sort_hand(card.owner)
	timer.queue_free()

func spawn(card,target,amount,type=""):
	if (type==""):
		return
	for i in range(amount):
		Main.create_creature(type,card.owner,card.node.pos)

func assemble(card,target):
	for c in []+Main.field[card.owner]:
		if (c.type=="creature"):
			card.temperature += c.temperature
			c.destroy()
	card.update()

func acid(card,target):
	target.level -= 2
	for eq in target.equiped:
		if ("equipment" in Cards.data[eq.ID]["tags"]):
			target.equipment.erase(eq)
			eq.destroy()
	target.update()

func freeze(card,target,attacked):
	printt("freeze",card.ID,target.ID,attacked.ID)
	if !("ice" in Cards.data[attacked.ID]["tags"]):
		return
	var eq = Main.add_equipment_card("freeze",card.owner,target,card.node.get_global_position())
	eq.temperature -= 1
	eq.update()

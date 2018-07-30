extends Node

# modify temperature #

func inc_temp(card,target,ammount):
	target.temperature += ammount
	target.update()

func dec_temp(card,target,ammount):
	target.temperature -= ammount
	target.update()

func neutralize_temp(card,target,ammount):
	if (target.temperature>0):
		target.temperature -= ammount
	elif (target.temperature<0):
		target.temperature += ammount
	target.update()

func amplify_temp(card,target,ammount):
	if (target.temperature>0):
		target.temperature += ammount
	elif (target.temperature<0):
		target.temperature -= ammount
	target.update()

func invert_temp(card,target):
	target.temperature *= -1
	target.update()

func inc_ally_temp(card,target,ammount):
	for c in Main.field[card.owner]:
		c.temperature += ammount
		c.update()

func dec_ally_temp(card,target,ammount):
	for c in Main.field[card.owner]:
			c.temperature -= ammount
			c.update()

func ice_armor(card,target,ammount):
	if (Main.player==card.owner):
		target.temperature += ammount
	else:
		target.temperature -= ammount
	target.update()

func fire_armor(card,target,ammount):
	if (Main.player==target.owner):
		target.temperature -= ammount
	else:
		target.temperature += ammount
	target.update()

func ice_aura(card,target,ammount):
	for c in Main.field[card.owner]:
		if ("ice" in Cards.data[c.ID]["tags"]):
			if (Main.player==c.owner):
				c.temperature += ammount
			else:
				c.temperature -= ammount
			c.update()

func fire_aura(card,target,ammount):
	for c in Main.field[card.owner]:
		if ("fire" in Cards.data[c.ID]["tags"]):
			if (Main.player==c.owner):
				c.temperature += ammount
			else:
				c.temperature -= ammount
			c.update()

func global_diffusion(card,target,ammount):
	var global_temp = (Main.get_player_temperature(Main.PLAYER1)+Main.get_player_temperature(Main.PLAYER2))/2
	target.temperature += ammount*sign(global_temp-target.temperature)

func global_diffusion_all(card,target,ammount):
	var global_temp = (Main.get_player_temperature(Main.PLAYER1)+Main.get_player_temperature(Main.PLAYER2))/2
	for c in Main.field[Main.PLAYER1]+Main.field[Main.PLAYER2]:
		if (c.type=="creature"):
			c.temperature += ammount*sign(global_temp-c.temperature)

func inc_player_temp(card,target,ammount):
	Main.temperature[card.owner] += ammount

func dec_player_temp(card,target,ammount):
	Main.temperature[card.owner] -= ammount

# destroy cards #

func kill_cold(card,target,ammount):
	if (target.temperature<0 && -target.temperature<=ammount):
		target.destroy()

func kill_hot(card,target,ammount):
	if (target.temperature>0 && target.temperature<=ammount):
		target.destroy()

func kill_level(card,target,ammount):
	printt(card,target,ammount)
	if (target.level<=ammount):
		target.destroy()

func kill_all_hot(card,target,ammount):
	for c in Main.field[Main.PLAYER1]+Main.field[Main.PLAYER2]:
		if (c.type=="creature" && c.temperature>0 && c.temperature<=ammount):
			c.destroy()

func kill_all_cold(card,target,ammount):
	for c in Main.field[Main.PLAYER1]+Main.field[Main.PLAYER2]:
		if (c.type=="creature" && c.temperature<0 && -c.temperature<=ammount):
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

func melt(card,target):
	if (Main.player!=card.owner):
		return
	card.temperature += 1
	card.update()
	if (card.temperature>=0):
		card.destroy()

func melt_target(card,target):
	if (Main.player!=card.owner):
		return
	target.temperature += 1
	target.update()
	if (target.temperature>=0):
		target.destroy()

func anneal(card,target):
	if (Main.player!=card.owner):
		return
	card.temperature -= 1
	card.update()
	if (card.temperature<=0):
		card.destroy()

func anneal_target(card,target):
	if (Main.player!=card.owner):
		return
	target.temperature -= 1
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
	if (target.owner!=Main.player && !((Main.ai || Main.multiplayer) && target.owner==Main.PLAYER1)):
		target.node.get_node("Animation").play("hide")
	Main.used_positions[enemy].erase(target.pos)
	Main.sort_hand(enemy)

# mana #

func inc_mana(card,target,ammount):
	Main.mana_max[card.owner] += ammount
	Main.update_stats()

func dec_mana(card,target,ammount):
	Main.mana_max[card.owner] -= ammount
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

func damage_enemy(card,target,ammount):
	var enemy = (Main.player+1)%2
	if (card.owner==Main.player):
		Main.health[enemy] -= ammount
		Main.update_stats()

func damage_player(card,target,ammount):
	if (card.owner==Main.player):
		Main.health[Main.player] -= ammount
		Main.update_stats()

func health_shield(card,ammount):
	var enemy = (Main.player+1)%2
	if (card.owner==enemy):
		Main.health[card.owner] += ammount

# special #

func draw(card,target,ammount):
	var timer = Timer.new()
	timer.set_one_shot(true)
	add_child(timer)
	Main.get_node("SoundShuffle").play()
	for i in range(ammount):
		Main._draw_card(card.owner)
		timer.set_wait_time(0.2)
		timer.start()
		yield(timer,"timeout")
	timer.set_wait_time(0.1)
	timer.start()
	yield(timer,"timeout")
	Main.sort_hand(card.owner)
	timer.queue_free()

func spawn(card,target,ammount,type=""):
	if (type==""):
		return
	for i in range(ammount):
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
	if !("ice" in Cards.data[attacked.ID]["tags"]):
		return
	var eq = Main.add_equipment_card("freeze",card.owner,target,card.node.get_global_position())
	eq.temperature -= 1
	eq.update()

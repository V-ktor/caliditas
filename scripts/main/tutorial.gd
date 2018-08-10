extends Node

var timer = Timer.new()

onready var text = get_node("Panel/Text")
onready var animation = get_node("AnimationPlayer")
onready var button = get_node("Panel/ButtonF")

signal forward()


func hide_text():
	var t = text.get_text()
	text.clear()
	text.push_color(Color(0.5,0.5,0.5))
	text.add_text(t+"\n")
	text.push_color(Color(1.0,1.0,1.0))

func _continue():
	emit_signal("forward")

func _ready():
	var card
	var ID = 0
	UI.get_node("Player1").hide()
	UI.get_node("Player2").hide()
	timer.set_one_shot(true)
	add_child(timer)
	get_node("Panel/ButtonF").connect("pressed",self,"_continue")
	Main.update_stats()
	text.clear()
	text.add_text(tr("TUTORIAL_INTRO1")+"\n")
	timer.set_wait_time(1.0)
	timer.start()
	yield(timer,"timeout")
	text.add_text(tr("TUTORIAL_INTRO2")+"\n")
	timer.set_wait_time(2.0)
	timer.start()
	yield(timer,"timeout")
	text.add_text(tr("TUTORIAL_INTRO3")+"\n")
	button.set_disabled(false)
	yield(self,"forward")
	button.set_disabled(true)
	Main.next_turn()
	# Disable player input for now.
	UI.get_node("Player1/VBoxContainer/ButtonE").set_disabled(true)
	Main.player = -1
	hide_text()
	text.add_text(tr("TUTORIAL_MANA1")+"\n")
	timer.set_wait_time(0.2)
	for i in range(Main.START_CARDS-2):
		Main.draw_card(Main.PLAYER1)
		Main.draw_card(Main.PLAYER2)
		timer.start()
		yield(timer,"timeout")
	UI.get_node("Player1/Animation").play("show")
	UI.get_node("Player2/Animation").play("show")
	ID = randi()%Main.deck[Main.PLAYER1].size()
	while (Cards.data[Main.deck[Main.PLAYER1][ID]]["type"]!="creature" || Cards.data[Main.deck[Main.PLAYER1][ID]]["level"]>3):
		ID = randi()%Main.deck[Main.PLAYER1].size()
	Main.draw_card(Main.PLAYER1,ID)
	Main.draw_card(Main.PLAYER2)
	timer.start()
	yield(timer,"timeout")
	ID = randi()%Main.deck[Main.PLAYER1].size()
	while (Cards.data[Main.deck[Main.PLAYER1][ID]]["type"]!="spell" || Cards.data[Main.deck[Main.PLAYER1][ID]]["level"]>3):
		ID = randi()%Main.deck[Main.PLAYER1].size()
	Main.draw_card(Main.PLAYER1,ID)
	Main.draw_card(Main.PLAYER2)
	timer.set_wait_time(0.5)
	timer.start()
	yield(timer,"timeout")
	text.add_text(tr("TUTORIAL_MANA2")%Main.mana[Main.PLAYER1]+"\n")
	button.set_disabled(false)
	yield(self,"forward")
	button.set_disabled(true)
	card = get_creature_card()
	if (card!=null):
		card.node.zoom()
	hide_text()
	text.add_text(tr("TUTORIAL_ATTRIBUTES1")+"\n")
	timer.set_wait_time(2.0)
	timer.start()
	yield(timer,"timeout")
	text.add_text(tr("TUTORIAL_ATTRIBUTES2")+"\n")
	timer.set_wait_time(2.0)
	timer.start()
	yield(timer,"timeout")
	text.add_text(tr("TUTORIAL_ATTRIBUTES3")+"\n")
	timer.set_wait_time(3.0)
	timer.start()
	yield(timer,"timeout")
	text.add_text(tr("TUTORIAL_ATTRIBUTES4")+"\n")
	timer.set_wait_time(4.0)
	timer.start()
	yield(timer,"timeout")
	text.add_text(tr("TUTORIAL_ZOOM")+"\n")
	button.set_disabled(false)
	yield(self,"forward")
	# Allow player to play cards.
	Main.player = Main.PLAYER1
	if (card!=null):
		card.node.unzoom()
	button.set_disabled(true)
	hide_text()
	text.add_text(tr("TUTORIAL_FIRST_TURN")+"\n")
	Main.connect("card_played",self,"_card_played",[],CONNECT_ONESHOT)

func _card_played(player,card,target):
	hide_text()
	if (card.type=="creature"):
		text.add_text(tr("WELL_DONE")+"\n")
	else:
		text.add_text(tr("TUTORIAL_NO_CREATURE")+"\n")
	timer.set_wait_time(1.0)
	timer.start()
	yield(timer,"timeout")
	text.add_text(tr("TUTORIAL_DRAW_CARD")+"\n")
	timer.set_wait_time(2.0)
	timer.start()
	yield(timer,"timeout")
	text.add_text(tr("TUTORIAL_NEXT_TURN")+"\n")
	UI.get_node("Player1/VBoxContainer/ButtonE").set_disabled(false)
	Main.connect("turn_started",self,"_next_turn")

func _next_turn(player):
	hide_text()
	if (player==Main.PLAYER2):
		text.add_text(tr("TUTORIAL_ENEMY_TURN")+"\n")
	else:
		var card
		text.add_text(tr("TUTORIAL_PLAYER_TURN")+"\n")
		Main.disconnect("turn_started",self,"_next_turn")
		# Disable player input for now.
		UI.get_node("Player1/VBoxContainer/ButtonE").set_disabled(true)
		Main.player = -1
		button.set_disabled(false)
		yield(self,"forward")
		button.set_disabled(true)
		card = get_creature_card()
		if (card!=null):
			card.node.zoom()
		hide_text()
		text.add_text(tr("TUTORIAL_CREATURES1")+"\n")
		timer.set_wait_time(2.0)
		timer.start()
		yield(timer,"timeout")
		text.add_text(tr("TUTORIAL_CREATURES2")+"\n")
		timer.set_wait_time(2.0)
		timer.start()
		yield(timer,"timeout")
		text.add_text(tr("TUTORIAL_CREATURES3")+"\n")
		timer.set_wait_time(1.0)
		timer.start()
		yield(timer,"timeout")
		text.add_text(tr("TUTORIAL_CREATURES4")+"\n")
		button.set_disabled(false)
		yield(self,"forward")
		button.set_disabled(true)
		if (card!=null):
			card.node.unzoom()
		hide_text()
		text.add_text(tr("TUTORIAL_ATTACK1")+"\n")
		timer.set_wait_time(2.0)
		timer.start()
		yield(timer,"timeout")
		text.add_text(tr("TUTORIAL_ATTACK2")+"\n")
		timer.set_wait_time(2.0)
		timer.start()
		yield(timer,"timeout")
		text.add_text(tr("TUTORIAL_ATTACK3")+"\n")
		button.set_disabled(false)
		yield(self,"forward")
		button.set_disabled(true)
		card = get_spell_card()
		if (card!=null):
			card.node.zoom()
		hide_text()
		text.add_text(tr("TUTORIAL_SPELLS1")+"\n")
		timer.set_wait_time(1.0)
		timer.start()
		yield(timer,"timeout")
		text.add_text(tr("TUTORIAL_SPELLS2")+"\n")
		timer.set_wait_time(2.0)
		timer.start()
		yield(timer,"timeout")
		text.add_text(tr("TUTORIAL_SPELLS3")+"\n")
		timer.set_wait_time(2.0)
		timer.start()
		yield(timer,"timeout")
		text.add_text(tr("TUTORIAL_SPELLS4")+"\n")
		timer.set_wait_time(2.0)
		timer.start()
		yield(timer,"timeout")
		text.add_text(tr("TUTORIAL_SPELLS5")+"\n")
		button.set_disabled(false)
		yield(self,"forward")
		# Allow player to play cards.
		UI.get_node("Player1/VBoxContainer/ButtonE").set_disabled(false)
		Main.player = Main.PLAYER1
		if (card!=null):
			card.node.unzoom()
		hide_text()
		text.add_text(tr("TUTORIAL_END")+"\n")
		timer.set_wait_time(1.0)
		timer.start()
		yield(timer,"timeout")
		text.add_text(tr("GOOD_LUCK")+"\n")
		button.set_disabled(false)
		yield(self,"forward")
		animation.play("fade_out")
		button.set_disabled(true)

func get_creature_card():
	var card
	for i in range(Main.hand[Main.PLAYER1].size()-1,-1,-1):
		var c = Main.hand[Main.PLAYER1][i]
		if (c.type=="creature"):
			card = c
			break
	return card

func get_spell_card():
	var card
	for i in range(Main.hand[Main.PLAYER1].size()-1,-1,-1):
		var c = Main.hand[Main.PLAYER1][i]
		if (c.type=="spell"):
			card = c
			break
	return card

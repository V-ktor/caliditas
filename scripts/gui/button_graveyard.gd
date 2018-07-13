extends Button

export (int,0,1) var player = 0


func _show():
	var ID = 0
	for card in Main.graveyard[player]:
		var pos = Vector2(240*(ID%7-3),320*(floor(ID/7)-1))
		card.node.get_node("Animation").play("show")
		card.node.get_node("Tween").interpolate_property(card.node,"global_position",get_parent().get_global_position(),pos,0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		card.node.get_node("Tween").start()
		card.node.show()
		card.node.set_z_index(3)
		ID += 1

func _hide():
	for card in Main.graveyard[player]:
		card.node.get_node("Animation").play("hide")
		card.node.get_node("Tween").interpolate_property(card.node,"global_position",card.node.get_global_position(),get_parent().get_global_position(),0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		card.node.get_node("Tween").start()
	if (Main.graveyard[player].size()>0):
		yield(Main.graveyard[player][0].node.get_node("Tween"),"tween_completed")
		for card in Main.graveyard[player]:
			card.node.hide()

func _gui_input(event):
	if (event is InputEventMouseButton):
		if (event.is_pressed()):
			_show()
		else:
			_hide()

func _ready():
	connect("gui_input",self,"_gui_input")

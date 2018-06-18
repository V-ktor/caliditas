extends CanvasLayer


func _hide():
	for c in get_children():
		if (c.has_method("hide")):
			c.hide()

func _show():
	get_node("Player1").show()
	get_node("Player2").show()

func _ready():
	_hide()
	
	# connect buttons
	for i in range(1,3):
		get_node("Player"+str(i)+"/VBoxContainer/ButtonC").connect("pressed",Main,"_confirm")
		get_node("Player"+str(i)+"/VBoxContainer/ButtonE").connect("pressed",Main,"end_turn")

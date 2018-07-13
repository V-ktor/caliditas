extends CanvasLayer


func hide():
	for c in get_children():
		if (c.has_method("hide")):
			c.hide()

func show():
	get_node("Player1").show()
	get_node("Player2").show()
	get_node("VBoxContainer").show()
	get_node("VBoxContainer/LabelT").set_text("")
	get_node("VBoxContainer/LabelP").set_text("")

func _ready():
	hide()
	
	# connect buttons
	for i in range(1,3):
		get_node("Player"+str(i)+"/VBoxContainer/ButtonC").connect("pressed",Main,"_confirm")
		get_node("Player"+str(i)+"/VBoxContainer/ButtonE").connect("pressed",Main,"end_turn")
		get_node("Player"+str(i)+"/VBoxContainer/ButtonD").connect("pressed",Main,"_draw_extra_card")

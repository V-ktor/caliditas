extends Button


func get_drag_data(position):
	if (get_parent().type=="dead" || get_parent().type=="equiped" || get_parent().type=="preview" || get_parent().card.owner!=Main.player):
		return
	var s = "creature"
	Main.get_node("Arrow").origin = get_parent().get_global_position()
	set_drag_preview(Main.get_node("Arrow"))
	if (get_parent().card.type=="creature" && get_parent().card.in_game):
		Main.hint_valid_cards("attack",get_parent().card)
	else:
		Main.hint_valid_cards(s,get_parent().card)
	Main.get_node("Arrow").show()
	return get_parent().card

func can_drop_data(position,data):
	return (data.type=="spell" && Cards.data[data.ID].has("target")) || (data.type=="creature" && Main.can_attack(data,get_parent().card))

func drop_data(position,data):
	if (data.type=="spell"):
		Main.play_card(data,data.owner,get_parent().card)
	elif (data.type=="creature"):
		if (data.owner!=get_parent().card.owner):
			Main.set_attack(data,get_parent().card)
			Main.deselect(false)
		else:
			Main.clear_attack(data)
			Main.deselect(false)
	else:
		Main.deselect(false)

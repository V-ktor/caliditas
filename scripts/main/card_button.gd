extends Button


func get_drag_data(position):
	if (get_parent().type=="dead" || get_parent().type=="equiped" || get_parent().type=="preview"):
		return
	Main.get_node("Arrow").origin = get_parent().get_global_position()
	set_drag_preview(Main.get_node("Arrow"))
	Main.get_node("Arrow").show()
	return get_parent().card

func can_drop_data(position,data):
	return data.type=="spell" && Cards.data[data.ID].has("target")

func drop_data(position,data):
	if (data.type=="spell"):
		Main.play_card(data,data.owner,get_parent().card)

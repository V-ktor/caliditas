extends Control


func can_drop_data(position,data):
	return data.type=="creature" || (data.type=="spell" && !Cards.data[data.ID].has("target"))

func drop_data(position,data):
	if (data.type=="creature"):
		Main.play_card(data,data.owner)
	elif (data.type=="spell"):
		Main.play_card(data,data.owner)

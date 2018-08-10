extends Control


func can_drop_data(position,data):
	return (data.type=="creature" && !data.in_game) || data.type=="land" || (data.type=="spell" && !Cards.data[data.ID].has("target"))

func drop_data(position,data):
	Main.play_card(data,data.owner)

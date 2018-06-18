extends Node

var temperature = 0


func _process(delta):
	var target_volume_db = clamp(-10*temperature-40,-80,0)
	var scale = 0.5-0.4*int(get_node("Cold1").get_volume_db()>target_volume_db)
	get_node("Cold1").set_volume_db(clamp(get_node("Cold1").get_volume_db()+delta*scale*(target_volume_db-get_node("Cold1").get_volume_db()),-80,0))
	target_volume_db = clamp(-5*temperature-60,-80,0)
	scale = 0.5-0.4*int(get_node("Cold2").get_volume_db()>target_volume_db)
	get_node("Cold2").set_volume_db(clamp(get_node("Cold2").get_volume_db()+delta*scale*(target_volume_db-get_node("Cold2").get_volume_db()),-80,0))
	
	target_volume_db = clamp(10*temperature-40,-80,0)
	scale = 0.5-0.4*int(get_node("Warm1").get_volume_db()>target_volume_db)
	get_node("Warm1").set_volume_db(clamp(get_node("Warm1").get_volume_db()+delta*scale*(target_volume_db-get_node("Warm1").get_volume_db()),-80,0))
	target_volume_db = clamp(5*temperature-60,-80,0)
	scale = 0.5-0.4*int(get_node("Warm2").get_volume_db()>target_volume_db)
	get_node("Warm2").set_volume_db(clamp(get_node("Warm2").get_volume_db()+delta*scale*(target_volume_db-get_node("Warm2").get_volume_db()),-80,0))
	

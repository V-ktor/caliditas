extends Sprite

var card
var pos
var _z = 0
var type = "hand"
var timer = Timer.new()


func zoom():
	get_node("TweenScale").remove_all()
	get_node("TweenScale").interpolate_property(self,"scale",get_scale(),Vector2(0.3*sign(get_scale().x),0.3),0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
	if (pos!=null):
		get_node("TweenScale").interpolate_property(self,"global_position",get_global_position(),Vector2(pos.x,0.6*pos.y),0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
	get_node("TweenScale").start()
	set_z_index(10)
	get_node("SoundTap").play()
	Main.emit_signal("card_enlarged",card)

func unzoom():
	timer.stop()
	if (get_scale().x>0.151 || get_scale().y>0.151):
		get_node("TweenScale").remove_all()
		get_node("SoundUntap").play()
		get_node("TweenScale").interpolate_property(self,"scale",get_scale(),Vector2(0.15*sign(get_scale().x),0.15),0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		if (pos!=null):
			get_node("TweenScale").interpolate_property(self,"global_position",get_global_position(),pos,0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		get_node("TweenScale").start()
	else:
		set_scale(Vector2(0.15*sign(get_scale().x),0.15))
	set_z_index(_z)

func _gui_input(event):
	if (type=="dead"):
		return
	
	if (event.is_action_pressed("LMB")):
		timer.start()
	elif (event.is_action_pressed("RMB")):
		zoom()
	elif (event.is_action_released("LMB") || event.is_action_released("RMB")):
		unzoom()

func selected():
	if (type=="dead" || type=="equiped" || type=="preview"):
		return
	Main.select(card,type)

func _ready():
	get_node("White").set_material(get_node("White").get_material().duplicate())
	get_node("Red").set_material(get_node("Red").get_material().duplicate())
	get_node("Blue").set_material(get_node("Blue").get_material().duplicate())
	get_node("Button").connect("pressed",self,"selected")
	get_node("Button").connect("gui_input",self,"_gui_input")
#	get_node("Button").connect("mouse_entered",self,"zoom")
	get_node("Button").connect("mouse_exited",self,"unzoom")
	timer.set_wait_time(0.5)
	timer.set_one_shot(true)
	add_child(timer)
	timer.connect("timeout",self,"zoom")

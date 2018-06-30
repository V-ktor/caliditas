extends Sprite

var card
var pos
var _z = 0
var type = "hand"


func zoom():
	if (type=="dead"):
		if (get_node("Animation").get_current_animation()!="fade_out"):
			get_node("Animation").play("fade_out")
		return
	
	get_node("TweenScale").interpolate_property(self,"scale",get_scale(),Vector2(0.3*sign(get_scale().x),0.3),0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
	if (pos!=null):
		get_node("TweenScale").interpolate_property(self,"global_position",get_global_position(),Vector2(pos.x,0.6*pos.y),0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
	get_node("TweenScale").start()
	set_z_index(10)
	get_node("SoundTap").play()

func unzoom():
	if (type=="dead"):
		if (get_node("Animation").get_current_animation()!="fade_out"):
			get_node("Animation").play("fade_out")
	get_node("TweenScale").interpolate_property(self,"scale",get_scale(),Vector2(0.15*sign(get_scale().x),0.15),0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
	if (pos!=null):
		get_node("TweenScale").interpolate_property(self,"global_position",get_global_position(),pos,0.25,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
	get_node("TweenScale").start()
	set_z_index(_z)
	get_node("SoundUntap").play()

func _gui_input(event):
	if (type=="dead"):
		return
	
	if (event.is_action_pressed("RMB")):
		zoom()
	elif (event.is_action_released("RMB")):
		unzoom()

func selected():
	if (type=="dead" || type=="equiped" || type=="preview"):
		return
	Main.select(card,type)

func _ready():
	get_node("White").set_material(get_node("White").get_material().duplicate())
	get_node("Button").connect("pressed",self,"selected")
	get_node("Button").connect("gui_input",self,"_gui_input")
#	get_node("Button").connect("mouse_entered",self,"zoom")
#	get_node("Button").connect("mouse_exited",self,"unzoom")

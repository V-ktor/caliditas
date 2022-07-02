extends Node

var origin = Vector2(0,0)
onready var arrow = $Arrow


func _process(_delta):
	arrow.set_global_position(arrow.get_global_mouse_position())
	arrow.set_rotation(arrow.get_global_position().angle_to_point(origin))
	arrow.set_region_rect(Rect2(Vector2(0,0),Vector2(2*arrow.get_global_position().distance_to(origin),128)))
	arrow.set_offset(Vector2(-arrow.get_region_rect().size.x/2,0))

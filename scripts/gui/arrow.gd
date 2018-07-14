extends Sprite

var origin = Vector2(0,0)


func _process(delta):
	set_global_position(get_global_mouse_position())
	set_rotation(get_global_position().angle_to_point(origin))
	set_region_rect(Rect2(Vector2(0,0),Vector2(2*get_global_position().distance_to(origin),128)))
	set_offset(Vector2(-get_region_rect().size.x/2,0))

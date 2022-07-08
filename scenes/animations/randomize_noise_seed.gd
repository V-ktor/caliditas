extends Sprite

func _ready():
	texture = texture.duplicate(true)
	texture.noise.seed = randi()

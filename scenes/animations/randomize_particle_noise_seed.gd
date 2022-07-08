extends Particles2D

func _ready():
	texture = texture.duplicate(true)
	texture.noise.seed = randi()

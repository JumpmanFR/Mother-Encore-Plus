extends Sprite

func _ready():
	var size = float($Shadow.texture.get_width()) / 5
	print(float(size / 10))
	$Shadow.scale.x = $Shadow.scale.x + float(size / 10)

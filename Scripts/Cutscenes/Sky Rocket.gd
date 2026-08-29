extends Node2D

var shake_magnitude := 3
const SHAKE_INTERVAL := 0.01

var time := 0.0

func _process(delta):
	if time >= SHAKE_INTERVAL:
		$Rocket.position = Vector2(rand_range( - shake_magnitude, shake_magnitude), rand_range( - shake_magnitude, shake_magnitude))
		time -= SHAKE_INTERVAL
	time += delta

func set_shake_magnitude(mag: int):
	shake_magnitude = mag

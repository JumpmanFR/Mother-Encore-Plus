extends Label

signal done()

func _ready():
	$AnimationPlayer.play("start")

# Sets tween to move number, as if bouncing off of a point
func run():
	# Move left or right
	var distance = rand_range(32, 64)
	if (randi()%2+0) == 1:
		distance *= -1
	
	var tween = create_tween().set_parallel().set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rect_position:x", rect_position.x + distance, 0.8)
	tween.tween_property(self, "rect_position:y", rect_position.y - 20, 0.4) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rect_position:y", rect_position.y + 180, 0.4) \
			.from(rect_position.y - 20).set_trans(Tween.TRANS_CIRC).set_delay(0.4)
	
	yield(tween, "finished")
	emit_signal("done")
	queue_free()

extends Control
class_name MusicNote

signal movement_finished

var _time := 0.0
var _movement := Vector2(14, 5)

const CENTER_X := 160
const SPEED := 3.0
var direction := 1

func do_movement(start_pos:Vector2, new_pos: Vector2, queue_free:= false):
	start_pos.x = CENTER_X + direction * start_pos.x
	new_pos.x = CENTER_X + direction * new_pos.x
	
	var tween = create_tween()
	tween.tween_property(self, "rect_position", new_pos, 0.6).from(start_pos).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	if queue_free:
		tween.connect("finished", self, "queue_free")

func _process(delta: float):
	_time += delta * SPEED
	$Sprite.position.y = -sin(_time*2) * _movement.y
	$Sprite.position.x = sin(_time) * _movement.x * direction

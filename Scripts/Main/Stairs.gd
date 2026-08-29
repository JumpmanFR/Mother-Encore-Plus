extends Area2D

export var _horizontal := true
export var _northeast_southwest := true
export var _step_length := 1
var _step_distance := 0
var _direction := 1
var _moving_actors := []

func _ready():
	if _northeast_southwest:
		_direction *= -1

func _physics_process(delta):
	if global.get_player().has_substantial_movement() and global.get_player().is_walking():
		var speed = global.get_player().get_velocity()
		for actor in _moving_actors:
			if is_instance_valid(actor):
				var _input_vector = actor.get_direction()
				if _horizontal:
					if global.get_player().is_running():
						actor.move_and_slide(Vector2(0, speed.x / _step_length * _direction))
					else:
						if actor == global.get_player():
							_step_distance += _input_vector.x
						if abs(_step_distance) >= _step_length:
							if actor == global.get_player():
								_step_distance -= _step_length * _input_vector.x
								actor.position.y += _input_vector.x * _direction
								global.partySpace[0].y += _input_vector.x * _direction
				else:
					if global.get_player().is_running():
						actor.move_and_slide(Vector2(speed.y / _step_length * _direction, 0))
					else:
						if actor == global.get_player():
							_step_distance += _input_vector.y
						if abs(_step_distance) >= _step_length:
							if actor == global.get_player():
								_step_distance -= _step_length * _input_vector.y
								actor.position.x += _input_vector.y * _direction
								global.partySpace[0].x += _input_vector.y * _direction
			else:
				_moving_actors.erase(actor)



func _on_Stairs_area_entered(area):
	var object = area.get_parent()
	if global.partyObjects.has(object):
		if _moving_actors.size() == 0:
			set_physics_process(true)
		_moving_actors.append(object)
		if object is PartyFollower:
			object.constraint_direction(_horizontal, !_horizontal)

func _on_Stairs_area_exited(area):
	var object = area.get_parent()
	if global.partyObjects.has(object):
		if object is PartyFollower:
			object.constraint_direction(false, false)
		_moving_actors.erase(object)
		if _moving_actors.size() == 0:
			set_physics_process(false)

extends Area2D

export var movement_direction := Vector2.ZERO
var _moving_actors := []

func _ready():
	set_physics_process(false)

func _physics_process(delta):
	var oldpos = global.get_player().position
	for actor in _moving_actors:
		actor.position += movement_direction
		actor.set_direction(movement_direction)
	if !global.get_player().has_substantial_movement() or global.get_player().is_paused():
		global.partySpace.push_front(global.get_player().position.round())
		global.partySpace.pop_back()

func _on_Threadmill_body_entered(body):
	if _moving_actors.size() == 0:
		set_physics_process(true)
	_moving_actors.append(body)
	if body == global.get_player():
		global.get_player().pause()
	else:
		body.set_physics_process(false)
	body.set_idle()

func _on_Threadmill_body_exited(body):
	_moving_actors.erase(body)
	if _moving_actors.size() == 0:
		set_physics_process(false)
	if body is PartyMemberPlayer:
		global.get_player().unpause()
		global.get_player().set_direction(movement_direction.round())
	else:
		body.set_physics_process(true)
		body.find_path()
	

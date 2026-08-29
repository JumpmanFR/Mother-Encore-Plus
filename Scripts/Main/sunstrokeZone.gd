extends Area2D

const SUNSTROKE_PROBABILITY: int = 30
const TIME_INTERVAL := 20.0
const SUNSTROKE_STATUS := "sunstroked"


var _active_bodies := {}

func _try_sunstroke(body):
	if !body.get_instance_id() in _active_bodies: return
	if body in global.partyObjects:
		var party_member: Character = body.get_party_member()
		var roll := randi() % 100 + 1
		var prob := SUNSTROKE_PROBABILITY - party_member.get_stat(Character.GUTS)
		if roll <= prob:
			party_member.add_status(SUNSTROKE_STATUS)
	_set_timer(body)

func _set_timer(body):
	var timer = get_tree().create_timer(TIME_INTERVAL)
	_active_bodies[body.get_instance_id()] = timer
	timer.connect("timeout", self, "_try_sunstroke", [body])

func _on_Area2D_body_entered(body):
	if body.get_instance_id() in _active_bodies: return
	_set_timer(body)

func _on_Area2D_body_exited(body):
	var body_id = body.get_instance_id()
	if body_id in _active_bodies:
		_active_bodies.erase(body_id)

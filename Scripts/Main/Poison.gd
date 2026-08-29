extends Area2D

export var stepping_sound : NodePath

onready var steppingSound = get_node_or_null(stepping_sound)

func _on_Area2D_body_entered(body):
	if not body is PartyObject:
		return
	if not global.get_player().is_paused():
		body.start_continuous_damage(4, 2, Vector2.ZERO, Status.AILMENT_POISONED)
		steppingSound._on_Stepping_Sounds_body_entered(body)

func _on_Poison_body_exited(body):
	if body is PartyObject:
		body.stop_continuous_damage()
		steppingSound._on_Stepping_Sounds_body_exited(body)

extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play("Explosion")


	global.currentCamera.shake_camera(8, 0.3, Vector2.ZERO)

func _on_Explosion_body_entered(body):
	if body is PartyObject:
		if !global.get_player().is_paused():
			body.damage(30, 5, self.global_position.direction_to(body.global_position) * 5)


func _on_AudioStreamPlayer2D_finished():
	queue_free()

extends Area2D

func _on_Dandelion_body_entered(body):
	if not body is PartyMemberPlayer or $Sprite.frame != 0:
		return
	$Sprite.frame = 1
	$CPUParticles2D.gravity = global.get_player().get_direction() * 5
	$CPUParticles2D.emitting = true

extends Area2D

func _ready():
	$Sprite.texture = load("res://Graphics/VFX/AnaOV%s.png" % global.get_player().get_current_skill_action())
	$RayCast2D.cast_to = global.get_player().get_ground_position() - global_position
	
	yield($Timer, "timeout")
	if $RayCast2D.get_collider() != null:
		if !$RayCast2D.get_collider() is KinematicBody2D:
			queue_free()
		else:
			$AnimationPlayer.play("Grow")
			$AudioStreamPlayer.play()
	else:
		$AnimationPlayer.play("Grow")
		$AudioStreamPlayer.play()
	
func _on_AnimationPlayer_animation_finished(_anim_name):
	queue_free()


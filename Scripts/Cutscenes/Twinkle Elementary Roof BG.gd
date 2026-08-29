extends AnimationPlayer
#
#func _process(delta):
#	if Input.is_action_just_pressed("ui_F1"):
#		clear_sky()

func play_anim():
	$AnimationPlayer.play("Clear Up")
	$AnimationPlayer.play()

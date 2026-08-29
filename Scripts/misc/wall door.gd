extends ControlledTwoStatesObject

func _init():
	_state_anim_player = "AnimationPlayer"

func _shake(duration: float):
	global.currentCamera.shake_camera(5, duration, Vector2.ZERO, 0.02, 1, false)

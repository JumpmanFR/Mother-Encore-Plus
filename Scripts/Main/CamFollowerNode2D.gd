extends Node2D

func _process(delta):
	global_position = global.currentCamera.get_camera_screen_center()

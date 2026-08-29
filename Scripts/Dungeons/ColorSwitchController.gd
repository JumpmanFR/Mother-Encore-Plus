extends Node
class_name ColorSwitchController

var _bodies_block_count := 0

func add_body():
	_bodies_block_count += 1
	global.currentScene.can_switch = false

func remove_body():
	_bodies_block_count -= 1
	if _bodies_block_count <= 0:
		global.currentScene.can_switch = true

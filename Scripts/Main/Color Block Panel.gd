extends Sprite

export (bool) var _initially_on

onready var ColorBlock = preload("res://Nodes/Overworld/Objects/Color Block.tscn")

func _ready():
	var color_block = ColorBlock.instance()
	
	if _initially_on:
		frame = 1
	else:
		frame = 0

	color_block.global_position = global_position
	color_block.set_initially_on(_initially_on)

	if global.currentScene.has_node("YSort"):
		global.currentScene.get_node("YSort").add_child(color_block)
	else:
		global.currentScene.get_node("Objects").add_child(color_block)

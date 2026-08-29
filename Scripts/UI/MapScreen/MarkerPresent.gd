tool 
extends FlaggableObject
class_name MarkerPresent

export (String, "item", "map") var type = "item" setget _set_type

func _ready():
	update()

func _set_type(sprite):
	type = sprite
	_update_sprite()

func update():
	if !Engine.is_editor_hint() and _get_flag_status():
		frame_coords.x = 1

func _update_sprite():
	if is_inside_tree():
		match type:
			"item":
				frame_coords.y = 0
			"map":
				frame_coords.y = 1

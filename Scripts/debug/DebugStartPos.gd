tool 
extends Position2D
class_name DebugStartPos

func _ready():
	if Engine.is_editor_hint():
		z_index = 1
	if OS.is_debug_build() and get_tree().current_scene is AreaRoom and !global.get_player().is_paused():
		global.get_player().global_position = global_position

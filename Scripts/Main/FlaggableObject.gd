class_name FlaggableObject
extends Sprite

export (String) var flag := ""
export (bool) var is_object_flag := false
export (bool) var emit_flag_updated_signal := false
export (bool) var reset_when_leaving_region := false
export (bool) var reset_when_leaving_area := false

func _ready():
	if !Engine.is_editor_hint():
		global.currentScene.connect("area_left", self, "_on_leave_area")

func _get_flag_status() -> bool:
	if Engine.is_editor_hint():
		return false
	if flag != null and flag != "":
		if is_object_flag:
			return globaldata.object_flags.get(flag, false)
		else:
			return globaldata.flags.get(flag, false)
	else:
		return globaldata.object_flags.get(global.currentScene.name + "/" + name, false)
	
func _set_flag_status(value = true):
	if Engine.is_editor_hint():
		return
	if flag != null and flag != "":
		if is_object_flag:
			globaldata.set_object_flag(flag, value, emit_flag_updated_signal)
		else:
			globaldata.set_flag(flag, value, emit_flag_updated_signal)
	else:
		globaldata.set_object_flag(global.currentScene.name + "/" + name, value, emit_flag_updated_signal)

func _on_leave_area(region_changed: bool):
	if reset_when_leaving_area or (region_changed and reset_when_leaving_region):
		_set_flag_status(false)

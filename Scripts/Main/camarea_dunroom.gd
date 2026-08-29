extends Camarea
class_name CamareaDunroom

var _flag: String

func _ready():
	_flag = global.currentScene.name + "/room_" + str(get_index())

func _on_enter():
	if !_get_flag_status():
		_set_flag_status(true)
	if global.currentScene is DungeonAreaRoom:
		global.currentScene.set_current_room(self)
	._on_enter()

func _get_flag_status() -> bool:
	return globaldata.object_flags.get(_flag, false)

func _set_flag_status(value = true):
	globaldata.set_object_flag(_flag, value)

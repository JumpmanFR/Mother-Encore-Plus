extends FlaggableObject
class_name DisappearingFlaggableObject

export var check_when_flags_updated := true

func _ready():
	if check_when_flags_updated: global.connect("flags_updated", self, "_check_flags")
	_check_flags()

func _check_flags():
	if _get_flag_status():
		queue_free()

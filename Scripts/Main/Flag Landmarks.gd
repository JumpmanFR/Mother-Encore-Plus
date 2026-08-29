extends Node2D
class_name FlagLandmark

export var appear_flag = ""
export var disappear_flag = ""
export var delete_if_hidden = true

func _ready():
	_check_flags()
	global.connect("flags_updated", self, "_check_flags")

func _check_flags():
	var shown = globaldata.check_appear_disappear_flags(appear_flag, disappear_flag)
	if delete_if_hidden and !shown:
		queue_free()
	else:
		visible = shown

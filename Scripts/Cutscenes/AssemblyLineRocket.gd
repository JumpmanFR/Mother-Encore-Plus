extends Sprite

var flag_frame = [
	"br_wings_attached", 
	"br_head_attached", 
	"br_finishing_touch"
]

export var disappear_flag = "bottle_rocket_found"

func _ready():
	check_flag_frame()
	global.connect("flags_updated", self, "check_flag_frame")

func check_flag_frame():
	if _get_flag_status(disappear_flag):
		queue_free()
		return
	for i in flag_frame.size():
		if !_get_flag_status(flag_frame[i]):
			break
		frame = i + 1

func _get_flag_status(flag) -> bool:
	return globaldata.flags.get(flag, false)

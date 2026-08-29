extends Sprite

const FLAG_SIZES: = [
	"lloyd_kitchen"
]

export var _intro_cloud: = false

func _ready():
	if !_intro_cloud:
		update_size()

func play_anim(anim):
	$AnimationPlayer.play(anim)

func update_size():
	var size = 0
	
	for i in FLAG_SIZES.size():
		if globaldata.flags[FLAG_SIZES[i]]:
			size = i + 1
	
	$AnimationPlayer.play("Size%s" % size)

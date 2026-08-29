extends Sprite

export (int) var index = 0
export (String) var dialogue = ""

const COUNT = 5

func _ready():
	global.connect("party_changed", self, "_update_visibility")
	_update_visibility()

func _update_visibility():
	var count_dead = 0
	for i in range(1, COUNT + 1):
		var flag = "flying_man_%s_joined" % i
		if globaldata.flags.get(flag, false):
			count_dead += 1
	if globaldata.flags.get("flying_man_in_party", false):
		count_dead -= 1
	visible = (count_dead >= index)
	$StaticBody2D/CollisionShape2D.disabled = !visible
	$interact/CollisionShape2D.disabled = !visible

func interact():
	uiManager.open_dialogue_box(dialogue)

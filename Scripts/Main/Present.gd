tool

extends ItemHolder

export (String, "item", "map", "briefcase") var type setget _set_type

func _ready():
	_update_sprite()
	if Engine.is_editor_hint():
		return
	if _get_flag_status():
		$Sprite.frame = 4
		_update_state()
	if dialog == "":
		dialog = "ItemDialogue/presentcheck"
	if dialog_full == "":
		dialog_full = "ItemDialogue/presentfull"
	if dialog_empty == "":
		dialog_empty = "ItemDialogue/presentempty"

func _set_type(sprite):
	type = sprite
	_update_sprite()

func _update_sprite():
	if not is_inside_tree():
		return
	match type:
		"item":
			get_node("Sprite").texture = load("res://Graphics/Objects/Common/Present Box.png")
		"map":
			get_node("Sprite").texture = load("res://Graphics/Objects/Common/Present Box Blue.png")
		"briefcase":
			get_node("Sprite").texture = load("res://Graphics/Objects/Common/Briefcase.png")


# Override
func _update_state():
	if _get_flag_status():
		$Sparkles.stop()
		$Sparkles.hide()
	else:
		$Sparkles.show()
		$Sparkles.play()

# Override
func _play_interact():
	$AnimationPlayer.play("Unwrapped")

# Override
func _play_collect_item():
	pass

# Override
func _play_revert():
	yield($AnimationPlayer,"animation_finished")
	$AnimationPlayer.play("Wrapped")

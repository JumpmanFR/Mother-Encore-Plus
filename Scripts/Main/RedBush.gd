tool

extends ItemHolder

export var animation_player_path: NodePath
onready var animation_player_node = get_node_or_null(animation_player_path)

func _ready():
	reset_when_leaving_region = true
	if _get_flag_status():
		animation_player_node.play("Collected")

# Override
func _update_state():
	var button_prompt_node = get_node(button_prompt)
	if button_prompt_node:
		button_prompt_node.get_parent().visible = !_get_flag_status()
		

# Override
func _play_interact():
	pass

# Override
func _play_collect_item():
	animation_player_node.play("Collect")

# Override
func _play_revert():
	pass

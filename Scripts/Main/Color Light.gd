tool 
extends ControlledTwoStatesObject

export (String, "Front", "Left", "Right") var direction: = "Front" setget _set_direction

func _init():
	_state_anim_player = "AnimationPlayer"


func _ready():
	_update_sprite()


func _set_direction(sprite):
	direction = sprite
	_update_sprite()

func _update_sprite():
	if is_inside_tree():
		$main.texture = load("res://Graphics/Objects/DuncansFactory/Color Light %s.png" % direction)

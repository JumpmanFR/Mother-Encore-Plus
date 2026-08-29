extends TwoStatesSwitch



func _ready():
	_on_state_changed(is_on())
	if !_is_one_way:
		$MagicantPearlClam.queue_free()
	
	

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "TurnOff":
		_anim_player.play("Float")
	if anim_name == "TurnOn" && _is_one_way:
		$MagicantPearlClam/AnimationPlayer.play("Close")

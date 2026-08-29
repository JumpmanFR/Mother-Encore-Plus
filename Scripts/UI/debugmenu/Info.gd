extends NinePatchRect


func _process(delta):
	var player = global.get_player()
	$VBoxContainer / fpsdisplay.text = "FPS: " + var2str(Engine.get_frames_per_second())
	$VBoxContainer / map.text = "Map: " + get_tree().get_current_scene().get_name()
	$VBoxContainer / pos.text = "XY: " + var2str(int(global.get_player().position.x)) + " " + var2str(int(global.get_player().position.y))
	if player.is_walking():
		$VBoxContainer / state.text = "State: Walk"
	else:
		$VBoxContainer / state.text = "State: Idle"
	$VBoxContainer / velocity.text = "Vel: " + str(global.get_player().get_velocity())
	$VBoxContainer / vsync.text = "Vsync: " + str(OS.vsync_enabled)

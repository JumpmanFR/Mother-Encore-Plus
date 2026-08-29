extends Control


func _input(event: InputEvent):
	if event.is_action_pressed("ui_backtick"):
		
		yield(get_tree(), "idle_frame")
		uiManager.remove_ui(self)

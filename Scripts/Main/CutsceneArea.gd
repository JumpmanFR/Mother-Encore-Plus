extends Area2D

export (String) var dialog
export var appear_flag = ""
export var disappear_flag = ""

func _ready():
	set_process(false)
	uiManager.connect("battle_to_ov", self, "_stop_process")

func _stop_process():
	set_process(false)

func _process(_delta):
	if uiManager.is_in_cutscene() or uiManager.is_in_battle() or uiManager.is_pause_menu_active():
		return
	if _check_flags():
		_start_cutscene()
		set_process(false)
	else:
		set_process(false)

func _on_Cutscene_Area_body_entered(body):
	if body == global.get_player():
		check_start()

func _on_Cutscene_Area_body_exited(body):
	if body == global.get_player() and !uiManager.is_in_battle():
		set_process(false)

func check_start():
	if dialog != "":
		if _check_flags():
			set_process(true)
		else:
			#start checking when player becomes unpaused again
			set_process(true)

func _start_cutscene():
	uiManager.close_commands_menu(true, false)
	global.get_player().pause()
	uiManager.open_dialogue_box_and_unpause(dialog)

func _check_flags():
	return globaldata.check_appear_disappear_flags(appear_flag, disappear_flag)

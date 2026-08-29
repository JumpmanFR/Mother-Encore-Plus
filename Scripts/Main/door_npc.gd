extends Area2D

export (String) var dialog: String
export (Array, PoolStringArray) var _all_dialog: Array
export var appear_flag := ""
export var disappear_flag := ""
var player_turn := { 
	"y": true, #Make "x" true if you want the player to turn left/right to face npc
	"x": false #Make "y" true if you want the player to turn up/down to face npc
}

func _ready():
	if dialog and (_all_dialog.empty() or _all_dialog[0][0] != ""):
		_all_dialog.push_front(["", dialog])
	set_process(false)

func _process(_delta):
	if uiManager.is_in_cutscene() or uiManager.is_in_battle() or uiManager.is_pause_menu_active():
		return
	if _check_flags():
		_start_cutscene()
		set_process(false)
	else:
		set_process(false)

# Similar in npc.gd
func _get_right_dialog(mark_as_seen := false) -> String:
	var ret := ""
	var last_dialog_hash := ""
	for i in _all_dialog.size():
		var flag: String = _all_dialog[i][0]
		if flag == "" or globaldata.flags.get(flag, false):
			for j in range(1, _all_dialog[i].size()):
				var cur_dialog: String = _all_dialog[i][j]
				var dialog_hash := "%s:%s:%s:%s" % [get_path(), flag, j, cur_dialog]
				if !globaldata.seen_dialogue_flags.get(dialog_hash, false) or j == _all_dialog[i].size() - 1:
					ret = cur_dialog
					last_dialog_hash = dialog_hash
					break
	if mark_as_seen and last_dialog_hash:
		globaldata.seen_dialogue_flags[last_dialog_hash] = true
	return ret

func _check_flags():
	return globaldata.check_appear_disappear_flags(appear_flag, disappear_flag)

func _start_cutscene():
	global.get_player().turn_to(self, true)
	global.get_player().pause()
	uiManager.set_cutscene(true)
	uiManager.toggle_black_bars(true)
	$AudioStreamPlayer.play()
	yield(get_tree().create_timer(1),"timeout")
	uiManager.open_dialogue_box_and_unpause(_get_right_dialog(true))
	uiManager.set_cutscene(false)

func _on_Door_NPC_body_entered(body):
	if body != global.get_player():
		return
	if _get_right_dialog() != "":
		if _check_flags():
			#if !uiManager.is_in_cutscene() and !uiManager.is_in_battle():
			set_process(true)
		else:
			#start checking when player becomes unpaused again
			set_process(true)

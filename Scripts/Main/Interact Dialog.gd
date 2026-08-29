tool

class_name InteractDialog
extends Node2D

export (String) var dialog: String
export (String) var _thoughts: String
export var no_problem_thoughts := true
export var appear_flag := ""
export var disappear_flag := ""
export (Array, PoolStringArray) var _all_dialog: Array
export (String) var _key_item := ""
export var player_turn := { 
	"y": true, #Make "x" true if you want the player to turn left/right to face npc
	"x": true #Make "y" true if you want the player to turn up/down to face npc
}
export (Vector2) var button_offset := Vector2.ZERO setget _set_button_offset


func _ready():
	if Engine.editor_hint: return
	_check_flags()
	global.connect("flags_updated", self, "_check_flags")

func _check_flags():
	visible = globaldata.check_appear_disappear_flags(appear_flag, disappear_flag)
	if !visible:
		queue_free()

func _set_button_offset(offset):
	button_offset = offset
	$ButtonPrompt.offset = button_offset

# Overridden
func interact():
	uiManager.open_dialogue_box(_get_right_dialog())

func interact_item(item: Item):
	if item.item_name == _key_item:
		uiManager.open_dialogue_box(_get_right_dialog())

func telepathy():
	uiManager.set_telepathy_effect(true)
	uiManager.open_dialogue_box(_thoughts)

func has_thoughts() -> bool:
	return _thoughts != ""

func _get_right_dialog() -> String:
	var ret := dialog
	for flags in _all_dialog:
		var flag = flags[0]
		if flag != "" and globaldata.flags.get(flag, false):
			ret = flags[1]
	return ret

extends Control

signal back (to_inventory)
signal show_statsbar (character)
signal hide_statsbar
signal next (character)

onready var ItemLabelTemplate := preload("res://Nodes/Ui/HighlightLabel.tscn")

var _char_list := []
onready var _arrow := $arrow2

var active := false

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	_arrow.connect("selected", self, "_on_select")
	_arrow.connect("cancel", self, "_on_cancel")
	_arrow.connect("moved", self, "_on_move")
	
#process data to update the available character list	
func _refresh_list_view():
	var nickname_list := []
	for name in _char_list:
		if name == "all":
			nickname_list.append("INVENTORY_ACTION_TARGET_ALL")
		else:
			for character in global.party:
				if character.get_name() == name:
					nickname_list.append(character.get_nickname())
			
	var labels := $PanelContainer/VBoxContainer/MarginContainer/VBoxContainer.get_children()
	for label in labels:
		label.queue_free()
	
	for chara_name in nickname_list:
		var label := ItemLabelTemplate.instance()
		label.text = chara_name
		$PanelContainer/VBoxContainer/MarginContainer/VBoxContainer.add_child(label)
	
	_arrow.on = true
	_arrow.set_cursor_from_index(0, false)


#used to make the box appear with the right parameters
func show_target_chara_select(pos, char_list):
	_char_list = char_list
	visible = true
	active = true
	_refresh_list_view()

	emit_signal("show_statsbar", _char_list[_arrow.cursor_index])


func _on_move(dir):
	if active:
		emit_signal("show_statsbar", _char_list[_arrow.cursor_index])

func _on_cancel():
	Input.action_release("ui_cancel")
	_arrow.on = false
	visible = false
	active = false
	emit_signal("back")
	return
		
func _on_select(idx: int):
	Input.action_release("ui_accept")
	_arrow.on = false
	visible = false
	active = false
	emit_signal("next", _char_list[idx])


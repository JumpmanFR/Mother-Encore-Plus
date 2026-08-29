class_name ItemHolder
extends FlaggableObject

export (String) var item := "" setget _set_item
export (String) var dialog := ""
export (String) var dialog_full := ""
export (String) var dialog_empty := ""
export (NodePath)onready var button_prompt
export (bool) var can_pickup := true

var player_turn := { 
	"y": true,
	"x": true
}

func _ready():
	reset_when_leaving_region = false
	if !can_pickup:
		var button_prompt_node = get_node(button_prompt)
		button_prompt_node.enabled = false
	if !Engine.is_editor_hint():
		_update_state()
		if dialog == "":
			dialog = "ItemDialogue/itemcheck"
		if dialog_full == "":
			dialog_full = "ItemDialogue/itemfull"

func interact():
	if can_pickup:
		if !_get_flag_status():
			_check_item()
		else:
			_warn_empty()


func _check_item():
	_play_interact()
	if item and (Inventory.has_inventory_space() or globaldata.get_item_data(item).get("keyitem", false)):
		global.item = Inventory.add_item_available(item)
		_play_collect_item()
		_set_flag_status()
		_update_state()
		uiManager.open_dialogue_box(dialog)
	elif !item:
		_play_revert()
		_warn_empty()
	else:
		_play_revert()
		global.item = Item.new(item)
		uiManager.open_dialogue_box(dialog_full)

func _warn_empty():
	if (dialog_empty != ""):
		uiManager.open_dialogue_box("ItemDialogue/presentempty")


func _set_item(t_item):
	item = t_item

func _update_state():
	pass

# Overridden
func _play_interact():
	pass

# Overridden
func _play_collect_item():
	pass

# Overridden
func _play_revert():
	pass

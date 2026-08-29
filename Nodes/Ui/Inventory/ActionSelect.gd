extends Control

signal back
signal exit_with_dialog (dialog_id)
signal exit_with_item (item)
signal action_selected
signal swap_mode_selected (target_character)
signal sort_mode_selected
signal show_statsbar (character, unequip)
signal hide_statsbar
signal show_dialogbox (dialog, chara_name, value, stat, item)
signal update_dialogbox (dialog, chara_name, value, stat, item)

const ACTION_EQUIP := "equip"
const ACTION_USE := "use"
const ACTION_CONSUME := "consume"
const ACTION_TRANSFORM := "transform"
const ACTION_GIVE := "give"
const ACTION_SORT := "sort"
const ACTION_DROP := "drop"

const ACTION_SUB_DROP := "drop"
const ACTION_SUB_EQUIP := "equip"
const ACTION_SUB_EQUIPGIVE := "equipgive"
const ACTION_SUB_SWAP := "swap"
const ACTION_SUB_SORTAUTO := "SortAuto"
const ACTION_SUB_SORTMANUAL := "SortManual"
const ACTION_SUB_BACK := "back"

export (NodePath) onready var _drop_label = get_node(_drop_label) as Label
export (NodePath) onready var _give_label = get_node(_give_label) as Label
export (NodePath) onready var _sort_label = get_node(_sort_label) as Label
export (NodePath) onready var _action_one_label = get_node(_action_one_label) as Label
export (NodePath) onready var _action_two_label = get_node(_action_two_label) as Label

onready var _arrow := $arrow

var _item_side_on_screen := 1.0
var _active := false
var _current_char = globaldata.characters.ninten
var _current_item: Item

var _actions: Dictionary
var _actions_details: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	pass
	
func set_for_new_item(pos: Vector2, item: Item, item_side: float, curr_char, item_idx: int):
	_current_item = item
	_current_char = curr_char
	_item_side_on_screen = item_side
	rect_position = pos
#	rect_position.x = _item_side_on_screen*pos.x

	var is_key_item = item.get_data().get("keyitem", false)

	_actions = {}

	if !is_key_item and item.get_data().value != 0:
		_actions[_drop_label.name] = ACTION_DROP
		_drop_label.visible = true
	else:
		_drop_label.visible = false
	
	_actions[_sort_label.name] = ACTION_SORT
	
	if !is_key_item and global.party.size() > 1:
		_actions[_give_label.name] = ACTION_GIVE
		_give_label.visible = true
	else:
		_give_label.visible = false
	
	_set_actions()
	
	_arrow.cursor_index = 0
	_arrow.set_cursor_from_index(0, false)
	visible = true
	_active = true
	_arrow.on = true

func _set_actions():
	var item_data := _current_item.get_data()

	var is_key_item := item_data.get("keyitem", false) as bool
	var is_equippable: bool = !is_key_item and _current_char.can_equip_item(_current_item)

	var action_labels := [_action_one_label, _action_two_label]
	var actions := item_data.get("actions", []) as Array
	var label_idx := 0

	for action in actions:
		if label_idx < action_labels.size():
			var label: Label = action_labels[label_idx]
			var add_action := false
			if action["function"] == ACTION_EQUIP:
				if is_equippable:
					label.text = "INVENTORY_ACTION_%s" % ("UNEQUIP" if _current_item.equipped else "EQUIP")
					add_action = true
			elif action["function"] in [ACTION_USE, ACTION_CONSUME, ACTION_TRANSFORM]:
				label.text = action["name"]
				add_action = true
			if add_action:
				label.visible = true
				_actions[label.name] = action["function"]
				_actions_details[label.name] = action
				label_idx += 1

	for i in range(label_idx, action_labels.size()):
		action_labels[i].visible = false

	yield(get_tree(), "idle_frame")
	_arrow.set_cursor_to_front()

func _physics_process(_delta: float):
	if _active:
		if (_actions[_arrow.get_current_item().name] == ACTION_EQUIP):
			if _current_item.equipped == false:
				emit_signal("show_statsbar", _current_char)
			else:
				emit_signal("show_statsbar", _current_char, true)
		else:
			emit_signal("hide_statsbar")
		
func chain_with_equip():
	$TargetCharaSelect.chain_with_equip()

func _on_TargetCharaSelect_back(to_inventory: bool):
	if to_inventory: _close()
	else: _back_from_submenu()

func _back_from_submenu():
	_active = true
	_arrow.on = true
	bounce()

func _close():
	visible = false
	_active = false
	_arrow.on = false
	emit_signal("back")

func _on_ConfirmationSelect_back(accept: bool, current_action: String, current_character, target_character, cur_item: Item):
	if accept:
		match current_action:
			ACTION_SUB_DROP:
				current_character.inv.drop_item(cur_item)
			ACTION_SUB_EQUIP:
				audioManager.play_sfx_by_name("equip", "menu")
				target_character.equip_item(cur_item)
				emit_signal("hide_statsbar")
			ACTION_SUB_EQUIPGIVE: # give item and equip
				audioManager.play_sfx_by_name("equip", "menu")
				current_character.give_item(target_character, cur_item)
				target_character.equip_item(target_character.inv.get_items()[-1])
				emit_signal("hide_statsbar")
			ACTION_SUB_SWAP:
				emit_signal("swap_mode_selected", target_character)
			ACTION_SUB_SORTMANUAL:
				emit_signal("sort_mode_selected")
				
		$TargetCharaSelect.close()
		_close()
	else:
		match current_action:
			ACTION_SUB_EQUIP: #answered no to equip after swap
				$TargetCharaSelect.close()
				emit_signal("hide_statsbar")
				_close()
			ACTION_SUB_EQUIPGIVE: #give item but don't equip
				current_character.give_item(target_character, cur_item)
				$TargetCharaSelect.close()
				emit_signal("hide_statsbar")
				_close()
			ACTION_SUB_SORTAUTO:
				current_character.inv.sort_auto()
				_close()
			ACTION_SUB_SWAP:
				$TargetCharaSelect.close()
				_close()
			ACTION_SUB_DROP:
				_back_from_submenu()
			ACTION_SUB_BACK:
				_back_from_submenu()

func bounce():
	if !is_node_ready(): yield(self, "ready")
	create_tween().tween_property(self, "rect_position", rect_position, 0.1) \
			.from(rect_position - Vector2(0, 2)).set_ease(Tween.EASE_IN)

func _on_ActionSelect_visibility_changed():
	bounce()

func _on_ConfirmationSelect_visibility_changed():
	bounce()

func _on_SortTypeSelect_visibility_changed():
	bounce()


func _on_arrow_selected(cursor_index: int):
	Input.action_release("ui_accept")
	bounce()
	_active = false
	_arrow.on = false
	var action_details := _actions_details.get(_arrow.get_current_item().name, {}) as Dictionary
	var item_data := _current_item.get_data()
	match(_actions[_arrow.get_current_item().name]):
		ACTION_EQUIP:
			#equips an item
			if _current_item.equipped == false:
				_current_char.equip_item(_current_item)
				audioManager.play_sfx_by_name("equip", "menu")
			else:
				_current_char.unequip(_current_item)
				audioManager.play_sfx_by_name("clear", "menu")
			_close()
			emit_signal("hide_statsbar")
		
		ACTION_CONSUME:
			if action_details.get("target_type") == 5:
				#consume an item on oneself
				$TargetCharaSelect.consume_item(_current_char, _current_item, action_details, _current_char)
				_close()
			else:
				# (give => to whom, use => on whom, eat => who)
				var title := "INVENTORY_ACTION_TARGET"
				var action_name = action_details["name"]
				if action_name == "INVENTORY_ACTION_USE":
					title = action_name + "_TARGET"
				#consume an item to recover hp and pp and boost some stats
				var targets_list := []
				for party_mem in global.get_party_in_natural_order():
					if _can_item_target(_current_item, action_details, party_mem):
						targets_list.append(party_mem)
				$TargetCharaSelect.show_target_chara_select(_current_char, _current_item, ACTION_CONSUME, action_details, targets_list, title)

		ACTION_USE:
			if item_data.get("dialog"):
				emit_signal("exit_with_dialog", item_data.dialog)
			elif item_data.get("map_for"):
				var overriden_map = AreaRoom.get_area_override(item_data.map_for)
				uiManager.open_map_screen(overriden_map, item_data.map_for, false, funcref(self, "_close"))
			else:
				emit_signal("exit_with_item", _current_item)
			
		ACTION_TRANSFORM:
			#transforms an item into another
			_current_char.inv.transform_item(_current_item)
			_close()
			emit_signal("show_dialogbox", "ACTION_RESULT_TRANSFORM_%s" % _current_item.item_name.to_upper())
		
		ACTION_GIVE:
			#summon targetCharaSelect
			# (give => to whom, use => on whom, eat => who)
			var targets_list := []
			for party_mem in global.get_party_in_natural_order():
				if party_mem != _current_char:
					targets_list.append(party_mem)

			$TargetCharaSelect.show_target_chara_select(_current_char, _current_item, "give", {}, targets_list, "INVENTORY_ACTION_GIVE_TARGET")
		
		ACTION_SORT:
			#sort
			$SortTypeSelect.show_confirmation_select(rect_position, "", _current_char, null, null)
		
		ACTION_DROP:
			#drop
			$ConfirmationSelect.show_confirmation_select(rect_position, "drop", "back", _current_char, null, _current_item)

	emit_signal("action_selected")

func _on_arrow_cancel():
	emit_signal("hide_statsbar")
	_close()

func _can_item_target(item: Item, item_action: Dictionary, character: PartyMember) -> bool:
	var status_heals = item.get_data().get("status_heals", [])
	if status_heals.has("all"): status_heals = ["asthma", "blinded", "burned", "cold", "confused", "forgetful", "mushroomized", "nausea", "numb", "poisoned", "sleeping", "stone", "sunstroked", "unconscious"]
	return ( not character.is_unconscious() or item_action.get("target_unconscious", false)) or status_heals.has("unconscious")

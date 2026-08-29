extends NinePatchRect

signal back (to_inventory)
signal chain_with_equip
signal show_statsbar (character, unequip)
signal hide_statsbar
signal show_dialogbox (dialog, character, value, stat, item)
signal update_dialogbox (dialog, character, value, stat, item)

onready var ItemLabelTemplate = preload("res://Nodes/Ui/HighlightLabel.tscn")

onready var _confirmation_select = $ConfirmationSelect

onready var _arrow = $arrow
onready var _options_container = $MarginContainer / VBoxContainer

var _current_character: PartyMember = globaldata.characters.ninten
var _current_item: Item = null
var _char_list := [] # list of Characters
var _target_all := false

var _active := false
var _action_name := ""
var _action_details := {}
var _messages_stack := {}

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false

#clear the list before filling it again
func _empty_list() -> void :
	var labels = _options_container.get_children()
	for i in labels.size():
		_options_container.remove_child(labels[i])
		labels[i].queue_free()

#process data to update the available character list	
func _update_character_list() -> void :
	var nickname_list := []
	#creating the character list by comparing the party with the full ordered list
	
	_empty_list()
	
	var init_pos := 0

	_arrow.on = true
	
	#display the list as several labels
	for i in _char_list.size() if !_target_all else 1:
		var label := ItemLabelTemplate.instance() as Label
		if _target_all:
			label.text = "INVENTORY_ACTION_TARGET_ALL"
		else:
			var party_mem = _char_list[i]
			label.text = party_mem.get_nickname()
			if party_mem == _current_character:
				init_pos = i
		_options_container.call_deferred("add_child", label)
		yield(label, "ready")
		
	_arrow.set_cursor_from_index(init_pos, false)
	
	yield(_options_container, "draw")
	
	_bg_resize()


func _do_action(source, target, action: = _action_name) -> void :
	if action != "give":
		visible = false
		_active = false
		consume_item(source, _current_item, _action_details, target)
		emit_signal("back", true)
		return
	if target.inv.is_full():
		
		_active = false
		_confirmation_select.show_confirmation_select(rect_position, "swap", "back", source, target, _current_item)
		yield(self, "chain_with_equip")
		var target_inventory_items = target.inv.get_items()
		var last_target_item = target_inventory_items[ - 1]
		if target.can_equip_item(last_target_item):
			visible = true
			
			_active = false
			_confirmation_select.show_confirmation_select(rect_position, "equip", "swap", source, target, last_target_item)
			yield(_confirmation_select, "back")
		else:
			emit_signal("back", true)
			emit_signal("hide_statsbar")
	else:
		
		if target.can_equip_item(_current_item) and source != target:
			
			_active = false
			_confirmation_select.show_confirmation_select(rect_position, "equipgive", "cancel", source, target, _current_item)
			yield(_confirmation_select, "back")
		else:
			source.give_item(target, _current_item)
			visible = false
			_active = false
			emit_signal("hide_statsbar")
			emit_signal("back", true)


func show_target_chara_select(cur_char: Character, item: Item, action_type: String, action_details: Dictionary, char_list: Array, title := "INVENTORY_ACTION_TARGET") -> void :
	_current_item = item
	_current_character = cur_char
	visible = true
	_active = true
	_char_list = char_list
	_action_name = action_type
	_action_details = action_details
	var item_data: Dictionary = item.get_data()
	_target_all = item_data.get("target_all", false) and _action_name != "give"
	yield(_update_character_list(), "completed")
	$ToWhomLabel.text = title
	_update_stats()


#cb function to chain with equip
func _on_chain_with_equip():
	pass


#called by parent to chain swap or give with equip
func chain_with_equip() -> void :
	connect("chain_with_equip", self, "_on_chain_with_equip")
	emit_signal("chain_with_equip")

func _on_arrow_moved(_dir):
	if _active:
		_update_stats()

func _on_arrow_selected(cursor_index: int):
	if not _active:
		return
	uiManager.info_plates_highlight([])
	_arrow.on = false
	_bounce()
	if _target_all:
		for char_name in _char_list:
			_do_action(_current_character, char_name)
	else:
		_do_action(_current_character, _char_list[_arrow.cursor_index])
	_process_messages()
	_arrow.cursor_index = 0

func _on_arrow_cancel():
	if _active:
		_arrow.cursor_index = 0
		uiManager.info_plates_highlight([])
		visible = false
		_active = false
		_arrow.on = false
		emit_signal("hide_statsbar")
		emit_signal("back", false)

func _update_stats() -> void :
	if _arrow.cursor_index >= _char_list.size():
		return
	var target: Character = _char_list[_arrow.cursor_index]
	var item_name: = _current_item.item_name
	if _current_character.can_equip_item(_current_item):
		emit_signal("show_statsbar", target)
		return
	if _target_all:
		var targets = []
		for _char in _char_list:
			targets.append(_char.get_name())
		uiManager.info_plates_highlight(targets)
	else:
		uiManager.info_plates_highlight([target.get_name()])

func consume_item(source, item: Item, action_details: Dictionary, target: PartyMember) -> void :
	var item_data: Dictionary = item.get_data()
	var actions_performed := {}
	var fail_reason: String = action_details.get("textfail", "ACTION_RESULT_FAIL_ANY")
	
	if item_data.get("can_consume", globaldata.characters).has(target.get_name()):
		if target.is_in_state_to_receive_item(item):
			actions_performed = source.inv.consume_item(item, target)
		else:
			fail_reason = target.get_item_inability_message(item)
	
	var success := false

	if actions_performed.size() == 0:
		emit_signal("show_dialogbox", fail_reason, target, 0, "", item_data)
	else:
		for key in actions_performed:
			var message = "ACTION_RESULT_%s" % Item.ItemActions.keys()[key]
			var cur_action = actions_performed[key]
			match key:
				Item.ItemActions.HP_UP, Item.ItemActions.PP_UP,\
				Item.ItemActions.HP_MAX, Item.ItemActions.PP_MAX:
					success = true
					if (_messages_stack.has(target)):
						_messages_stack[target].append(TextTools.format_text_with_context(message, target, {}, cur_action))
					else:
						_messages_stack[target] = [TextTools.format_text_with_context(message, target, {}, cur_action)]
				Item.ItemActions.STAT_UP:
					success = true
					var stats = cur_action
					for stat in stats:
						emit_signal("show_dialogbox", message, target, stats[stat], stat)
				Item.ItemActions.HEAL:
					success = true
					if cur_action.size() > 1:
						emit_signal("show_dialogbox", "ACTION_RESULT_HEAL_ALL", target)
					else:
						emit_signal("show_dialogbox", Status.get_status_message(cur_action[0], "heal_overworld"), target)
				Item.ItemActions.HEAL_FAIL:
					if cur_action.size() > 1:
						emit_signal("show_dialogbox", "ACTION_RESULT_HEAL_NONE", target)
					else:
						emit_signal("show_dialogbox", Status.get_status_message(cur_action[0], "heal_overworld_fail"), target)
	
	if success:	
		audioManager.play_sfx(load("res://Audio/Sound effects/EB/eat.wav"), "menu")


func _on_ConfirmationSelect_back(accept: bool, current_action: String, _current_character: PartyMember, _target_character: PartyMember, _current_item: Item):
	if !accept:
		if current_action == "cancel":
			_active = true
			_arrow.on = true
			_bounce()
		else:
			_active = false
			hide()

func _bounce() -> void :
	create_tween().tween_property(self, "rect_position", rect_position, 0.1) \
			.from(rect_position - Vector2(0, 2)).set_ease(Tween.EASE_IN)


func _on_VBoxContainer_resized():
	yield(get_tree(), "idle_frame")
	_bg_resize()

func _bg_resize() -> void :
	$MarginContainer.set_size(Vector2.ZERO)
	rect_size.x = $MarginContainer.rect_size.x
	rect_size.y = $MarginContainer.rect_size.y
	_confirmation_select.rect_position.x = $MarginContainer.rect_size.x
	
func _process_messages():
	if _messages_stack.empty():
		return
	var _dialog_box := false
	for target in _messages_stack.keys():
		for message in _messages_stack[target]:
			if !_dialog_box:
				emit_signal("show_dialogbox", message, target)
				_dialog_box = true
				yield(get_tree().create_timer(0.5), "timeout")
				continue
			emit_signal("update_dialogbox", message, target)
			yield(get_tree().create_timer(0.5), "timeout")
	_messages_stack = {}

func close() -> void :
	_active = false
	hide()

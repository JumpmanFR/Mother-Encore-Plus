extends CanvasLayer

signal back

#small icon showing wether the item give bonus or malus when equipping
onready var _boost_icon_empty = preload("res://Graphics/UI/EquipMenu/empty.png")
onready var _boost_icon_bonus = preload("res://Graphics/UI/EquipMenu/red_arrow.png")
onready var _boost_icon_malus = preload("res://Graphics/UI/EquipMenu/blue_arrow.png")

#external paths and references
onready var _item_label_template = preload("res://Nodes/Ui/HighlightLabel.tscn")

onready var _char_tabs = $EquipMenu/Box/InventorySelect
onready var _cursor_slots: Cursor = $EquipMenu/Box/Panels/Slots/SlotArrow
onready var _cursor_list: Cursor = $EquipMenu/Box/Panels/Slots/ItemListPanel/ItemArrow
onready var _item_panel = $EquipMenu/Box/Panels/Slots/ItemListPanel
onready var _items_container = $EquipMenu/Box/Panels/Slots/ItemListPanel/ItemList
onready var _desc_panel = $EquipMenu/Description/DescriptionPanel
onready var _level_label = $EquipMenu/Box/Panels/Stats/Columns/Values/LevelValue

export (Dictionary) onready var _np_values
export (Dictionary) onready var _np_boost_values
export (Dictionary) onready var _np_boost_icons

var _current_character: PartyMember
var _item_list := []

#true when a slot is selected and items are shown to be equipped
var _item_selection := false

#used by the general menu to show the equip menu
func open(party_member: PartyMember):
	audioManager.play_sfx_by_name("menu_open", "menu_open")
	$AnimationPlayer.play("Open")
	$AnimationPlayerDesc.assigned_animation = "Close"
	_current_character = party_member
	_char_tabs.init_from_character(_current_character.get_name())
	_char_tabs.visible = true
	_cursor_slots.set_cursor_from_index(0, false)
	_update_panel()

func _update_item_info():
	_update_description()
	_update_portraits()
	_update_stats()

func _update_description():
	var selected_item := _get_selected_item()
	var anim_to_play := "Close"
	if selected_item:
		_desc_panel.set_item(selected_item)
		anim_to_play = "Open"
	
	if $AnimationPlayerDesc.assigned_animation != anim_to_play:
		$AnimationPlayerDesc.play(anim_to_play)

func _get_current_slot() -> String:
	return Inventory.SLOTS[_cursor_slots.cursor_index]

func _get_selected_item() -> Item:
	if _item_selection:
		return _item_list[_cursor_list.cursor_index] if _item_list else null
	else:
		return _current_character.get_equipped_item(_get_current_slot())

func _get_boost_icon(current_value: int, projected_value: int) -> Texture:
	if projected_value == current_value:
		return _boost_icon_empty
	elif projected_value > current_value:
		return _boost_icon_bonus
	else:
		return _boost_icon_malus



func _update_stats():
	_level_label.text = str(_current_character.get_level())
	for stat in Character.BOOSTABLE_STATS:
		get_node(_np_values[stat]).text = str(_current_character.get_stat(stat))
	
	$EquipMenu/Box/CharacterName.text = _current_character.get_nickname()
	
	var equipped_item_boost: Dictionary = _current_character.inv.calculate_stats_boost_from_slot(_get_current_slot())
	var selected_item_boost: Dictionary = _get_selected_item().get_data().get("boost", {}) if _get_selected_item() else {}
	
	for stat in Character.BOOSTABLE_STATS:
		var current_value: int = _current_character.get_stat(stat)
		var projected_value: int = current_value - equipped_item_boost.get(stat, 0) + selected_item_boost.get(stat, 0)
		
		get_node(_np_boost_values[stat]).text = "" if projected_value == current_value else str(projected_value)
		get_node(_np_boost_icons[stat]).texture_normal = _get_boost_icon(current_value, projected_value)

func _on_slot_cursor_selected(cursor_index: int):
	if !_current_character.get_items_for_slot( _get_current_slot(), true, false).empty():
		_item_selection = true
		_update_panel()
		_cursor_slots.play_sfx("cursor2")
	else:
		_cursor_slots.play_sfx("restricted")

func _on_slot_cursor_cancel():
	Input.action_release("ui_cancel")
	_char_tabs.visible = false
	_char_tabs.active = false
	_cursor_slots.on = false
	_cursor_list.on = false
	audioManager.play_sfx_by_name("menu_close", "menu_close")
	$AnimationPlayer.play("Close")
	if $AnimationPlayerDesc.assigned_animation != "Close":
		$AnimationPlayerDesc.play("Close")
	emit_signal("back")

func _on_list_cursor_selected(cursor_index: int):
	if _cursor_list.get_current_item().text == "EQUIP_NONE":
		_current_character.unequip_slot(_get_current_slot())
		audioManager.play_sfx_by_name("clear", "menu")
	else:
		_current_character.equip_item(_get_selected_item())
		audioManager.play_sfx_by_name("equip", "menu")
	_item_selection = false
	_update_panel()

func _on_list_cursor_cancel():
	_cursor_list.play_sfx("back")
	_item_selection = false
	_update_panel()

func _on_cursor_moved(dir: Vector2):
	_update_item_info()

func _update_panel():
	if _item_selection:
		_update_item_list_for_slot()
		_cursor_list.cursor_index = 0
		_char_tabs.active = false
		_cursor_slots.on = false
		_cursor_list.on = true
		_item_panel.visible = true
	else:
		_update_slots()
		_item_panel.visible = false
		_cursor_list.on = false
		_cursor_slots.on = true
		_char_tabs.active = true

#callback function when character is changed
func _on_character_changed(char_name: String):
	_current_character = globaldata.characters.get(char_name)
	_update_slots()

#show proper name of equipped stuff 
func _update_slots():
	var index = 0
	var equipment = _current_character.get_equipment()
	var slots_texts = $EquipMenu/Box/Panels/Slots/EquippeditemsNames.get_children()
	#reset slots to "EQUIP_EMPTY"
	for i in slots_texts.size():
		slots_texts[i].text = "EQUIP_EMPTY"
	#set slot names
	for piece in equipment.values():
		if piece:
			index = Inventory.SLOTS.find(piece.get_data()["slot"])
			slots_texts[index].text = piece.get_data().name
	_update_item_info()

#for a specific slot, list all the applicable items from the character inventory
#minus the already equipped one
func _update_item_list_for_slot():
	var current_slot := _get_current_slot()
	var items = _current_character.get_items_for_slot(current_slot, true, true)
	for n in _items_container.get_children():
		n.free()
	_item_list.clear()
	for item in items:
		var item_label =_item_label_template.instance()
		_item_list.append(item)
		_items_container.add_child(item_label)
		item_label.text = item.get_data().name
	
	if _current_character.get_equipped_item(current_slot) or items.empty():
		var none_label = _item_label_template.instance()
		_item_list.append("")
		none_label.text = "EQUIP_NONE"
		_items_container.add_child(none_label)
	_update_item_info()

#update portrait modifier according to selected items (both mode)
func _update_portraits():
	var current_item
	
	var selected_item = _get_selected_item()
	
	# But we've left the value in the array, just in case.
	if selected_item:
		#valid item, check if suitable, equipped, ....
		current_item = selected_item
	else:
		#show nothing on portrait
		for character in global.party:
			_char_tabs.update_portrait_modifiers(character)
		return
			
	#update portrait modifiers
	#for each character, check if:
	for character in global.party:
		var is_suitable := false
		var is_equipped := false
		var is_better := false
		var is_lower := false
		
		if character.get_name() in global.POSSIBLE_PLAYABLE_MEMBERS:
			if current_item.is_equippable():
				is_suitable = character.can_equip_item(current_item)
				is_equipped = character.has_item_equipped(current_item)
				
				# if not equipped, check if stats boost
				if !is_equipped:
					var res = character.is_the_item_better(current_item)
					is_better = res == 1
					is_lower = res == - 1
			
			
			_char_tabs.update_portrait_modifiers(character, is_suitable, is_equipped, is_better, is_lower)

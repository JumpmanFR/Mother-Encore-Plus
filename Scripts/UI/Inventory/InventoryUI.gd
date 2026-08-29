extends Control

signal back
signal exit_with_dialog (dialog_id)
signal exit_with_item (item)

#external paths and references
onready var ItemLabelTemplate = preload("res://Nodes/Ui/HighlightLabel.tscn")

onready var _select_panel = $InventorySelect
onready var _stats_bar = $Bottom/StatsBar
onready var _dialog_box = $Bottom/DialogBox
onready var _action_select = $ActionSelect
onready var _arrow: Cursor = $Inventory/Arrow
onready var _items_grid = $Inventory/CenterContainer/Items/GridContainer 
onready var _scroll_bar = $Inventory/DescriptionPanel/Scrollbar

const NB_COLUMNS := 2
const NB_ROWS_WITH_DESC := 5
const ARROW_MOVE_OFFSET_X := 123
const ARROW_MOVE_OFFSET_Y := 12
const MAX_SUBMENU_POSITION := 60

var _is_active := false

var _current_character = globaldata.characters.ninten
var _current_scroll_pos := 0
var _is_desc_shown := false
var _swap_mode := false
var _swap_source: PartyMember
var _swap_source_item: Item
var _swap_target: PartyMember
var _sort_mode := false
var _sort_source_idx := 0

	
func open(party_member: PartyMember):
	_current_character = party_member
	_select_panel.init_from_character(_current_character.get_name())
	_show_hide_description(globaldata.description)
	_scroll_bar.nb_visible_rows = NB_ROWS_WITH_DESC
	_update_inventory()
	uiManager.info_plates_update()
	_set_active(true)
	audioManager.play_sfx_by_name("menu_open", "menu_open")
	$AnimationPlayer.play("Open")
	$Inventory.visible = true
	_select_panel.visible = true
	_highlight()
	
func _update_inventory(reset_select:= false):
	if reset_select:
		_current_scroll_pos = 0
		_set_selected_idx(0)
	else:
		pass
		#_idx_y = int(clamp(_idx_y, 1, _get_max_items_rows()))
	_update_scroll()	
	
func _ready():
	$Inventory.visible = false
	_update_list_view()
	global.connect("locale_changed", self, "_update_description")
	
#Update the list 	
func _update_list_view(select_idx := -1):
	for i in _items_grid.get_child_count():
		var which_row = i / NB_COLUMNS
		var item_label = _items_grid.get_child(i)
		var item_idx = i + _current_scroll_pos * 2
		if item_idx < _get_current_item_list().size() and (!_is_desc_shown or i < NB_ROWS_WITH_DESC * NB_COLUMNS):
			var item: Item = _get_current_item_list()[item_idx]
			item_label.text = TextTools.replace_text(item.get_data().get("name", ""))
			item_label.show_equipped(item.equipped)
		else:
			item_label.text = ""
			item_label.show_equipped(false)

	_arrow.visible = !_is_inventory_empty()
			
	var total_rows = ceil(_get_current_item_list().size() * 1.0 / NB_COLUMNS)

	# In case scrolling goes above the last row (like, because an item was deleted and the last row is empty)
	if total_rows < _current_scroll_pos + NB_ROWS_WITH_DESC:
		total_rows = _current_scroll_pos + NB_ROWS_WITH_DESC

	if select_idx > -1:
		_arrow.set_cursor_from_index(select_idx - _current_scroll_pos * NB_COLUMNS, false)

	_scroll_bar.nb_rows = total_rows
	_scroll_bar.position = _current_scroll_pos

	_highlight()
	_update_item_details()

func _update_item_details():
	_update_description()
	_update_portraits()

func _set_active(val: bool):
	_is_active = val
	_update_select_panel_state()
	_arrow.on = val

func _update_select_panel_state():
	_select_panel.active = _is_active and !_sort_mode

func _is_inventory_empty() -> bool:
	return _get_current_item_list().empty()

func _get_selected_pos_x() -> int:
	return _get_selected_idx() % NB_COLUMNS

func _get_selected_pos_y() -> int:
	return _get_selected_idx() / NB_COLUMNS

func _get_selected_idx() -> int:
	var idx := _arrow.cursor_index + _current_scroll_pos * NB_COLUMNS
	if _get_current_item_list().size() in range(1, idx + 1):
		idx = _get_current_item_list().size() - 1
	return idx

func _get_selected_item() -> Item:
	return _current_character.inv.get_item_from_idx(_get_selected_idx())

func _get_current_item_list() -> Array:
	return _current_character.inv.get_items()

func _update_scroll():
	_set_selected_idx(_get_selected_idx())

func _set_selected_idx(index: int):
	if _is_desc_shown:
		if index < NB_COLUMNS * _current_scroll_pos:
			_current_scroll_pos = index / NB_COLUMNS
		elif index >= NB_COLUMNS * (_current_scroll_pos + NB_ROWS_WITH_DESC):
			_current_scroll_pos = index / NB_COLUMNS - NB_ROWS_WITH_DESC + 1
	else:
		_current_scroll_pos = 0
		
	_update_list_view(index)

func _get_max_items_rows(pos_x: int) -> int:
	return ((_get_current_item_list().size() / NB_COLUMNS)+((-pos_x) * \
			(_get_current_item_list().size() % NB_COLUMNS)))+(_get_current_item_list().size() % NB_COLUMNS)

func _update_description():
	if _get_selected_idx() < _get_current_item_list().size():
		$Inventory/DescriptionPanel.set_item_from_inv(_get_selected_item())
	else:
		$Inventory/DescriptionPanel.set_item_from_inv(null)

func _update_portraits():
	#update portrait modifiers
	#for each character, check if:
	for character in global.party:
		var is_suitable = false
		var is_equipped = false
		var is_better = false
		var is_lower = false
		#	- item is suitable for the character
		if character.get_name() in global.POSSIBLE_PLAYABLE_MEMBERS:
			if _get_selected_idx() < _get_current_item_list().size():
				var current_item = _get_selected_item()
				if current_item.is_equippable():
					is_suitable = character.can_use_item(current_item)
					is_equipped = character.has_item_equipped(current_item)
					
					#if not equipped, check if stats boost
					if is_suitable and not is_equipped:
						var res = character.is_the_item_better(current_item)
						is_better = res == 1
						is_lower = res == - 1
				
				# then update the modifiers
				_select_panel.update_portrait_modifiers(character, is_suitable, is_equipped, is_better, is_lower)

func _update_party_infos():
	uiManager.info_plates_update()

func _on_arrow_moved(dir: Vector2):
	#check for inputs for selecting items in the inventory
	_update_item_details()
	if !_is_inventory_empty():
		_highlight()

func _on_arrow_failed_move(dir: Vector2):
	if _is_inventory_empty():
		return

	var prev_selected_idx: = _get_selected_idx()
	var pos_x: = _get_selected_pos_x()
	var pos_y: = _get_selected_pos_y()
	pos_y += dir.y as int

	if pos_y >= _get_max_items_rows(pos_x):
		pos_y = 0
	elif pos_y < 0:
		pos_y = _get_max_items_rows(pos_x) - 1

	pos_x = posmod(pos_x + int(dir.x), NB_COLUMNS)

	_set_selected_idx(pos_y * NB_COLUMNS + pos_x)
	
	if _get_selected_idx() != prev_selected_idx:
		_arrow.play_sfx("cursor1")

	_update_scroll()

func _on_arrow_selected(cursor_index: int):
	if _is_inventory_empty():
		return
	#item selected and validated, show actions box at the right place
	Input.action_release("ui_accept")
	var item = _get_selected_item()
	if _swap_mode:
		_swap_source.inv.swap_between_characters(_swap_source_item, _swap_target, item)
		_swap_mode = false
		_set_active(false)
		_set_selected_idx(_swap_source.inv.get_item_index(_swap_source_item))
		_current_character = _swap_source
		_select_panel.set_swap_mode(false, _swap_source, _swap_target)
		_show_hide_description(globaldata.description)
		_update_inventory()
		_action_select.visible = true
		_action_select.chain_with_equip()
	elif _sort_mode:
		var target_idx = _get_selected_idx()
		_current_character.inv.switch_items(_sort_source_idx, target_idx)
		_update_inventory()
		_sort_mode = false
		_show_hide_description(globaldata.description)
		_update_list_view()
		_update_select_panel_state()
	else:
		var side: = - 1.5 if _get_selected_pos_x() == 1 else 1.0
		var submenu_position = $Inventory / Arrow / Position2D.global_position
		submenu_position.x = submenu_position.x + 25 * side
		submenu_position.y = min(MAX_SUBMENU_POSITION, submenu_position.y)
		_action_select.set_for_new_item(submenu_position, item, side, _current_character, _get_selected_idx())
		_set_active(false)

func _on_arrow_cancel():
	if _sort_mode:
		_arrow.play_sfx("back")
		_sort_mode = false
		_show_hide_description(globaldata.description)
		_highlight()
		_update_select_panel_state()
	elif _swap_mode:
		_arrow.play_sfx("back")
		_swap_mode = false
		_show_hide_description(globaldata.description)
		_highlight()
		_select_panel.set_swap_mode(false, _swap_source, _swap_target)
		_current_character = _swap_source
		_update_inventory()
	else:
		_close()

func _input(event: InputEvent):
	if not _is_active or _is_inventory_empty():
		return
	if event.is_action_pressed("ui_scope"):
		Input.action_release("ui_scope")
		if not _swap_mode and not _sort_mode:
			globaldata.description = not globaldata.description
			_show_hide_description(globaldata.description)
					
#highlight item
func _highlight():
	var item_to_hl = _arrow.cursor_index
	
	var items = _items_grid.get_children()
	
	for item_idx in items.size():
		if _sort_mode and item_idx == _sort_source_idx:
			if items[item_idx].blinking == false:
				items[item_idx].blink(true)
		elif item_idx == item_to_hl and item_idx < _get_current_item_list().size():
			if _swap_mode:
				if !items[item_idx].blinking:
					items[item_idx].blink(true)
			else:
				if items[item_idx].blinking:
					items[item_idx].blink(false)
				items[item_idx].highlight(1)
		else:
			if items[item_idx].blinking:
				items[item_idx].blink(false)
			items[item_idx].highlight(0)

func _show_hide_description(value: bool):
	$Inventory/DescriptionPanel.visible = value
	_is_desc_shown = value
	_update_scroll()
	#_update_list_view()

func _on_InventorySelect_character_changed(character_id: String):
	_current_character = Inventory.get_inventory_holder(character_id)
	_update_inventory(true)

func _on_ActionSelect_back():
	_update_inventory()
	_set_active(true)
	_update_select_panel_state()

func _on_ActionSelect_exit_with_dialog(dialog_id: String):
	_exit_pause()
	emit_signal("exit_with_dialog", dialog_id)

func _on_ActionSelect_exit_with_item(item: Item):
	_exit_pause()
	emit_signal("exit_with_item", item)

func _on_ActionSelect_swapmode(target: PartyMember):
	_show_hide_description(false)
	_swap_source = _current_character
	_swap_source_item = _get_selected_item()
	_current_character = target
	_swap_target = target
	_swap_mode = true
	_select_panel.set_swap_mode(true, _swap_source, _swap_target)
	_update_inventory()


func _on_ActionSelect_sortmode():
	_show_hide_description(false)
	_sort_source_idx = _get_selected_idx()
	_sort_mode = true
	_update_select_panel_state()

func _on_ActionSelect_show_statsbar(character: PartyMember, unequip := false):
	var modifiers = {}
	var item = _get_selected_item()
	var item_stats = item.get_data()
	var item_slot = item_stats["slot"]
	var is_equipped = false
	
	#test if item equipped:
	var projected_stat
	
	if character == null:
		_hide_stats_bar()
	elif character.get_equipped_item(item_slot) != item:
		for stat in _stats_bar.stats_list:
			if not item_stats["boost"].has(stat):
				continue
			var boost = int(item_stats["boost"][stat])
			if boost == 0:
				continue
			var equipped_item = character.get_equipped_item(item_slot)
			var equipped_boost = 0
			if equipped_item:
				equipped_boost = equipped_item.get_data()["boost"][stat]
			projected_stat = character.get_stat(stat) - equipped_boost + boost
				
			modifiers[stat] = projected_stat
	else:
		for stat in _stats_bar.stats_list:
			if not item_stats["boost"].has(stat):
				continue
			var boost = int(item_stats["boost"][stat])
			if boost == 0:
				continue
			var equipped_item = character.get_equipped_item(item_slot)
			var equipped_boost = 0
			if equipped_item:
				equipped_boost = equipped_item.get_data()["boost"][stat]
			projected_stat = character.get_stat(stat) - equipped_boost
				
			modifiers[stat] = projected_stat
				
	_stats_bar.show_statsBar(character, modifiers)
	uiManager.info_plates_hide()

func _on_ActionSelect_hide_statsbar():
	_hide_stats_bar()

func _on_TargetCharaSelect_hide_statsbar():
	_hide_stats_bar()

func _hide_stats_bar():
	_stats_bar.hide_statsBar()
	uiManager.info_plates_show()

func _close():
	$AnimationPlayer.play("Close")
	audioManager.play_sfx_by_name("menu_close", "menu_close")
	_set_active(false)
	emit_signal("back")

func _exit_pause():
	$AnimationPlayer.play("Close")
	audioManager.play_sfx_by_name("menu_close", "menu_close")
	_set_active(false)

func _on_ActionSelect_show_dialogbox(dialog: String, character := globaldata.characters.ninten, value := 0, stat := "", item := {}):
	yield(get_tree(), "idle_frame")
	_set_active(false)
	_dialog_box.show_dialog_box(dialog, character, value, stat, item)
	_update_description()
	_update_portraits()
	
func _on_ActionSelect_update_dialogbox(dialog: String, character := globaldata.characters.ninten, value := 0, stat := "", item := {}):
	_dialog_box.update_dialog_box(dialog, character, value, stat, item)

func _on_DialogBox_back():
	uiManager.info_plates_update()
	_update_scroll()
	_set_active(true)


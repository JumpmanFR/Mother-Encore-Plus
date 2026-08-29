extends Control

var portraitSprites := {
	PartyMember.NINTEN: preload("res://Graphics/UI/Inventory/characters/ninten.png"),
	PartyMember.ANA: preload("res://Graphics/UI/Inventory/characters/ana.png"),
	PartyMember.LLOYD: preload("res://Graphics/UI/Inventory/characters/lloyd.png"),
	PartyMember.TEDDY: preload("res://Graphics/UI/Inventory/characters/teddy.png"),
	PartyMember.PIPPI: preload("res://Graphics/UI/Inventory/characters/pippi.png"),
	PartyNPC.FLYING_MAN: preload("res://Graphics/UI/Inventory/characters/flyingman.png"),
	PartyNPC.EVE: preload("res://Graphics/UI/Inventory/characters/eve.png"),
	PartyNPC.CANARY_CHICK: preload("res://Graphics/UI/Inventory/characters/canarychick.png"),
}

var hlportraitSprites := {
	PartyMember.NINTEN: preload("res://Graphics/UI/Inventory/characters/ninten_hl.png"),
	PartyMember.ANA: preload("res://Graphics/UI/Inventory/characters/ana_hl.png"),
	PartyMember.LLOYD: preload("res://Graphics/UI/Inventory/characters/lloyd_hl.png"),
	PartyMember.TEDDY: preload("res://Graphics/UI/Inventory/characters/teddy_hl.png"),
	PartyMember.PIPPI: preload("res://Graphics/UI/Inventory/characters/pippi_hl.png"),
	PartyNPC.FLYING_MAN: preload("res://Graphics/UI/Inventory/characters/flyingman_hl.png"),
	PartyNPC.EVE: preload("res://Graphics/UI/Inventory/characters/eve_hl.png"),
	PartyNPC.CANARY_CHICK: preload("res://Graphics/UI/Inventory/characters/canarychick_hl.png")
}

# Nodes
onready var _chara_select = $StorageBox/InventorySelect
onready var _list_on_hand: ItemListMenu = $StorageBox/ItemsOnHand
onready var _list_storage: ItemListMenu = $StorageBox/ItemsStored
onready var _desc_panel = $DescContainer/DescriptionPanel
onready var _dialog = $DescContainer/DescriptionDialog

var god_mode := false setget _set_god_mode

var _character_order := [PartyMember.NINTEN, PartyMember.LLOYD, PartyMember.ANA, PartyMember.TEDDY, PartyMember.PIPPI, PartyNPC.FLYING_MAN, PartyNPC.EVE, PartyNPC.CANARY_CHICK]
var _storage_holder = Inventory.get_inventory_holder(Inventory.INV_NAME_STORAGE)

# Common
var _current_char # Character or storage holder
var _current_panel_is_storage := false

var _callback: FuncRef = null

func setup(callback: FuncRef = null):
	_callback = callback

func _ready():
	
	_set_god_mode()
	_storage_holder.inv.sort_auto()

	_chara_select.visible = true
	_chara_select.active = true

	_chara_select.connect("character_changed", self, "_change_character")
	_list_on_hand.connect("moved", self, "_on_list_move")
	_list_storage.connect("moved", self, "_on_list_move")
	_list_on_hand.connect("selected", self, "_on_selected_on_hand")
	_list_storage.connect("selected", self, "_on_selected_storage")
	_list_on_hand.connect("failed_select", self, "_on_failed_select")
	_list_storage.connect("failed_select", self, "_on_failed_select")
	_list_on_hand.connect("exited", self, "_on_exit_on_hand")
	_list_storage.connect("exited", self, "_on_exit_storage")
	_dialog.connect("closed", self, "_on_dialog_closed")
	global.connect("locale_changed", self, "_on_locale_changed")

	# set up character order
	_character_order.clear()
	for party_mem in global.get_party_in_natural_order():
		_character_order.append(party_mem.get_name())

	_change_character(_character_order[0])
	_update_list_storage()
	_switch_to_panel(false, true)
	#_update_desc()

func _on_locale_changed():
	_update_list_storage()
	_update_desc()

func _set_god_mode(value := god_mode):
	god_mode = value
	_storage_holder = Inventory.get_inventory_holder(Inventory.INV_NAME_STORAGE_GOD if god_mode else Inventory.INV_NAME_STORAGE)
	if _chara_select:
		_chara_select.noKey = !value
		_chara_select.include_storage = value

func _get_current_item() -> Item:
	var from_list: ItemListMenu
	if !_current_panel_is_storage:
		from_list = _list_on_hand
	else:
		from_list = _list_storage
	return from_list.get_current_item()

func _on_arrow_failed_move(dir: Vector2):
	if !_dialog.open:
		if dir.x < 0:
			_switch_to_panel(false, false, true)
		elif dir.x > 0:
			_switch_to_panel(true, false, true)
		

func _switch_to_panel(is_storage: bool, force := false, same_index := false):
	var cur_index := _list_storage.cursor.cursor_index if _current_panel_is_storage else _list_on_hand.cursor.cursor_index

	if (!is_storage) and (force or !_list_on_hand.item_list.empty()): # To "on hand" panel
		if _current_panel_is_storage:
			_list_on_hand.cursor.play_sfx("cursor1")
		_current_panel_is_storage = false
		_list_on_hand.enter(false, cur_index if same_index else -1)
		_list_storage.exit()
		_update_desc()			
	elif is_storage and (force or !_list_storage.item_list.empty()): # To storage panel
		if !_current_panel_is_storage:
			_list_on_hand.cursor.play_sfx("cursor1")
		_current_panel_is_storage = true
		_list_storage.enter(false, cur_index if same_index else -1)
		_list_on_hand.exit()
		_update_desc()

func _change_character(char_name: String):
	_current_char = Inventory.get_inventory_holder(char_name)
	_update_portraits()
	_update_list_on_hand()
	_update_list_storage()
	_update_desc()

func _update_list_on_hand():
	_update_list(_list_on_hand, _current_char)

func _update_list_storage():
	_update_list(_list_storage, _storage_holder)
	$StorageBox/TitleAndCounter/Counter/Label.text = "%s / %s" % [_list_storage.item_list.size(), _storage_holder.inv.get_max_size()]

func _update_list(list: ItemListMenu, target):
	list.restriction_func = funcref(self, "_list_restrictions_cb")
	list.item_list = target.inv.get_items()

func _list_restrictions_cb(item_instance: Item) -> bool:
	if item_instance in _current_char.inv.get_items():
		return !_storage_holder.inv.is_full()
	else:
		return !_current_char.inv.is_full()

func _update_portraits():
	var current_item: = _get_current_item()
	for i in 4: # there's 4 portraits!
		# equipment information
		var is_suitable: = false
		var is_equipped: = false
		var is_better: = false
		var is_lower: = false
		var is_inventory_full: = false
		if i < _character_order.size():
			if current_item:
				var current_item_data := current_item.get_data()
				var character = globaldata.characters[_character_order[i]]
				is_inventory_full = character.inv.is_full() and (_current_char != character or _current_panel_is_storage)
				if current_item.is_equippable():
					is_suitable = character.can_equip_item(current_item)
					var current_item_slot = current_item_data["slot"]
					# item is equipped
					
					is_equipped = character.get_equipped_item(current_item_slot) == current_item
					
					
					if is_suitable and not is_equipped:
						var res = character.is_the_item_better(current_item)
						is_better = res == 1
						is_lower = res == - 1
					is_suitable = is_suitable and not is_equipped and not is_inventory_full
			_chara_select.update_portrait_modifiers(globaldata.characters[_character_order[i]], is_suitable, is_equipped, is_better, is_lower, is_inventory_full)

func _on_list_move(item_pos: int):
	_update_desc()

func _update_desc():
	var item = _get_current_item()
	_update_portraits()
	_desc_panel.set_item_from_inv(item)
	_desc_panel.visible = !!item

func _on_selected_on_hand(item_pos: int):
	if !_storage_holder.inv.is_full():
		var item := _list_on_hand.get_current_item()
		var item_id := item.item_name
		var itemData := item.get_data()
		var is_equipped: bool = _current_char.inv.get_items()[item_pos].equipped
		
		if is_equipped:
			var question_str := TextTools.format_text_with_context("TRANSACTION_ASK_UNEQUIP", null, itemData)
			_ask_user(question_str, item_id, "_unequip_and_store", [_current_char, item_pos])
		else:
			_store_item(_current_char, item_pos)
	else:
		_warn_user(tr("TRANSACTION_STORAGE_FULL"))


func _on_selected_storage(item_pos: int):
	if !_current_char.inv.is_full():
		var item := _list_storage.get_current_item()
		_withdraw_item(_current_char, item_pos)
		var item_id := item.item_name
		var itemData := item.get_data()
		if _current_char is PartyMember and _current_char.can_equip_item(item):
			var item_uid = _current_char.inv.get_items().back().uid
			var question_str := TextTools.format_text_with_context("SHOP_ASK_EQUIP", null, itemData)
			_ask_user(question_str, item_id, "_equip_after_withdrawal", [ _current_char, item_uid])
	else:
		_warn_user(tr("TRANSACTION_FULL"))

func _ask_user(question_str: String, item_id: String, callback: String, cbParams: Array):
	_dialog.ask(question_str, item_id, funcref(self, callback), cbParams, true)
	_list_on_hand.exit()
	_list_storage.exit()
	_chara_select.active = false

func _warn_user(question_str: String):
	_desc_panel.warn(question_str, 1)

func _on_dialog_closed():
	_chara_select.active = true
	_switch_to_panel(_current_panel_is_storage, true)

func _unequip_and_store(character, item_pos: int):
	audioManager.play_sfx_by_name("clear", "menu")
	_store_item(character, item_pos)

func _equip_after_withdrawal(character, item_pos: int):
	audioManager.play_sfx_by_name("equip", "menu")
	var item_uid = character.inv.get_items().back().uid
	character.equip_item(character.inv.get_item_from_uid(item_uid))
	_update_list_on_hand()

func _store_item(character, item_pos: int):
	_item_transaction(character.inv, _storage_holder.inv, item_pos, _list_storage, true)

func _withdraw_item(character, item_pos: int):
	_item_transaction(_storage_holder.inv, character.inv, item_pos, _list_on_hand)

func _item_transaction(source_inv: Inventory, target_inv: Inventory, item_pos: int, targetList: ItemListMenu, sort := false):
	var item = source_inv.get_items()[item_pos]
	source_inv.transfer_item(target_inv, item)
	if sort:
		_storage_holder.inv.sort_auto()
	_update_list_on_hand()
	_update_list_storage()
	_update_desc()
	#_scroll_to_focus(targetList, item_id)

func _scroll_to_focus(list: ItemListMenu, item_id: String):
	var new_pos := 0
	for i in list.item_list.size():
		if list.item_list[i].item_name == item_id:
			new_pos = i
	list.scroll_to(new_pos)

func _on_failed_select(item_pos: int):
	audioManager.play_sfx_by_name("restricted", "menu")

func _on_exit_on_hand():
	if not _current_panel_is_storage and _dialog.open == false:
		uiManager.remove_ui(self)

func _on_exit_storage():
	if _current_panel_is_storage and _dialog.open == false:
		uiManager.remove_ui(self)

# Override
func close():
	if _callback and _callback.is_valid():
		_callback.call_func()
		_callback = null
	queue_free()

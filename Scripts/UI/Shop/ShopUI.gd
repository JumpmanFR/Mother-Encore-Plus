extends Control

var _portrait_sprites = {
	PartyMember.NINTEN: preload("res://Graphics/UI/Inventory/characters/ninten.png"),
	PartyMember.ANA: preload("res://Graphics/UI/Inventory/characters/ana.png"),
	PartyMember.LLOYD: preload("res://Graphics/UI/Inventory/characters/lloyd.png"),
	PartyMember.TEDDY: preload("res://Graphics/UI/Inventory/characters/teddy.png"),
	PartyMember.PIPPI: preload("res://Graphics/UI/Inventory/characters/pippi.png"),
	PartyNPC.FLYING_MAN: preload("res://Graphics/UI/Inventory/characters/flyingman.png"),
	PartyNPC.EVE: preload("res://Graphics/UI/Inventory/characters/eve.png"),
	PartyNPC.CANARY_CHICK: preload("res://Graphics/UI/Inventory/characters/canarychick.png"),
}

var _hl_portrait_sprites = {
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
onready var _desc_no_dialog = $DescBox/DescriptionPanel
onready var _desc_dialog = $DescBox/DescriptionDialog
onready var _sell_label = $BuySellDialog/VBoxContainer/NoLabel
onready var _menu_buy = $ShopBox/BuyMenu
onready var _menu_sell = $ShopBox/SellMenu
onready var _main_cursor = $BuySellDialog/arrow
onready var _portraits_node = $CharacterSelect/CharacterPortraits

# Common
var _current_character
var _selected_item: Item
var _prev_equip: Item
var _last_purchased: Item
var _character_order = [PartyMember.NINTEN, PartyMember.LLOYD, PartyMember.ANA, PartyMember.TEDDY, PartyMember.PIPPI, PartyNPC.FLYING_MAN, PartyNPC.EVE, PartyNPC.CANARY_CHICK]
var _characterIdx = 0

# Buy or Sell Menu State
# Buy state
var _shop_yaml_name = ""
var _can_sell = true
var _callback: FuncRef = null
# Description Dialog State
enum DialogState {
	BUY,
	EQUIP_BOUGHT,
	SELL_OLD_EQUIP,
	SELL_EQUIP_NO_SPACE,
	SELL_FOR_CASH,
	SELL,
}
# 0 - Buy a {...}?
# 	Yes -> dialog state, 1. process buy item
# 	No -> buy state
# 1 - {...} bought. Equip now?
# 	Yes -> dialog state, 2. process equip item
# 	No -> buy state
# 2 - Sell your old {...}?
# 	Yes -> buy state. process sold item
# 	No -> buy state
# 3 - Your inventory is full, sell {...}?
# 	Yes -> buy state. process sold item
# 	No -> buy state
# 4 - You don't have enough, sell something?
# 	Yes -> sell state
# 	No -> buy state
# 5 - Sell {...}?
# 	Yes -> sell state
# 	No -> sell state

func setup(shop_yaml_name: String, can_sell = true, callback: FuncRef = null):
	_shop_yaml_name = shop_yaml_name
	_can_sell = can_sell
	_callback = callback
	

# Called when the node enters the scene tree for the first time.
func _ready():
	_main_cursor.connect("selected", self, "_on_buysell_select")
	_main_cursor.connect("cancel", self, "_on_arrow_cancel")
	_menu_buy.connect("exited", self, "_on_exit_buy")
	_menu_buy.connect("entered", self, "_on_enter_buy")
	_menu_buy.connect("moved", self, "_on_buy_cursor_moved")
	_menu_buy.connect("selected", self, "_on_buy_item_selected")
	_menu_sell.connect("exited", self, "_on_exit_sell")
	_menu_sell.connect("entered", self, "_on_enter_sell")
	_menu_sell.connect("moved", self, "_on_sell_cursor_moved")
	_menu_sell.connect("selected", self, "_on_sell_item_selected")
	
	# set up character order
	_character_order.clear()
	for partyMem in global.get_party_in_natural_order():
		_character_order.append(partyMem.get_name())
	
	# init shop
	var shop_list := globaldata.get_shop_data(_shop_yaml_name)
	_menu_buy.item_list.clear()
	_menu_buy.restriction_func = funcref(self, "_is_purchasable_cb")
	for item_name in shop_list:
		_menu_buy.item_list.append(Item.new(item_name))
	
	_enter_buysell()
	#set up highlights for buy/sell
	$BuySellDialog/VBoxContainer/YesLabel.highlight(1)
	_change_character(0)
	_update_cash()

func _input(event: InputEvent):
	if event.is_action_pressed("ui_focus_next"):
		get_tree().set_input_as_handled()
		if !_desc_dialog.open:
			_change_character(1)
	elif event.is_action_pressed("ui_focus_prev"):
		get_tree().set_input_as_handled()
		if !_desc_dialog.open:
			_change_character(-1)

func close():
	if _callback and _callback.is_valid():
		_callback.call_func(_last_purchased.item_name if _last_purchased else "")
		_callback = null
	queue_free()

func _update_cash():
	$ShopBox/Header/CashBox/HBoxContainer/Amount.text = str(globaldata.cash).pad_zeros(6)

func _is_purchasable_cb(item_instance):
	return !_current_character.inv.is_full() and item_instance.get_data().cost <= globaldata.cash

func _is_sellable_cb(item_instance):
	return item_instance.get_data().value > 0

func _enter_buysell():
	# hide non-used menus
	$DescBox.hide()
	_desc_dialog.hide()
	_desc_no_dialog.hide()
	_menu_buy.hide()
	_menu_sell.hide()
	_sell_label.visible = _can_sell
	_selected_item = null
	_prev_equip = null
	_update_portraits()
	_main_cursor.on = true

func _enter_buy(reset := true):
	# some bs to make sure you know what menu ur in lol
	_main_cursor.set_cursor_from_index(0, false)
	_main_cursor.on = false
	$DescBox.show()
	_desc_no_dialog.show()
	_menu_buy.show()
	_menu_buy.enter(reset)
	_update_desc_and_portraits(_menu_buy)

func _enter_sell(reset := true):
	# some bs to make sure you know what menu ur in lol
	_main_cursor.set_cursor_from_index(1, false)
	_main_cursor.on = false
	_menu_sell.restriction_func = funcref(self, "_is_sellable_cb")
	_menu_sell.item_list = _current_character.inv.get_items()
	$DescBox.show()
	_desc_no_dialog.show()
	_menu_sell.show()
	_menu_sell.enter(reset)
	_update_desc_and_portraits(_menu_sell)

func _enter_desc_dialog(state: int, selected_index: int):
	if !_selected_item:
		_selected_item = Item.new("error")
	var item = _selected_item
	var question
	match(state):
		DialogState.BUY:
			question = "SHOP_ASK_BUY"
		DialogState.EQUIP_BOUGHT:
			question = "SHOP_ASK_EQUIP"
		DialogState.SELL_OLD_EQUIP:
			item = _prev_equip
			_desc_no_dialog.set_item(_prev_equip)
			question = "SHOP_ASK_SELL_OLD"
		DialogState.SELL:
			question = "SHOP_ASK_SELL"
		DialogState.SELL_EQUIP_NO_SPACE:
			item = _prev_equip
			_desc_no_dialog.set_item(_prev_equip)
			question = "SHOP_ASK_SELL_FOR_SPACE"
		DialogState.SELL_FOR_CASH:
			question = "SHOP_ASK_SELL_FOR_CASH"
	
	question = TextTools.format_text_with_context(question, null, item.get_data())
	_desc_dialog.ask(question, item.item_name, funcref(self, "_desc_dialog_answer"), [state, selected_index])
	

func _desc_dialog_answer(state: int, selected_index: int, yes: bool):
	if !_selected_item:
		_selected_item = Item.new("error")
	var item_data = _selected_item.get_data()
	match(state):
		DialogState.BUY:
			if yes:
				_buy_something()
				if _current_character.can_equip_item(_selected_item):
					# next dialog state if equippible
					_enter_desc_dialog(DialogState.EQUIP_BOUGHT, selected_index)
					return
			# else, re enable buy state
			_enter_buy(false)
		DialogState.EQUIP_BOUGHT:
			if yes:
				_prev_equip = _current_character.get_equipped_item(item_data.slot)
				# get most recent item (bought item)
				var recentItem = _current_character.inv.get_items().back()
				_current_character.equip_item(recentItem)
				audioManager.play_sfx_by_name("equip", "menu")
				if _prev_equip:
					_enter_desc_dialog(DialogState.SELL_OLD_EQUIP, selected_index)
					return
			_enter_buy(false)
		DialogState.SELL_OLD_EQUIP:
			if yes:
				_sell_something(_prev_equip)
			_prev_equip = null
			_enter_buy(false)
		DialogState.SELL:
			if yes:
				_sell_something(_selected_item)
			_enter_sell(false)
		DialogState.SELL_EQUIP_NO_SPACE:
			if yes:
				_sell_something(_prev_equip)
				_enter_desc_dialog(DialogState.BUY, selected_index)
				_prev_equip = null
				return
			_prev_equip = null
			_enter_buy(false)
		DialogState.SELL_FOR_CASH:
			if yes:
				_menu_buy.exit()
				_menu_buy.hide()
				_enter_sell()
			else:
				_enter_buy(false)

func _buy_something():
	audioManager.play_sfx_by_name("cash", "menu")
	var item_data := _selected_item.get_data()
	globaldata.cash -= item_data.get("cost", 0)
	_update_cash()
	_last_purchased = _selected_item
	if item_data.get("use_at_shop", false):
		uiManager.remove_ui(self)
	else:
		_current_character.inv.add_item_by_name(_selected_item.item_name)
	# update purchasables(in cash update?)

func _sell_something(item: Item):
	audioManager.play_sfx_by_name("cash", "menu")
	globaldata.cash += _get_resale_price(item)
	_current_character.inv.drop_item(item)
	# update sell list
	_update_cash()

func _get_resale_price(item: Item) -> int:
	return item.get_data().value * item.doses

func _update_portraits(highlighted_item=null):
	for i in 4: # there's 4 portraits!
		var portrait_node = _portraits_node.get_node(str("Party", i + 1))
		if i >= _character_order.size():
			portrait_node.texture = null
		elif i == _characterIdx:
			portrait_node.texture = _hl_portrait_sprites[_character_order[i]]
		else:
			portrait_node.texture = _portrait_sprites[_character_order[i]]
		
		# equipment information
		var is_suitable: = false
		var is_equipped: = false
		var is_better: = false
		var is_lower: = false
		var is_inventory_full: = false
		if i < _character_order.size():
			var character = globaldata.characters[_character_order[i]]
			is_inventory_full = character.inv.is_full() and not _menu_sell.visible
			if highlighted_item and highlighted_item.is_equippable():
				is_suitable = character.can_equip_item(highlighted_item)
				is_equipped = character.has_item_equipped_by_name(highlighted_item.item_name)
				if is_suitable and not is_equipped:
					var res = character.is_the_item_better(highlighted_item)
					is_better = res == 1
					is_lower = res == - 1
				is_suitable = is_suitable and not is_equipped and not is_inventory_full
		portrait_node.show_is_item_suitable(is_suitable)
		portrait_node.show_is_item_equipped(is_equipped)
		portrait_node.show_is_item_better(is_better)
		portrait_node.show_is_item_lower(is_lower)
		portrait_node.show_is_inventory_full(is_inventory_full)

func _update_desc_and_portraits(current_menu):
	var item = current_menu.get_current_item()
	_update_portraits(item if item else null)
	_desc_no_dialog.set_item_from_inv(item)

func _change_character(dir):
	_characterIdx = wrapi(_characterIdx + dir, 0, _character_order.size())
	# change _current_character
	for partyMem in global.party:
		if partyMem.get_name() == _character_order[_characterIdx]:
			_current_character = partyMem
	#if in "sell" phase, reenter it to refresh items
	if _menu_sell.visible:
		_menu_sell.exit()
		_menu_sell.hide()
		_main_cursor.on = false
		_enter_sell()
	elif _menu_buy.visible:
		#_update_portraits(_menu_buy.get_current_item_id())
		_enter_buy(false)
	#Trust me this is helpful
	else:
		_update_portraits()

# SIGNAL CONNECTIONS


func _on_buysell_select(idx):
	if idx == 0:
		_enter_buy()
	else:
		_enter_sell()

func _on_exit_buy():
	_enter_buysell()
	audioManager.play_sfx_by_name("back", "menu")

func _on_exit_sell():
	_enter_buysell()
	audioManager.play_sfx_by_name("back", "menu")

func _on_buy_cursor_moved(item_idx):
	_update_desc_and_portraits(_menu_buy)

func _on_buy_item_selected(item_idx):
	var item = _menu_buy.get_current_item()
	var itemData = item.get_data()
	if _current_character.inv.is_full():
		_prev_equip = _current_character.get_equipped_item(itemData.slot) if (itemData.slot in _current_character.get_equipment()) else null
		# For SELL_EQUIP_NO_SPACE: The party member should be able to equip the item,
		# they should have another equippable item in the same slot, it should be different,
		# and they should have enough money to buy it after selling the current one
		if _current_character.can_equip_item(item)\
				and _prev_equip != null and _prev_equip.item_name != item.item_name \
				and itemData.cost - _prev_equip.get_data().value <= globaldata.cash:
			_selected_item = item
			_menu_buy.cursor.on = false
			_enter_desc_dialog(DialogState.SELL_EQUIP_NO_SPACE, item_idx)
		else:
			_desc_no_dialog.warn(tr("TRANSACTION_FULL"), 1)
	elif itemData.cost > globaldata.cash:
		_selected_item = item
		_menu_buy.cursor.on = false
		_enter_desc_dialog(DialogState.SELL_FOR_CASH, item_idx)
	else:
		_selected_item = item
		_menu_buy.cursor.on = false
		_enter_desc_dialog(DialogState.BUY, item_idx)

func _on_sell_cursor_moved(item_idx):
	_update_desc_and_portraits(_menu_sell)

func _on_sell_item_selected(item_idx):
	var item = _menu_sell.get_current_item()
	var itemData = item.get_data()
	if itemData.value <= 0:
		return
	_selected_item = item
	_menu_sell.cursor.on = false
	_enter_desc_dialog(DialogState.SELL, item_idx)

func _on_enter_buy():
	if _menu_buy.item_list.empty():
		$DescBox.hide()
	else:
		$DescBox.show()

func _on_enter_sell():
	if _menu_sell.item_list.empty():
		$DescBox.hide()
	else:
		$DescBox.show()

func _on_arrow_cancel():
	uiManager.remove_ui(self)

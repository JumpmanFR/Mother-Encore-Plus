class_name Inventory

enum InvType {NORMAL, KEY, STORAGE, STORAGE_GOD}

const _MAX_INVENTORY_SIZE := 16
const _MAX_STORAGE_SIZE := 64
const _MAX_STORAGE_SIZE_GOD := 99
const BOOSTABLE_STATS_COEFFS := { 
	Character.MAXHP: 2,
	Character.MAXPP: 2,
	Character.OFFENSE: 3,
	Character.DEFENSE: 2,
	Character.SPEED: 1,
	Character.IQ: 1,
	Character.GUTS: 1 
}
const SLOTS := ["weapon", "body", "arms", "other"]

# Must match the variable names in globaldata
const INV_NAME_KEY := "key_items"
const INV_NAME_STORAGE := "storage"
const INV_NAME_STORAGE_GOD := "god_storage"

var _type: int
var _items := []

func _init(type:= InvType.NORMAL, load_data:= []):
	_type = type
	if _type == InvType.STORAGE_GOD:
		_init_god_storage()
	if load_data:
		init_from_serialized(load_data)

func get_type() -> int:
	return _type

func _init_god_storage():
	for item in globaldata.get_all_items():
		var inv_item = Item.new(item)
		_items.append(inv_item)
	sort_auto()

# Load inventories from savegame data
func init_from_serialized(serialized_inv: Array):
	var inv_content = []
	for item in serialized_inv:
		inv_content.append(Item.new(item["item_name"], item.get("equipped", false),\
				item.get("doses", 1), int(item.get("uid", Item.get_uid(Item.used_uids_tab)))))
	_items = inv_content

# Save inventories into savegame data	
func to_array() -> Array:
	var serialized_inv = []
	for item in _items:
		serialized_inv.append(item.to_dict())
	return serialized_inv

func reset():
	_items.clear()

func add_item(item: Item) -> bool:
	if !is_full():
		_items.append(item)
		return true
	return false

func add_item_by_name(item_name: String) -> Item:
	var item := Item.new(item_name)
	var result := add_item(item)
	return item if result else null

func drop_item(item: Item) -> bool:
	item.equipped = false
	var size := _items.size()
	_items.erase(item)
	return _items.size() != size

func get_random_item(only_throwable := false) -> Item:
	var list := _items
	if only_throwable:
		list = []
		for item in _items:
			if item.get_data().value > 0 and !item.get_data().get("keyitem", false):
				list.append(item)
		
	if !list.empty():
		var index := randi() % list.size()
		return list[index]
	else:
		return null

func remove_item_by_name(item_name: String) -> bool:
	for item in _items:
		if item.item_name == item_name:
			drop_item(item)
			return true
	return false

func reduce_or_drop_item(item: Item) -> bool:
	if item.doses > 1:
		item.doses -= 1
		return true
	else:
		return drop_item(item)

func get_items() -> Array:
	return _items

func get_item_from_idx(idx: int) -> Item:
	return _items[idx]

# Search item from uid
func get_item_from_uid(uid: int) -> Item:
	for item in _items:
		if item.uid == uid:
			return item
	return null

func get_item_index(item: Item) -> int:
	return _items.find(item)

func find_item(item_name: String) -> Item:
	for item in _items:
		if item.item_name == item_name:
			return item
	return null

func has_item(item_name: String) -> bool:
	return !!find_item(item_name)

func is_full() -> bool:
	if _type == InvType.STORAGE_GOD:
		return false
	else:
		var inv_size = get_max_size()
		return inv_size > 0 and _items.size() >= inv_size

func get_max_size() -> int:
	if _type == InvType.STORAGE:
		return _MAX_STORAGE_SIZE
	elif _type == InvType.STORAGE_GOD:
		return _MAX_STORAGE_SIZE_GOD
	elif _type == InvType.KEY:
		return 0
	else:
		return _MAX_INVENTORY_SIZE

func _sort_auto(a: Item, b: Item) -> bool:
	var STEP := 100000
	var STEP_SLOT := 10000
	var SCORE_CAT_HP_RECOVER	:= (11 - 1)  * STEP # HP recovery items come first
	var SCORE_CAT_PP_RECOVER	:= (11 - 2)  * STEP # PP recovery items come second
	var SCORE_CAT_STATUS_HEALS	:= (11 - 3)  * STEP # status healing items come fourth
	var SCORE_CAT_CONSUMABLE	:= (11 - 4)  * STEP # consumable items come fifth
	var SCORE_CAT_BATTLE_ITEMS	:= (11 - 5)  * STEP # battle items come third
	var SCORE_CAT_USABLE		:= (11 - 6)  * STEP # usable items come sixth
	var SCORE_CAT_OTHERS		:= (11 - 7)  * STEP # uncategorized items come fifth to last
	var SCORE_CAT_BOOSTS		:= (11 - 8)  * STEP # stats boosting items come fourth to last
	var SCORE_CAT_UNEQUIPPED	:= (11 - 9)  * STEP # unequipped items come third to last
	var SCORE_CAT_EQUIPPED		:= (11 - 10) * STEP # equipped items come second to last
	var SCORE_CAT_KEY			:= (11 - 10) * STEP # key items come last
	
	var sorting_scores := []
	
	for item in [a, b]:
		var item_data: Dictionary = item.get_data()
		
		var boost_total := get_boost_total(item_data.get("boost", {}))
		var item_actions := item_data.get("actions", []) as Array
		var function: String = item_actions[0].get("function", "") if item_actions.size() > 0 else ""
		var score := 0
		
		if item_data.get("keyitem", false):
			score += SCORE_CAT_KEY
		elif item_data.get("battle_action", {}).get("skill"):
			score += SCORE_CAT_BATTLE_ITEMS
		elif item_data.get("status_heals"):
			score += SCORE_CAT_STATUS_HEALS
		elif item.is_equippable():
			score += SCORE_CAT_EQUIPPED if item.equipped else SCORE_CAT_UNEQUIPPED
			var slot_name: String = item_data["slot"]
			var slot = SLOTS.size() - SLOTS.find(slot_name)
			score += slot * STEP_SLOT
			score += boost_total
		elif boost_total > 0:
			score += SCORE_CAT_BOOSTS
			score += boost_total
		elif item_data.get("PPrecover", 0) > 0:
			score += SCORE_CAT_PP_RECOVER
			score += item_data["PPrecover"]
		elif item_data.get("HPrecover", 0) > 0:
			score += SCORE_CAT_HP_RECOVER
			score += item_data["HPrecover"]
		elif function == "consume":
			score += SCORE_CAT_CONSUMABLE
		elif function == "use":
			score += SCORE_CAT_USABLE
		else:
			score += SCORE_CAT_OTHERS
		
		sorting_scores.append(score)
	
	if sorting_scores[0] > sorting_scores[1]:
		return true
	elif sorting_scores[0] < sorting_scores[1]:
		return false
	else:
		# If scores are equal, sort by name
		return tr(a.get_data()["sorting_name"]) < tr(b.get_data()["sorting_name"])

func sort_auto():
	_items.sort_custom(self, "_sort_auto")

# Move item between inventories
func transfer_item(target_inv: Inventory, item: Item):
	if self != target_inv:
		if _type == InvType.STORAGE_GOD:
			target_inv.add_item(item)
		else:
			drop_item(item)
			if target_inv.get_type() != InvType.STORAGE_GOD:
				target_inv.add_item(item)


# Transform an item into another in inventory
func transform_item(item: Item) -> Item:
	var item_data = item.get_data()
	var new_item_name := item_data.get("transform", "") as String

	# Making sure to drop the previous item first to make room in the inventory
	if new_item_name != "":
		drop_item(item)
		return add_item_by_name(new_item_name)
	
	return null
	
func transform_one_item_by_name(item_name: String) -> Item:
	for item in _items:
		if item.item_name == item_name:
			var new_item := transform_item(item)
			if new_item:
				return new_item
	return null

func transform_items_by_name(item_name: String):
	var success := true
	while success:
		success = !!transform_one_item_by_name(item_name)

func find_repairable_item() -> Item:
	for item in _items:
		var item_data: Dictionary = item.get_data()
		if item_data.get("repairable", false) and item_data.get("transform", "") != "":
			if item_data.has("repairiq"):
				for member in item_data["repairiq"]:
					var party_member = global.get_party_member_in_party(member)
					if party_member and party_member.get_stat("iq") >= item_data["repairiq"][member]:
						return item
			else:
				return item
	return null

func repair_one_item() -> Item:
	for item in _items:
		if item.get_data().get("repairable", false):
			var new_item := transform_item(item)
			if new_item:
				return new_item
	return null

func find_all_occurrences(item_name: String) -> Array:
	var ret := []
	for item in _items:
		if item.item_name == item_name:
			ret.append(item)
	return ret

func switch_items(item1_idx: int, item2_idx: int):
	var item1 = get_items()[item1_idx]
	var item2 = get_items()[item2_idx]
	
	get_items()[item2_idx] = item1
	get_items()[item1_idx] = item2

func swap_between_characters(source_item: Item, target: Character, target_item: Item):
	drop_item(source_item)
	add_item(target_item)
	target.inv.drop_item(target_item)
	target.inv.add_item(source_item)

func consume_item(item: Item, receiver: Character) -> Dictionary:
	var item_name = item.item_name
	var item_data = item.get_data()
	
	var is_reusable = item_data.get("reusable", false)
	var performed_actions := {}
	
	if int(item_data["HPrecover"]) > 0:
		receiver.set_hp(receiver.get_hp() + int(item_data["HPrecover"]))
		if receiver.get_hp() >= receiver.get_stat(Character.MAXHP):
			performed_actions[Item.ItemActions.HP_MAX] = true
		else:
			performed_actions[Item.ItemActions.HP_UP] = int(item_data["HPrecover"])
	
	if int(item_data["PPrecover"]) > 0 and receiver.get_stat(Character.MAXPP) > 0:
		receiver.set_pp(receiver.get_pp() + int(item_data["PPrecover"]))
		if receiver.get_pp() >= receiver.get_stat(Character.MAXPP):
			performed_actions[Item.ItemActions.PP_MAX] = true
		else:
			performed_actions[Item.ItemActions.PP_UP] = int(item_data["PPrecover"])
	
	
	var status_heals = item_data.get("status_heals", [])
	if status_heals.has("all"): status_heals = ["asthma", "blinded", "burned", "cold", "confused", "forgetful", "mushroomized", "nausea", "numb", "poisoned", "sleeping", "stone", "sunstroked", "unconscious"]
	for status in status_heals:
		if receiver.has_status(status):
			performed_actions[Item.ItemActions.HEAL] = performed_actions.get(Item.ItemActions.HEAL, [])
			performed_actions[Item.ItemActions.HEAL].append(status)
			receiver.remove_status(status)
		else:
			performed_actions[Item.ItemActions.HEAL_FAIL] = performed_actions.get(Item.ItemActions.HEAL_FAIL, [])
			performed_actions[Item.ItemActions.HEAL_FAIL].append(status)
	
	receiver.apply_boosts(item_data["boost"], performed_actions)
	
	
	
	if !is_reusable:
		reduce_or_drop_item(item)

	return performed_actions


#####################################################################
######################### INVENTORY HOLDERS #########################
#####################################################################

class AbstractInventoryHolder:
	var _inventory
	var inv setget , get_inventory

	func _init(inventory):
		_inventory = inventory

	func get_inventory():
		return _inventory

static func get_inventory_holder(holder_name: String):
	return globaldata.characters[holder_name] if holder_name in globaldata.characters else AbstractInventoryHolder.new(globaldata.get(holder_name))





#####################################################################
########################## STATIC  METHODS ##########################
#####################################################################

static func get_boost_total(item_boost) -> int:
	var total = 0
	for stat in BOOSTABLE_STATS_COEFFS:
		total += item_boost.get(stat, 0) * BOOSTABLE_STATS_COEFFS[stat]
	
	return total

static func _get_all_inventories(include_storage := false, include_keys := true) -> Array:
	var inventories := []
	for member in global.party:
		inventories.append(member.inv)
	if include_keys:
		inventories.append(globaldata.key_items)
	if include_storage:
		inventories.append(globaldata.storage)
	return inventories

static func find_item_for_all(item_name: String) -> Item:
	for inv in _get_all_inventories():
		var item: Item = inv.find_item(item_name)
		if item != null:
			return item
	return null

static func party_has_item(item_name: String) -> bool:
	return !!find_item_for_all(item_name)

static func find_all_in_inventories(item_name: String) -> Array:
	var ret := []
	for inv in _get_all_inventories():
		ret.append_array(inv.find_all_occurrences(item_name))
	return ret

static func get_item_owner(item: Item, default_as_leader := false): # -> PartyMember
	if globaldata.key_items.get_items().has(item):
		return global.party[0] if default_as_leader else get_inventory_holder(INV_NAME_KEY)
	for chara in globaldata.characters.values():
		if "inv" in chara and item in chara.inv.get_items():
			return chara
	return null

# Test if party has space in inventory
static func has_inventory_space() -> bool:
	for inv in _get_all_inventories(false, false):
		if !inv.is_full():
			return true
	return false

static func add_item_available(item_name: String) -> Item:
	var item_data = globaldata.get_item_data(item_name)
	if item_data.get("keyitem", false):
		return globaldata.key_items.add_item_by_name(item_name)
	elif has_inventory_space():
		for member in global.party:
			var inv = member.inv
			if !inv.is_full():
				return inv.add_item_by_name(item_name)
	return null

static func reduce_or_drop_item_for_all(item: Item):
	get_item_owner(item).inv.reduce_or_drop_item(item)

static func remove_item_from_party(item_name: String) -> bool:
	for inv in _get_all_inventories():
		var res = inv.remove_item_by_name(item_name)
		if res:
			return true
	return false

static func drop_item_from_party(item: Item) -> bool:
	var owner = get_item_owner(item)
	return owner.inv.drop_item(item) if owner and "inv" in owner else false

static func transform_items_for_all(item_name: String):
	for inv in _get_all_inventories():
		inv.transform_items_by_name(item_name)

static func get_phone_units() -> int:
	var all_phone_cards: Array = find_all_in_inventories("PhoneCard")
	var sum := 0
	for card in all_phone_cards:
		sum += (card as Item).doses
	return sum

static func is_map_possessed(region: String) -> bool:
	for inv in _get_all_inventories():
		for item in inv.get_items():
			if item.get_data().get("map_for") == region:
				return true
	return false

#####################################################################
############################# EQUIPMENT #############################
#####################################################################

func get_equipment() -> Dictionary:
	var ret := {}
	for slot in SLOTS:
		ret[slot] = get_equipped_item(slot)
	return ret

func get_equipped_item(slot: String) -> Item:
	for item in _items:
		if item.equipped:
			var item_data = item.get_data()
			if item_data["slot"] == slot:
				return item
	return null

# Equip when equippable (current character) maybe another system?
func equip_item(item: Item) -> bool:
	var item_data = item.get_data()
	if item.is_equippable():
		var old_equipped = get_equipped_item(item_data["slot"])
		if old_equipped != null:
			# Unequip item if needed
			unequip(old_equipped)
		item.equipped = true
		return true
	else:
		return false

# Unequip item from character name and item name
func unequip(item: Item) -> bool:
	if item.equipped:
		item.equipped = false
		return true
	else:
		return false
		
# Unequip item in a slot
func unequip_slot(slot: String):
	var item = get_equipped_item(slot)
	if item: unequip(item)

func get_equipment_boosts() -> Dictionary:
	var total_boosts := {}
	for slot in SLOTS:
		var item = get_equipped_item(slot)
		if item != null:
			var item_data = item.get_data()
			var item_boosts = item_data["boost"]
			for boost in item_boosts.keys():
				total_boosts[boost] = total_boosts.get(boost, 0) + item_boosts[boost]
	return total_boosts

func calculate_stats_boost_from_slot(slot: String) -> Dictionary:
	var boost := {}
	for stat in Character.BOOSTABLE_STATS:
		var add_boost := 0
		var equipment_in_slot = get_equipped_item(slot)
		if equipment_in_slot:
			var item_data = equipment_in_slot.get_data()
			add_boost = item_data["boost"].get(stat, 0)
		boost[stat] = boost.get(stat, 0) + add_boost
	return boost

class_name Item

enum ItemActions { HP_UP, PP_UP, HP_MAX, PP_MAX, STAT_UP, HEAL, HEAL_FAIL }

#existing IUDs to prevent having several items with same IUD
const used_uids_tab := []

var item_name: String
var uid: int
var equipped: bool
var doses: int # how many times it can be consumed

func _ready():
	pass

func _init(item_name: String, equipped := false, doses := -1, uid := get_uid(used_uids_tab)):
	self.item_name = item_name
	self.equipped = equipped
	self.uid = uid
	self.doses = doses
	if doses == -1:
		self.doses = get_data().get("doses", 1)

func get_data() -> Dictionary:
	return globaldata.get_item_data(item_name)

func is_equippable() -> bool:
	return _has_function("equip")

static func get_uid(used_uids) -> int:
	randomize()
	var new_uid = randi()
	while(new_uid in used_uids):
		new_uid = randi()
	used_uids.append(new_uid)
	return new_uid

func _has_function(function: String) -> bool:
	var item_data = globaldata.get_item_data(item_name)
	for action in item_data.get("actions", []):
		if action["function"] == function:
			return true
	return false

func to_dict() -> Dictionary:
	return {"item_name": item_name, "equipped": equipped, "doses": doses, "uid": uid}

func is_healing_item() -> bool:
	var item_data := get_data()
	return (item_data.get("HPrecover", 0) > 0 and item_data.get("boost", {}).get("maxhp", 0) == 0) or\
			(item_data.get("PPrecover", 0) > 0 and item_data.get("boost", {}).get("maxpp", 0) == 0) or\
			!item_data.get("status_heals", []).empty()

func is_battle_usable() -> bool:
	var item_data := get_data()
	return is_healing_item() or\
			(is_equippable() and !equipped) or\
			item_data.has("battle_action")

func is_battle_consumable() -> bool:
	var item_data := get_data()
	return !item_data.get("battle_action", {}).get("reusable", false) and\
			(is_healing_item() or\
			item_data.has("battle_action"))

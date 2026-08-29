class_name DialogueTestingTools

const DEFAULT_ITEM_IDS := ["Antidote", "AsthmaSpray", "BaseballCap", "BatAluminum", "BatHank", "BatOld", "BatPlastic", "BatWooden", "BeamLaser", "BeamPlasma", "BigBag", "Bomb", "BombSuper", "Boomerang", "BottleRocket", "BottleRocketBig", "BottleRocketMulti", "Bread", "Bullhorn", "CanaryChick", "CapsuleDEF", "CapsuleGUT", "CapsuleHP", "CapsuleIQ", "CapsuleOFE", "CapsulePP", "CapsuleSPD", "CashCard", "CoinMagic", "CoinPeace", "CoinProtect", "CourageBadge", "Crumbs", "Dentures", "DogTreats", "EagleFeather", "Error", "EyeDrops", "FlameThrower", "FlashDark", "FleaBag", "FranklinBadge", "FranklinBadge0.8", "Fries", "GGFDiary", "GhostHouseKey", "GunAir", "GunStun", "Hamburger", "Hat", "HerbMagic", "HerbRed", "HotDog", "Insecticide", "IronSkillet", "Katana", "KeyBasement", "KeyZoo", "KnifeButter", "KnifeSurvival", "LastWeapon", "LifeUpCream", "MagicCandy", "MagicRibbon", "MapPodunk", "MemoryChip", "Milk", "Mouthwash", "NobleSeed", "Ocarina", "OnyxHook", "OrangeJuice", "PanFrying", "PanNonStick", "Pass", "PendantEarth", "PendantFire", "PendantH2O", "PendantSea", "PhoneCard", "PSIStone", "RealRocket", "RedBandana", "RepelRing", "RingBrass", "RingGold", "RingSilver", "Rope", "Ruler", "Shovel", "Slingshot", "SlingshotBionic", "SportsDrink", "StickyMachine", "StrawberryTofu", "SuperSpray", "Sword", "Ticket", "TicketStub", "WordsLove", "WordsSwear"]
const GAMEPAD_BUTTON_NAMES = ["Share", "Select", "Optns", "Start"]

const _items_list := []

var _font: Font

func _init(font: Font):
	_font = font
	_build_items_list()

func _build_items_list():
	_items_list.clear()
	var item_ids := []
	var dir := Directory.new()
	if dir.open("res://Data/Items/") == OK:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".yaml") or file_name.ends_with(".json"):
				item_ids.append(file_name.left(file_name.length() - 5))
			file_name = dir.get_next()
	if !item_ids:
		item_ids = DEFAULT_ITEM_IDS
	for item_id in item_ids:
		var item := {}
		if globaldata.does_item_exist(item_id):
			item = globaldata.get_item_data(item_id)
		else:
			item["name"] = item_id.to_upper() + "_NAME"
			item["article"] = item_id.to_upper() + "_ART"
		_items_list.append(item)

func get_random_item() -> Item:
	return Item.new(_items_list[randi() % _items_list.size()].id)

func find_longest_item() -> String:
	return find_longest_in_array(_items_list, "name", true)

func find_longest_in_array(array: Array, field_name := "", translate := false) -> String:
	var longest: String
	var longest_width := 0
	for elt in array:
		var string: String
		if field_name:
			string = elt.call(field_name) if elt is Object else elt[field_name]
		else: string = elt
		if translate: string = tr(string)
		var string_width = _font.get_string_size(string).x
		if string_width > longest_width:
			longest = elt.id if elt is Dictionary else elt
			longest_width = string_width
	return longest


func replace_key_names(string: String, longest_mode := false, device: int = globaldata.device) -> String:
	var start_index := 0
	var regex := RegEx.new()
	regex.compile("\\[([A-Za-z_@]+)\\]")
	var tag := regex.search(string)
	
	while tag:
		var result := tag.get_string()
		var tag_content := tag.get_string(1).to_lower()
		var str_before := string.substr(0, tag.get_start())
		var str_after := string.substr(tag.get_end())
		if tag_content.begins_with("ui_"):
			result = _find_longest_key_name(device) if longest_mode else TextTools.get_key_name(tag_content, device)
		else:
			start_index = tag.get_start() + 1
		string = str_before + result + str_after
		tag = regex.search(string, start_index)
	return string

func _find_longest_key_name(device: int = globaldata.device) -> String:
	var list_of_keys := GAMEPAD_BUTTON_NAMES if device == globaldata.GAMEPAD else globaldata.ALLOWED_KEYS
	var list_of_key_names := []
	for key in list_of_keys:
		var key_name := TextTools.get_key_from_scancode(key) if device == globaldata.KEYBOARD else key
		list_of_key_names.append(key_name)
	return find_longest_in_array(list_of_key_names)

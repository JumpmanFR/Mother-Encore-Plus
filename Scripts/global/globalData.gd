extends Node

enum BtnStyles {NINTENDO, PLAYSTATION, XBOX, DETECT}
enum {KEYBOARD, GAMEPAD}

# Special known data
const SKILL_GUARD := "guard"
const SKILL_BASH := "bash" # Basic move for enemies
const SKILL_ATTACK := "attack" # Basic move for party members
const SKILL_SPY := "spy"
const SKILL_TELEPATHY := "telepathy"
const SKILL_TELEPORT_A := "teleportA"

const ALLOWED_KEYS := [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_KP_MULTIPLY, KEY_KP_DIVIDE, KEY_KP_SUBTRACT, KEY_KP_PERIOD, KEY_KP_ADD, KEY_KP_0, KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4, KEY_KP_5, KEY_KP_6, KEY_KP_7, KEY_KP_8, KEY_KP_9, KEY_SPACE, KEY_ESCAPE, KEY_TAB, KEY_BACKSPACE, KEY_ENTER, KEY_INSERT, KEY_DELETE, KEY_PAUSE, KEY_HOME, KEY_END, KEY_PAGEUP, KEY_PAGEDOWN, KEY_SHIFT, KEY_CONTROL, KEY_META, KEY_ALT, KEY_SUPER_L, KEY_SUPER_R, KEY_MENU, KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11, KEY_F12, KEY_F13, KEY_F14, KEY_F15, KEY_F16]
const TEXT_SPEEDS := [0.02, 0.028, 0.035]
const TEXT_SPEEDS_NAMES := ["FAST", "MEDIUM", "SLOW"]
const BUTTON_PROMPTS := ["Both", "Objects", "NPCs", "None"]
const FLAVORS := ["Plain", "Mint", "Strawberry", "Banana", "Peanut", "Grape", "Melon"]
const LANG_ALT := "upupdodolerilericaac"

var save_file := 0
var playtime := 0
var win_size := 3
var master_volume := 0
var music_volume := 0
var sfx_volume := 0
var earned_cash := 0
var cash := 10000
var bank := 0
var respawn_point := Vector2.ZERO
var respawn_run_sound := "wood"
var respawn_shadow_effect := "shadow"
var respawn_scene := ""
var description := true
var rumble := true
var favorite_food := "Oreos"
var menu_flavor: String = FLAVORS[0]
var text_speed: float = TEXT_SPEEDS[0] setget _set_text_speed, _get_text_speed
var button_prompts: String = BUTTON_PROMPTS[0]
var player_name := ""
var rare_drops := {}
var buttons_style: int = BtnStyles.DETECT
var encountered := {}
var device := KEYBOARD

var characters := {
	PartyMember.NINTEN: PartyMember.new(),
	PartyMember.ANA: PartyMember.new(),
	PartyMember.LLOYD: PartyMember.new(),
	PartyMember.TEDDY: PartyMember.new(),
	PartyMember.PIPPI: PartyMember.new(),
	PartyNPC.CANARY_CHICK: PartyNPC.new(),
	PartyNPC.FLYING_MAN: PartyNPC.new(),
	PartyNPC.EVE: PartyNPC.new()
}

var key_items := Inventory.new(Inventory.InvType.KEY)
var storage := Inventory.new(Inventory.InvType.STORAGE)
var god_storage: Inventory

const _battle_skills := {}
const _field_skills := {}
const _passive_skills := {}
const _items := {}
const _status_ailments := {}
const _shop_lists := {}

var keys := {}

var object_flags := {}
var seen_dialogue_flags := {}

var flags := {}

# TO REMOVE
func _test_all_yaml():
	var test_dict := {}

	var types := ["Animations", "Battlers", "BattleScripts", "BattleSkills", "Dialogue", "FieldSkills", "Items", "MapMarkers", "NamingSequences", "PassiveSkills", "Shops", "StatusAilments"]

	for key in types:
		test_dict[key] = {}
		_load_data("res://Data/%s/" % key, test_dict[key])
		for sub_key in test_dict[key]:
			print("== %s ==" % sub_key)
			print(test_dict[key][sub_key])
			print("")


func _init():
	_init_flags()

	var to_load := {
		"BattleSkills": _battle_skills,
		"FieldSkills": _field_skills,
		"PassiveSkills": _passive_skills,
		"Shops": _shop_lists,
		"Items": _items,
		"StatusAilments": _status_ailments
	}
	for key in to_load:
		_load_data("res://Data/%s/" % key, to_load[key])
	
func _ready():
	god_storage = Inventory.new(Inventory.InvType.STORAGE_GOD)
	#get_all_text()

#func get_all_text():
#	var file := File.new()
#	if file.file_exists("res://Translations/TranslatedText/keys.txt"):
#		file.open("res://Translations/TranslatedText/keys.txt", File.READ)
#		var csv_file
#		while !file.eof_reached():
#			var key = file.get_line()
#			if key != "":
#				if key.begins_with("#"):
#					var csv_file_name = key.trim_prefix("#").strip_edges()
#					csv_file = File.new()
#					csv_file.open("res://Translations/%s - sheet.txt" % csv_file_name, File.WRITE)
#					csv_file.store_line("key,%s" % ",".join(global.LANGUAGES))
#				else:
#					var entry_en
#					#var csv_line = key
#					var csv_line = PoolStringArray([key])
#					var has_entries = false
#					for lang in global.LANGUAGES:
#						TranslationServer.set_locale(lang)
#						var entry = tr(key)
#						if lang == global.LANGUAGES[0]:
#							entry_en = entry
#						else:
#							if entry == entry_en:
#								entry = ""
#						
#						if entry != key:
#							has_entries = true
#
#						entry = entry.replace("\n", "\\n")
#						#if "," in entry:
#						#	entry = "\"%s\"" % entry
#						#csv_line += ",%s" % entry
#						csv_line.append(entry)
#					if csv_file:
#						csv_file.store_csv_line(csv_line)
#					#print(csv_line)
#					if !has_entries:
#						print("No entries for key: %s" % key)
#	else:
#		print("Couldn’t find keys.txt file")

func _init_flags():
	var flag_names := [
		#===GLOBAL===
		#Melodies
		"doll_melody",
		"canary_melody",
		"monkey_melody",
		"piano_melody",
		"cactus_melody",
		"dragon_melody",
		"eve_melody",
		"grave_melody",

		#Abilities
		"switch_leader",
		"bat",
		"energy_beam",
		"eagle_feather",
		"used_encore",
		
		
		#Misc
		"earned_cash",
		"good_morning",
		"saved",

		#Debug
		"npc_disappear_1",
		"npc_dialog_1",
		"npc_dialog_2",
		
		#Exploration
		"visited_podunk",
		"visited_magicant",
		"visited_merrysville",
		"visited_twinkle_elementary",
		"visited_reindeer",
		"visited_spookane",
		"visited_snowman",
		"visited_yucca",
		"visited_youngtown",
		"visited_ellay",
		"visited_mtitoi",
		
		#===ACT 1===
		#Ninten's House
		
		"pippi_reunion",
		"pippi_met_lloyd",
		"pippi_met_ana",
		"pippi_met_teddy",
		"pippi_rocket",
		
		
		"lloyd_magicant",
		"ana_magicant",
		"teddy_magicant",
		
		
		
		"poltergeist",
		"mimmie_door_opened",
		"doll_attack",
		"pillow_attack",
		"minnie_leave",
		"minnie_door",
		"doll_defeated",
		"phone_ring",
		"talked_to_dad",
		"mimmie_ask_key",
		"carol_ask_key",
		"mick_scratch",
		"mick_telepathy",
		"ninten_basement_door",
		"got_juice",
		"got_diary",
		"got_dog_treats",
		"got_asthma_spray",
		"gave_treats",

		#Podunk
		"beat_dog_bridge",
		"pippis_mom_call",
		"pippis_mom_help",

		#Podunk Cemetery
		"disguised_zombie_defeated",
		"cem_roots_grown",
		"got_shovel",
		"returned_shovel",

		#Podunk Catacombs
		"hidden_entrance_opened",
		"pippi_fight",
		"pippi_fought",
		"pippi_rescued",
		"courage_badge_received",
		"church_door_opened",
		"church_exited",
		
		#Return to podunk
		"canary_found",
		"wally_attack",
		"wally_fought",
		"wally_defeat",
		"pippi_reunite",
		"alfred_song",
		"leave_canary_village",
		"pippi_delivered",

		#Zoo
		"zoo_key_stolen",
		"starman_jr_fought",
		"zoo_freed",
		"monkey_apologize",
		"guard_moved",
		"ninten_family_goodbye",
		
		
		
		#===ACT 2===
		
		#Magicant
		"got_magic_candy",
		"got_magic_ribbon",
		"lent_cash_card",
		"got_big_bag",
		"met_happiness_guy",
		"met_guy_who_talks_about_how_you_cant_part_if_you_havent_met",
		"got_nicknamed",
		"slept_at_spoon_guys_place",
		"guard_riddle_solved",
		"fountain_scouts_met",
		"marys_story_learned",
		"enteredwell",
		"first_flying_man",
		"flying_man_in_party",
		"flying_man_1_joined",
		"flying_man_2_joined",
		"flying_man_3_joined",
		"flying_man_4_joined",
		"flying_man_5_joined",

		"onyx_hook_found",
		"fish_attack",
		"fish_defeat",
		
		"forgotten_man_1",
		"forgotten_man_2",
		"forgotten_man_3",
		"forgotten_man_4",
		"forgotten_man_5",

		#Merrysville
		
		
		"roof_door_checked",
		"janitor_cutscene_finished",
		"lloyd_roof_1",
		
		
		"rat_king_1",
		"rat_king_2",
		"sweet_factory_key_1",
		"got_br_wings",
		"got_br_head",
		"br_progress_1",
		"br_progress_1_arrived",
		"br_wings_attached",
		"br_progress_2",
		"br_progress_2_arrived",
		"br_head_attached",
		"br_progress_3",
		"br_progress_3_arrived",
		"br_finishing_touch",
		"rat_king_attack",
		"rat_king_defeat",
		"rat_king_disappear",
		"bottle_rocket_found",
		"sweet_factory_bomb_chain",
		"sweet_factory_exit_open",

		"lloyd_befriended",
		"lab_destroyed",
		"missile_explosion",
		"missile_damage_seen",
		"weird_teacher_appear",
		"weird_teacher_alt_dialogue",
		"got_factory_pass",
		
		#Duncan's Factory
		
		"guard_dog_beaten",
		"drdistorto_1",
		"drdistorto_2",
		"drdistorto_3",
		"drdistorto_4",
		"computer_left_hacked",
		"computer_right_hacked",
		"computers_all_hacked",
		"franklin_badge_found",
		"drdistorto_attack",
		"drdistorto_defeat",
		"rocket_launched",
		"drdistorto_disappear",
		
		"lloyd_kitchen",
		"fixed_merrysville_road_bridge",
		"lloyd_mom_goodbye",
		"train_to_reindeer",
		
		
		
		"magicant_second_visit",
		"magicant_third_visit",
		"magicant_fourth_visit",
		"magicant_fifth_visit",
		"magicant_sixth_visit"
	]


	for flag in flag_names:
		flags[flag] = false

func _load_data(path: String, dest: Dictionary, sub_dir: String = ""):
	var dir = Directory.new()
	if dir.open(path) != OK:
		print("An error occurred when trying to access %s." % path)
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if not file_name in [".", ".."]:
				_load_data("%s%s/" % [path, file_name], dest, "%s%s/" % [sub_dir, file_name])
		else:
			if file_name.ends_with(".yaml"):
				var json_data = get_json_data(path + file_name)
				dest[sub_dir + file_name.trim_suffix(".yaml")] = json_data
		file_name = dir.get_next()

func get_json_data(file_path: String, fallback: String = "") -> Dictionary:
	#print("get_json_data: %s" % file_path)
	var file := File.new()
	if file.file_exists(file_path):
		file.open(file_path, File.READ)
		var file_content := file.get_as_text()
		var res = YAMLParser.parse_file(file_path)
		if res == null:
			push_warning("Couldn’t parse yaml file at %s" % file_path)
			return {}
		return res
	else:
		if fallback:
			return get_json_data(fallback)
		else:
			push_warning("Couldn’t find yaml file at %s" % file_path)
			return {}

func check_appear_disappear_flags(appear_flag: String, disappear_flag: String) -> bool:
	var flag_on := true
	if appear_flag != "":
		flag_on = flags.get(appear_flag, false)
	if disappear_flag != "":
		flag_on = flag_on and !flags.get(disappear_flag, false)
	return flag_on

####################### VAR GETTERS, SETTERS #######################


func _set_text_speed(value: float) -> void :
	if value <= 0:
		text_speed = TEXT_SPEEDS[TEXT_SPEEDS.size() / 2]
		return
	# Finding the closest text speed
	var closest: = 0.0
	var smallest_delta: = 1.0
	for s in TEXT_SPEEDS:
		if abs(s - value) < smallest_delta:
			smallest_delta = abs(s - value)
			closest = s
	text_speed = closest

func _get_text_speed() -> float:
	return text_speed

func set_flag(flag_name: String, value: bool, emit_signal := true):
	if flags.has(flag_name):
		flags[flag_name] = value
		if emit_signal: global.emit_signal("flags_updated")

func set_object_flag(flag_name: String, value: bool, emit_signal := true):
	object_flags[flag_name] = value
	if emit_signal: global.emit_signal("flags_updated")



########################### DATA GETTERS ###########################

# AILMENTS
func get_ailment_data(ailment_name: String) -> Dictionary:
	var ailment_data: Dictionary = _status_ailments.get(ailment_name, {})
	if ailment_data: ailment_data["id"] = ailment_name
	else: push_warning("ERROR: The status effect “%s” doesn’t exist!" % ailment_name)
	return ailment_data

func does_ailment_exist(ailment_name: String) -> bool:
	return !!_status_ailments.get(ailment_name)

func get_all_ailments() -> Array:
	return _status_ailments.keys()

# ITEMS
func get_item_data(item_name: String) -> Dictionary:
	var item_data: Dictionary = _items.get(item_name, {})
	if item_data: item_data["id"] = item_name
	else: push_warning("ERROR: The item “%s” doesn’t exist!" % item_name)
	return item_data

func does_item_exist(item_name: String) -> bool:
	return _items.has(item_name)

func get_all_items() -> Array:
	return _items.keys()

# ENEMIES
func get_enemy_data(enemy_name: String) -> Dictionary:
	var ret: Dictionary = get_json_data("res://Data/Battlers/%s.yaml" % enemy_name)
	if ret: ret["id"] = enemy_name
	else: push_warning("ERROR: The enemy “%s” doesn’t exist!" % enemy_name)
	return ret

# SHOPS
func get_shop_data(shop_name: String) -> Array:
	var shop_data: Array = _shop_lists.get(shop_name, [])
	if !shop_data: push_warning("ERROR: The shop “%s” doesn’t exist!" % shop_name)
	return shop_data

# NAMING
func get_naming_sequence(name: String) -> Dictionary:
	var ret: Dictionary = get_json_data("res://Data/NamingSequences/%s.yaml" % name)
	if ret:
		ret["id"] = name
	return ret

# BATTLE SKILLS
func get_battle_skill(skill_name: String) -> Dictionary:
	var skill_data: Dictionary = _battle_skills.get(skill_name, {})
	if skill_data:
		skill_data["id"] = skill_name
	else:
		push_warning("ERROR: The battle skill “%s” doesn’t exist!" % skill_name)
	return skill_data

func does_battle_skill_exist(skill_name: String) -> bool:
	return _battle_skills.has(skill_name)

func get_all_battle_skills() -> Array:
	return _battle_skills.keys()

# PASSIVE SKILLS
func get_passive_skill(skill_name: String) -> Dictionary:
	var skill_data: Dictionary = _passive_skills.get(skill_name, {})
	if skill_data: skill_data["id"] = skill_name
	else: push_warning("ERROR: The passive skill “%s” doesn’t exist!" % skill_name)
	return skill_data

# FIELD SKILLS
func get_field_skill(skill_name: String) -> Dictionary:
	var skill_data: Dictionary = _field_skills.get(skill_name, {})
	if skill_data: skill_data["id"] = skill_name
	else: push_warning("ERROR: The field skill “%s” doesn’t exist!" % skill_name)
	return skill_data

func get_all_field_skills() -> Array:
	return _field_skills.keys()

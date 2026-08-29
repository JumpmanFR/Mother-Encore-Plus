extends Character
class_name PartyMember

const LEVEL_CAP := 30

const NINTEN := "ninten"
const ANA := "ana"
const LLOYD := "lloyd"
const TEDDY := "teddy"
const PIPPI := "pippi"

var _nickname: String
var _learned_skills := []
var _inventory: Inventory
var _permanent_boosts := { }
 
var inv: Inventory setget ,get_inventory

####################################################################
#################### STATIC PARTY-RELATED STUFF ####################
####################################################################

# The stat target table is a dictionary with stats that each have an array
# Each stat array represents where a stat should be at that (index * 10) level
# e.g. Ninten's offense at level 30 would be in index 3, the 4th number in the array
#      Level 30 - Offense Stat target is 49
const PLAYER_STAT_TARGET_TABLE := {
	NINTEN: {
		MAXHP: [60, 88, 121, 160, 205, 254, 308, 365, 425, 487, 550],
		MAXPP: [25, 38, 54, 73, 94, 118, 144, 171, 200, 230, 260],
		OFFENSE: [10, 21, 34, 49, 66, 85, 106, 128, 152, 176, 200],
		DEFENSE: [7, 11, 16, 21, 28, 36, 44, 52, 61, 71, 80],
		SPEED: [6, 10, 15, 21, 28, 35, 43, 52, 61, 70, 80],
		IQ:  [5, 11, 18, 26, 36, 47, 58, 70, 83, 97, 110],
		GUTS: [8, 10, 13, 17, 20, 25, 29, 34, 39, 44, 50],
	},
	ANA: {
		MAXHP: [40, 65, 95, 130, 170, 214, 263, 314, 368, 424, 480],
		MAXPP: [30, 47, 69, 93, 122, 153, 187, 223, 261, 300, 340],
		OFFENSE: [6, 12, 19, 27, 37, 47, 59, 71, 84, 97, 140],
		DEFENSE: [3, 6, 11, 16, 21, 28, 34, 42, 49, 57, 65],
		SPEED: [8, 12, 18, 24, 31, 40, 48, 58, 67, 78, 88],
		IQ:  [8, 14, 22, 31, 41, 52, 65, 78, 91, 106, 120],
		GUTS: [6, 8, 10, 13, 16, 19, 23, 27, 31, 35, 40],
	},
	LLOYD: {
		MAXHP: [80, 109, 145, 186, 234, 286, 343, 404, 467, 533, 600], 
		MAXPP: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 
		OFFENSE: [2, 6, 10, 16, 22, 29, 36, 44, 53, 61, 70], 
		DEFENSE: [10, 14, 20, 26, 34, 42, 50, 60, 69, 80, 90], 
		SPEED: [10, 15, 21, 27, 35, 44, 53, 63, 73, 84, 95], 
		IQ: [10, 18, 29, 41, 54, 69, 86, 103, 122, 141, 160], 
		#GUTS: [3, 5, 6, 9, 11, 14, 17, 20, 23, 27, 30],
		GUTS: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	},
	
	TEDDY: {
		MAXHP: [80, 111, 150, 195, 245, 302, 363, 429, 497, 568, 640],
		MAXPP: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		OFFENSE: [8, 20, 34, 51, 71, 92, 115, 140, 166, 193, 220],
		DEFENSE: [10, 16, 22, 30, 40, 50, 61, 72, 85, 97, 110],
		SPEED: [10, 15, 21, 29, 38, 48, 58, 69, 81, 93, 105],
		IQ:  [3, 8, 14, 21, 29, 37, 47, 57, 68, 79, 90],
		GUTS: [8, 11, 14, 19, 23, 29, 34, 40, 47, 53, 60],
	},
	PIPPI: {
		MAXHP: [80, 111, 150, 195, 245, 302, 363, 429, 497, 568, 640],
		MAXPP: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		OFFENSE: [8, 20, 34, 51, 71, 92, 115, 140, 166, 193, 220],
		DEFENSE: [10, 16, 22, 30, 40, 50, 61, 72, 85, 97, 110],
		SPEED: [10, 15, 21, 29, 38, 48, 58, 69, 81, 93, 105],
		IQ:  [3, 8, 14, 21, 29, 37, 47, 57, 68, 79, 90],
		GUTS: [8, 11, 14, 19, 23, 29, 34, 40, 47, 53, 60],
	},
}

const PLAYER_LEARN_SKILL_TABLE_FLAGS := {
	NINTEN: {
	},
	LLOYD: {
		
	},
	ANA: {
	},
	PIPPI: {
		
	},
	TEDDY: {
		
	}
}

const PLAYER_LEARN_SKILL_TABLE := {
	NINTEN: {
		
		2: ["telepathy"],
		3: ["speedUpA"],
		4: ["healingA"],
		6: ["courage"],
		7: ["offenseUpA"],
		8: ["defenseUpA"],
		
		11: ["curveball", "ricochet"],
		13: ["darknessA"],
		
		16: ["battingAThousand", "ballFlame"],
		17: ["hypnosisA"],
		
		18: ["lifeUpB"],
		19: ["shieldA"],
		
		21: ["healingB"],
	},
	LLOYD: {
		1: ["spy"]
	},
	ANA: {
		5: ["pkFreezeA"],
		7: ["pkFireA"]
	},
	PIPPI: {
		
	},
	TEDDY: {
		
	}
}

const SKILLS_ORDER := [
	"courage", "pepTalk", "strike", "curveball", "battingAThousand", "homerun", "bunt", "return", "splitShot", "ricochet", "ballFlame", "ballPoison", "ballWeb", "ballMeteor", # Ninten’s skills
	"spy", "copyCamera", "stickyMachine", "flameThrower", "hpSucker", "bellGun", "psiCounterUnit", "defenseShower", "shieldKiller", "heavyBazooka", # Lloyd’s skills
	"pray", "meditate", # Ana’s skills
	"revenge", "powerSmash", "deadlyBlow", "flex", "toughen", "swearWords", "wordsOfLove", "smoke", # Teddy’s skills
	"telepathy", "teleportA", "teleportO", # Field PSI skills
	"pkFireA", "pkFireB", "pkFireG", "pkFireO", "pkFreezeA", "pkFreezeB", "pkFreezeG", "pkFreezeO", "pkThunderA", "pkThunderB", "pkThunderG", "pkThunderO", "pkBeamA", "pkBeamB", "pkBeamG", "pkBeamO", "pkFlashA", "pkFlashO", # Offensive PSI skills
	"lifeUpA", "lifeUpB", "lifeUpG", "lifeUpO", "healingA", "healingB", "healingG", "healingO", "psiMagnetA", "psiMagnetO", # Recovery PSI skills
	"shieldA", "shieldO", "counterA", "counterO", "psiShieldA", "psiShieldO", "psiCounterA", "psiCounterO", "offenseUpA", "offenseUpO", "offenseDownA", "offenseDownO", "defenseUpA", "defenseUpO", "defenseDownA", "defenseDownO", "speedUpA", "speedUpO", "speedDownA", "speedDownO", "hypnosisA", "hypnosisO", "darknessA", "darknessO", "brainshockA", "brainshockO", "paralysisA", "paralysisO", "shieldOff", "psiBlock", "4thDSlip" # Assist PSI skills
]


static func _level_to_exp(level: int) -> int:
	return 0 if level == 1 else _level_to_exp(LEVEL_CAP) if level > LEVEL_CAP else int(level * level * (level + 1) * 0.75)

static func _exp_to_level(xp: int) -> int:
	var level := 1
	while xp >= _level_to_exp(level + 1) and level < LEVEL_CAP:
		level += 1
	return level


#####################################################################
################### SERIALIZATION/DESERIALIZATION ###################
#####################################################################

func _init(data := {}):
	if data:
		init_from_dict(data)

# Override
func to_dict() -> Dictionary:
	return {
		"nickname": _nickname,
		"level": _level,
		"exp": _exp,
		"hp": _hp,
		"pp": _pp,
		"permanent_boosts": _permanent_boosts,
		"affinity_multipliers": _affinity_multipliers,
		"learnedSkills": _learned_skills,
		"inventory": _inventory.to_array(),
		"status": status_to_array()
	}

# Override
func init_from_dict(dict: Dictionary):
	_inventory = Inventory.new(Inventory.InvType.NORMAL, dict.get("inventory", []))
	_name = dict["name"]
	_set_exp(max(dict["exp"], _level_to_exp(dict["level"])) as int, false)
	_status_init_from_dict(dict)
	
	_nickname = dict.get("nickname", _name)
	_learned_skills = dict.get("learnedSkills", [])
	_permanent_boosts = dict.get("permanent_boosts", {})
	_affinity_multipliers = dict.get("affinity_multipliers", {})
	
	set_hp(dict["hp"])
	set_pp(dict["pp"])

	_learned_skills.sort_custom(self, "_sort_skills")

func reset(reset_nickname := true, set_inventory_to_new_game := false):
	if reset_nickname: set_nickname("")
	remove_all_statuses()
	_learned_skills.clear()
	_permanent_boosts.clear()
	_inventory.reset()
	_set_exp(0, false)
	var stats: Dictionary = PLAYER_STAT_TARGET_TABLE[get_name()]
	for stat in stats:
		set_stat(stat, stats[stat][0])
		if stat == MAXHP:
			set_hp(stats[stat][0])
		elif stat == MAXPP:
			set_pp(stats[stat][0])
	if set_inventory_to_new_game:
		var save_data: Dictionary = globaldata.get_json_data(global.SAVE_NEW_GAME_PATH)
		_inventory.init_from_serialized(save_data[get_name()].get("inventory", []))





#####################################################################
######################## GETTERS AND SETTERS ########################
#####################################################################

# Override
func get_character_type() -> int:
	return Type.PARTY_MEMBER

func get_nickname() -> String:
	return _nickname

func set_nickname(new_nickname: String):
	_nickname = new_nickname

func get_inventory() -> Inventory:
	return _inventory

# Returns learned skills; can filter by type (basic, skill, psi)
func get_learned_skills(by_type := "") -> Array:
	var all_learned_skills := _learned_skills + _get_battle_skills_from_inv()
	return _filter_skills_by(all_learned_skills, by_type) if by_type else all_learned_skills

func _sort_skills(skill_name_1: String, skill_name_2: String):
	if !SKILLS_ORDER.has(skill_name_1):
		return false
	elif !SKILLS_ORDER.has(skill_name_2):
		return true
	else:
		return SKILLS_ORDER.find(skill_name_1) < SKILLS_ORDER.find(skill_name_2)

# Only returns skills if the required weapon is equipped
# Can also filter by type (basic, skill, psi)
# Filters by battle use case by default
func get_usable_skills(by_type := "", by_use_case := 1) -> Array:
	var usable_skills := []
	for skill_id in get_learned_skills():
		if _is_skill_usable(skill_id):
			usable_skills.append(skill_id)
	if by_type:
		return _filter_skills_by(usable_skills, by_type, by_use_case)
	else:
		return usable_skills

func _is_skill_usable(skill_id: String) -> bool:
	var skill_data = globaldata.get_battle_skill(skill_id)
	if skill_data:
		if skill_data.has("required_item"):
			for item in skill_data.required_item:
				if has_item_activated_by_name(item):
					return true
		else:
			return true
	return false

func _filter_skills_by(skills: Array, by_type: String, by_use_case := 0) -> Array:
	var ret := []
	for skill_id in skills:
		var skill_data: Dictionary = globaldata.get_battle_skill(skill_id)
		if skill_data.get("skill_type") == by_type:
			if by_use_case == 0 or skill_data.get("use_cases", 0) == 0 or by_use_case == skill_data.get("use_cases", 0):
				ret.append(skill_id)
	return ret

func has_skill(skill_name: String) -> bool:
	return skill_name in (_learned_skills + _get_battle_skills_from_inv())

func has_field_skill(skill_name: String) -> bool:
	var skill: Dictionary = globaldata.get_field_skill(skill_name)
	var ret := true
	if skill.has("usable") and !skill.usable.get(get_name(), false):
		ret = false
	if skill.has("flag") and !globaldata.flags.get(skill.flag, false):
		ret = false
	if skill.has("battle_skill") and !has_skill(skill.battle_skill):
		ret = false
	return ret

func add_skill(skill_name: String):
	if !skill_name in _learned_skills:
		_learned_skills.append(skill_name)
		_learned_skills.sort_custom(self, "_sort_skills")

func set_level(lvl: int, learn_skills := true, out_increased_stats := {}, out_learned_skills := []):
	_set_exp(_level_to_exp(lvl), learn_skills, out_increased_stats, out_learned_skills)

func _set_exp(new_value: int, learn_skills := true, out_increased_stats := {}, out_learned_skills := []):
	_exp = min(new_value, _level_to_exp(LEVEL_CAP)) as int
	_update_level_from_exp(learn_skills, out_increased_stats, out_learned_skills)

func _update_level_from_exp(learn_skills := true, out_increased_stats := {}, out_learned_skills := []):
	var new_level := _exp_to_level(_exp)
	
	if _level != new_level:
		var level_diff := new_level - _level
		level_diff = max(0, level_diff) as int

		_level = new_level
	
		for stat in PLAYER_STAT_TARGET_TABLE[get_name()]:
			var new_value := _get_stat_for_level(stat, _level)
			var difference := new_value - get_base_stat(stat)
			set_stat(stat, new_value)
			if difference > 0:
				out_increased_stats[stat] = difference
		
		if learn_skills:
			_learn_new_skills(level_diff, out_learned_skills) # learning up to 1 new skill per new level
	
	elif _level == LEVEL_CAP:
		if learn_skills:
			_learn_new_skills(1, out_learned_skills)

func _learn_new_skills(limit: int, out_learned_skills := []):
	var learn_table := PLAYER_LEARN_SKILL_TABLE.get(get_name(), {}) as Dictionary
	var skill_flags := PLAYER_LEARN_SKILL_TABLE_FLAGS.get(get_name(), {}) as Dictionary
		
	var new_skills_count := 0
	for level in _level + 1:
		var skills_for_level := learn_table.get(level, []) as Array
		for skill_id in skills_for_level:
			if _learned_skills.has(skill_id) or not _is_skill_usable(skill_id):
				continue
			var skill_flag: = skill_flags.get(skill_id, "") as String
			if not skill_flag or globaldata.flags.get(skill_flag, false):
				out_learned_skills.append(skill_id)
				add_skill(skill_id)
				new_skills_count += 1
				if new_skills_count >= limit:
					return

func give_exp(quantity: int, out_stats := {}, out_learned_skills := []) -> Dictionary:
	return _set_exp(_exp + quantity, true, out_stats, out_learned_skills)

func get_exp_for_next_level() -> int:
	return _level_to_exp(get_level() + 1)

func get_basic_skill() -> String:
	var weapon := get_weapon()
	if weapon:
		var weapon_data := weapon.get_data()
		var skill_name: String = weapon_data.get("basic_skill", "")
		if skill_name:
			return skill_name
	return globaldata.SKILL_ATTACK

func _get_stat_for_level(stat_name: String, level: int) -> int:
	var stats_dict_for_member: Dictionary = PLAYER_STAT_TARGET_TABLE[get_name()]
	var level_tens := min(level / 10, stats_dict_for_member[stat_name].size() - 2)
	var level_units := level - (level_tens * 10)
	var lower_stat: int = stats_dict_for_member[stat_name][level_tens]
	var upper_stat: int = stats_dict_for_member[stat_name][level_tens + 1]
	return int(lerp(lower_stat, upper_stat, level_units / 10.0))

func _get_passive_skills_from_inv() -> Array:
	var ret := []
	for item in _inventory.get_items():
		if item.equipped or !item.is_equippable():
			ret.append_array(item.get_data().get("passive_skills", []))
	return ret

# Override
func get_passive_skills() -> Array:
	return _get_passive_skills_from_inv()

func _get_battle_skills_from_inv() -> Array:
	var ret := []
	var inventories := [_inventory, globaldata.key_items]
	for cur_inv in inventories:
		for item in cur_inv.get_items():
			if item.equipped or !item.is_equippable():
				var item_data := (item as Item).get_data()
				var skill_id := item_data.get("enable_skill", "") as String
				if skill_id and get_id() in item_data.get("can_use", []):
					ret.append(skill_id)
	return ret

# Override
func set_stat(stat: String, new_value: int):
	if !(is_unconscious() and stat == HP and new_value > 0):
		.set_stat(stat, new_value)
		if stat == HP:
			_refresh_status_from_hp()

# Override
func add_status(ailment: String):
	.add_status(ailment)
	_refresh_hp_from_status()

# Override
func remove_status(ailment: String):
	.remove_status(ailment)
	_refresh_hp_from_status()

func _refresh_hp_from_status():
	if is_unconscious() and _hp > 0:
		set_hp(0)
	elif !is_unconscious() and _hp == 0:
		set_hp(999)

func _refresh_status_from_hp():
	if _hp == 0 and !is_unconscious():
		pass




#####################################################################
################### ITEMS/INVENTORY RELATED STUFF ###################
#####################################################################

func get_equipment() -> Dictionary:
	return _inventory.get_equipment()

func get_equipped_item(slot: String) -> Item:
	return _inventory.get_equipped_item(slot)

func get_weapon() -> Item:
	return _inventory.get_equipped_item("weapon")

# Override
func get_affinity_multipliers(include_nerfs := true, include_ailments := true, include_skills := true, include_others := true) -> Dictionary:
	var ret := .get_affinity_multipliers(include_nerfs, include_ailments, include_others)
	for item in _inventory.get_items():
		if item.equipped or !item.is_equippable():
			var item_multipliers = item.get_data().get("affinity_multipliers", {})
			for cur_mult in item_multipliers:
				var is_elemental := Character.AFFINITIES_ELEMENTS.has(cur_mult)
				var is_nerf := Character.AFFINITIES_NERFS.has(cur_mult)
				var is_ailment: bool = globaldata.does_ailment_exist(cur_mult)
				var is_skill: bool = globaldata.does_battle_skill_exist(cur_mult)
				var is_other := not (is_nerf or is_ailment or is_elemental)
				if is_elemental or (is_nerf and include_nerfs) or (is_other and include_others) or (is_skill and include_skills) or \
				(is_ailment and include_ailments and can_get_status(cur_mult)):
					ret[cur_mult] = ret.get(cur_mult, 1) * item_multipliers[cur_mult]
	return ret

func give_item(target: PartyMember, item: Item):
	_inventory.transfer_item(target.inv, item)

func get_items_for_slot(slot: String, only_suitable := false, only_unequipped := false) -> Array:
	var ret := []
	for item in _inventory.get_items():
		var is_suitable := can_use_item(item)
		if !(only_unequipped and item.equipped) and !(only_suitable and !is_suitable):
			if item.get_data().get("slot") == slot:
				ret.append(item)
	return ret

func can_use_item(item: Item) -> bool:
	var item_data = item.get_data()
	return item_data.get("can_use", globaldata.characters).has(get_name())

func can_equip_item(item: Item) -> bool:
	return item.is_equippable() and can_use_item(item)

# Override
func can_receive_item(item: Item) -> bool:
	var item_data := item.get_data()
	if !item_data.get("can_consume", globaldata.characters).has(get_name()):
		return false
	return is_in_state_to_receive_item(item)

func is_the_item_better(item: Item) -> int:
	var item_data = item.get_data()
	
	var actual_boost := _inventory.calculate_stats_boost_from_slot(item_data["slot"])
		# Check offense boost
	return int(sign(Inventory.get_boost_total(item_data["boost"]) - Inventory.get_boost_total(actual_boost)))

# Equip when equipable (current caracter) maybe another system?
func equip_item(item: Item) -> bool:
	return _inventory.equip_item(item)

func unequip(item: Item):
	_inventory.unequip(item)

func unequip_slot(slot: String):
	_inventory.unequip_slot(slot)

func apply_boosts(boosts: Dictionary, performed_actions := {}):
	for stat_name in boosts.keys():
		if boosts[stat_name] > 0 and stat_name in BOOSTABLE_STATS:
			_permanent_boosts[stat_name] = _permanent_boosts.get(stat_name, 0) + boosts[stat_name]
			performed_actions[Item.ItemActions.STAT_UP] = performed_actions.get(Item.ItemActions.STAT_UP, {})
			performed_actions[Item.ItemActions.STAT_UP][stat_name] = boosts[stat_name]
			match stat_name:
				MAXHP:
					set_hp(get_hp() + boosts[stat_name])
				MAXPP:
					set_pp(get_pp() + boosts[stat_name])



# Boosts = permanent stats boosting items (like capsules) and equipment
# Not to be confused with mods (stats changes during a fight)
func get_boosts() -> Dictionary:
	var total_boosts := {}
	for stat in BOOSTABLE_STATS:
		total_boosts[stat] = _permanent_boosts.get(stat, 0) + _inventory.get_equipment_boosts().get(stat, 0)
	return total_boosts

func get_boost_for_stat(stat: String) -> int:
	return get_boosts().get(stat, 0)

# Override
func get_base_stat(stat: String, with_boosts := false) -> int:
	var res = .get_base_stat(stat, with_boosts)
	if with_boosts:
		res += get_boost_for_stat(stat)
	return res

func has_item_equipped(item: Item) -> bool:
	if !can_equip_item(item):
		return false
	else:
		var item_data = item.get_data()
		return item == get_equipped_item(item_data.slot)

func has_item_equipped_by_name(item_name: String) -> bool:
	for item in _inventory.find_all_occurrences(item_name):
		if item.equipped:
			return true
	return false

# Activated = equipped if equippable, otherwise just possessed
func has_item_activated_by_name(item_name: String, include_key_items := true) -> bool:
	var all_occurrences := _inventory.find_all_occurrences(item_name)
	if include_key_items:
		all_occurrences += globaldata.key_items.find_all_occurrences(item_name)
	for item in all_occurrences:
		if item.equipped or !item.is_equippable():
			return true
	return false

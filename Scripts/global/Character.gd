extends Object
class_name Character

enum Type {PARTY_MEMBER, PARTY_NPC, ENEMY}

var _name: String
var _level: int
var _exp: int
var _status := []

var _hp: int
var _maxhp: int
var _pp: int
var _maxpp: int
var _offense: int
var _defense: int
var _speed: int
var _iq: int
var _guts: int

const HP := "hp"
const MAXHP := "maxhp"
const PP := "pp"
const MAXPP := "maxpp"
const OFFENSE := "offense"
const DEFENSE := "defense"
const SPEED := "speed"
const IQ := "iq"
const GUTS := "guts"

const WEAKNESS := "weakness"
const IMMUNITY := "immunity"
const RESISTANCE := "resistance"

const AFFINITIES_ELEMENTS := ["fire", "ice", "lightning", "explosion", "insecticide"]
const AFFINITIES_NERFS := ["offense", "defense"]

# Everyone is immune to them unless stated otherwise
const RARE_AFFINITIES := ["asthma", "insecticide"]

const BOOSTABLE_STATS := [MAXHP, MAXPP, OFFENSE, DEFENSE, SPEED, IQ, GUTS]

var _affinity_multipliers := {}

signal status_changed
signal stat_changed(stat)

# Overridden
func init_from_dict(dict: Dictionary):
	_name = dict["name"]
	_level = dict["level"]
	_exp = dict["exp"]
	_hp = dict.get("hp", 1)
	_maxhp = dict["maxhp"]
	_pp = dict.get("pp", 0)
	_maxpp = dict["maxpp"]
	_offense = dict["offense"]
	_defense = dict["defense"]
	_speed = dict["speed"]
	_iq = dict["iq"]
	_guts = dict["guts"]
	_status_init_from_dict(dict)

# Overridden
func to_dict() -> Dictionary:
	return {
		"level": _level,
		"exp": _exp,
		"hp": _hp,
		"maxhp": _maxhp,
		"pp": _pp,
		"maxpp": _maxpp,
		"offense": _offense,
		"defense": _defense,
		"speed": _speed,
		"iq": _iq,
		"guts": _guts,
		"status": status_to_array()
	}

####################################################################
########################### GENERAL DATA ###########################
####################################################################


func get_name() -> String:
	return _name.to_lower()

# Overridden
func get_character_type() -> int:
	return -1

# Overridden
func get_id() -> String:
	return get_name()

# Overridden (only in Enemy.gd)
func is_boss() -> bool:
	return false

func get_sprite() -> String:
	return _name

func get_article() -> String:
	return "ARTICLES_" + _name.to_upper()

func get_level() -> int:
	return _level

func get_exp() -> int:
	return _exp

func get_status_ailments() -> Array:
	return _status

# Overridden
func get_base_stat(stat: String, with_boosts := false) -> int:
	match stat:
		HP: return _hp
		PP: return _pp
		MAXHP: return _maxhp
		MAXPP: return _maxpp
		OFFENSE: return _offense
		DEFENSE: return _defense
		SPEED: return _speed
		IQ: return _iq
		GUTS: return _guts
		_: return 0

func get_stat(stat: String) -> int:
	var base_stat := get_base_stat(stat, true)
	var final_stat := base_stat
	var effects = get_combined_status_effect("stat_mods")
	if effects.size() > 0:
		final_stat = base_stat * effects.get(stat, 1)
	return final_stat

func get_hp() -> int:
	return get_stat(HP)

func get_pp() -> int:
	return get_stat(PP)

func set_stat(stat: String, new_value: int):
	var old_value := get_base_stat(stat)
	var diff := new_value - old_value
	if diff != 0:
		match stat:
			HP: _hp = int(clamp(new_value, 0, get_stat(MAXHP)))
			PP: _pp = int(clamp(new_value, 0, get_stat(MAXPP)))
			MAXHP: _maxhp = new_value
			MAXPP: _maxpp = new_value
			OFFENSE: _offense = new_value
			DEFENSE: _defense = new_value
			SPEED: _speed = new_value
			IQ: _iq = new_value
			GUTS: _guts = new_value

		emit_signal("stat_changed", stat)

		if diff > 0:
			if stat == MAXHP:
				set_hp(_hp + diff)
			elif stat == MAXPP:
				set_pp(_pp + diff)

func set_pp(new_value: int):
	set_stat(PP, new_value)

func set_hp(new_value: int):
	set_stat(HP, new_value)

func get_passive_skills() -> Array:
	return []

# Overridden
func get_description() -> String:
	return ""

func is_unconscious() -> bool:
	return has_status(Status.AILMENT_UNCONSCIOUS)

func is_targetable() -> bool:
	return true


####################################################################
############################## STATUS ##############################
####################################################################

func can_get_status(ailment: String) -> bool:
	var status_data: Dictionary = globaldata.get_ailment_data(ailment)
	if status_data.has("can_get"):
		var can_get: Dictionary = status_data["can_get"]
		for key in can_get:
			if key == get_name():
				return can_get[key]
			if key == "psi_characters" and _pp > 0:
				return can_get[key]
		return false
	else:
		return !status_data.empty() # You can get the status if it exists and doesn't have specific can_get conditions

func get_status(ailment: String) -> Status:
	for sts in _status:
		if sts.ailment == ailment:
			return sts
	return null

func has_status(status: String) -> bool:
	return get_status(status) != null

func has_any_status() -> bool:
	return !_status.empty()

func add_status(ailment: String):
	if globaldata.does_ailment_exist(ailment):
		if !has_status(ailment) and !_has_exclusive_status():
			if globaldata.get_ailment_data(ailment).get("exclusive_status", false):
				remove_all_statuses()
			_status.append(Status.new(ailment))
			_status.sort_custom(self, "_sort_by_priority")
			emit_signal("status_changed")
	else:
		print("Invalid status! " + str(ailment) + " does not exist!")

func _has_exclusive_status():
	for sts in _status:
		var info = sts.get_data()
		if info.get("exclusive_status", false):
			return true
	return false

func remove_status(ailment: String):
	if globaldata.does_ailment_exist(ailment):
		for sts in _status:
			if sts.ailment == ailment:
				_status.erase(sts)
				emit_signal("status_changed")
	else:
		print("Invalid status! " + str(ailment) + " does not exist!")

func remove_all_statuses():
	while not _status.empty():
		remove_status(_status[0].ailment)

func get_status_effects(effect_name := "") -> Array:
	var effects := []
	for sts in _status:
		var ailment_info = sts.get_data()
		if ailment_info == null or !ailment_info.has("effects_by_char"):
			continue
		var effects_for_type := _pick_status_effects(ailment_info.effects_by_char, sts.times_afflicted)
		if effect_name != "":
			if effects_for_type.has(effect_name):
				effects.append(effects_for_type[effect_name])
		else:
			effects.append(effects_for_type)
	
	return effects

func _pick_status_effects(effects_by_char: Dictionary, times_afflicted := 0) -> Dictionary:
	var effects = {}
	var char_type = get_character_type()
	var is_boss = is_boss()
	for case in effects_by_char:
		var condition := false
		match case:
			"field_party_member":
				condition = !uiManager.is_in_battle()
			"party_member":
				condition = (char_type == Type.PARTY_MEMBER)
			"enemy":
				condition = (char_type == Type.ENEMY)
			"boss":
				condition = is_boss
			"boss_layer_1":
				condition = (is_boss and times_afflicted <= 1)
			"boss_layer_2":
				condition = (is_boss and times_afflicted > 1)
			"any":
				condition = true
		if condition:
			for key in effects_by_char[case]:
				effects[key] = effects_by_char[case][key]
	return effects

func get_combined_status_effect(effect_name: String):
	var effects := get_status_effects(effect_name)
	var combined_effect
	match effect_name:
		"hp_scroll_multiplier", "damage_multiplier":
			combined_effect = 1
		"miss_chance":
			combined_effect = 0
		"info_plate_color":
			combined_effect = 'FFFFFF'
		"stat_mods":
			combined_effect = {}
		"incapacitated", "overworld_sweat", "paralyzed_sprite":
			combined_effect = false
		"cant_select", "turn_skip", "confusion":
			combined_effect = {}
		"dealt_mod", "dealt_color", "received_mod", "received_color", "cant_do", "cant_receive_item", "overworld_damage":
			combined_effect = []
		"change_sprite":
			combined_effect = ""
	for i in effects.size():
		match effect_name:
			"hp_scroll_multiplier", "damage_multiplier":
				combined_effect *= effects[i]
			"miss_chance":
				var existing_success_rate: float = 1.0 - (combined_effect / 100.0)
				var new_success_rate: float = 1.0 - (effects[i] / 100.0)
				combined_effect = int((1.0 - new_success_rate * existing_success_rate) * 100)
			"info_plate_color":
				combined_effect = effects[i]
				break
			"stat_mods":
				for stat in effects[i]:
					combined_effect[stat] = effects[i].get(stat, 0)
			"turn_skip", "confusion":
				combined_effect = effects[i]
				if combined_effect.get("enable", false):
					break
			"incapacitated", "overworld_sweat", "paralyzed_sprite":
				combined_effect = combined_effect or effects[i]
			"cant_select":
				for action in effects[i]:
					combined_effect[action] = combined_effect.get(action, false) or effects[i][action]
			"dealt_mod", "dealt_color", "received_mod", "received_color", "cant_do", "cant_receive_item", "overworld_damage":
				combined_effect.append(effects[i])
			"change_sprite":
				combined_effect += effects[i]
				return combined_effect #take only the first one
	return combined_effect

func _sort_by_priority(sts1, sts2):
	return sts1.get_data().get("priority", 0) > sts2.get_data().get("priority", 0)

func status_to_array() -> Array:
	var serialized_sts := []
	for sts in _status:
		serialized_sts.append(sts.to_dict())
	return serialized_sts

func _status_init_from_dict(dict: Dictionary):
	if dict.has("status"):
		var loaded_sts := []
		for sts in dict.status:
			var new_status := Status.new(sts["status"])
			new_status.battle_turns = sts.get("passive_healing_turns", 0)
			loaded_sts.append(new_status)
		_status = loaded_sts
		_status.sort_custom(self, "_sort_by_priority")

func is_incapacitated() -> bool:
	return get_combined_status_effect("incapacitated")

# Overridden

func can_receive_item(item: Item) -> bool:
	return is_in_state_to_receive_item(item)

func is_in_state_to_receive_item(item: Item) -> bool: # Due to status; not to be confused with can_receive_item
	var cant_receive = get_combined_status_effect("cant_receive_item")
	var can_receive := true
	var item_data := item.get_data()
	for effect in cant_receive:
		var type = effect.get("type")
		if not type is Array:
			type = [type]
		for item_type in type:
			match item_type:
				"food":
					can_receive = !item_data.get("is_food", false)
				"status_heals":
					can_receive = !item_data.get(item_type, {})
	return can_receive

func get_item_inability_message(item: Item) -> String:
	var item_data := item.get_data()
	var inability_data = get_combined_status_effect("cant_receive_item")
	var can_receive := true
	for effect in inability_data:
		var type = effect.get("type")
		if !(type is Array):
			type = [type]
		for item_type in type:
			match item_type:
				"HPrecover", "PPrecover":
					can_receive = !item_data.get(item_type, 0) > 0
				"status_heals":
					can_receive = !item_data.get(item_type, {})
				"food":
					can_receive = !item_data.get("is_food", false)
		if !can_receive:
			return effect.get("message", "")
	return ""


####################################################################
############################ AFFINITIES ############################
####################################################################




func get_affinity_multipliers(include_nerfs := true, include_ailments := true, include_skills := true, include_others := true) -> Dictionary:
	for key in RARE_AFFINITIES:
		_affinity_multipliers[key] = _affinity_multipliers.get(key, 0)
		
	var ret := {}
	for key in _affinity_multipliers:
		var is_elemental := AFFINITIES_ELEMENTS.has(key)
		var is_nerf := AFFINITIES_NERFS.has(key)
		var is_ailment: bool = globaldata.does_ailment_exist(key)
		var is_skill: bool = globaldata.does_battle_skill_exist(key)
		var is_other := not (is_nerf or is_ailment or is_elemental or is_skill)
		if is_elemental or (is_nerf and include_nerfs) or (is_other and include_others) or (is_skill and include_skills) or \
		(is_ailment and include_ailments and can_get_status(key)):
			ret[key] = _affinity_multipliers[key]
	return ret

func get_affinities_dialog() -> Array:
	var dialog := []
	var affinities := {WEAKNESS: [], RESISTANCE: [], IMMUNITY: []}
	var multipliers := get_affinity_multipliers(true, true, true, false)
	for key in multipliers:
		if key in RARE_AFFINITIES:
			if multipliers[key] > 0:
				affinities[WEAKNESS].append(key)
		else:
			if multipliers[key] == 0:
				affinities[IMMUNITY].append(key)
			elif multipliers[key] < 1:
				affinities[RESISTANCE].append(key)
			elif multipliers[key] > 1:
				affinities[WEAKNESS].append(key)
	for affinity_type in affinities:
		var cur_affinities: Array = affinities[affinity_type]
		if !cur_affinities.empty():
			var line := tr("BATTLE_MSG_SPY_%s%s" % [affinity_type.to_upper(), "_PLUR" if cur_affinities.size() > 1 else ""])
			for j in cur_affinities.size():
				if j > 0:
					line += tr("BATTLE_MSG_SPY_SEPARATOR%s" % ("_LAST" if j == cur_affinities.size() - 1 else ""))
				var affinity = cur_affinities[j]
				if globaldata.does_battle_skill_exist(affinity):
					var skill = globaldata.get_battle_skill(affinity)
					line += tr(skill.get("name", ""))
				else:
					line += tr("BATTLE_MSG_SPY_AFFINITY_%s" % cur_affinities[j].to_upper())
			line += tr("BATTLE_MSG_SPY_END_LIST")
			dialog.append(line)
	return dialog

# Overridden
func are_affinities_hidden() -> bool:
	return false


func has_mysterious_stats() -> bool:
	return false

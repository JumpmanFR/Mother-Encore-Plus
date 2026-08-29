extends Character
class_name Enemy

var _enemy_id: String
var _skills := []
var _passive_skills := []
var _boss: bool
var _cash: int

func _init(enemy_id: String):
	_enemy_id = enemy_id
	var data = get_data()
	_name = data.name
	_level = data.level
	_exp = data.exp
	_hp = data.hp
	_maxhp = data.maxhp
	_pp = data.pp
	_maxpp = data.maxpp
	_offense = data.offense
	_defense = data.defense
	_speed = data.speed
	_iq = data.iq
	_guts = data.guts
	_boss = data.get("boss", false)
	_cash = data.get("cash", 0)
	_skills = data.get("skills", [])
	_passive_skills = data.get("passive_skills", [])
	_affinity_multipliers = data.get("affinity_multipliers", {})

func update_data(enemy_id: String):
	_enemy_id = enemy_id
	var data = get_data()
	_name = data.get("name", _name)
	_level = data.get("level", _level)
	_exp = data.get("exp", _exp)
	_offense = data.get("offense", _offense)
	_defense = data.get("defense", _defense)
	_speed = data.get("speed", _speed)
	_iq = data.get("iq", _iq)
	_guts = data.get("guts", _guts)
	_boss = data.get("boss", _boss)
	_cash = data.get("cash", _cash)
	_skills = data.get("skills", _skills)
	_passive_skills = data.get("passive_skills", _passive_skills)
	_affinity_multipliers = data.get("affinity_multipliers", _affinity_multipliers)


func get_data() -> Dictionary:
	return globaldata.get_enemy_data(_enemy_id)

func get_id() -> String:
	return _enemy_id

# Override
func get_character_type() -> int:
	return Type.ENEMY

func get_nickname() -> String:
	var data = get_data()
	if data.has("nickname"):
		return data.nickname
	return data.name

func get_sprite() -> String:
	return get_data().get("sprite")

func get_article() -> String:
	return get_data().get("article", "")

# Override
func get_description() -> String:
	return get_data().get("description", "")

func get_skills() -> Array:
	return _skills

# Override
func get_passive_skills() -> Array:
	return _passive_skills

# Override
func is_boss() -> bool:
	return _boss

func get_cash() -> int:
	return _cash

# Override
func are_affinities_hidden() -> bool:
	return get_data().get("hide_affinities", false)


func has_mysterious_stats() -> bool:
	return get_data().get("mysterious_stats", false)

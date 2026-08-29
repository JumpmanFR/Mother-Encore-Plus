extends Character
class_name PartyNPC

var _untargetable := false
var _skills := []

const CANARY_CHICK := "canarychick"
const FLYING_MAN := "flyingman"
const EVE := "eve"

func _init(data := {}, constant_data := {}):
	init_from_dict(data)
	init_from_dict(constant_data)

func to_dict() -> Dictionary:
	var dict := .to_dict()
	dict["untargetable"] = _untargetable
	dict["skills"] = _skills
	return dict

func init_from_dict(dict: Dictionary):
	if dict:
		.init_from_dict(dict)
		_untargetable = dict.get("untargetable", false)
		_skills = dict["skills"]

# Override
func get_character_type() -> int:
	return Type.PARTY_NPC

func get_nickname() -> String:
	return "[tr:NAME_" + _name.to_upper() + "]"

func get_skills() -> Array:
	return _skills

func is_targetable() -> bool:
	return !_untargetable

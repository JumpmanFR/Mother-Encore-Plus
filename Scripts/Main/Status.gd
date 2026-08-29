extends Node
class_name Status

const AILMENT_POISONED := "poisoned"
const AILMENT_UNCONSCIOUS := "unconscious"

var ailment: String
var battle_turns := 0
var times_afflicted := 1
var passive_heal_probability: int

func _init(status):
	ailment = status
	var status_dictionary: Dictionary = get_data()
	if get_data()["healing"].get("passive_heal", false):
		passive_heal_probability = status_dictionary["healing"].get("heal_prob", 25)

func get_data() -> Dictionary:
	return globaldata.get_ailment_data(ailment)

func to_dict() -> Dictionary:
	var dict = {"status": ailment}
	if get_data()["healing"].get("passive_heal", false):
		dict["passive_healing_turns"] = battle_turns
	return dict

static func get_status_message(ailment: String, message: String) -> String:
	var ailment_info = globaldata.get_ailment_data(ailment)
	if ailment_info.has("messages"):
		return ailment_info.messages.get(message, "")
	return ""

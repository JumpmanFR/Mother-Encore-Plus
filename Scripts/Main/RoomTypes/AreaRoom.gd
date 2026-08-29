extends Node2D
class_name AreaRoom

signal area_left
signal synced_switches_changed(emitter, state, silent)

# Find position 0,0 in the scene, and then find where that is in the map image.
export var _player_map_offset := Vector2.ZERO

# Leave blank to rely on name of scene's root node. Names are case-sensitive.
export var _region_name := ""

# Tells the map whether or not to keep updating the player's position.
export var _is_sub_area := false

export var area_bg_color := Color("1c1c1c")


const MAP_AREA_OVERRIDES := {
	"Podunk": "Merrysville"
}

const REGION_VISIT_FLAGS := {
	"Podunk": "visited_podunk", 
	"Magicant": "visited_magicant", 
	"Merrysville": "visited_merrysville", 
	"Reindeer": "visited_reindeer", 
	"Snowman": "visited_snowman", 
	"Spookane": "visited_spookane", 
	"Yucca Desert": "visited_yucca", 
	"Youngtown": "visited_youngtown", 
	"Ellay": "visited_ellay", 
	"Mt Itoi": "visited_mtitoi"
}


var _switches_state := false
var can_switch := true

func _init():
	connect("synced_switches_changed", self, "_on_switches_changed_state")

func _ready():
	_update_visit_flags()
	_update_flying_man_status()

func get_region_name() -> String:
	return _region_name

func is_sub_area() -> bool:
	return _is_sub_area

func get_map_name(only_if_possessed: bool, with_map_override := true) -> String:
	
	var map_name = _region_name
	if !Inventory.is_map_possessed(map_name) or with_map_override:
		map_name = get_area_override(map_name)
	
	if !only_if_possessed or Inventory.is_map_possessed(map_name):
		return self.name if map_name == "" else map_name
	else:
		return ""

static func get_area_override(area_name := _region_name) -> String:
	if area_name in MAP_AREA_OVERRIDES:
		
		var area_override = MAP_AREA_OVERRIDES[area_name]
		
		if Inventory.is_map_possessed(area_override):
			area_name = area_override
		
	return area_name

func get_player_map_offset() -> Vector2:
	return _player_map_offset

func leave_for(new_scene):
	emit_signal("area_left", new_scene.get_region_name() != self.get_region_name())

func _update_flying_man_status():
	var is_magicant = (_region_name == "Magicant")
	if !is_magicant or globaldata.flags["flying_man_in_party"]:
		if is_magicant != (globaldata.characters.flyingman in global.partyNpcs):
			if is_magicant:
				global.partyNpcs.append(globaldata.characters.flyingman)
			else:
				global.partyNpcs.erase(globaldata.characters.flyingman)

func _update_visit_flags():
	if _region_name in REGION_VISIT_FLAGS:
		var flag := REGION_VISIT_FLAGS[_region_name] as String
		globaldata.set_flag(flag, true)

func _on_switches_changed_state(emitter: TwoStatesSwitch, value: bool, silent: bool):
	_switches_state = value

func get_switches_state() -> bool:
	return _switches_state

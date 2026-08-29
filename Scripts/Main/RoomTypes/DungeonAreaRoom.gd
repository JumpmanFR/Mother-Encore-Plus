extends AreaRoom
class_name DungeonAreaRoom

export var current_floor := 0
var _current_room = null

func set_current_room(room):
	_current_room = room

func get_current_room_id():
	return _current_room.get_index()

func get_player_position_relative_to_current_room() -> Vector2:
	return global.get_player().global_position - _current_room.get_area_global_position()

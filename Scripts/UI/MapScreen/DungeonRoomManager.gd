extends Node2D
class_name DungeonMapRoomManager

export var room_name: String

func get_room_offset(room_id: int) -> Vector2:
	var room = get_child(room_id)
	var rect = room.get_used_rect()
	return position + room.position + rect.position * room.cell_size + (rect.size * room.cell_size / 2)

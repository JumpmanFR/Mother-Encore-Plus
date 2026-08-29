extends Area2D
class_name NearFogArea

var _original_position: Vector2
var _original_direction: Vector2
var _fade_in_progress: bool = false

func _on_FogZone_body_entered(body):
	if body is PartyMemberPlayer:
		_original_position = body.global_position
		_original_direction = body.get_direction()

func get_original_position() -> Vector2:
	return _original_position

func get_original_direction() -> Vector2:
	return _original_direction

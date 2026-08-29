extends Area2D
class_name Camarea

export var cam_rect_path: NodePath
export var camera_offset: Vector2

var inside = false

onready var cam_node: ReferenceRect = get_node_or_null(cam_rect_path)

func _on_enter():
	global.currentCamera.camareas += 1
	inside = true
	
	
	_reset_camera_limits()
	yield(get_tree(), "idle_frame")
	if inside:
		var size = get_size()
		
		
		var view_size = get_viewport_rect().size
		if size.y < view_size.y:
			size.y = view_size.y
			
		if size.x < view_size.x:
			size.x = view_size.x
		
		if cam_node != null:
			global.currentCamera.limit_top = int(cam_node.margin_top)
			global.currentCamera.limit_left = int(cam_node.margin_left)
			
		else:
			global.currentCamera.limit_top = $CollisionShape2D.global_position.y - size.y/2
			global.currentCamera.limit_left = $CollisionShape2D.global_position.x - size.x/2
			
		global.currentCamera.limit_bottom = global.currentCamera.limit_top + size.y
		global.currentCamera.limit_right = global.currentCamera.limit_left + size.x
		
		global.currentCamera.set_camarea_offset(camera_offset)

func get_size() -> Vector2:
	var size
	if cam_node != null:
		size = cam_node.rect_size
	else:
		size = $CollisionShape2D.shape.extents * 2 * self.transform.get_scale()
	size.x = round(size.x)
	size.y = round(size.y)
	return size

func get_area_global_position() -> Vector2:
	return $CollisionShape2D.global_position

func _on_exit():
	global.currentCamera.camareas -= 1
	inside = false
	if global.currentCamera.camareas == 0:
		_reset_camera_limits()

func _reset_camera_limits():
	global.currentCamera.limit_top = - 10000000
	global.currentCamera.limit_left = - 10000000
	global.currentCamera.limit_right = 10000000
	global.currentCamera.limit_bottom = 10000000
	global.currentCamera.set_camarea_offset(Vector2.ZERO)


func _on_camarea_body_exited(body):
	if body == global.get_player():
		_on_exit()

func _on_camarea_body_entered(body):
	if body == global.get_player():
		_on_enter();

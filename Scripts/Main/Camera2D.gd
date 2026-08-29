extends Camera2D
class_name GameCamera

signal stopped_shaking

const CAM_LIMIT := 50
const BUTTON_PROMPTS_DELAY := 1
const QUICK_SCOPE_DURATION := 0.3


const SCOPE_MOVE_SPEED := 2
const SCOPE_VERTICAL_LIMIT := 90
const SCOPE_HORIZONTAL_LIMIT := 160


const MIN_SHAKE_MAGNITUDE := 1.0
const MIN_SHAKE_TIME := 0.2
const SHAKE_STEP_TIME := 0.02

var _base_offset := Vector2.ZERO
var _shake_offset := Vector2.ZERO
var _camarea_offset := Vector2.ZERO # offset added to the camera when inside of a camarea
var camareas := 0
var _shaking := false
var tween: SceneTreeTween

onready var _scope_arrows := $ScopeArrows

func _ready():
	if get_parent() == global.get_player():
		uiManager.connect("battle_to_ov", self, "_scoping_stop")
		global.get_player().connect("paused", self, "_on_player_pause")

func _process(_delta: float):
	
	
	if _scope_arrows.visible: _scope_arrows.global_position = get_camera_screen_center()

func _physics_process(delta: float):
	if !uiManager.is_in_battle() and global.get_player().get_state() != global.get_player().CAMERA:
		offset = _base_offset + _shake_offset
	else:
		offset = _base_offset
		
	if !global.get_player().is_being_damaged() and self == global.currentCamera and global.get_player().get_state() == global.get_player().CAMERA:
		if Input.is_action_just_pressed("ui_scope", true):
			_scoping_start()
		if Input.is_action_just_released("ui_scope"):
			_scoping_stop()
		if Input.is_action_pressed("ui_scope", true) and global.get_player().get_state() != global.get_player().ATTACK:
			_scoping_process(delta)

func _scoping_start():
	uiManager.info_plates_hide()
	global_position = get_camera_screen_center()
	$ArrowsAnim.play("Come In")
	_scope_arrows.show()

func _scoping_stop():
	_scope_arrows.hide()
	$ArrowsAnim.play("Come Out")
	global.get_player().exit_camera()
	return_offset(0.3)

func _scoping_process(delta: float):
	var input: Vector2 = controlsManager.get_controls_vector()
	var screen_center := get_camera_screen_center()
	var move_direction := Vector2.ZERO
	
	
	var can_move_up := _base_offset.y > - CAM_LIMIT and screen_center.y - SCOPE_VERTICAL_LIMIT > limit_top
	var can_move_down := _base_offset.y < CAM_LIMIT and screen_center.y + SCOPE_VERTICAL_LIMIT < limit_bottom
	_scope_arrows.set_arrow_visible(Vector2.UP, can_move_up)
	_scope_arrows.set_arrow_visible(Vector2.DOWN, can_move_down)
	
	if input.y < 0 and can_move_up: move_direction.y = - 1
	elif input.y > 0 and can_move_down: move_direction.y = 1
	
	
	var can_move_left := _base_offset.x > - CAM_LIMIT and screen_center.x - SCOPE_HORIZONTAL_LIMIT > limit_left
	var can_move_right := _base_offset.x < CAM_LIMIT and screen_center.x + SCOPE_HORIZONTAL_LIMIT < limit_right
	_scope_arrows.set_arrow_visible(Vector2.LEFT, can_move_left)
	_scope_arrows.set_arrow_visible(Vector2.RIGHT, can_move_right)
	
	if input.x < 0 and can_move_left: move_direction.x = - 1
	elif input.x > 0 and can_move_right: move_direction.x = 1
	
	_base_offset += move_direction * SCOPE_MOVE_SPEED

func _input(_event: InputEvent):
	_scope_arrows.handle_input_events()

func _on_player_pause():
	_scope_arrows.hide()

func move_camera(pos: Vector2, time: float):
	if tween and tween.is_running(): tween.kill()
	if time > 0.0:
		tween = create_tween()
		yield(tween.tween_property(self, "global_position", pos, time)\
		.from(get_camera_screen_center()).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT), "finished")
	else:
		global_position = pos

func move_offset(target_offset: Vector2, time: float):
	if tween and tween.is_running(): tween.kill()
	
	var camera_pos = get_camera_screen_center()
	var clamped_offset_x = clamp(target_offset.x, limit_left - camera_pos.x, limit_right - camera_pos.x)
	var clamped_offset_y = clamp(target_offset.y, limit_top - camera_pos.y, limit_bottom - camera_pos.y)
	var final_offset = Vector2(clamped_offset_x, clamped_offset_y)
	
	tween = create_tween()
	tween.tween_property(self, "_base_offset", final_offset, time)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func return_camera(time := 1.0):
	if tween: tween.kill()
	tween = create_tween()
	yield(tween.tween_property(self, "position", _camarea_offset, time)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT), "finished")
	
	position = _camarea_offset

func return_offset(time := 1.0):
	if tween: tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_base_offset", Vector2.ZERO, time)
	tween.parallel().tween_property(self, "position", _camarea_offset, time)
	yield(tween, "finished")
	
	position = _camarea_offset
	_base_offset = Vector2.ZERO

func set_camarea_offset(off: Vector2):
	_camarea_offset = off
	position = _camarea_offset

func get_offset_with_camerea_offset() -> Vector2:
	return position + _camarea_offset

func reset():
	for i in [position, _base_offset, _shake_offset]:
		i = Vector2.ZERO

func shake_camera(magnitude := 1.0, length := 1.0, direction := Vector2.ONE, interval := SHAKE_STEP_TIME, lerp_weight := 0.5, diminish := true):
	if _scope_arrows.visible: return
	
	_shaking = true
	
	var shaker = Shaker.new(self, "_shake_offset")\
	.set_shake_direction(direction)\
	.set_shake_magnitude(magnitude)\
	.set_shake_length(length)\
	.set_shake_interval(interval)\
	.set_shake_weight(lerp_weight)\
	.set_shake_diminish(diminish).start()
	
	yield(shaker, "finished_shake")
	
	var final_tween = create_tween()
	final_tween.tween_property(self, "_shake_offset", Vector2.ZERO, 0.1)
	yield(final_tween, "finished")
	yield(get_tree(), "idle_frame")
	_shaking = false
	emit_signal("stopped_shaking")

func is_shaking() -> bool:
	return _shaking

func set_current():
	limit_bottom = global.currentCamera.limit_bottom
	limit_left = global.currentCamera.limit_left
	limit_right = global.currentCamera.limit_right
	limit_top = global.currentCamera.limit_top
	camareas = global.currentCamera.camareas
	global_position = global.currentCamera.get_camera_screen_center()
	make_current()
	global.currentCamera = self

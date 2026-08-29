extends Node

var _mouse_position := Vector2.ZERO
var _mouse_shown_time := 0.0
var _mouse_hidden_time := 0.0
var _mouse_idle_time := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_mouse_position = Input.get_last_mouse_speed()

func _notification(what: int):
	if what == NOTIFICATION_WM_MOUSE_ENTER:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta):
	_manage_mouse(delta)

func _input(event: InputEvent):
	if Input.get_mouse_button_mask():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_mouse_hidden_time = 0.0
		_mouse_shown_time = 0.0
		_mouse_idle_time = 0.0

func _manage_mouse(delta):
	if _mouse_position != Input.get_last_mouse_speed():
		_mouse_shown_time = 0
		_mouse_idle_time = 0
		if Input.get_mouse_mode() == Input.MOUSE_MODE_HIDDEN:
			_mouse_hidden_time += delta
			if _mouse_hidden_time >= delta * 5:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				_mouse_hidden_time = 0
	else:
		_mouse_idle_time += delta
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		_mouse_shown_time += delta
	
	_mouse_position = Input.get_last_mouse_speed()
	
	if _mouse_idle_time >= 0.5:
		_mouse_hidden_time = 0
	
	if _mouse_shown_time >= 1.5:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		_mouse_shown_time = 0

func set_active(value: bool):
	set_process(value)
	if !value:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

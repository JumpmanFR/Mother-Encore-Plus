extends Node

onready var intervalTimer = $IntervalTimer #the  interval between input repeats for when you hold down a direction 
onready var intervalSwitchTimer = $IntervalSwitchTimer #how much time it takes for it to switch between slow and quick interval

const SLOWTIME := 0.3
const FASTTIME := 0.1

func was_just_pressed(direction: Vector2) -> bool:
	match direction:
		Vector2.UP:
			return Input.is_action_just_pressed("ui_up") \
					or Input.is_action_just_pressed("ui_lstick_up") \
					or Input.is_action_just_pressed("ui_rstick_up")
		Vector2.DOWN:
			return Input.is_action_just_pressed("ui_down") \
					or Input.is_action_just_pressed("ui_lstick_down") \
					or Input.is_action_just_pressed("ui_rstick_down")
		Vector2.LEFT:
			return Input.is_action_just_pressed("ui_left") \
					or Input.is_action_just_pressed("ui_lstick_left") \
					or Input.is_action_just_pressed("ui_rstick_left")
		Vector2.RIGHT:
			return Input.is_action_just_pressed("ui_right") \
					or Input.is_action_just_pressed("ui_lstick_right") \
					or Input.is_action_just_pressed("ui_rstick_right")
		_:
			return false

func was_just_released(direction: Vector2) -> bool:
	match direction:
		Vector2.UP:
			return Input.is_action_just_released("ui_up") \
					or Input.is_action_just_released("ui_lstick_up") \
					or Input.is_action_just_released("ui_rstick_up")
		Vector2.DOWN:
			return Input.is_action_just_released("ui_down") \
					or Input.is_action_just_released("ui_lstick_down") \
					or Input.is_action_just_released("ui_rstick_down")
		Vector2.LEFT:
			return Input.is_action_just_released("ui_left") \
					or Input.is_action_just_released("ui_lstick_left") \
					or Input.is_action_just_released("ui_rstick_left")
		Vector2.RIGHT:
			return Input.is_action_just_released("ui_right") \
					or Input.is_action_just_released("ui_lstick_right") \
					or Input.is_action_just_released("ui_rstick_right")
		_:
			return false


#returns the directional input vector that has just been pressed
func get_just_pressed_input_vector() -> Vector2:
	var input_vector = Vector2.ZERO
	for v in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		if was_just_pressed(v):
			input_vector += v

	return input_vector

#returns the directional input vector that has just been pressed
func get_just_released_input_vector() -> Vector2:
	var input_vector = Vector2.ZERO
	for v in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		if was_just_released(v):
			input_vector += v

	return input_vector

func get_just_pressed_directions() -> Array:
	var ret := []
	for v in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		if was_just_pressed(v):
			ret.append(v)
	return ret

func get_just_released_directions() -> Array:
	var ret := []
	for v in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		if was_just_released(v):
			ret.append(v)
	return ret

func get_controls_vector(discontinued := false) -> Vector2: #use discontinued for menus
	var input_vector := Vector2.ZERO
	var just_pressed_vector := get_just_pressed_input_vector()
	var just_released := !get_just_released_directions().empty()
	#return nothing or the input that has just been pressed if the interval has not been finished
	if intervalTimer.time_left != 0 and discontinued and just_pressed_vector == Vector2.ZERO and !just_released:
		return input_vector
	
	#get the direction from all direction input types
	input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	input_vector += Input.get_vector("ui_lstick_left", "ui_lstick_right", "ui_lstick_up", "ui_lstick_down")
	input_vector += Input.get_vector("ui_rstick_left", "ui_rstick_right", "ui_rstick_up", "ui_rstick_down")
	#reduce to unit vectors
	input_vector = _get_vector_sign(input_vector)
	
	if discontinued:
		if just_pressed_vector != Vector2.ZERO or just_released:
			input_vector = just_pressed_vector
			intervalTimer.wait_time = SLOWTIME
			intervalSwitchTimer.start()
			intervalTimer.start()
		if input_vector != Vector2.ZERO and intervalTimer.time_left == 0:
			intervalTimer.start()
	
	return input_vector

func _get_vector_sign(vector2: Vector2, threshold := 0) -> Vector2:
	var vector = Vector2.ZERO
	if abs(vector2.x) > threshold:
		vector.x = sign(round(vector2.x))
	if abs(vector2.y) > threshold:
		vector.y = sign(round(vector2.y))
	return vector

func consume_all_directions():
	for a in ["ui_up", "ui_down", "ui_left", "ui_right",\
	"ui key_up", "ui_key_down", "ui_key_left", "ui_key_right",\
	"ui_dpad_up", "ui_dpad_down", "ui_dpad_left", "ui_dpad_right",\
	"ui_lstick_up", "ui_lstick_down", "ui_lstick_left", "ui_lstick_right",\
	"ui_lstick_up", "ui_lstick_down", "ui_lstick_left", "ui_lstick_right"]:
		Input.action_release(a)
	get_tree().set_input_as_handled()

func _on_IntervalSwitchTimer_timeout():
	if get_controls_vector() != Vector2.ZERO:
		intervalTimer.wait_time = FASTTIME

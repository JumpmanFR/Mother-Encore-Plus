extends Node
class_name Shaker
#Used for shaking a Vector2 attribute


var _playing := false

var _timer := 0.0
var _shakes_left: int

var _shake_length: float # The time between movements during the shake
var _shake_interval: float # The amount of movement in a shake
var _shake_lerp_weight: float # The amount the shake is reduced after each movement
var _diminishing: bool # The direction to shake in
var _shake_magnitude: float # Flips between -1 and 1 to determine the position
var _shake_magnitude_reduction: float = 0.0 # x determines the multiplier when shake_side = -1, y determines the multiplier when shake_side = 1
var _shake_direction: Vector2 # The original offset of the property
var _shake_side = 1
var _shake_side_amplitude := Vector2.ONE
var _old_offset = Vector2.ZERO
var _dir: Vector2
var _shaked_object = null
var _shaked_property = ""

signal finished_shake

# The shake's constructor
func _init(object: Node2D, property: String, direction := Vector2.ZERO, magnitude := 1.0, length := 1.0, interval := 0.2, weight := 0.5, diminish := true) -> void :
	_shaked_object = object
	_old_offset = object.get(property)
	_shaked_property = property
	_shake_direction = direction
	_dir = _shake_direction
	_shake_magnitude = magnitude
	_diminishing = diminish
	_shake_length = length
	_shake_interval = interval
	_shake_lerp_weight = weight
	object.add_child(self)

func set_shake_direction(direction: Vector2) -> Shaker:
	_shake_direction = direction
	_dir = _shake_direction
	return self

func set_shake_magnitude(magnitude: float) -> Shaker:
	_shake_magnitude = magnitude
	return self

func set_shake_length(length: float) -> Shaker:
	_shake_length = length
	return self

func set_shake_interval(interval: float) -> Shaker:
	_shake_interval = interval
	return self

func set_shake_weight(weight: float) -> Shaker:
	_shake_lerp_weight = weight
	return self

func set_shake_side_amplitude(left_side: float, right_side: float) -> Shaker:
	_shake_side_amplitude = Vector2(left_side, right_side)
	return self

func set_shake_diminish(diminish: bool) -> Shaker:
	_diminishing = diminish
	return self

func _calculate_shakes_left() -> int:
	return int(_shake_length / _shake_interval)

func _update_shakes_left():
	_shakes_left = int(_shake_length / _shake_interval)

func _update_shake_reduction():
	if _diminishing:
		_shake_magnitude_reduction = (_shake_magnitude / _calculate_shakes_left())
	else:
		_shake_magnitude_reduction = 0

func start() -> Shaker:
	_update_shakes_left()
	_update_shake_reduction()
	_playing = true
	
	return self

func pause() -> Shaker:
	_playing = false
	
	return self

func is_playing() -> bool:
	return _playing

func stop():
	_shaked_object.set(_shaked_property, _old_offset)
	_shaked_object = null
	emit_signal("finished_shake")
	queue_free()

func _physics_process(delta: float) -> void :
	if _playing:
		if _shakes_left > 0:
			_timer += delta
			if _timer >= _shake_interval:
				_shakes_left -= 1
				_shake_side = _shake_side * -1
				_timer -= _shake_interval
				var new_side = _shake_side
				
				if new_side == 1:
					new_side *= _shake_side_amplitude.y
				else:
					new_side *= _shake_side_amplitude.x
				
				# Make it so if the shake magnitude is less than a pixel, 
				# it sets the magnitude to either 0 or 1
				var new_magnitude = max(_shake_magnitude, 1.0)
				if _shake_magnitude <= 0.5 and _shake_side == - 1:
					new_magnitude = 0
				
				var offsetting:Vector2
				var old__dir = _dir
				if _shake_direction != Vector2.ZERO:
					offsetting = Vector2(new_side, new_side)
				else:
					offsetting = Vector2(1, 1)
					while (_dir == old__dir):
						_dir = Vector2(round(rand_range(-1, 1)), round(rand_range(-1, 1)))
				var new_offset = offsetting * _dir * new_magnitude
				new_offset += _old_offset
				
				var initial_value = _shaked_object.get(_shaked_property)
				var new_value: Vector2
				if _shakes_left > 1:
					new_value = new_offset
				else:
					new_value = _old_offset
				
				if _shake_magnitude <= 1:
					_shaked_object.set(_shaked_property, new_value)
				else:
					_shaked_object.set(_shaked_property, lerp(initial_value, new_value, _shake_lerp_weight))
			
			if _diminishing:
				_shake_magnitude -= _shake_magnitude_reduction
		else:
			stop()


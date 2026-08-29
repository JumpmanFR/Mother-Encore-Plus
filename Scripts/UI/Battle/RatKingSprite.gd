extends "res://Scripts/UI/Battle/EnemySprite.gd"

const RAT_KING_JUMP_HEIGHTS = [30, 20]
const RAT_KING_JUMP_DURATION = 0.3
const RATS_JUMP_HEIGHTS = [20, 10]
const RATS_JUMP_DURATION = 0.3
const JUMP_STRETCH_SCALE = Vector2(0.9, 1.1)

const RECLOAK_JUMP_DURATION = 0.3
const RECLOAK_JUMP_HEIGHT = 20

const RAT_SPRITE = "res://Graphics/Battle Sprites/stronger rat.png"
const SMALL_RAT_KING_SPRITE = "res://Graphics/Battle Sprites/rat king sprites/stronger rat king.png"
const RAT_KING_SPRITE = "res://Graphics/Battle Sprites/rat king.png"

const CLOAK_ANIM_DURATION = 2.0
const CLOAK_SWAY_DURATION = CLOAK_ANIM_DURATION / 4.0
const CLOAK_FALL_HEIGHT = 20
const CLOAK_SWAY_DIST = 15
const CLOAK_ROT_DIST = 10

onready var _stronger_rat = $strongerrat
onready var _stronger_rat_2 = $strongerrat2
onready var _cloak = $cloak
onready var _original_sprite_pos = _sprite.position
var _original_cloak_pos: Vector2

func _ready():
	_stronger_rat.appear()
	_stronger_rat_2.appear()
	set_texture(RAT_KING_SPRITE)
	_cloak.position = _sprite.position
	
	_stronger_rat.set_texture(RAT_SPRITE)
	_stronger_rat_2.set_texture(RAT_SPRITE)
	_set_z_indexes()

func _set_z_indexes():
	_stronger_rat.get_sprite().z_index = - 1
	_stronger_rat_2.get_sprite().z_index = - 1
	_cloak.z_index = - 2

func _reset_z_indexes():
	_stronger_rat.get_sprite().z_index = 0
	_stronger_rat_2.get_sprite().z_index = 0
	_cloak.z_index = - 1

func _reparent(object, to_self = true):
	var global_pos = object.get_global_position()
	if to_self:
		object.get_parent().remove_child(object)
		add_child(object)
	else:
		remove_child(object)
		get_parent().add_child(object)
	object.set_global_position(global_pos)
	return global_pos

func _animate_cloak():
	var sway_dist = CLOAK_SWAY_DIST
	var rot_dist = CLOAK_ROT_DIST
	
	var end_pos_y = _cloak.position.y + CLOAK_FALL_HEIGHT
	
	if randi() % 2 == 1:
		sway_dist *= - 1
		rot_dist *= - 1
	
	create_tween().tween_property(_cloak, "position:y", end_pos_y, CLOAK_ANIM_DURATION)\
	.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	var sway_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	sway_tween.tween_property(_cloak, "position:x", _cloak.position.x + sway_dist, CLOAK_SWAY_DURATION)
	sway_tween.parallel().tween_property(_cloak, "rotation_degrees", rot_dist, CLOAK_SWAY_DURATION)
	
	sway_tween.chain().tween_property(_cloak, "position:x", _cloak.position.x - sway_dist, CLOAK_SWAY_DURATION * 2)
	sway_tween.parallel().tween_property(_cloak, "rotation_degrees", - rot_dist, CLOAK_SWAY_DURATION * 2)
	
	sway_tween.chain().tween_property(_cloak, "position:x", _cloak.position.x, CLOAK_SWAY_DURATION)
	sway_tween.parallel().tween_property(_cloak, "rotation_degrees", 0, CLOAK_SWAY_DURATION)

func uncloak():
	_set_z_indexes()
	yield(_shake(), "completed")
	
	$AnimationPlayer.play("prepareUncloak");yield($AnimationPlayer, "animation_finished")
	
	set_texture(SMALL_RAT_KING_SPRITE)
	_reparent(_cloak, false)
	_animate_cloak()
	_original_cloak_pos = _cloak.get_global_position()
	
	for object in [_cloak, _stronger_rat, _stronger_rat_2]:
		object.show()
	
	_stronger_rat.rect_position = Vector2(0, 20)
	_stronger_rat_2.rect_position = Vector2(0, 40)
	$AnimationPlayer.play("uncloak");yield($AnimationPlayer, "animation_finished")
	
	_uncloak_jump(self)
	yield(get_tree().create_timer(0.2), "timeout")
	if randi() % 2 == 1:
		_uncloak_jump(_stronger_rat)
		yield(get_tree().create_timer(0.2), "timeout")
		yield(_uncloak_jump(_stronger_rat_2, true), "finished")
	else:
		_uncloak_jump(_stronger_rat, true)
		yield(get_tree().create_timer(0.2), "timeout")
		yield(_uncloak_jump(_stronger_rat_2), "finished")
	yield(get_tree(), "idle_frame")
	_reset_z_indexes()

func recloak():
	var cloak_global_pos = _reparent(_cloak).round()
	_cloak.set_global_position(cloak_global_pos - Vector2(1, 0))
	
	yield(_recloak_jump(), "completed")
	
	var i = 0
	for node in get_parent().get_children():
		if node != self and node.visible:
			_reparent(node)
			if i == 0:
				_stronger_rat = node
				node.name = "strongerrat"
			else:
				_stronger_rat_2 = node
				node.name = "strongerrat2"
			
			i += 1
	_set_z_indexes()
	
	var tween = create_tween().set_parallel()
	for rat in [_stronger_rat, _stronger_rat_2]:
		tween.tween_property(rat, "rect_position", Vector2.ZERO, 0.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(_cloak, "position", _original_sprite_pos, 0.4)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	yield(tween, "finished")
	$AnimationPlayer.play("prepareUncloak");yield($AnimationPlayer, "animation_finished")
	
	
	rect_global_position -= Vector2(10, 30.5)
	rect_scale = Vector2(0.3, 0.2)
	set_texture(RAT_KING_SPRITE)
	_cloak.set_global_position(_original_cloak_pos)
	for object in [_cloak, _stronger_rat, _stronger_rat_2]:
		object.hide()
	
	$AnimationPlayer.play("appear");yield($AnimationPlayer, "animation_finished")


func transition(new_position: Vector2, callback: FuncRef, cb_params: Array):
	.transition(new_position, callback, cb_params)
	if _sprite.position != _original_sprite_pos:
		_transition_tween.parallel().tween_property(_sprite, "position", _original_sprite_pos, 0.4)

func _shake():
	var tween = create_tween()
	for i in range(2):
		for j in range(4):
			tween.tween_property(_sprite, "position:x", _sprite.position.x + 3, 0.04).set_ease(Tween.EASE_OUT)
			tween.tween_property(_sprite, "position:x", _sprite.position.x, 0.04).set_ease(Tween.EASE_IN)
		tween.tween_interval(0.1)
	yield(tween, "finished")

func _uncloak_jump(object, to_right = false):
	var is_rat_king = object == self
	var jump_heights = RATS_JUMP_HEIGHTS
	var duration = RATS_JUMP_DURATION
	if is_rat_king:
		jump_heights = RAT_KING_JUMP_HEIGHTS
		duration = RAT_KING_JUMP_DURATION
	
	var jumps_num = jump_heights.size()
	
	var height_summation := 0.0
	for h in jump_heights:
		height_summation += h
	
	var jump_zone = $ratKingJumpZone if is_rat_king else $strongerRatJumpZone if object == _stronger_rat else $strongerRatJumpZone2
	var target_pos = _get_random_point(jump_zone)
	
	if is_rat_king and randi() % 2 == 1:
		target_pos = Vector2(2 * _sprite.position.x - target_pos.x + 12, target_pos.y)
	elif !is_rat_king and to_right:
		target_pos = Vector2(2 * object.rect_position.x - target_pos.x, target_pos.y)
	
	var tween_object = _sprite if is_rat_king else object
	var tween_property = "position" if is_rat_king else "rect_position"
	var scale_tween_property = "scale" if is_rat_king else "rect_scale"
	
	var start_pos = tween_object.get(tween_property)
	var x_tween = create_tween()
	var y_tween = create_tween().set_trans(Tween.TRANS_SINE)
	var scale_tween = create_tween().set_trans(Tween.TRANS_SINE)
	x_tween.tween_property(tween_object, tween_property + ":x", target_pos.x, duration).set_ease(Tween.EASE_IN_OUT)
	
	var current_pos_y = start_pos.y
	for i in range(jumps_num):
		var jump_duration = duration * jump_heights[i] / height_summation
		var current_jump_height = jump_heights[min(i, jump_heights.size() - 1)]
		var next_y_target = lerp(start_pos.y, target_pos.y, (i + 1.0) / jumps_num)
		var peak_y = min(current_pos_y, next_y_target) - current_jump_height
		
		var normal_scale = tween_object.get(scale_tween_property)
		
		scale_tween.tween_property(tween_object, scale_tween_property, JUMP_STRETCH_SCALE, jump_duration / 4).set_ease(Tween.EASE_OUT)
		y_tween.tween_property(tween_object, tween_property + ":y", peak_y, jump_duration / 2).set_ease(Tween.EASE_OUT)
		
		scale_tween.tween_property(tween_object, scale_tween_property, normal_scale, jump_duration / 4).set_ease(Tween.EASE_IN)
		y_tween.tween_property(tween_object, tween_property + ":y", next_y_target, jump_duration / 2).set_ease(Tween.EASE_IN)
		
		current_pos_y = next_y_target
	
	return x_tween

func _recloak_jump():
	var cur_y = _sprite.position.y
	var peak_y = cur_y - RECLOAK_JUMP_HEIGHT
	
	for i in range(2):
		var scale_tween = create_tween().set_trans(Tween.TRANS_SINE)
		var tween = create_tween().set_trans(Tween.TRANS_SINE)
		
		scale_tween.tween_property(_sprite, "scale", JUMP_STRETCH_SCALE, RECLOAK_JUMP_DURATION / 4).set_ease(Tween.EASE_OUT)
		tween.tween_property(_sprite, "position:y", peak_y, RECLOAK_JUMP_DURATION / 2).set_ease(Tween.EASE_OUT)
		
		scale_tween.tween_property(_sprite, "scale", Vector2.ONE, RECLOAK_JUMP_DURATION / 4).set_ease(Tween.EASE_IN)
		tween.tween_property(_sprite, "position:y", cur_y, RECLOAK_JUMP_DURATION / 2).set_ease(Tween.EASE_IN)
		yield(tween, "finished")
	
	yield(get_tree().create_timer(0.2), "timeout")

func _get_random_point(area: Area2D) -> Vector2:
	var rectangle = area.get_node("CollisionShape2D")
	var size = rectangle.shape.extents * 2
	var center_pos = area.position + rectangle.position
	var top_left_corner = center_pos - size / 2
	
	return Vector2(
			rand_range(top_left_corner.x, top_left_corner.x + size.x), 
			rand_range(top_left_corner.y, top_left_corner.y + size.y))

func get_stronger_rats_sprites() -> Array:
	return [_stronger_rat, _stronger_rat_2] if _stronger_rat.rect_position.x < _stronger_rat_2.rect_position.x else [_stronger_rat_2, _stronger_rat]

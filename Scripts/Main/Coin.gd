extends KinematicBody2D

export (NodePath)onready var _sprite = get_node_or_null(_sprite) as Sprite
export (NodePath)onready var _animation_player = get_node_or_null(_animation_player) as AnimationPlayer

export (NodePath)onready var _drop_sfx = get_node_or_null(_drop_sfx) as AudioStreamPlayer2D
export (AudioStream)onready var _collect_sfx

onready var collisions = $Area2D / CollisionShape2D


const MIN_SPEED: = 50
const MAX_SPEED: = 80
const AIR_TIME_MULTIPLIER: = 0.012
const MIN_HEIGHT: = 20
const MAX_HEIGHT: = 28
const DECELERATION: = 200

var _direction: Vector2
var _speed: = 70.0
var _cash_amount: = 1
var _start_air_time: = 1.0
var _air_time: = 1.0
var _max_height: = 10.0
var _grounded: = true

func _ready():
	randomize_movement()
	start_jump()

func randomize_movement():
	_speed = rand_range(MIN_SPEED, MAX_SPEED)
	_direction = Vector2.RIGHT.rotated(randi() % 360)

func start_jump():
	_set_collisions_disabled(true)
	_animation_player.play("Flipping")
	var height = rand_range(MIN_HEIGHT, MAX_HEIGHT)
	_air_time = height * AIR_TIME_MULTIPLIER
	_start_air_time = _air_time
	
	
	var tween = get_tree().create_tween()
	tween.tween_property(_sprite, "offset:y", - height, _air_time / 2)
	tween.tween_property(_sprite, "offset:y", 0, _air_time / 2)
	tween.play()
	_grounded = false
	
	yield(tween, "finished")
	var anim = "Grounded"
	_animation_player.play(anim)
	_drop_sfx.play()
	_set_collisions_disabled(false)
	_grounded = true
	yield(get_tree(), "idle_frame")
	_animation_player.seek(rand_range(0.0, _animation_player.get_animation(anim).length), true)

func _set_collisions_disabled(disabled: bool):
	collisions.set_deferred("disabled", disabled)

func _physics_process(delta):
	if _speed > 0.0 and not _grounded:
		move_and_slide(_direction * _speed)
		
		_speed -= DECELERATION * delta
	else:
		position = position.round()
		set_physics_process(false)

func _collect():
	_set_collisions_disabled(true)
	$CollisionShape2D.set_deferred("disabled", true)
	uiManager.add_cash(_cash_amount)
	_animation_player.play("Collect")
	audioManager.play_sfx(_collect_sfx, "Coin")
	yield(_animation_player, "animation_finished")
	queue_free()

func _on_Area2D_body_entered(body):
	if body is PartyObject:
		_collect()

func _on_Area2D_area_entered(area):
	if area.get_collision_layer_bit(1):
		_collect()

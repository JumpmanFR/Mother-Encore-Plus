extends KinematicBody2D
class_name Bomb

signal exploded
signal jump_done
signal bat_interact
signal beam_interact

export (NodePath)onready var _animation_player = get_node(_animation_player) as AnimationPlayer
export var explosion: PackedScene
export var explosion_offset: Vector2
export var hit_sound: AudioStream

export var hit_cam_shake_direction := Vector2(0, 0)
export var hit_cam_shake_magnitude := 2
export var hit_cam_shake_length := 0.1
export var hit_cam_shake_interval := 0.01

var _initSpriteHeight: float
var _respawnable: bool

func _ready():
	_initSpriteHeight = $main.position.y
	
	global.get_player().connect("paused", self, "_on_player_pause")
	global.get_player().connect("unpaused", self, "_on_player_unpause")

func set_respawnable(r := true):
	_respawnable = r

func explode():
	if visible:
		var bomb_explosion = explosion.instance()
		bomb_explosion.global_position = global_position + explosion_offset
		get_parent().add_child(bomb_explosion)
		emit_signal("exploded")
		hide()
		queue_free()

func jump(height := 32, ascendLength := 0.3, hangTime := 0.1, descendLength := 0.3, disableCollisions := true):
	yield(get_tree(), "idle_frame")
	if disableCollisions:
		set_collisions(false)
	var tween = create_tween()
	tween.tween_property($main, "position:y", _initSpriteHeight - height, ascendLength)\
	.set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_property($main, "position:y", _initSpriteHeight, descendLength)\
	.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(hangTime)
	yield(tween, "finished")
	if disableCollisions:
			set_collisions(true)
	emit_signal("jump_done")
	print("jump done")

func set_collisions(enabled: bool):
	$CollisionShape2D.set_deferred("disabled", not enabled)

func bat_interaction():
	pass

func beam_interaction(beamArea):
	pass


func _on_player_pause():
	set_physics_process(false)
	_animation_player.playback_speed = 0
		


func _on_player_unpause():
	set_physics_process(true)
	_animation_player.playback_speed = 1
	

func _on_Hurtbox_area_entered(area):
	if area.get_collision_layer_bit(1) == true:
		print("bat interaction")
		emit_signal("bat_interact")
		global.currentCamera.shake_camera(hit_cam_shake_magnitude, hit_cam_shake_length, hit_cam_shake_direction, hit_cam_shake_interval)
		global.get_player().hit_stop(hit_cam_shake_length, 0, false, 0.5, "Bat")
		audioManager.play_sfx(hit_sound, "bomb")
		bat_interaction()
	elif area.get_collision_layer_bit(2) == true and area.get_groups().has("BeamArea"):
		emit_signal("beam_interact")
		beam_interaction(area)
	elif (area.get_collision_layer_bit(3) == true or area.get_collision_layer_bit(7) == true):
		explode()

func _on_VisibilityNotifier2D_screen_exited():
	if _respawnable:
		emit_signal("exploded")
		emit_signal("bat_interact")
		queue_free()

class_name AbstractSwitch
extends FlaggableObject

signal switch_hit

onready var _audio_player: AudioStreamPlayer = $AudioStreamPlayer
onready var _anim_player: AnimationPlayer = $AnimationPlayer

var _is_disabled := false
var _is_ready_to_interact := false

func _ready():
	yield(get_tree().create_timer(0.2), "timeout")
	_is_ready_to_interact = true

func _try_operate_manually():
	if !_is_disabled and !global.get_player().is_paused() and _is_ready_to_interact:
		_operate_manually()

func _operate_manually():
	if global.currentScene.can_switch:
		if _audio_player: _audio_player.playing = true
		if _anim_player and _anim_player.has_animation("Hit"):
			_anim_player.play("Hit")
		emit_signal("switch_hit")
		_do_switch_action()
	else:
		audioManager.play_sfx(load("res://Audio/Sound effects/M3/bump.wav"), "switch")


# Overridden
func _do_switch_action():
	pass

func interact():
	_try_operate_manually()

func _on_hit(area):
	_try_operate_manually()

func _on_player_entered(body):
	if body == global.get_player():
		_try_operate_manually()

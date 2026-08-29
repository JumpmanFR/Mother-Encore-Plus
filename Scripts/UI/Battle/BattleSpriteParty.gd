extends Control

signal apply_damage

export (int) var _hits: = 0
export var _distance_to_shown: = 20
const PSI_ANIMATIONS: = ["psiPrep2"]
const ATTACK_ANIMATIONS: = ["bash", "bat", "slingshot", "gun", "boomerang", "pan", "knife", "sword"]

var _shown_pos := 0.0
var _hide_pos := 0.0
var state: int = States.HIDDEN
var _dead := false
var _paralyzed := false
var _paralyzed_frame = null
var _tween: SceneTreeTween
var _prev_anim: String
var _prev_state: int


enum States{HIDDEN, SHOWN, BOUNCING}

onready var sprite = $Sprite
onready var _anim_player: AnimationPlayer = $AnimationPlayer

func _ready():
	_hide_pos = rect_position.y
	_shown_pos = rect_position.y - _distance_to_shown
	_anim_player.play("lookIntoYourSoul")

func _process(_delta):
	if _paralyzed and sprite.frame != _paralyzed_frame:
		sprite.frame = _paralyzed_frame

func play(anim:String, override := false) -> bool:
	var result := _anim_player.has_animation(anim)
	if !_anim_player.is_playing() or override:
		_anim_player.clear_queue()
		_anim_player.stop()
		_anim_player.play(anim)
	elif !override:
		_anim_player.queue(anim)
	if !"psi" in anim:
		$Sprite.material.set_shader_param("width", 0)
	return result
		
func set_psi_colors(colors: Array):
	for animationName in PSI_ANIMATIONS:
		var animation = _anim_player.get_animation(animationName)
		for i in range(3):
			animation.track_set_key_value(1, i, Color(colors[i]))

func _apply_damage():
	emit_signal("apply_damage")

func show_in():
	if _tween and _tween.is_running(): _reset_tween()
	else: _tween = create_tween().set_parallel()
	_tween.tween_property(self, "rect_position:y", _shown_pos, 0.12)
	state = States.SHOWN

func show_and_play(anim):
	show_in()
	play(anim)
	#$Tween.connect("tween_all_completed", _anim_player, "play", [anim], CONNECT_ONESHOT)

func hide_away(anim := "", override := false, queued := true):
	state = States.HIDDEN
	var is_loop: = false
	if queued and _anim_player.is_playing():
		is_loop = _anim_player.get_animation(_anim_player.current_animation).loop
		if not is_loop:
			yield(_anim_player, "animation_finished")
	if state == States.HIDDEN:
		if anim != "":
			play(anim, override)
		if _tween and _tween.is_running(): _reset_tween(is_loop)
		else: _tween = create_tween().set_parallel()
		_tween.tween_property(self, "rect_position:y", _hide_pos, 0.12)

func _reset_tween(retain_connections: = false):
	_tween.stop()
	_tween = create_tween().set_parallel()
	if retain_connections:
		_tween.connect("finished", self, "_play_after_hit", [_prev_anim, _prev_state], CONNECT_ONESHOT)


func dodge():
	var movement = 8
	if (randi() % 2 + 0) == 1:
		movement = - 8
	if not _tween or not _tween.is_running(): _tween = create_tween().set_parallel()
	_tween.tween_property(self, "rect_position:x", rect_position.x + movement, 0.1)\
	.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "rect_position:x", rect_position.x, 0.1).from(rect_position.x + movement)\
	.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN).set_delay(0.1)

func shake(magnitude):
	if not _tween or not _tween.is_running(): _tween = create_tween().set_parallel()
	_tween.tween_property(self, "rect_position:y", rect_position.y, 0.15).from(rect_position.y + 5)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "rect_position:x", rect_position.x, 0.2).from(rect_position.x + 10)\
	.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func bounce_up_hit(intensity = 1):
	if _tween and _tween.is_running(): _reset_tween()
	else: _tween = create_tween().set_parallel()
	var toAdd = 0
	if state == States.HIDDEN:
		toAdd = _distance_to_shown
	_tween.tween_property($Sprite, "scale", Vector2.ONE, 0.2).from(Vector2(0.6, 1.6))\
	.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "rect_position:y", rect_position.y - toAdd - 32 * intensity - 16, 0.2)\
	.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "rect_position:y", _hide_pos, 0.2).from(rect_position.y - toAdd - 32 * intensity - 16)\
	.set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN).set_delay(0.32)
	
	_prev_state = state
	state = States.BOUNCING
	
	var prev_anim_colors = []
	if not _anim_player.get_queue().empty():
		_prev_anim = _anim_player.get_queue()[ - 1]
	else:
		_prev_anim = _anim_player.assigned_animation
		if _prev_anim == "psiPrep2":
			for i in range(3):
				prev_anim_colors.append(_anim_player.get_animation("psiPrep2").track_get_key_value(1, i))
	
	var hitAnim = "hit"
	if _hits > 0:
		
		hitAnim = "hit" + var2str(int(round(rand_range(1, _hits))))
	play(hitAnim, true)
	if _prev_anim in ["psiPrep", "psiPrep2"]:
		set_psi_colors(prev_anim_colors)
	_tween.connect("finished", self, "_play_after_hit", [_prev_anim, _prev_state], CONNECT_ONESHOT)

func _play_after_hit(prev, prevState):
	if _dead:
		play("lookIntoYourSoul", true)
	else:
		_anim_player.clear_queue()
		play(prev, true)
		var anim = _anim_player.get_animation(prev)
		if prev != "psiPrep2":
			_anim_player.seek(anim.length, true)
		if prevState == States.SHOWN:
			show_in()

func is_attacking() -> bool:
	return _anim_player.current_animation in ATTACK_ANIMATIONS

func die():
	_dead = true
	if state != States.BOUNCING:
		play("lookIntoYourSoul", true)

func revive():
	_dead = false

func set_paralyzed(value: bool):
	_paralyzed = value
	if _paralyzed:
		_paralyzed_frame = 0
		sprite.frame = _paralyzed_frame
	else:
		_paralyzed_frame = null

func get_shown_global_position() -> Vector2:
	return Vector2(rect_global_position.x + rect_size.x/2, rect_global_position.y + rect_size.y/1.3 - _distance_to_shown )

tool 

extends Node2D

export (String, "Objects", "NPCs") var type := "Objects"
export (String, "ui_accept") var key := "ui_accept"
export var offset := Vector2.ZERO
export var enabled := true

var _force_show := false
var _force_hide := false

var _player_nearby := false
var _hidden := false

var _pressing_button := false

func _ready():
	_reset_scale()
	if !Engine.is_editor_hint():
		hide()
		_hidden = true
		set_process(false)
		_set_key_name()
		global.get_player().connect("event_detector_entered", self, "_on_player_nearby", [true])
		global.get_player().connect("event_detector_exited", self, "_on_player_nearby", [false])
		
		global.connect("inputs_changed", self, "_set_key_name")
		global.connect("locale_changed", self, "_set_key_name")
		global.get_player().connect("paused", self, "_on_player_toggle_pause")
		global.get_player().connect("unpaused", self, "_on_player_toggle_pause")

func _process(delta: float):
	position = offset
	if get_parent().get("scale") != null:
		_reset_scale()

func set_enabled(value: bool, quick := false):
	enabled = value
	_refresh_visibility(quick)

func force_show(quick := false):
	_force_show = true
	_force_hide = false
	_refresh_visibility(quick)

func force_hide(quick := false):
	_force_hide = true
	_force_show = false
	_refresh_visibility(quick)

func unforce_show_hide(quick := false):
	_force_show = false
	_force_hide = false
	_refresh_visibility(quick)

func _on_player_nearby(object, value: bool):
	if object == get_parent():
		_player_nearby = value
		_refresh_visibility()

func _on_player_toggle_pause():
	_refresh_visibility(true)

func press_button():
	if _can_show():
		_hidden = true
		_pressing_button = true
		$AnimationPlayer.play("Press")
		yield($AnimationPlayer, "animation_finished")
		_pressing_button = false
		emit_signal("hide")

func _reset_scale():
	position = offset
	position.x = position.x / get_parent().scale.x
	position.y = position.y / get_parent().scale.y
	scale.x = 1.0 / get_parent().scale.x
	scale.y = 1.0 / get_parent().scale.y

func _set_key_name():
	$HBoxContainer / Label.text = TextTools.get_key_name(key)

func _can_show() -> bool:
	return globaldata.button_prompts in [type, "Both"] and enabled

func _refresh_visibility(quick := false):
	if _pressing_button:
		return

	var should_show: bool = _can_show() and _player_nearby and !global.get_player().is_paused()
	should_show = (should_show or _force_show) and !_force_hide
	
	if _hidden and should_show:
		_hidden = false
		_reset_scale()
		_set_key_name()
		if !quick:
			$AnimationPlayer.play("Show")
		else:
			show()
			$AnimationPlayer.play("Float")
	
	elif !_hidden and !should_show:
		_hidden = true
		if !quick:
			$AnimationPlayer.play("Hide")
		else:
			$AnimationPlayer.stop()
			hide()

func _on_AnimationPlayer_animation_finished(anim_name: String):
	if anim_name == "Show" and visible:
		$AnimationPlayer.play("Float")

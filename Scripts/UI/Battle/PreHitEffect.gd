extends Control

onready var _anim_player: AnimationPlayer = $AnimationPlayer

signal apply_damage

func play(effect: String):
	if !_anim_player.is_connected("animation_finished", self, "_apply_damage"):
		_anim_player.connect("animation_finished", self, "_apply_damage")
	_anim_player.play(effect)
	_anim_player.advance(0)

func _apply_damage(_anim_name: String = ""):
	emit_signal("apply_damage")
	if _anim_player.is_connected("animation_finished", self, "_apply_damage"):
		_anim_player.disconnect("animation_finished", self, "_apply_damage")

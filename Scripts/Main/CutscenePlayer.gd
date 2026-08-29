extends AnimationPlayer
class_name CutscenePlayer

export var anim_name: String

func _input(event: InputEvent):
	if OS.is_debug_build() and event.is_action_pressed("ui_F1"):
		play_anim()

func play_anim():
	play(anim_name)

extends Control

func _ready():
	$Title/Earth.playing = true

func form_logo():
	$AnimationPlayer.play("Start")
	yield($AnimationPlayer, "animation_finished")

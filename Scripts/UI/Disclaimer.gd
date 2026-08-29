extends Control

onready var _fade = $CanvasLayer / Fade
onready var _door = $Objects / DoorToTitle

func _init():
	if OS.has_feature("dialogue_tester"):
		global.goto_scene("res://Maps/Testing/DialogueTester.tscn")

func _ready():
	global.get_player().pause(true)
	create_tween().tween_property(_fade, "modulate", Color.transparent, 3)\
	.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)

func _input(event: InputEvent):
	if ( not event is InputEventKey and not event is InputEventJoypadButton) or not event.pressed:
		return
	if OS.is_debug_build():
		for action in InputMap.get_actions():
			if (event is InputEventKey and event.is_action_pressed(action) and 
					(action in ["ui_load", "ui_translate", "ui_F11", "ui_F12"] or event.alt)):
				return
	_door.enter()

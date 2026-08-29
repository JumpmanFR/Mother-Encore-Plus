extends Node2D

export var flag = ""
export var New_parent : NodePath
export var called_object : NodePath
export var call_object_function = ""
export var object_function_disappear_flag = ""

onready var _anim_player = $AnimationPlayer
onready var sprite = $Sprite
onready var visibilityNotifier = $VisibilityNotifier2D
onready var new_parent = get_node_or_null(New_parent)
onready var calledObject = get_node_or_null(called_object)


func _ready():
	visibilityNotifier.connect("screen_entered", self, "show")
	visibilityNotifier.connect("screen_exited", self, "hide")
	hide()
	
	#make bush appear only when the flag is true
	
	if flag:
		if globaldata.flags.get(flag):
			_anim_player.play("Idle")
		else: _anim_player.play("Hidden")
	else: _anim_player.play("Idle")
	
	if New_parent == null:
		new_parent = get_parent()

func grow():
	global.start_joy_vibration(0, 0.5, 0.7, 0.8)
	_anim_player.play("Grow")
	yield(_anim_player, "animation_finished")
	_anim_player.play("Idle")

func interact():
	if visible:
		if globaldata.flags["bat"]:
			uiManager.open_dialogue_box("Reusable/easytobreak")
		else: uiManager.open_dialogue_box("Reusable/hardtobreak")

func _on_Hitbox_area_entered(area):
	var Roots = sprite.duplicate()
	Roots.frame = 1
	new_parent.add_child(Roots)
	Roots.position = sprite.global_position
	_anim_player.play("Break")
	$AudioStreamPlayer.play()
	$interact / ButtonPrompt.set_enabled(false)

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Break" and globaldata.flags.has(object_function_disappear_flag):
		if calledObject != null and call_object_function != "" and !globaldata.flags[object_function_disappear_flag]:
			calledObject.call_deferred(call_object_function)
		queue_free()

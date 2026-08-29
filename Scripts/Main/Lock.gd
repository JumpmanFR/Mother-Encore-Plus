extends FlaggableObject

var opened = false 

func _ready():
	if not _get_flag_status():
		return
	opened = true
	$AnimationPlayer.play("Opened")
	open()

func interact(): #Opens the door if you have a key. Otherwise it opens a dialog box that says you can't open it.
	if opened:
		return
	if not uiManager.try_alter_key_count( - 1):
		uiManager.open_dialogue_box("Reusable/locklocked")
		return
	$AnimationPlayer.play("Open")
	opened = true
	_set_flag_status()
	uiManager.update_key_indicator()
		

func open():
	$StaticBody2D/CollisionShape2D.disabled = true
	$interact / ButtonPrompt.enabled = false

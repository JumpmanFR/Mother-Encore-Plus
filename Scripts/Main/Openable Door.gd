tool

extends Sprite

export (Texture) var sprite setget _set_texture
export (Vector2) var door_offset = Vector2(0, - 32) setget _set_offset
export (String, "None", "M3/door_open.wav") var sound := "M3/door_open.wav"
export (String, "None", "Door_Short.mp3") var end_sound := "Door_Short.mp3"
export (String) var interact_doorblocked = "Reusable/doorblocked"
export (String) var interact_lockopened = "Reusable/lockopened"
export (String) var interact_locklocked = "Reusable/locklocked"
export (String) var key = ""
export (bool) var blocked = false
export (bool) var locked = false
export (bool) var remove_key = false
export (String) var flag = ""
export (String) var activates_flag = ""
export (String) var deactivates_flag = ""
export (bool) var one_way = false

var _unlocked := true

func _set_texture(tex: Texture):
	sprite = tex
	$Sprite.texture = sprite

func _set_offset(off: Vector2):
	door_offset = off
	if Engine.is_editor_hint():
		_update_positions()

func _update_positions():
	$Sprite.position = door_offset
	for obj in [$Area2D, $interact, $StaticBody2D, $NonPlayerStaticBody2D]:
		obj.position.y = door_offset.y + 32

func _ready():
	if Engine.is_editor_hint():
		return
	_update_positions()
	_update_door_state()
	global.connect("flags_updated", self, "_update_door_state")
	$AnimationPlayer.play("Normal")

func _update_door_state():
	if key or blocked or one_way or locked:
		lock()
	else:
		unlock()
	if flag and globaldata.flags.has(flag):
		_unlocked = globaldata.flags[flag]
		$interact/ButtonPrompt.enabled = not globaldata.flags[flag]
		

func _on_Area2D_body_entered(body):
	
	if locked and flag and globaldata.flags[flag]:
		unlock()
		locked = false
	if _is_valid_body_in_area() and $Timer.time_left == 0 and _unlocked\
	and $AnimationPlayer.current_animation == "Normal" and !one_way:
		open()
	
	if blocked and global.get_player().is_running() and global.get_player().get_direction().y == -1 and !_unlocked:
		global.currentCamera.shake_camera(1, 0.2, Vector2(2,0))
		open()
		unlock()
		blocked = false
		if flag and globaldata.flags.has(flag):
			globaldata.flags[flag] = true

func _on_Area2D_body_exited(body):
	if global.get_player().is_paused():
		$AnimationPlayer.play("Normal")
	elif !_is_valid_body_in_area(body) and _unlocked:
		$Timer.start()

func _on_Timer_timeout():
	if _is_valid_body_in_area():
		return
	$AnimationPlayer.play("Normal")
	if end_sound != "None" and not global.get_player().is_paused():
		close()
	if one_way: lock();close()

func close() -> void :
	$AudioStreamPlayer.stream = load("Audio/Sound effects/" + end_sound)
	$AudioStreamPlayer.play()

func open() -> void :
	$AnimationPlayer.play("Action")
	$interact / ButtonPrompt.hide()
	$interact / ButtonPrompt.enabled = false
	if sound == "None":
		return
	if blocked and not _unlocked:
		$AudioStreamPlayer.stream = load("res://Audio/Sound effects/bash.mp3")
	else:
		$AudioStreamPlayer.stream = load("Audio/Sound effects/" + sound)
	if not global.entering_door:
		$AudioStreamPlayer.play()

func unlock() -> void :
	$StaticBody2D/CollisionShape2D.set_deferred("disabled", true)
	$interact/ButtonPrompt.enabled = false
	_unlocked = true

func lock() -> void :
	$StaticBody2D/CollisionShape2D.set_deferred("disabled", false)
	$interact/ButtonPrompt.enabled = true
	_unlocked = false

func _use_key(key_item: Item) -> void :
	globaldata.flags[flag] = true
	open();unlock()
	if remove_key: Inventory.drop_item_from_party(key_item)

func interact() -> void :
	if _unlocked:
		return
	
	if activates_flag and globaldata.flags.has(activates_flag):
		globaldata.flags[activates_flag] = true
		global.emit_signal("flags_updated")
	
	if deactivates_flag and globaldata.flags.has(deactivates_flag):
		globaldata.flags[deactivates_flag] = false
		global.emit_signal("flags_updated")
	if blocked:
		uiManager.open_dialogue_box(interact_doorblocked)
	else:
		var key_item: = Inventory.find_item_for_all(key)
		if not key_item:
			uiManager.open_dialogue_box(interact_locklocked)
			return
		_use_key(key_item)
		global.item = key_item
		uiManager.open_dialogue_box(interact_lockopened)

func interact_item(item: Item) -> void :
	if _unlocked:
		return
	if not item.item_name == key or blocked:
		uiManager.open_dialogue_box(interact_doorblocked)
		return
	_use_key(item)
	global.item = item
	uiManager.open_dialogue_box(interact_lockopened)

func _is_valid_body_in_area(exclude_body = null) -> bool:
	var bodies = $Area2D.get_overlapping_bodies()
	for body in bodies:
		if body != exclude_body and body is PartyObject:
			return true
	return false

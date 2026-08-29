tool
extends ItemHolder

export (bool) var reset_when_consumed := false

func _ready():
	hide()
	if is_inside_tree():
		_update_sprite()
	if !Engine.is_editor_hint():
		if _get_flag_status():
			queue_free()
			return
		global.get_player().connect("paused", self, "_on_player_paused")
		global.get_player().connect("unpaused", self, "_on_player_unpaused")
	yield(get_tree(), "idle_frame")
	show()
	
func _set_item(t_item):
	item = t_item
	_update_sprite()

func _update_sprite():
	if not is_inside_tree():
		return
	var path: = str("res://Graphics/Objects/Items/%s.png" % item)
	var directory = Directory.new()
	var doesFileExist = directory.file_exists(path)
	if doesFileExist or not Engine.is_editor_hint():
		$Sprite.texture = load(path)
	else:
		$Sprite.texture = load("res://Graphics/Objects/Items/Error.png")

func _unparent_button_prompt():
	var button_prompt_node = get_node(button_prompt)
	button_prompt_node.force_show()
	if not button_prompt_node.visible:
		button_prompt_node.queue_free()
		return
	button_prompt_node.press_button()
	button_prompt_node.connect("hide", button_prompt_node, "queue_free")
	$interact.remove_child(button_prompt_node)
	get_parent().add_child(button_prompt_node)
	button_prompt_node.position = position + button_prompt_node.offset
	
# Override
func _check_item():
	._check_item()
	$Tween.start()

func disappear():
	$Timer.start(5)
	if global.get_player().is_paused():
		_on_player_paused()
	yield($Timer,"timeout")
	$AnimationPlayer.play("blink")
	$Timer.start(2)
	yield($Timer,"timeout")
	$AnimationPlayer.playback_speed = 2
	$Timer.start(2)
	yield($Timer,"timeout")
	$AnimationPlayer.playback_speed = 3
	$Timer.start(3)
	yield($Timer,"timeout")
	queue_free()

func _on_player_paused():
	$Timer.paused = true

func _on_player_unpaused():
	$Timer.paused = false

# Override
func _play_collect_item():
	_unparent_button_prompt()
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "global_position", global.get_player().global_position, 0.3) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT).set_delay(0.045)
	tween.tween_property(self, "scale", Vector2(0.5, 0), 0.20) \
			.from(Vector2(0.7, 1.3)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	yield(tween, "finished")
	queue_free()

# Override
func _play_revert():
	if item:
		$Tween.interpolate_property($Sprite, "rotation_degrees", 30, 0, 1, Tween.TRANS_ELASTIC,Tween.EASE_OUT)

func _exit_tree():
	if reset_when_consumed:
		_set_flag_status(false)
		

extends YSort

var movedObjects := []

func _ready():
	$BG.self_modulate.a = 0
	show()

func appear():
	global_position = global.currentCamera.get_camera_screen_center()
	#for partyMember in global.partyObjects:
	#	movedObjects.append([partyMember, partyMember.get_parent()])
	#	if partyMember.get("active") != null:
	#		partyMember.active = false
	#	partyMember.position -= position
	#	partyMember.get_parent().remove_child(partyMember)
	#	add_child(partyMember)
	var actors = uiManager.get_dialogue_actors()
	for i in actors:
		print(i)
		var actor = actors[i]
		if actor.get("position") != null:
			movedObjects.append([actor, actor.get_parent()])
			actor.position -= position
			actor.get_parent().remove_child(actor)
			add_child(actor)
	if global.talker != null:
		movedObjects.append([global.talker, global.talker.get_parent()])
		global.talker.position -= position
		global.talker.get_parent().remove_child(global.talker)
		add_child(global.talker)
	$AnimationPlayer.play("Melody")
	create_tween().tween_property($BG, "self_modulate", Color8(255, 255, 255, 255), 0.5) \
			.from(Color8(255, 255, 255, 0)).set_ease(Tween.EASE_OUT)

func disappear():
	yield(create_tween().tween_property($BG, "self_modulate", Color8(255, 255, 255, 0), 0.5) \
			.set_ease(Tween.EASE_OUT), "finished")
	$AnimationPlayer.stop()
	for i in movedObjects:
		if i[0].get("active") != null:
			i[0].active = true
		i[0].position += position
		remove_child(i[0])
		i[1].add_child(i[0])
	movedObjects.clear()

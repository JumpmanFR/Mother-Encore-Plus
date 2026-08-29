extends YSort


func summon_old_man():
	$Fountain.get_node("AnimationPlayer").play("Appear")
	for i in get_child_count():
		if i != 0:
			get_child(i).get_node("AnimationPlayer").play("Glow")

func goodbye_old_man():
	$Fountain.get_node("AnimationPlayer").play("Disappear")
	for i in get_child_count():
		if i != 0:
			get_child(i).get_node("AnimationPlayer").play("Glow")

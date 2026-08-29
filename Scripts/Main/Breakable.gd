extends FlaggableObject

export var contents: NodePath
export (bool) var Drop_item_if_hidden
export var Drop_where: NodePath
export var New_parent: NodePath
export var appear_flag = ""
export var disappear_flag = ""
export var interact_content = false
export var pause_on_break := false
export var coins_spawned := 5
export var coin_spawner: NodePath
onready var coinSpawner = get_node_or_null(coin_spawner) as CoinSpawner
onready var item = get_node_or_null(contents)
onready var dropOff = get_node_or_null(Drop_where)
onready var newParent = get_node_or_null(New_parent)

func _ready():
	_check_flags()
	set_item()

func _on_Hurtbox_area_entered(_area):
	
	if pause_on_break: global.get_player().pause()
	
	var distance = global_position.distance_to(_area.global_position)
	var delay = 0.002 * distance
	
	if delay > 0.06: delay = 0.06
	
	yield(get_tree().create_timer(delay), "timeout")
	
	global.start_joy_vibration(0, 0.5, 0.8, 0.2)
	$AnimationPlayer.play("Break")
	$Hurtbox.set_collision_layer_bit(0, false)
	$Hurtbox.set_collision_layer_bit(1, false)
	$Hurtbox.set_collision_layer_bit(2, false)
	$Hurtbox.set_collision_mask_bit(1, false)
	$StaticBody2D / CollisionShape2D.set_deferred("disabled", true)
	$StaticBody2D.set_collision_layer_bit(1, false)
	set_item()
	if item != null:
		_drop()
	
	if coinSpawner and coins_spawned > 0 and !_get_flag_status():
		_set_flag_status(true)
		coinSpawner.spawn_coins(coins_spawned)
	
	yield($AnimationPlayer, "animation_finished")
	
	if get_parent() != newParent and newParent:
		get_parent().remove_child(self)
		newParent.add_child(self)

func set_item():
	if !is_visible() and Drop_item_if_hidden:
		item.position = position
	item = get_node_or_null(contents)

func _check_flags():
	visible = globaldata.check_appear_disappear_flags(appear_flag, disappear_flag)
	if !visible: queue_free()

func _drop():
	if dropOff == null:
		dropOff = global.currentScene.get_node("Objects")
	
	if item.get("start_pos") != null:
		item.start_pos = $Position2D.global_position
	
	if item.get("changingParents") != null:
		item.changingParents = true
	
	
	var children = item.get_children()
	
	for child in children:
		if child is Area2D or child is KinematicBody2D:
			var childrens_children = child.get_children()
			for childs_child in childrens_children:
				if childs_child is CollisionShape2D or childs_child is CollisionPolygon2D:
					childs_child.set_deferred("disabled", true)
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", true)
	item.get_parent().remove_child(item)
	dropOff.call_deferred("add_child", item)
	item.call_deferred("set", "position", $Position2D.global_position)
	if Drop_where == "Objects" or Drop_where == "":
		item.hide()
	
	$Timer.start()
	yield($Timer, "timeout")
	
	item.set_physics_process(false)
	for child in children:
		if child is Area2D or child is KinematicBody2D:
			var childrens_children = child.get_children()
			for childs_child in childrens_children:
				if childs_child is CollisionShape2D or childs_child is CollisionPolygon2D:
					childs_child.set_deferred("disabled", false)
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", false)
	
	if item.get("changingParents") != null:
		item.changingParents = false
	
	if interact_content:
		interact(item)
	
	
	if dropOff.name == "Objects":
		item.show()
		yield(create_tween().tween_property(item, "position", Vector2(item.position.x, item.position.y - 6), 0.1)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT), "finished")
		
		create_tween().tween_property(item, "position", Vector2(item.position.x, item.position.y + 6), 0.2)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	item.set_physics_process(true)

func interact(object):
	if object.has_method("interact"): object.interact()

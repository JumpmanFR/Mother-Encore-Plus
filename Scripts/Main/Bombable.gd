extends DisappearingFlaggableObject

export var New_parent: NodePath
export var coin_spawner: NodePath

onready var newParent = get_node_or_null(New_parent)
onready var coinSpawner = get_node_or_null(coin_spawner) as CoinSpawner

func _on_Hurtbox_area_entered(area):
	_set_flag_status(true)
	if coinSpawner:
		coinSpawner.spawn_coins()
	$AnimationPlayer.play("Break")
	global.currentCamera.shake_camera(4, 0.2, Vector2.ZERO)
	yield($AnimationPlayer, "animation_finished")
	if get_parent() != newParent and newParent:
		get_parent().remove_child(self)
		newParent.add_child(self)

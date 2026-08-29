extends Position2D

export (String) var enemy
export var _return = true
export var _perma_death = false
export var _appearance_rate = 100
export var _inital_direction = Vector2.ZERO

var _enemy_scene

var _attached_enemy = null


func _ready():
	$Sprite.queue_free()
	var enemyData = globaldata.get_enemy_data(enemy.replace(" ", ""))
	var ov_type = enemyData["ov"].get("type", "Basic Enemy")
	_enemy_scene = load("res://Nodes/Overworld/Enemies/%s.tscn" % ov_type)

func _set_attached_enemy(enemy_node):
	_attached_enemy = enemy_node
	if _attached_enemy == null and is_inside_tree():
		$Timer.start()

func _on_VisibilityNotifier2D_screen_entered():
	if randi() % 100 > _appearance_rate or _appearance_rate == 0 or _attached_enemy\
	or uiManager.is_in_cutscene() or $Timer.time_left > 0:
		return
	
	_create_enemy()
	if _perma_death:
		queue_free()

func _create_enemy():
	var new_parent = global.currentScene.get_node("Objects")
	var enemy_node = _enemy_scene.instance()

	enemy_node.enemy = enemy
	enemy_node.returning = _return
	enemy_node.global_position = self.global_position
	enemy_node.start_pos = enemy_node.global_position
	new_parent.add_child(enemy_node)
	
	if _inital_direction != Vector2.ZERO and enemy_node.get("direction") != null:
		enemy_node.set_direction_and_input(_inital_direction)
	enemy_node.connect("enemy_erased", self, "_set_attached_enemy", [null])
	_set_attached_enemy(enemy_node)

func _on_Enemy_Spawner_tree_exited():
	if _attached_enemy != null:
		_attached_enemy.die(false)

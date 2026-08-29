extends AbstractSpawner
class_name BombSpawner

export var SpawnedBomb: NodePath

onready var attached_bomb : Bomb = get_node_or_null(SpawnedBomb)

var entry_blocked = false
var can_spawn = true
var on_screen = false

func _ready():
	if attached_bomb != null:
		attached_bomb.connect("exploded", self, "spawn_bomb")
	else:
		can_spawn = true

func create_bomb():
	var bomb : Bomb = create_object()
	create_tween().tween_property(bomb, "global_position", $EndPos.global_position, 0.1) \
			.from($StartPos.global_position).set_ease(Tween.EASE_IN)
	bomb.set_respawnable()
	attached_bomb = bomb
	attached_bomb.connect("exploded", self, "bomb_exploded")
	if $AnimationPlayer.has_animation("Close"):
		attached_bomb.connect("bat_interact", $AnimationPlayer, "play", ["Close"], CONNECT_ONESHOT)

func bomb_exploded():
	can_spawn = true
	if on_screen:
		spawn_bomb()

func spawn_bomb():
	can_spawn = false
	yield(get_tree().create_timer(0.8), "timeout")
	Shaker.new($Sprite, "offset")\
	.set_shake_direction(Vector2.ZERO)\
	.set_shake_magnitude(4)\
	.set_shake_length(0.2)\
	.set_shake_interval(0.02).start()
	
	while (true):
		yield(get_tree().create_timer(0.5),"timeout")
		if (!entry_blocked):
			break	
	
	$AnimationPlayer.play("Spawn")

func _on_Area2D_body_entered(body):
	if body == global.get_player():
		entry_blocked = true

func _on_Area2D_body_exited(body):
	if body == global.get_player():
		entry_blocked = false

func _on_VisibilityNotifier2D_screen_entered():
	on_screen = true
	if can_spawn:
		spawn_bomb()

func _on_VisibilityNotifier2D_screen_exited():
	on_screen = false

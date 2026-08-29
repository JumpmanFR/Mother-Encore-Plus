extends Sprite

export var infinite_mouse = false

var Mouse = load("res://Nodes/Overworld/Enemies/Basic Enemy.tscn")
var _is_mouse
var _mouse_respawn = true

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite.frame = 0
	$Sprite.visible = false

func _on_Area2D_body_entered(body):
	if body != global.get_player():
		return
	_is_mouse = global.currentScene.get_node_or_null("Objects/" + self.name)
	if _is_mouse == null and _mouse_respawn == true and $Timer.time_left == 0:
		$AnimationPlayer.play("Come out")
		if infinite_mouse == false:
			_mouse_respawn = false

func create_mouse():
	var new_parent = global.currentScene.get_node("Objects")
	var mouse = Mouse.instance()
	mouse.enemy = "rat"
	mouse.name = self.name
	mouse.global_position = self.global_position
	mouse.set_direction_and_input(Vector2(0,1))
	mouse.walk_frequency = 0.6
	new_parent.add_child(mouse)
	
	yield(create_tween().tween_property(mouse, "global_position", Vector2(self.global_position.x, self.global_position.y + 3), 0.1) \
			.set_ease(Tween.EASE_IN), "finished")
	mouse.start_pos = mouse.global_position
	$Timer.start()

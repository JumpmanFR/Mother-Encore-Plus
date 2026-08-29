extends Sprite

export var interval = 4.0
export var delay = 0.0

onready var poison = preload("res://Nodes/Overworld/poison geyser.tscn")
onready var timer = $Timer

func _ready():
	timer.wait_time = delay if delay != 0.0 else interval
	timer.start()
	global.get_player().connect("paused", self, "pause")
	global.get_player().connect("unpaused", self, "unpause")

func pause():
	timer.paused = true

func unpause():
	timer.paused = false

func _on_Timer_timeout():
	timer.wait_time = interval
	var newPoison = poison.instance()
	global.currentScene.get_node("Objects").call_deferred("add_child", newPoison)
	newPoison.position = position - Vector2(0, 8)

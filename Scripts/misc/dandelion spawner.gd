extends Position2D

onready var _dandelion = preload("res://Nodes/Overworld/dandelion.tscn")
var _current_dandelion = null

func _ready():
	$Sprite.queue_free()

func _on_VisibilityNotifier2D_screen_entered():
	if !_current_dandelion:
		var new_dandelion = _dandelion.instance()
		new_dandelion.global_position = position
		get_parent().add_child(new_dandelion)
		_current_dandelion = new_dandelion

func _on_VisibilityNotifier2D_screen_exited():
	if !_current_dandelion:
		_current_dandelion.queue_free()
		_current_dandelion = null

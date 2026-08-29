extends Control

export var _label_name: String = "MENU_PP"
export (NodePath) onready var _container

onready var _anim_player = $AnimationPlayer


func _ready():
	_refresh_label_name()

func set_visible(enabled: bool, animated: bool = true):
	if animated:
		if enabled and !$CostBox.visible:
			_anim_player.play("Show")
		elif !enabled and $CostBox.visible:
			_anim_player.play("Hide")
	else:
		$CostBox.visible = enabled

func set_label_name(name: String):
	_label_name = name
	_refresh_label_name()

func set_cost(cost: int):
	$CostBox/HBoxContainer/Label2.text = str(cost)

func _refresh_label_name():
	$CostBox/HBoxContainer/Label.text = _label_name

func _container_behind_parent(value: bool):
	if _container:
		(get_node(_container) as CanvasItem).show_behind_parent = value

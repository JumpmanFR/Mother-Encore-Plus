extends Area2D


export var direction: = Vector2.ZERO

onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")

func _ready():
	animationTree.active = true
	animationTree.set("parameters/Point/blend_position", direction)
	animationTree.set("parameters/Glow/blend_position", direction)
	animationState.travel("Point")

func _on_BombPanel_area_entered(area):
	var body = area.get_parent()
	if body is RunningBomb and body.running:
		animationState.travel("Glow")
		body.change_dir(direction)

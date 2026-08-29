extends KinematicBody2D

onready var animation = $AnimationPlayer
onready var animationTree = $AnimationTree

func _ready():
	animation.play("Move Right")
	
	
func _physics_process(delta):
	global.get_player().position.x = self.global_position.x
	global.get_player().position.y = self.global_position.y
	

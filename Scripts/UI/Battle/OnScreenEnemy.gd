extends Node
class_name OnScreenEnemy

var enemy: Enemy
var overworld_object: Node2D

func _init(e: Enemy, o: Node2D = null):
	enemy = e
	overworld_object = o

func remove_self_from_on_screen_enemies():
	uiManager.erase_on_screen_enemy(self)


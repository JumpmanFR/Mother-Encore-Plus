extends Node2D
class_name AbstractSpawner

export var object : PackedScene

func create_object():
	var new_parent = global.currentScene.get_node("Objects")
	var obj = object.instance()
	obj.global_position = global_position
	new_parent.add_child(obj)
	return obj

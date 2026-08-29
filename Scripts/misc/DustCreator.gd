extends Node2D
class_name DustCreator

onready var Dust = preload("res://Nodes/Reusables/Effects/Dust.tscn")

var _created_dusts := []

func create_dust():
	var dust = Dust.instance()
	global.currentScene.get_node("Objects").add_child(dust)
	dust.global_position.x = self.global_position.x + round(rand_range(-3,3))
	dust.global_position.y = self.global_position.y + round(rand_range(-3,3))
	dust.global_position.y = dust.global_position.y - 0.01 * global.party.size()
	
	_created_dusts.append(dust)

	dust.get_node("AnimationPlayer").play("Dusty")
	dust.get_node("AnimationPlayer").connect("animation_finished", self, "_destroy_dust", [dust], CONNECT_ONESHOT)

func _destroy_dust(anim_name: String, dust: Sprite):
	if dust:
		if is_instance_valid(dust):
			_created_dusts.erase(dust)
			dust.queue_free()


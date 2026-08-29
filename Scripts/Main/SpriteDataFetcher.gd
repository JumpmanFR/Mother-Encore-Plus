class_name SpriteDataFetcher
extends Node

export var _sprite_path: NodePath
export var _ignore_reflection: bool = false;
export var _toggle_flip_reflection: bool = true;

export var reflect_offset: float = 4.0;

onready var _sprite_node = get_node_or_null(_sprite_path)
onready var _parent_node = self.get_parent()

onready var reflect_node = global.currentScene.get_node_or_null("FloorReflector")

var _obj_reflection: CharacterReflection
var _has_reflection: bool = false;

# Getters


func get_texture() -> Texture:
	return _sprite_node.texture

func get_hframes() -> int:
	return _sprite_node.hframes

func get_vframes() -> int:
	return _sprite_node.vframes

func get_frames() -> int:
	return _sprite_node.frame

func get_visibility() -> bool:
	return _sprite_node.visible
	
func get_sprite_node() -> Sprite:
	var sprite_ret = _sprite_node
	return sprite_ret
	
# Reflection functions
	
func generate_reflection():
	print("Reflect");
	_obj_reflection = reflect_node.create_reflection(self, _parent_node, _toggle_flip_reflection)
	_parent_node.add_child(_obj_reflection)
	_has_reflection = true

func delete_reflection():
	if(is_instance_valid(_obj_reflection)):
		_obj_reflection.queue_free()
		_has_reflection = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Probably a more efficient way to do this. Oh well!
	reflect_node = global.currentScene.get_node_or_null("FloorReflector")
	# Lord forgive me for this ungodly conditional
	if (!_ignore_reflection && reflect_node && !_has_reflection):
		generate_reflection()
	elif !(reflect_node):
		# Reflect node is no longer in the scene. Destroy itself.
		delete_reflection()
	pass

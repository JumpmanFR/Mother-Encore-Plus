extends Node2D
# FloorReflector - If something ain't right ask QuickSlash

# Specify where the objects are in the scene to be reflected.
export var object_path: NodePath = "../Objects"
# Specify what shader to use on the reflection objects.
export var shader_material: ShaderMaterial

onready var tilemap = get_node_or_null(object_path)

func get_sprite_info(obj_reflect : CharacterReflection, sprite_fetcher):
	obj_reflect.texture = sprite_fetcher.get_texture()
	obj_reflect.hframes = sprite_fetcher.get_hframes()
	obj_reflect.vframes = sprite_fetcher.get_vframes()
	obj_reflect.visible = sprite_fetcher.get_visibility()
	
# Function to generate a reflection. Intended to be called by
# a SpriteDataFetcher in a scene if it detects the FloorReflector.
# First arg  : The SpriteDataFetcher itself.
# Second arg : The parent object to add the reflection to.
func create_reflection(sprite_fetcher: SpriteDataFetcher, parent_object, toggle_flip_reflection: bool) -> CharacterReflection:
		print("called create_reflection for: " + str(parent_object.name))
		
		# Apply shader
		var clone_material := shader_material
		var obj_reflect = CharacterReflection.new(sprite_fetcher, clone_material)
		
		obj_reflect.name = (str(parent_object.name) + "Reflection") 
		if toggle_flip_reflection: obj_reflect.flip_v = true;
		
		get_sprite_info(obj_reflect, sprite_fetcher)
		obj_reflect.z_index = -1;
		obj_reflect.offset.y = ((obj_reflect.texture.get_height() / obj_reflect.vframes) * 0.6) + sprite_fetcher.reflect_offset

		# Add to tree
		return obj_reflect

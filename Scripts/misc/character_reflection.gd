class_name CharacterReflection
extends Sprite

var _parent_node = null
var _fetcher = null
var _current_scene = null
var _faded_in = true
var _transparency := 1.0
var _is_climbing := false;
var _lock_y := 0.0;

func fade_out():
	modulate.a = lerp(modulate.a, 0.0, 0.2);
	
func fade_in():
	modulate.a = lerp(modulate.a, 1.0, 0.2);
	
func get_reflection_offset():
	return ((texture.get_height() / vframes) * 0.6) + _fetcher.reflect_offset

func refresh_sprite():
	frame = _fetcher.get_frames()
	offset.y = get_reflection_offset()
	texture = _fetcher.get_texture()
	
func refresh_shader():
	if (_fetcher.reflect_node != null):
		material = _fetcher.reflect_node.shader_material

func refresh_vframes():
	self.material.set_shader_param("instance_vframes", vframes)
	print("modified " + str(material.shader) + " in " + name + ". Set vframes to " + str(material.get("shader_param/instance_vframes")) + " should be: " + str(vframes));

func _init(provided_fetcher, new_material):
	_current_scene = _current_scene
	_fetcher = provided_fetcher
	material = new_material;
	material.resource_local_to_scene = true;
	
func _ready():
	_parent_node = get_parent()
	# WHY THE FUCK DOES THIS EDIT ALL SHADERS IN THE SCENE
	#self.material.set_shader_param("hframes", _fetcher.get_hframes())
	#print(self.name + "hframe properties: " + str(self.material.get_shader_param("hframes")))

func _process(delta):
	visible = _fetcher.get_visibility()
	if (visible):
		refresh_sprite()
		if (_current_scene != global.currentScene):
			refresh_shader()
	if (uiManager.is_in_battle()):
		#Get sprite ready to fade in after the battle.
		modulate.a = 0.0;
	else:
		modulate.a = lerp(modulate.a, 1.0, 0.2);
	
	if (_parent_node is PartyObject):
		if (_parent_node.is_climbing()):
			modulate.a = lerp(modulate.a, 0.0, 1);
		# Add to Y offset as player moves up.
		else:
			modulate.a = lerp(modulate.a, 1.0, 0.00005);

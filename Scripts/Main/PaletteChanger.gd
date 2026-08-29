extends Node
class_name PalSwapFlagChecker

export (Array, NodePath) var _node_paths 
export (Texture) var _palette
export var on_flag := ""
export var off_flag := ""
export (float, 0, 1) var on_mix_value := 1.0 #value of mix when on
export (float, 0, 1) var off_mix_value := 0.0 #value of mix when off

var _nodes: Array

func _ready():
	for path in _node_paths:
		_nodes.append(get_node_or_null(path))
	_check_flags()
	global.connect("flags_updated", self, "_check_flags")

func _check_flags():
	if on_flag != "" and !globaldata.flags[on_flag]:
		return
	var flag_state = globaldata.check_appear_disappear_flags(on_flag, off_flag)
	var mix = _get_mix(flag_state)
	_set_all_color_mix(mix)
	if flag_state and _palette:
		_set_all_pal_out(_palette)

func _get_mix(enabled: bool) -> float:
	if enabled:
		return on_mix_value
	return off_mix_value

func _set_all_pal_out(texture: Texture):
	for node in _nodes:
		_set_node_pal_out(node, texture)

func _set_all_color_mix(mix: float):
	for node in _nodes:
		_set_node_color_mix(node, mix)

func _set_node_pal_out(node: Node, texture: Texture):
	node.material.set_shader_param("palette_out", texture)

func _set_node_color_mix(node: Node, mix: float):
	node.material.set_shader_param("color_mix", mix)

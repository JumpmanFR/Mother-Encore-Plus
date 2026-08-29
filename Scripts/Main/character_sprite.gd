tool 
extends Sprite

signal sprite_changed

export (String,FILE,"*.yaml") var yaml
export (String,FILE) var sprite
export var _auto_offset = true

var _json_data = null
var dir = 0
var _default_offset = Vector2.ZERO
var _direction = Vector2.ZERO
var animationState = null
var animationTree = null
var _current_state = ""
var _directional_tags = []
var _all_tags = []

onready var _anim_player = $AnimationPlayer

onready var _anim_root_node = _anim_player.get_node(_anim_player.root_node)
onready var _sprite_path: NodePath = _anim_root_node.get_path_to(self)
onready var _sprite_frame_path: NodePath = "%s:frame" % _sprite_path


func _ready():
	var animTree = AnimationTree.new()
	add_child(animTree)
	animationTree = animTree
	
	#debug stuff
	if yaml != "":
		if !Engine.editor_hint: _json_data = globaldata.get_json_data(yaml)
		else: _json_data = EditorTools.get_json_data(yaml)
		
		if _json_data:
			hframes = _json_data["size"][0]
			vframes = _json_data["size"][1]

		if !Engine.editor_hint:
			_create_animations()

		set_spritesheet()

#sets the yaml file to be used for animation
#connections sets what type of switch mode will be set between animation states
#each index is for one type of connection
#inside of each index, the first index is the origin of the connection, the second index is the target of the connection, and the third index is the switch mode as an integer number
#for the switch modes, 0 is for an immediate switch mode, 1 is for a sync switch mode and 2 is for a switch mode at end
#for example, [["Talk", "Idle", 2]] will add a connection from "Talk" to "Idle" with a SWITCH_MODE_AT_END switch mode
func set_animation(path, connections = []):
	yaml = path
	if !Engine.editor_hint: _json_data = globaldata.get_json_data(yaml)
	else: _json_data = EditorTools.get_json_data(yaml)

	if _json_data:
		hframes = _json_data["size"][0]
		vframes = _json_data["size"][1]

	if !Engine.editor_hint:
		_create_animations(connections)


#manually set sprite offset
func set_sprite_offset(sprite_offset):
	offset = _default_offset + sprite_offset

func set_sprite(path):
	sprite = path


func _create_animations(connections = []):
	for anim in _anim_player.get_animation_list():
		_anim_player.remove_animation(anim)
	var singleTags = []
	hframes = _json_data["size"][0]
	vframes = _json_data["size"][1]
	
	for i in _json_data["animations"]:
		#If the animation has only one direction, it adds it to the single tags array
		if _json_data["animations"][i]["directions"].size() == 1:
			singleTags.append(i)
		dir = _json_data["animations"][i]["directions"].size()
		
		var directionalAnims = []
		#Creates the animation 
		for j in _json_data["animations"][i]["directions"].size():
			
			var anim := Animation.new()
			var frame_track_id: int = anim.add_track(Animation.TYPE_VALUE)
			anim.track_set_path(frame_track_id, _sprite_frame_path)
			
			if _json_data["animations"][i]["type"] == 0:
				anim.loop = true
			else:
				anim.loop = false
				
			var frameCount = _json_data["animations"][i]["directions"][0].size()
			
			var animationLength = _json_data["animations"][i]["directions"][j][0]
			
			for frame_index in frameCount - 1:
				anim.track_insert_key(frame_track_id, animationLength, _json_data["animations"][i]["directions"][j][frame_index + 1][0]-1)
				animationLength = animationLength + _json_data["animations"][i]["directions"][j][frame_index + 1][1]
			
			anim.length = animationLength
			anim.value_track_set_update_mode(frame_track_id,Animation.UPDATE_DISCRETE)
			
			var dirTitle = ""
			var vector = Vector2.ZERO
			var animationSize = _json_data["animations"][i]["directions"].size()
			if animationSize > 1:
				if animationSize == 2:
					match j:
						0:
							dirTitle = " Left"
							vector = Vector2.LEFT
						1:
							dirTitle = " Right"
							vector = Vector2.RIGHT
				else:
					match j:
						0:
							dirTitle = " Down"
							vector = Vector2.DOWN
						1:
							dirTitle = " Left"
							vector = Vector2.LEFT
						2:
							dirTitle = " Right"
							vector = Vector2.RIGHT
						3:
							dirTitle = " Up"
							vector = Vector2.UP
						4:
							dirTitle = " DownLeft"
							vector = (Vector2.DOWN + Vector2.LEFT).normalized()
						5:
							dirTitle = " DownRight"
							vector = (Vector2.DOWN + Vector2.RIGHT).normalized()
						6:
							dirTitle = " UpLeft"
							vector = (Vector2.UP + Vector2.LEFT).normalized()
						7:
							dirTitle = " UpRight"
							vector = (Vector2.UP + Vector2.RIGHT).normalized()
						
				directionalAnims.append([i + dirTitle, vector])
				
			_anim_player.add_animation(i + dirTitle, anim)
		_directional_tags.append([i, directionalAnims])
	
	_create_tree(_directional_tags, singleTags, connections)

#sets the sprite texture
func set_spritesheet():
	if sprite != "":
		if ResourceLoader.exists(sprite):
			texture = load(sprite)
			if texture != null:
				if _auto_offset:
					offset.y = -int(texture.get_height()/float(vframes*2))
				offset += Vector2(_json_data["offset"][0], _json_data["offset"][1])
				_default_offset = offset
			show()
		else:
			hide()
	if !Engine.editor_hint:
		emit_signal("sprite_changed")

#creates the animation tree
func _create_tree(tags: Array, singleTags: Array, connections := []):
	var animState = AnimationNodeStateMachine.new()
	animationTree.set_animation_player("../AnimationPlayer")
	animationTree.tree_root = animState
	
	_all_tags.clear()
	var tagNodes = []
	_all_tags.append_array(singleTags)
	
	for i in singleTags:
		var blendtree = AnimationNodeBlendTree.new()
		var timescale = AnimationNodeTimeScale.new()
		var blendnode = AnimationNodeAnimation.new()
		
		animState.add_node(i, blendtree)
		blendtree.add_node(i, blendnode)
		blendtree.add_node("TimeScale", timescale)
		
		blendnode.set_animation(i)
		
		timescale.add_input("Scale")
		
		blendtree.connect_node("TimeScale", 0, i)
		blendtree.connect_node("output", 0, "TimeScale")
		
		if i == "Idle":
			animState.set_start_node("Idle")
	
	
	for i in tags:
		if !animState.has_node(i[0]):
			tagNodes.append(i[0])
			var blendtree = AnimationNodeBlendTree.new()
			var blendspace = AnimationNodeBlendSpace2D.new()
			var timescale = AnimationNodeTimeScale.new()
			
			animState.add_node(i[0],blendtree)
			blendtree.add_node(i[0], blendspace)
			blendtree.add_node("TimeScale", timescale)
			
			timescale.add_input("TimeScale")
			
			blendtree.connect_node("TimeScale", 0, i[0])
			blendtree.connect_node("output", 0, "TimeScale")
			
			
			blendspace.blend_mode = AnimationNodeBlendSpace2D.BLEND_MODE_DISCRETE
			
			for j in i[1]:
				var animationNode = AnimationNodeAnimation.new()
				animationNode.set_animation(j[0])
				
				blendspace.add_blend_point(animationNode, j[1])
				
			if i[0] == "Idle":
				animState.set_start_node("Idle")
	
	_all_tags.append_array(tagNodes)
	
	#Create an Idle node if there isn't one
	if animState.get_start_node() == "":
		var blendnode = AnimationNodeAnimation.new()
		animState.add_node("Idle", blendnode)
		animState.set_start_node("Idle")
	
	#Create animation connections
	for anim in connections:
		var trans = AnimationNodeStateMachineTransition.new()
		match anim[2]:
			0:
				trans.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
			1:
				trans.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_SYNC
			2:
				trans.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
		
		if animationTree.tree_root.has_node(anim[0]) and animationTree.tree_root.has_node(anim[1]):
			animationTree.tree_root.add_transition(anim[0],anim[1],trans)
	
	for i in _all_tags:
		for j in _all_tags:
			if i != j:
				if !animationTree.tree_root.has_transition(i, j):
					var trans = AnimationNodeStateMachineTransition.new()
					trans.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
					animationTree.tree_root.add_transition(i,j,trans)
	
	animationTree.active = true
	animationState = animationTree.get("parameters/playback")
	travel("Idle")



#travel to an animation state
func travel(state: String):
	if animationTree.tree_root and animationTree.tree_root.has_node(state):
		animationState.travel(state)
		_current_state = state

#returns the current animation state
func get_state() -> String:
	return _current_state

func get_direction() -> Vector2:
	return _direction

#sets the direction for all animation states with multiple directions

func blend_position(vector: Vector2):
	_direction = vector
	for i in _directional_tags:
		
		animationTree.set("parameters/"+ i[0] + "/" + i[0] + "/blend_position", _direction)

#sets the speed at which animations play
func set_time_scale(scale := 1.0):
	for i in _all_tags:
		animationTree.set("parameters/"+ i + "/TimeScale/scale", scale)

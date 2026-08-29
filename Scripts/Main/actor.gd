extends KinematicBody2D
class_name Actor

signal actor_ready
signal finished_movement
signal finished_action
signal enemy_erased

enum {MOVETO, STEP, TALKING, ROTATING, IDLE}

onready var emotes := $CharacterSprite/emotes
onready var camera := $Camera2D
onready var character_sprite := $CharacterSprite
onready var _special_sprite := $SpecialSprite
var speed: float = 64.0
var is_party_member := false
var is_party_object := false
var party_member_name := ""
var pause := false
var _jumping := false
var talking := false
var mute := false
var _moonwalk := false
var _looping := false
var _blend_position := true
var _animating := false
var new_pos := position
var _direction := Vector2.ZERO
var velocity := Vector2.ZERO
var _replaced = null
var _replaced_path: NodePath
var _original_scene := ""
var drafted := false
var state := IDLE
var _idle_anim := "Idle"
var _talk_idle_anim := "Idle"
var _sprite_position := Vector2.ZERO

var _spinning := false
var _spin_time := 0.0
var _spin_speed := 0.2
var _spin_anticlockwise := false

var keepAfterBattle := false
var _on_screen_enemy: OnScreenEnemy = null

class MoveAction:
	var movement: Vector2
	
	func _init(m: Vector2):
		movement = m

class WaitAction:
	var waitTime: float
	
	func _init(w: float):
		waitTime = w

class TurnAroundAction:
	pass

class SetDirAction:
	var direction: Vector2
	
	func _init(d: Vector2):
		direction = d

class TurnToAction:
	var direction: Vector2
	var speed: float
	
	func _init(d: Vector2, s: float):
		direction = d
		speed = s

class SpinAction:
	var enabled: bool
	var speed: float
	var anticlockwise: bool
	
	func _init(e: bool, s: float, a: bool):
		enabled = e
		speed = s
		anticlockwise = a

class ShakeAction:
	var offset: Vector2
	var length: float
	var async: bool
	
	func _init(o: Vector2, l := 1.0, a := false):
		offset = o
		length = l
		async = a

class JumpAction:
	var height: float
	var length: float
	var times: int
	var shadow: bool
	var crouch: bool
	var async: bool
	
	func _init(h: float, l: float, t := 1, s := true, c := false, a := false):
		height = h
		length = l
		times = t
		shadow = s
		crouch = c
		async = a

class VisibilityAction:
	var is_visible: bool
	
	func _init(v := true):
		is_visible = v

class EmoteAction:
	var emote: String
	
	func _init(e: String):
		emote = e

class SoundEffectAction:
	var sfx: String
	
	func _init(s: String):
		sfx = s

class BlendAction:
	var blend: bool
	
	func _init(b: bool):
		blend = b

class ShadowAction:
	var shadow_visible: bool
	
	func _init(s: bool):
		shadow_visible = s

class AnimAction:
	var anim: String
	var speed: float
	var type: int
	var newidle: bool
	var async: bool
	
	func _init(a: String, s: float, t: int, n: bool, asy := false):
		anim = a
		speed = s
		type = t
		newidle = n
		async = asy

class TeleportAction:
	var pos: Vector2
	
	func _init(p: Vector2):
		pos = p

class MoonwalkAction:
	var moonwalking: bool
	
	func _init(m: bool):
		moonwalking = m

class MoveSpeedAction:
	var speed: float
	
	func _init(s: float):
		speed = s

class AnimSpeedAction:
	var speed: float
	
	func _init(s: float):
		speed = s

func init(replaced_npc: Node2D, disable_replaced: bool):
	_replaced = replaced_npc
	_replaced_path = _replaced.get_path()
	if disable_replaced and _replaced.get("active"):
		_replaced.active = false
		_replaced.set_physics_process(false)

func _ready():
	hide()
	_original_scene = global.currentScene.name
	if _replaced: _handle_replaced()
	
	emit_signal("actor_ready")
	
	if party_member_name != "":
		global.connect("party_changed", self, "_update_replaced")
	else:
		global.connect("scene_changed", self, "_update_replaced")

func _handle_replaced():
	global_position = _replaced.global_position
	
	set_spritesheet()
	
	if global.talker == _replaced:
		global.talker = self
	
	if _replaced == global.get_player():
		camera.set_current()
	
	_direction = _replaced.get_direction()
	
	
	if _direction.x != 0 and _direction.y != 0:
		
		if abs(_direction.x) > abs(_direction.y):
			_direction.y = 0
		else:
			_direction.x = 0
	
	set_blending(true)
	blend_position(_direction)
	
	if _replaced.get("idle_animation") != null:
		_idle_anim = _replaced.idle_animation
	if _replaced.get("talk_idle_animation") != null:
		_talk_idle_anim = _replaced.talk_idle_animation
	character_sprite.travel(_idle_anim)
	
	if !_replaced.get_node("Shadow").visible:
		$Shadow.visible = false
	else:
		$Shadow.scale.x = _replaced.get_node("Shadow").scale.x
	character_sprite.animationTree.advance(0)
	_replaced.hide()
	show()

func update_npcs():
	if _replaced_exists():
		_replaced.global_position = global_position
		_direction = _direction.round()
		_replaced.set_direction(_direction)
		if _replaced.get("start_pos") != null:
			_replaced.start_pos = _replaced.global_position
			_replaced.new_pos = _replaced.global_position
		
		
		if _replaced == global.get_player():
			global.get_player().camera.set_current()
			global.get_player().camera.return_camera(0.5)
			if global.partySpace.size() > 1:
				for space in global.partySpace.size():
					global.partySpace.push_front(global.get_player().position)
					global.partySpace.pop_back()
		
		if _replaced.get("character_sprite") != null:
			if _replaced.get("idle_animation"):
				_replaced.idle_animation = _idle_anim
			_replaced.character_sprite.travel(_idle_anim)
			yield(_replaced.character_sprite, "frame_changed")
		yield(get_tree(), "idle_frame")
		
		if !uiManager.is_in_battle() or not is_party_object:
			_replaced.show()
		_replaced.modulate.a = 1.0
	unmake_persistent()
	queue_free()


func _update_replaced():
	if is_party_object:
		var party = global.partyObjects
		for i in global.partyObjects.size():
			if party[i].get_party_member().get_name() == party_member_name:
				print("updating replaced for %s to %s" % [party_member_name, party[i]])
				change_replaced(party[i])
				return
	elif global.currentScene.name == _original_scene:
		var replaced = get_node_or_null(_replaced_path)
		if replaced:
			change_replaced(get_node(_replaced_path))
			return

func stop_interaction():
	if _replaced_exists() and _replaced.has_method("stop_interaction"):
		_replaced.stop_interaction()

func change_replaced(replacement):
	if replacement != _replaced:
		
		_remove_replaced()
		
		_replaced = replacement
		_replaced.hide()
		_replaced_path = replacement.get_path()
		_update_is_party_member()
	

func _remove_replaced():
	if _replaced in global.partyObjects:
		print("removing: %s" % _replaced.get_party_member().get_name())
		global.party.erase(_replaced.get_party_member())
		global.partyNpcs.erase(_replaced.get_party_member())
		global.create_party_followers(false)
	elif _replaced_exists() and _replaced != global.get_player():
		global.remove_persistent(_replaced)
		_replaced.queue_free()
	_replaced = null

func set_direction(vector2: Vector2):
	_direction = vector2
	blend_position(vector2)

func get_direction() -> Vector2:
	return _direction

func _physics_process(delta: float):
	if _spinning:
		_spin_time += delta
		if _spin_time >= _spin_speed:
			_spin_time -= _spin_speed
			var angle = 45 * - 1 if _spin_anticlockwise else 1
			_direction = _direction.rotated(angle).round().normalized().round()
			blend_position(_direction)
	
	match state:
		MOVETO:
			_move_to(new_pos, delta, false)
		STEP:
			_move_to(new_pos, delta, true)
		IDLE:
			if !_animating:
				if _jumping and is_party_member:
					return
				elif talking and !mute:
					character_sprite.travel("Talk")
				elif global.talker == self:
					character_sprite.travel(_talk_idle_anim)
				else:
					character_sprite.travel(_idle_anim)
			position = position.round()
	






	
	



	
func move_queue(moves: Array, animation: String, walk_speed: float, type: String, moonwalk := false, loop := false, queue := false):
	if state != IDLE or queue: yield(self, "finished_action")
	speed = walk_speed
	_moonwalk = moonwalk
	_looping = loop
	for action in moves:
		if action is MoveAction:
			if type in ["position", "1"]:
				state = MOVETO
				new_pos = action.movement
			elif type == "step":
				state = STEP
				new_pos = global_position + action.movement
			if animation != "":
				character_sprite.travel(animation)
			yield(self, "finished_movement")
		
		elif action is TurnAroundAction:
			state = IDLE
			set_direction( - _direction)
		
		elif action is SetDirAction:
			state = IDLE
			set_direction(action.direction)
		
		elif action is TurnToAction:
			var turnDirection = action.direction
			if turnDirection != _direction.normalized().round():
				print("doing the turn")
				state = IDLE
				turn_to(turnDirection, action.speed)
				yield(self, "finished_action")
		
		elif action is SpinAction:
			set_spin(action.enabled, action.speed, action.anticlockwise)
		
		elif action is ShakeAction:
			shake(action.offset, action.length)
			if !action.async:
				state = IDLE
				yield(self, "finished_action")
		
		elif action is JumpAction:
			jump(action.height, action.length, action.times, false, action.shadow, action.crouch)
			if !action.async:
				state = IDLE
				yield(self, "finished_action")
		
		elif action is AnimAction:
			play_anim(action.anim, action.speed, false, action.type, action.newidle)
			if !action.async:
				state = IDLE
				yield(self, "finished_action")
		
		elif action is VisibilityAction:
			visible = action.is_visible
		
		elif action is EmoteAction:
			emotes.animaPlayer.play(action.emote)
		
		elif action is SoundEffectAction:
			if !action.sfx.begins_with("res://"):
				action.sfx = "res://Audio/Sound effects/" + action.sfx
			audioManager.play_sfx(load(action.sfx), "%sActorSound" % name)
		
		elif action is BlendAction:
			set_blending(action.blend)
		
		elif action is ShadowAction:
			set_shadow(action.shadow_visible)
		
		elif action is TeleportAction:
			global_position = action.pos
		
		elif action is MoonwalkAction:
			_moonwalk = action.moonwalking
			_direction = _direction * Vector2( - 1, - 1)
		
		elif action is MoveSpeedAction:
			speed = action.speed
		
		elif action is AnimSpeedAction:
			_set_anim_speed(action.speed)
		
		elif action is WaitAction:
			talking = false
			state = IDLE
			if animation != "":
				character_sprite.travel(_idle_anim)
			yield(get_tree().create_timer(float(action.waitTime)), "timeout")
	if _looping:
		state = IDLE
		move_queue(moves, animation, walk_speed, type, moonwalk, loop)
	else:
		print("move queue done")
		if _moonwalk:
			_direction = _direction * Vector2(-1, -1)
		_moonwalk = false
		state = IDLE
		if animation != "":
			character_sprite.travel(_idle_anim)
		emit_signal("finished_action")

func stop_loop():
	_looping = false

func _move_to(vector2: Vector2, delta: float, snap_diagonal: bool = false):
	var difference = max(ceil(abs(speed * delta)), 1.0)
	if abs(global_position.x - new_pos.x) > difference or abs(global_position.y - new_pos.y) > difference:
		var dir
		if snap_diagonal:
			var angle = global_position.angle_to_point(vector2)
			dir = Vector2( - cos(angle), - sin(angle))
		else:
			dir = global_position.direction_to(vector2)
		
		velocity = move_and_slide(dir * speed)
		if _blend_position:
			_direction = dir
			if _moonwalk:
				blend_position( - _direction)
			else:
				blend_position(_direction)
	else:
		global_position = new_pos
		emit_signal("finished_movement")

func set_shadow(enabled):
	$Shadow.visible = enabled

func jump(height, length, times = 1, queue = false, shadow = true, crouch = false): #height in pixels, speed in length of jump
	if queue: yield(self, "finished_action")
	blend_position(_direction)
	if is_party_member and crouch:
		_jumping = true
		character_sprite.travel("Crouch")
		yield(get_tree().create_timer(0.1), "timeout")
		character_sprite.travel("Jump")
	for i in times:
		if !shadow:
			set_shadow(false)
		var tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tween.tween_property(character_sprite, "position", Vector2(0, _sprite_position.y - height), length * 0.6)\
		.from(Vector2(0, _sprite_position.y)).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tween.tween_property(character_sprite, "position", Vector2(0, _sprite_position.y), length * 0.4)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		yield(tween, "finished")
		if !shadow:
			set_shadow(true)
		if times > 1:
			if is_party_member and crouch:
				character_sprite.travel("Crouch")
			yield(get_tree().create_timer(0.1), "timeout")
			if is_party_member and crouch:
				character_sprite.travel("Jump")
	_jumping = false
	emit_signal("finished_action")
	

func turn_to(newDir, rotSpeed = 0.2, queue = false):
	_direction = _direction.normalized().round()
	newDir = newDir.normalized().round()
	if queue: yield(self, "finished_action")
	if newDir != _direction.round():
		state = ROTATING
		var angle = 45 * sign(_direction.angle_to(newDir))
		while _direction != newDir:
			_direction = _direction.rotated(angle).round()
			blend_position(_direction)
			yield(get_tree().create_timer(rotSpeed),"timeout")
		state = IDLE
	print("turn finished")
	emit_signal("finished_action")

func set_spin(enabled: bool, rotSpeed := 0.2, anticlockwise := false):
	if !enabled:
		_spin_time = 0.0
	_spinning = enabled
	_spin_speed = rotSpeed
	_spin_anticlockwise = anticlockwise

func set_spritesheet():
	#Set character sprite and animations
	
	
	character_sprite.set_sprite(_replaced.get_sprite_texture().resource_path)
	
	var specialPath = _replaced.get_sprite_texture().resource_path.replace("main.png", "cutscene.png")
	if ResourceLoader.exists(specialPath):
		_special_sprite.set_sprite(specialPath)
	if _replaced.get("character_sprite") != null:
		character_sprite.set_animation(_replaced.yaml, _replaced.connections)
		character_sprite.position = _replaced.character_sprite.position
		is_party_member = _replaced.is_party_member()
	else: #Otherwise set default to Party Member animations
		is_party_member = true
		character_sprite.set_animation("res://Data/Animations/PartyMember.yaml", [["Talk", "Idle", 2]])
		
		var special = File.new()
		var specialAnimPath = "res://Data/Animations/" + _replaced.get_party_member().get_sprite() + "Cutscene.yaml"
		if special.file_exists(specialAnimPath):
			_special_sprite.set_animation(specialAnimPath)
			_special_sprite.set_spritesheet()
	character_sprite.set_spritesheet()
	_update_is_party_member()
	
	_set_special_sprite(false)
	_sprite_position = character_sprite.position
	

# anim: name of the animation
# anim_speed: playback speed
# queue: have the animation play after other actions or not
# type: 1 for special animation, 0 for regular animation

func play_anim(anim, speed = 1.0, queue = false, type = 0, newidle = false):
	if queue: yield(self, "finished_action")
	
	var obj = _special_sprite if type == 1 else character_sprite
	obj.travel(anim)
	_set_special_sprite(type == 1)
	obj.set_time_scale(speed)
	obj.animationTree.advance(0)
	
	if (anim == _idle_anim or anim == _talk_idle_anim) and character_sprite.visible:
		_animating = false
		emit_signal("finished_action")
	else: _animating = true
	
	if newidle: _idle_anim = anim

func _set_anim_speed(speed: float):
	_special_sprite.set_time_scale(speed)
	character_sprite.set_time_scale(speed)

func _set_special_sprite(enabled):
	_special_sprite.visible = enabled
	character_sprite.visible = !enabled

func shake(offset = Vector2(1, 0), length = 1.0, queue = false):
	if queue: yield(self, "finished_action")
	var oldOffset = character_sprite.offset
	if length <= 0:
		_looping = true
		length = 0.1
	for i in int(length * 10):
		character_sprite.offset = oldOffset + offset
		yield(get_tree().create_timer(0.05), "timeout")
		character_sprite.offset = oldOffset - offset
		yield(get_tree().create_timer(0.05), "timeout")
	character_sprite.offset = oldOffset
	if _looping:
		shake(offset, -1)
	else:
		emit_signal("finished_action")

func set_blending(blend):
	_blend_position = blend

func blend_position(vector2):
	var blend = true
	vector2 = vector2.round()
	if !is_party_member and abs(vector2.x) - abs(vector2.y) == 0 :
		blend = false
	if vector2 != Vector2.ZERO and blend:
		character_sprite.blend_position(vector2)
	
	if _replaced_exists() and _replaced.has_method("blend_position"):
		_replaced.blend_position(_direction)

func duplicate_sprite() -> Sprite:
	return character_sprite.duplicate() as Sprite

func activate():
	remove_battle()
	update_npcs()

func die():
	erase()

func erase():
	unmake_persistent()
	if _replaced_exists() and _replaced != global.get_player():
		_replaced.queue_free()
	emit_signal("enemy_erased")
	queue_free()

func add_battle(enemy: Enemy):
	drafted = true
	_on_screen_enemy = uiManager.add_on_screen_enemy(enemy, self)

func remove_battle():
	uiManager.erase_on_screen_enemy(_on_screen_enemy)
	_on_screen_enemy = null

func make_persistent():
	global.add_persistent(self)
	global.add_persistent(_replaced)

func unmake_persistent():
	global.remove_persistent(self)
	global.remove_persistent(_replaced)

func _update_is_party_member() -> void :
	if is_party_member and _replaced is PartyObject:
		party_member_name = _replaced.get_party_member().get_name()
		is_party_object = true
	else:
		party_member_name = ""
		is_party_object = false

func _is_in_party() -> bool:
	return _replaced in global.partyObjects

func _replaced_exists() -> bool:
	return _replaced and is_instance_valid(_replaced)

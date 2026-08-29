class_name PartyObject
extends KinematicBody2D

const PAUSABLE_FLASH_ANIMS := ["Flash"]
const LOOPED_ANIMS := ["Walk", "Run", "FaintedWalk"]

const STEP_DISTANCE := 100

onready var sprite: Sprite = $Position/main
onready var _anim_player = $AnimationPlayer
onready var _anim_tree: AnimationTree = $AnimationTree
onready var _anim_state: AnimationNodeStateMachinePlayback = _anim_tree.get("parameters/playback")
onready var _collision = $CollisionShape2D
onready var _flash_anim = $FlashAnim
onready var _after_image_creator = $AfterImageCreator

var _input_vector := Vector2.ZERO
var _party_member: Character = globaldata.characters.ninten
var _attack_damage := 0
var _damage_variance := 0
var _last_step_pos := Vector2.ZERO
var _dist_btwn_steps := 0.0
var _spinning := false
var _climbing := false
var _is_continuous_damage := false
var _steps := 0
var _paused_anim_state := ""

func _ready():
	global.connect("party_changed", self, "update_party_member")
	update_party_member()

func get_party_member() -> Character:
	return _party_member

# Overridden
func update_party_member():
	push_warning("update_party_member must be overridden!")

func set_idle():
	set_anim_state("Idle")

func set_anim_state(state_name: String):
	if !_climbing:
		if _party_member.is_incapacitated():
			match state_name:
				"Walk", "Run":
					state_name = "Walk"
				"Blink", "Crouch":
					state_name = "Idle"
			state_name = "Fainted" + state_name
		_anim_state.travel(state_name)

# Overridden
func set_direction(new_dir: Vector2):
	_input_vector = new_dir
	blend_position(new_dir)

func get_direction() -> Vector2:
	return _input_vector

# Overridden
func blend_position(vector2: Vector2):
	pass

func blend_animation(animation: String, vector2: Vector2):
	_anim_tree.set("parameters/%s/blend_position" % animation, vector2)

func is_being_damaged() -> bool:
	return _is_continuous_damage

func is_climbing() -> bool:
	return _climbing

func toggle_anim_tree(value: bool):
	_anim_tree.active = value

func _refresh_party_member_connections():
	if !_party_member.is_connected("status_changed", self, "_refresh_status"):
		_party_member.connect("status_changed", self, "_refresh_status")

func _refresh_status():
	_steps = 0
	if _party_member.get_combined_status_effect("overworld_sweat"):
		$Sweatdrops.playing = true
	else:
		$Sweatdrops.playing = false
		$Sweatdrops.frame = 0

func _on_step_taken():
	var effects = _party_member.get_combined_status_effect("overworld_damage")
	for i in effects:
		if _steps % i.get("steps", 10) == 0:
			damage(i.get("value", 10), i.get("variation", 0), Vector2.ZERO, true)

func _calculate_steps():
	_dist_btwn_steps += _last_step_pos.distance_to(self.position)
	if _dist_btwn_steps >= STEP_DISTANCE:
		_steps += 1
		_dist_btwn_steps = 0
		_last_step_pos = self.position
		_on_step_taken()

func _is_invulnerable() -> bool:
	return _flash_anim.get_current_animation() == "Flash"

# Overridden
func damage(damage: int, damage_variance := 0, hit_direct := Vector2.ZERO, cant_kill := true):
	#if cant_kill and _party_member.get_hp() == 1:
	#	return
	damage = damage + int(rand_range(-damage_variance, damage_variance))
	if cant_kill:
		var hp := int(max(_party_member.get_hp() - damage, 1))
		damage = _party_member.get_hp() - hp
	play_flash_anim("Flash")
	audioManager.play_sfx(load("res://Audio/Sound effects/Hurt 1.mp3"), "damage")
	if !_party_member.is_incapacitated() and _party_member.get_stat(Character.MAXHP) != 0:
		_party_member.set_hp(_party_member.get_hp() - damage)
		uiManager.info_plates_show(false, true)
		uiManager.info_plates_update(true)
		if damage > 0:
			uiManager.create_flying_num(damage, global_position)
		if _party_member.get_hp() <= 0:
			_party_member.add_status(Status.AILMENT_UNCONSCIOUS)
			if global.get_conscious_party() == []:
				global.get_player().game_over()

# Overridden
func start_continuous_damage(damage: int, damage_variance := 0, hit_direct := Vector2.ZERO, status := ""):
	_is_continuous_damage = true
	_attack_damage = damage
	_damage_variance = damage_variance
	if status != "":
		_party_member.add_status(status)

func stop_continuous_damage():
	_is_continuous_damage = false

func play_flash_anim(anim: String):
	_flash_anim.play(anim)

func pause_flash_anim():
	if _flash_anim.get_current_animation() in PAUSABLE_FLASH_ANIMS:
		_flash_anim.stop(false)
	else:
		_flash_anim.play("RESET")

func resume_flash_anim():
	if _flash_anim.get_assigned_animation() in PAUSABLE_FLASH_ANIMS \
	and _flash_anim.get_current_animation_position() > 0 and _flash_anim.get_current_animation_position() < _flash_anim.get_current_animation_length():
		_flash_anim.play(_flash_anim.get_assigned_animation())

func set_collisions(value: bool):
	_collision.disabled = !value

func has_collisions() -> bool:
	return !_collision.disabled

func pause_timers():
	$MiscTimer.set_paused(true)

func resume_timers():
	$MiscTimer.set_paused(false)

func duplicate_sprite() -> Node:
	return sprite.duplicate()

func get_sprite_texture() -> Texture:
	return sprite.texture


func get_ground_position() -> Vector2:
	return global_position + get_node("CollisionShape2D").position * 2

func set_shadow(anim: String):
	$Shadow.set_anim(anim)

func get_shadow() -> String:
	return $Shadow.animation

func start_creating_afterimage():
	_after_image_creator.start_creating()

func stop_creating_afterimage():
	_after_image_creator.stop_creating()

# Overridden
func ladder():
	_anim_tree.active = false
	_anim_player.play("Ladder")
	_anim_player.playback_speed = 0
	_climbing = true

# Overridden
func unladder():
	_anim_tree.active = true
	_anim_player.stop()
	set_anim_state("Idle")
	$Position.position.y = 0
	$Shadow.show()
	_climbing = false

# Overridden
func jump(height: float, length: float, hide_shadow:= false, anim := "Jump", start_crouch_time := 0.1, end_crouch_time := 0.0):
	pass

func _anim_play_pause(is_play: bool, play_idle := false):
	if _climbing:
		_anim_player.playback_speed = 1 if is_play else 0
	elif play_idle:
		set_idle()
	
	if !is_play: # to pause
		if !_paused_anim_state and _anim_state.get_current_node() in LOOPED_ANIMS:
			_paused_anim_state = _anim_state.get_current_node()
			_anim_tree.set("parameters/%s/TimeScale/scale" % _paused_anim_state, 0)
	else: # to play
		if _paused_anim_state in LOOPED_ANIMS:
			_anim_tree.set("parameters/%s/TimeScale/scale" % _paused_anim_state, 1)
			_paused_anim_state = ""

func get_paused_anim_state() -> String:
	return _paused_anim_state

export var debug_turn_to: bool = true



func _turn_to(target):
	var _direction = global_position.direction_to(target.global_position)
	blend_animation("Idle", _direction)
	set_anim_state("Idle")

export var debug_try_turn_to: bool = true


func try_to_turn(target: Node2D):
	var player_turn_constraints = target.get("player_turn")
	if not player_turn_constraints:
		if debug_turn_to: print_debug("%s tried to turn but target:[%s] don have player_turn_constraints!" % [_party_member.get_name(), target.to_string()])
		return
	_turn_to(target)

class_name PartyFollower
extends PartyObject

signal action_done

enum { FOLLOW, GO }

var active := true
var jumps := 0

onready var _dust_time = $Dust_time

export (int) var _spacing := 20
var _current_space := 20
var _last_pos := Vector2.ZERO
var _direction_multiplier := Vector2.ONE
var _delay := 0.2
var _speed := 1
var _follower_idx := 1 #should be at least 1, since player is 0.
var _idle := true
var _start_run := true
var _walk_type := FOLLOW

func init_with_follower_idx(follower_idx: int):
	_follower_idx = follower_idx
	_spacing = _follower_idx * 18
	_delay = _follower_idx * 0.2
	position = global.partySpace[_spacing]
	reinit()

func reinit():
	_collision.disabled = true
	_last_pos = position
	_current_space = _spacing
	if position != global.partySpace[_current_space-1]:
		set_direction(position.direction_to(global.partySpace[_current_space-1]))
	else:
		set_direction(global.get_player().get_direction())
	_anim_tree.active = true
	update_party_member()
	set_shadow("shadow")
	spritesheet()
	_collision.disabled = false
	for sig in ["paused", "unpaused"]:
		if !global.get_player().is_connected(sig, self, "_on_played_pause_changed"):
			global.get_player().connect(sig, self, "_on_played_pause_changed")

func _physics_process(_delta: float):
	var player = global.get_player()
	if global.partySpace[_spacing] != null and active:
		if player.get_state() == player.SOOT:
			_anim_state.travel("Soot")
		else:
			var old_pos := position.round()
			if !(abs(position.x - global.partySpace[_spacing].x) > 2 or abs(position.y - global.partySpace[_spacing].y) > 2): #and _direction_multiplier == Vector2.ONE:
				_walk_type = FOLLOW
				#if _current_space < _spacing:
				#	_current_space = _spacing 
			if _walk_type == GO:
				position = position.move_toward(global.partySpace[_current_space], 4000)
				#if position == global.partySpace[_current_space]:
				if !player.is_paused():
					_current_space -= _speed
				
				if _current_space < _spacing:
					_current_space = _spacing
					_walk_type = FOLLOW
				#if !player.is_walking() and !player.is_paused():
				#	_current_space -= 1
			else:
				if _current_space < _spacing and player.is_walking():
					_current_space += 1 
					if player.is_running():
						_current_space += 1
				position = global.partySpace[_current_space]
			$Timer.wait_time = _delay
			
			if !player.is_paused():
				if old_pos != position.round(): #(position.direction_to(global.partySpace[_current_space-1]) != Vector2.ZERO and player.is_walking()) or 
					_input_vector = position.direction_to(global.partySpace[_current_space-1])
					_idle = false
					if !_spinning:
						blend_position(_input_vector)
					if _climbing == true:
						_anim_player.playback_speed = 1
					else:
						set_anim_state("Walk")
						_anim_tree.set("parameters/FaintedWalk/TimeScale/scale", 1)
						$BlinkTime.stop()
					if player.is_running() or _walk_type == GO:
						set_anim_state("Run")
						_anim_tree.set("parameters/FaintedWalk/TimeScale/scale", 2)
						if _start_run == true:
							_dust_time.wait_time = 0.083 * _follower_idx
							_dust_time.start()
							_start_run = false
						if _start_run == false and _dust_time.time_left == 0:
							_dust_time.wait_time = 0.25
							_dust_time.start()
							if !_climbing:
								$DustCreator.create_dust()
					else: 
						_dust_time.wait_time = 0.083 * _follower_idx
						_start_run = true
					if modulate.a == 0:
						appear()
				else:
					if _climbing:
						_anim_player.playback_speed = 0
					elif $BlinkTime.time_left == 0:
						if !_idle or _spinning:
							set_anim_state("Idle")
							$BlinkTime.wait_time = 10 * _follower_idx + randf()*5
							$BlinkTime.start()
						else:
							set_anim_state("Blink")
					_dust_time.wait_time = 0.083 * _follower_idx
					_start_run = true
				
					if player.is_crouching():
						set_anim_state("Crouch")
					else:
						set_anim_state("Idle")
			
			if _is_continuous_damage and !player.is_paused() and !_is_invulnerable():
				damage(_attack_damage, _damage_variance)
			
			if _walk_type == FOLLOW:
				self.position.x = round(self.position.x)
				self.position.y = round(self.position.y) - global.partyObjects.find(self) * 0.01
			else:
				self.position.y = round(self.position.y)
	else:
		set_anim_state("Idle")
	
	var can_climb = true
	for i in global.partyObjects:
		if i.is_climbing():
			can_climb = false
	if player.get_state() == player.MOVE and !player.is_paused() and can_climb and globaldata.flags["switch_leader"] and global.party.size() != 1 and _party_member.get_name() in global.POSSIBLE_PLAYABLE_MEMBERS:
		if Input.is_action_just_pressed("ui_focus_next"):
			_spin(8,45,0.015)
		if Input.is_action_just_pressed("ui_focus_prev"):
			_spin(8,-45,0.015)
	_calculate_steps()

func disappear():
	modulate.a = 0.0

func appear():
	create_tween().tween_property(self, "modulate:a", 1.0, 0.1)
	spritesheet()

func find_path(speed := 2):
	_walk_type = GO
	_speed = speed
	for i in global.partySpace.size() - _spacing:
		var space = _spacing + i
		if global.partySpace.size() > space:
			if position.distance_to(global.partySpace[space]) < position.distance_to(global.partySpace[_current_space]):
				_current_space = space

# Override
func update_party_member():
	var all_members: Array = global.party + global.partyNpcs
	if all_members.size() > _follower_idx:
		_party_member = all_members[_follower_idx]
		_refresh_party_member_connections()
		_refresh_status()
		spritesheet()

func spritesheet():
	var normal_texture: String = "res://Graphics/Character Sprites/%s/main.png" % _party_member.get_sprite()
	var snow_texture: String = "res://Graphics/Character Sprites/%sSnow/main.png" % _party_member.get_sprite()
	if sprite.texture.resource_path != normal_texture:
		if ResourceLoader.exists(normal_texture):
			if global.get_player().costume == "Snow" and ResourceLoader.exists(snow_texture):
				sprite.texture = ResourceLoader.load(snow_texture)
			else:
				sprite.texture = ResourceLoader.load(normal_texture)
				set_anim_state("Idle")
			sprite.vframes = 20
			sprite.offset.y = - sprite.texture.get_height() / 40 + 14
		else:
			sprite.texture = ResourceLoader.load("res://Graphics/Character Sprites/Ninten/main.png")

func _on_Timer_timeout():
	pass

func _spin(times: int, angle: float, rot_speed: float):
	_spinning = true
	var dir := _input_vector.round()
	var wait := Timer.new()
	wait.set_wait_time(rot_speed)
	wait.set_one_shot(true)
	self.add_child(wait)
	for n in times:
		dir = dir.rotated(angle).round()
		blend_position(dir)
		wait.start()
		yield(wait,"timeout")
	_spinning = false
	wait.queue_free()

# Override
func damage(damage: int, damage_variance := 0, hit_direct := Vector2.ZERO, cant_kill := true):
	set_anim_state("Idle")
	.damage(damage, damage_variance, hit_direct, cant_kill)

func _on_played_pause_changed():
	_anim_play_pause(!global.get_player().is_paused(), global.get_player().is_paused())


# Override
func ladder():
	.ladder()
	$Shadow.hide()

func jump(height: float, length: float, hide_shadow:= false, anim := "Jump", start_crouch_time := 0.1, end_crouch_time := 0.0):
	_idle = false
	blend_position(_input_vector)
	_anim_state.travel("Crouch")
	yield(get_tree().create_timer(0.1), "timeout")
	_anim_state.travel("Jump")
	if hide_shadow:
		$Shadow.hide()
	
	var tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", Vector2.ONE, length)\
	.from(Vector2(0.9, 1.1)).set_delay(0.02)
	tween.tween_property($Position, "position", Vector2(0, - height), length)\
	.from(Vector2.ZERO)
	tween.tween_property($Position, "position", Vector2.ZERO, length * 0.75)\
	.from(Vector2(0, - height)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(length)
	yield(tween, "finished")
	if hide_shadow:
		$Shadow.show()

# Override
func blend_position(vector2: Vector2):
	if Vector2(vector2.x * _direction_multiplier.x, vector2.y * _direction_multiplier.y) != Vector2.ZERO:
		vector2.x = vector2.x * _direction_multiplier.x
		vector2.y = vector2.y * _direction_multiplier.y
	
	if vector2 != Vector2.ZERO:
		for param in ["Idle", "Blink", "Walk/Walk", "FaintedIdle", "FaintedWalk/FaintedWalk", "Down", "Crouch", "Run/Run", "Jump"]:
			blend_animation(param, vector2)

func _on_BlinkTime_timeout():
	_idle = true

func constraint_direction(horizontal := false, vertical := false):
	_direction_multiplier = Vector2(0 if vertical else 1, 0 if horizontal else 1)

func rotate_to(new_dir: Vector2, rot_speed: float):
	new_dir = new_dir.round()
	var angle = 45 * sign(_input_vector.angle_to(new_dir))
	while _input_vector != new_dir:
		_input_vector = _input_vector.rotated(angle).round()
		blend_position(_input_vector)
		yield(get_tree().create_timer(rot_speed),"timeout")


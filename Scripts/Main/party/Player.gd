class_name PartyMemberPlayer
extends PartyObject

signal event_detector_entered(object)
signal event_detector_exited(object)
signal jump_finished
signal moved
signal paused
signal unpaused

enum {
	MOVE,
	ATTACK_PREP,
	ATTACK,
	CAMERA,
	JUMPING,
	TELEPORTING,
	SOOT,
	BOUNCING,
	LANDING
}

enum TPModes {
	MANUAL = -1,
	ALPHA,
	OMEGA = 3
}

const SPEED_WALKING := 64
const SPEED_RUNNING := 96
const SPEED_LANDING := 540
const SPEED_DEBUG := 600
const LANDING_SLOWDOWN := 300

const TP_SPEED_UP :=					{ TPModes.MANUAL: 5, TPModes.ALPHA: 5, TPModes.OMEGA: 2}
const TP_SPEED_CAP :=					{ TPModes.MANUAL: 400, TPModes.ALPHA: 540, TPModes.OMEGA: 400}
const TP_TIME_TO_TAKE_OFF :=			{ TPModes.MANUAL: -1, TPModes.ALPHA: 1, TPModes.OMEGA: 1}
const TP_TAKE_OFF_SPEED_MULTIPLIER := 	{ TPModes.MANUAL: 1, TPModes.ALPHA: 1.2, TPModes.OMEGA: 1.3}

var costume := "Normal"
var run_sound := "wood"
var can_interact := true

var _direction := Vector2.ZERO
var _state := MOVE
var _current_skill_action := ""
var _knockback := Vector2.ZERO
var _hit_direct := Vector2.ZERO
var _velocity := Vector2.ZERO
var _speed: float = SPEED_WALKING
var _walk := false
var _substantial_movement: bool
var _crouch := false
var _tap_run := false
var _running := false
var _switching := false
var _spin_num := 0
var _idle := false
var _event_collider = null
var _tp_crouch_timer_done := false
var _tp_max_speed_reached := false
var _tp_take_off_timer_done := false
var _tp_mode: int = TPModes.MANUAL
var _paused := false

var _debug_speed := false

var _tp_crash_sound = load("res://Audio/Sound effects/EB/tcrash.wav")

onready var Beam = preload("res://Nodes/Reusables/Overlap/Beam.tscn")
onready var Cast = preload("res://Nodes/Reusables/Overlap/PKOV.tscn")

onready var _special = $SpecialAnimations
onready var eventRayCaster = $EventDetector
onready var emotes = $Position / main / emotes
onready var camera: GameCamera = $Camera2D
onready var _timer = $Timer
onready var _tp_crouch_timer = $TPCrouchTime
onready var _tp_take_off_timer = $TPTakeOffTime


func _ready():
	global.currentCamera = camera
	for i in global.partySpace.size():
		global.partySpace.push_front(position)
		global.partySpace.pop_back()
	_anim_tree.active = true
	_tap_run = false
	_crouch = false
	_direction = Vector2(0,1)
	blend_position(_direction)
	set_shadow("shadow")
	update_party_member()
	var sfx := load("res://Audio/Sound effects/Footsteps/%s.mp3" % run_sound)
	audioManager.add_sfx(sfx, "run")
	_last_step_pos = position
	
# warning-ignore:unused_argument
func _physics_process(delta: float):
	match _state:
		MOVE:
			_move_state(delta)
		
		TELEPORTING:
			_teleport_state(delta)
		
		LANDING:
			_landing_state(delta)
		
		ATTACK_PREP:
			_attack_hold()
		BOUNCING:
			_bounce_state(delta)
		CAMERA:
			_controls()
			set_anim_state("Idle")
			if _input_vector != Vector2.ZERO:
				blend_position(camera.offset)
		SOOT:
			_soot_state()
	
	
	if not _state in [MOVE, TELEPORTING, LANDING]:
		_set_running(false)
	
	if _state == MOVE or (_state == TELEPORTING and _tp_mode == TPModes.MANUAL):
		_calculate_steps()
	if _is_continuous_damage and !_paused:
		_knockback = _hit_direct * 50
		if !_is_invulnerable():
			damage(_attack_damage, _damage_variance, _hit_direct)
	_knockback = _knockback.move_toward(Vector2.ZERO, 200)
	
	if _debug_speed:
		_speed = SPEED_DEBUG


# Override
func update_party_member():
	_party_member = global.party[0]
	_refresh_party_member_connections()
	_refresh_status()
	spritesheet()

func _teleport_state(delta: float):
	if !_paused:
		var old_pos := global_position
		_controls()
		
		
		var incorrect_inputs := [
			_direction * -1,
			(_direction * -1).rotated(0.25*PI).round(),
			(_direction * -1).rotated(-0.25*PI).round()
		]
		
		if !_tp_take_off_timer_done and _input_vector != Vector2.ZERO and !_input_vector in incorrect_inputs:
			set_direction(_input_vector)

		if !_tp_max_speed_reached:
			if _speed < TP_SPEED_CAP[_tp_mode]:
				_speed += TP_SPEED_UP[_tp_mode]
			elif _speed >= TP_SPEED_CAP[_tp_mode]:
				_speed = TP_SPEED_CAP[_tp_mode]
				_tp_max_speed_reached = true
				global.party_call("play_flash_anim", "TeleportPulse")
				global.party_call("start_creating_afterimage")
				if TP_TIME_TO_TAKE_OFF[_tp_mode] > 0:
					_tp_take_off_timer.start(TP_TIME_TO_TAKE_OFF[_tp_mode])
		elif _tp_take_off_timer_done:
			_speed = _speed * TP_TAKE_OFF_SPEED_MULTIPLIER[_tp_mode]
		
		_velocity = _direction * _speed
		move_and_slide(_velocity)
		set_anim_state("Run")
		_anim_tree.set("parameters/FaintedWalk/TimeScale/scale", 2)
		
		if (_tp_mode == TPModes.MANUAL and Input.is_action_just_pressed("ui_toggle")) \
				or (!_tp_take_off_timer_done and max(abs(old_pos.x - global_position.x), abs(old_pos.y - global_position.y)) <= 1):
			_set_running(false)
			_substantial_movement = false
			_idle = true
			_state = SOOT
			_tp_max_speed_reached = false
			_tp_take_off_timer.stop()
			_anim_state.travel("Soot")
			_tp_crouch_timer.start()
			global.party_call("play_flash_anim", "RESET")
			global.party_call("stop_creating_afterimage")
			camera.shake_camera(_speed / 50.0, 0.4, _direction)
			audioManager.play_sfx(_tp_crash_sound, "tcrash")
		_update_party_positions(old_pos, 0.5)

func _landing_state(delta: float):
	var old_pos := global_position
	_speed -= LANDING_SLOWDOWN * delta
	_velocity = _direction * _speed
	move_and_slide(_velocity)
	_update_party_positions(old_pos)
	if _speed <= SPEED_WALKING:
		global.party_call("set_collisions", true)
		_state = MOVE

static func get_landing_distance() -> float:
	return (SPEED_LANDING * SPEED_LANDING - SPEED_WALKING * SPEED_WALKING) / (2.0 * LANDING_SLOWDOWN)

func _soot_state():
	if _paused or _tp_crouch_timer.time_left != 0:
		return
	_controls()
	if _input_vector != Vector2.ZERO:
		_direction = _input_vector
		_state = MOVE

func _move_state(delta: float):
	if !_paused and !global.entering_door:
		
		_check_event_collider()
		
		_controls()
		_movement(delta)
	else:
		if audioManager.get_sfx("run") != null and audioManager.get_sfx("run").playing:
			audioManager.get_sfx("run").stop()

func _input(event: InputEvent):
	if _paused or _state != MOVE or global.entering_door:
		return
	if event.is_action_pressed("ui_cancel") and not _climbing and not _spinning:
		var action_skills = _get_skills_button_actions()
		if action_skills.empty():
			_current_skill_action = ""
		elif not _current_skill_action in action_skills:
			_current_skill_action = action_skills.front()
		
		_do_attack()
	
	if event.is_action_pressed("ui_scope", true) and not _is_continuous_damage and global.can_pause:
		_state = CAMERA

func _do_attack():
	match _current_skill_action:
		"swing":
			_state = ATTACK
			_crouch = false
			_idle = false
			_tap_run = false
			_set_running(false)
			_walk = false
			_attack_unleash()
		
		"energy_beam":
			$AimTime.start()
			_state = ATTACK_PREP
			_crouch = false
			_idle = false
			_tap_run = false
			_set_running(false)
			_walk = false
		
		"pkfire", "pkfreeze", "pkthunder":
			_anim_state.travel("Cast")
			_state = ATTACK_PREP
			$PKTime.wait_time = 0.733
			$PKTime.start()
			$OutlineAnim.play("Flash")

func _get_skills_button_actions() -> Array:
	var ret := []
	for skill_id in globaldata.get_all_field_skills():
		if _party_member.has_field_skill(skill_id) and globaldata.get_field_skill(skill_id).get("is_skill_button", false):
			ret.append(skill_id)
	ret.sort()
	return ret

func _controls():
	_input_vector = controlsManager.get_controls_vector()
	if _climbing:
		_input_vector.x = 0

func _move():
	_velocity = _speed * (_direction if _tap_run else _input_vector)
	
	if _input_vector != Vector2.ZERO:
		_direction = _input_vector
		eventRayCaster.rotation = _direction.angle() - TAU/4
		emit_signal("moved")

func _movement(delta: float):
	if _input_vector != Vector2.ZERO or _tap_run:
		_move()
		
		if _climbing:
			_anim_player.playback_speed = 1
		if Input.is_action_pressed("ui_toggle") or _tap_run:
			if  Input.is_action_just_pressed("ui_toggle") and !_crouch and !_running and !_climbing:
				_crouch = true
				if _party_member.has_field_skill("teleport"):
					_tp_crouch_timer.start()
			if Input.is_action_just_pressed("ui_toggle") and _tap_run:
				_tap_run = false
				_set_running(false)
			if !_paused and _substantial_movement:
				_set_running(true)
			set_anim_state("Run")
			_anim_tree.set("parameters/FaintedWalk/TimeScale/scale", 2)
			_speed = SPEED_RUNNING
		else:
			_speed = SPEED_WALKING
			_crouch = false
			
			if !_climbing:
				set_anim_state("Walk")
				_anim_tree.set("parameters/FaintedWalk/TimeScale/scale", 1)
	
			if Input.is_action_just_released("ui_toggle") and !_tap_run:
				_set_running(false)
			
			if audioManager.get_sfx("run") and audioManager.get_sfx("run").playing:
				audioManager.get_sfx("run").stop()
		
		if _spinning == false:
			blend_position(_direction)
	else:
		_velocity = Vector2.ZERO
		_walk = false
		if Input.is_action_just_released("ui_toggle") and _crouch:
			_crouch = false
			if _tp_crouch_timer_done:
				start_teleport(TPModes.MANUAL)
			else:
				_speed = SPEED_RUNNING
				_tap_run = true
				
				_velocity = _direction * _speed
	
	var oldpos = self.position
	_velocity = move_and_slide(_velocity * delta * (_speed/1.7))
	_knockback = move_and_slide(_knockback)
	if max(round(abs(oldpos.x - position.x)), round(abs(oldpos.y - position.y))) > 0 or abs(_knockback.x) > 0.1 or abs(_knockback.y) > 0.1:
		_substantial_movement = true
		_idle = false
	else:
		_substantial_movement = false
	if _substantial_movement:
		_walk = true
		_crouch = false
		_update_party_positions(oldpos)
		if _running and _timer.time_left == 0:
			_timer.start()
			if !_climbing:
				$DustCreator.create_dust()
				#if !$AudioStreamPlayer.playing:
				#	$AudioStreamPlayer.playing = true
	else:
		set_anim_state("Idle")
		_walk = false
		_tap_run = false
		_set_running(false)
		if _climbing:
			_anim_player.playback_speed = 0
		if Input.is_action_just_pressed("ui_toggle") and !_crouch:
			emit_signal("moved")
			_crouch = true
			if _party_member.has_field_skill("teleport"):
				_tp_crouch_timer.start()
		elif Input.is_action_just_pressed("ui_toggle") and _crouch:
			_crouch = false
		if _crouch:
			_anim_state.travel("Crouch")
		else:
			if $BlinkTime.time_left == 0:
				if _idle == false or _spinning:
					set_anim_state("Idle")
					$BlinkTime.wait_time = 10 + randf()*5
					$BlinkTime.start()
				else:
					set_anim_state("Blink")
	position = position.round()
	
	var can_climb := true
	for i in global.partyObjects:
		if i.is_climbing():
			can_climb = false
	if can_climb and global.party.size() != 1 and _party_member.has_field_skill("relay"):
		if Input.is_action_just_pressed("ui_focus_next"):
			swap_spin(1)
		if Input.is_action_just_pressed("ui_focus_prev"):
			swap_spin( - 1)
	if Input.is_action_just_pressed("ui_accept") and !_paused and can_interact and !global.entering_door and eventRayCaster.is_colliding():
		if _crouch:
			use_telepathy()
		else:
			interact_with()


#emits a signal when the EventDetector detects a new object or when an object exits it
func _check_event_collider():
	_set_event_collider(eventRayCaster.get_collider())

func _set_event_collider(collide):
	if _event_collider == collide:
		return
	
	if collide != null:
		if not collide.is_connected("tree_exited", self, "_set_event_collider"):
			collide.connect("tree_exited", self, "_set_event_collider", [null])
		emit_signal("event_detector_entered", collide)
	
	if _event_collider != null:
		if _event_collider.is_connected("tree_exited", self, "_set_event_collider"):
			_event_collider.disconnect("tree_exited", self, "_set_event_collider")
		emit_signal("event_detector_exited", _event_collider)
	
	_event_collider = collide

func is_colliding() -> bool:
	return eventRayCaster.is_colliding()

func interact_with():
	if not uiManager.is_stack_empty():
		return
	
	_set_event_collider(null)
	var collide = eventRayCaster.get_collider()
	if collide == null:
		uiManager.open_dialogue_box("Reusable/noproblem")
		return
	
	if "interact" in collide.name:
		var collided = collide.get_parent()
		for c in [collide, collided]:
			if not c.has_method("interact"):
				continue
			if c.has_method("has_dialog") and not c.has_dialog():
				return
			global.party_call("try_to_turn", c)
			c.interact()
			break
		if collide.get_node_or_null("ButtonPrompt"):
			collide.get_node_or_null("ButtonPrompt").press_button()
	elif not collide is Area2D:
		uiManager.open_dialogue_box("Reusable/noproblem")

func interact_item_with(item: Item):
	_set_event_collider(null)
	var collide = eventRayCaster.get_collider()

	if collide == null:
		uiManager.open_dialogue_box("Reusable/nothinghappened")
		return
	
	var collided = collide.get_parent()
	for c in [collide, collided]:
		if not c.has_method("interact_item"):
			continue
		global.party_call("try_to_turn", c)
		c.interact_item(item)
		return

func use_telepathy():
	if not _can_use_telepathy():
		uiManager.open_dialogue_box("Reusable/nothinghappened")
		return

	_set_event_collider(null)
	var collide = eventRayCaster.get_collider()
	if collide == null:
		uiManager.open_dialogue_box("Reusable/noproblem")
		return

	var target = _find_telepathy_target(collide)
	if target:
		_process_telepathy_target(target, collide)
	else:
		uiManager.open_dialogue_box("Reusable/nothoughts")
		_press_button_prompt(collide)

func _can_use_telepathy() -> bool:
	return uiManager.is_stack_empty() and _party_member.has_field_skill("telepathy")

func _find_telepathy_target(collide):
	var parent = collide.get_parent()
	if parent and parent.has_method("telepathy"):
		return parent
	if collide.has_method("telepathy"):
		return collide
	return null

func _process_telepathy_target(target, source):
	try_to_turn(target)
	if target.has_thoughts():
		if target != source:
			uiManager.set_telepathy_effect(true, target)
		target.telepathy()
		_press_button_prompt(source)
		return

	if target == source:
		uiManager.open_dialogue_box("Reusable/nothoughts")
		return

	if target.no_problem_thoughts:
		uiManager.open_dialogue_box("Reusable/nothoughts")
	else:
		uiManager.open_dialogue_box("Reusable/straythoughts")
		_press_button_prompt(source)

func _press_button_prompt(node):
	var button_prompt = node.get_node_or_null("ButtonPrompt")
	if button_prompt:
		button_prompt.press_button()

func spritesheet():
	var normal_texture: String = "res://Graphics/Character Sprites/%s/main.png" % _party_member.get_sprite()
	var special_texture: String = "res://Graphics/Character Sprites/%s/special.png" % _party_member.get_sprite()
	var snow_texture: String = "res://Graphics/Character Sprites/%sSnow/main.png" % _party_member.get_sprite()
	if ResourceLoader.exists(normal_texture) and sprite.texture.resource_path != normal_texture:
		if ResourceLoader.exists(special_texture):
			_special.texture = ResourceLoader.load(special_texture)
		if costume == "Snow" and ResourceLoader.exists(snow_texture):
				sprite.texture = ResourceLoader.load(snow_texture)
		else:
			sprite.texture = ResourceLoader.load(normal_texture)
		$Position / main.offset.y = - $Position / main.texture.get_height() / 40 + 14
		#print("Player sprite should now be: ", fullTexPath)
	elif not ResourceLoader.exists(normal_texture):
		sprite.texture = ResourceLoader.load("res://Graphics/Character Sprites/Ninten/main.png")

# Override
func blend_position(vector2: Vector2):
	if vector2 != Vector2.ZERO:
		for param in ["Idle", "Blink", "Walk/Walk", "FaintedIdle", "FaintedWalk/FaintedWalk", "Down", "Crouch", "Run/Run", "Jump", "Bat/Bat", "ShootPrep", "Cast", "CastHold", "CastPrep", "ShootHold"]:
			blend_animation(param, vector2)

func _attack_hold():
	var old_dir = _direction
	var party_lead = _party_member.get_name()
	if $AimTime.time_left == 0:
		_controls()
	if _input_vector != Vector2.ZERO:
		set_direction(_input_vector)
	if party_lead == PartyMember.LLOYD:
		_anim_state.travel("ShootHold")
		if $AimTime.time_left == 0 and old_dir != _direction:
			camera.move_offset(Vector2(_direction.x * 30, _direction.y * 20), 0.3)
	elif party_lead == PartyMember.ANA:
		_anim_state.travel("CastHold")
	elif party_lead == PartyMember.TEDDY:
		_state = MOVE
	else:
		_state = MOVE
		
	if Input.is_action_just_released("ui_cancel"):
		
		_attack_unleash()

func _attack_unleash():
	_state = ATTACK
	match _current_skill_action:
		"swing":
			$AudioStreamPlayer.stream = load("res://Audio/Sound effects/Ninten Bat.mp3")
			$AudioStreamPlayer.play()
			global.start_joy_vibration(0, 0.35, 0, 0.2)
			_anim_state.travel("Bat")
			if _party_member.is_incapacitated():
				_anim_tree.set("parameters/Bat/TimeScale/scale", 0.7)
			else:
				_anim_tree.set("parameters/Bat/TimeScale/scale", 1)
		"energy_beam":
			blend_animation("Shoot", _direction)
			_anim_state.travel("Shoot")
			camera.return_offset(0.4)
			$AimTime.stop()
		"pkfire", "pkfreeze", "pkthunder":
			_anim_state.travel("Cast")
			$OutlineAnim.play("Normal")
			$PKTime.stop()
		_:
			_state = MOVE

func _attack_animation_finished():
	$HitboxPivot/BatHitbox/CollisionShape2D.disabled = true
	_state = MOVE
	_tap_run = false

func hit_stop(length: float, camShake: float, pause := false, timeScale := 0.0, animation := ""):
	var oldTimeScale = 1
	if animation != "":
		oldTimeScale = _anim_tree.get("parameters/" + animation + "/TimeScale/scale")
		_anim_tree.set("parameters/" + animation + "/TimeScale/scale", timeScale)
	
	if pause:
		get_tree().paused = true
	
	if length != 0:
		if !camera.is_shaking() and camShake != 0:
			camera.shake_camera(camShake, 0.1, Vector2(1, 0))
		print("hit stop")
		yield(get_tree().create_timer(float(length)), "timeout")
	
	if pause:
		get_tree().paused = false
	if animation != "":
		_anim_tree.set("parameters/"+ animation +"/TimeScale/scale", oldTimeScale)



func _shoot():
	var b = Beam.instance()
	global.currentScene.get_node("Objects").add_child(b)
	var beam = b.get_node("BeamHead")
	beam.animationTree.set("parameters/_shoot/blend_position", _direction)
	beam.global_position = $HitboxPivot/BulletSpawn.global_position
	beam.inputVector = _direction
	beam.rotation = $HitboxPivot/BulletSpawn.global_rotation
	beam.animationState.travel("shoot")
	b.show()

func _cast():
	var ini_dir = _direction
	var ini_pos = $HitboxPivot/BulletSpawn.global_position
	var wait = Timer.new()
	wait.set_wait_time(0.067)
	wait.set_one_shot(true)
	self.add_child(wait)
	for i in 3 :
		var pk = Cast.instance()
		if ini_dir.x != 0:
			pk.position = (ini_pos + (Vector2(30 * i,30 * i) * ini_dir.normalized()))
		else:
			pk.position = (ini_pos + (Vector2(30 * i,25 * i) * ini_dir.normalized()))
		global.currentScene.get_node("Objects").add_child(pk)
		wait.start()
		yield(wait, "timeout")
	
	wait.queue_free()

func jump(height: float, length: float, hide_shadow:= false, anim := "Jump", start_crouch_time := 0.1, end_crouch_time := 0.0):
	_state = JUMPING
	blend_position(_direction)
	if start_crouch_time > 0.0:
		_anim_state.travel("Crouch")
		yield(get_tree().create_timer(start_crouch_time), "timeout")
	_anim_state.travel(anim)
	if hide_shadow:
		$Shadow.hide()
	
	var tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	if anim == "Jump":
		tween.tween_property($Position/main, "scale", Vector2(1,1), length) \
				.from(Vector2(0.9, 1.1)).set_delay(0.02)
	tween.tween_property($Position, "position", Vector2(0,-height), length) \
			.from(Vector2.ZERO)
	tween.chain().tween_property($Position, "position", Vector2.ZERO, length*0.75) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	yield(tween, "finished")
	if hide_shadow:
		$Shadow.show()
	if end_crouch_time > 0.0:
		_anim_state.travel("Crouch")
		yield(get_tree().create_timer(end_crouch_time), "timeout")
	emit_signal("jump_finished")

func bounce(height, length, anim):
	_anim_tree.set("parameters/"+ anim +"/TimeScale/scale", 0.0)

	jump(height, length, false, anim, 0.0, 0.1)
	_state = BOUNCING
	_anim_tree.active = false
	yield(self, "jump_finished")
	_anim_tree.set("parameters/"+ anim +"/TimeScale/scale", 1.0)
	_anim_tree.active = true
	
	_state = MOVE

func _bounce_state(delta: float):
	_velocity = -_direction * _speed * 0.9
	move_and_slide(_velocity)

func swap_spin(dir = 1):
	_switching = true
	_crouch = false
	_current_skill_action = ""
	yield (_spin(8, 45 * dir, 0.015, dir), "completed")
	_switching = false

func _spin(times, angle, rot_speed, leader_swap = 0):
	_spinning = true
	_spin_num = 0
	var dir = _direction.round()
	for n in times:
		_spin_num += 1
		if _switching and _spin_num == 4:
			match leader_swap:
				1:
					global.swap_party_forward()
				- 1:
					global.swap_party_backward()
			global.update_party_spritesheets()

		dir = dir.rotated(angle).round()
		blend_position(dir)
		yield(get_tree().create_timer(rot_speed),"timeout")
	_spinning = false

func rotate_to(new_dir: Vector2, rot_speed: float):
	new_dir = new_dir.normalized().round()
	_direction = _direction.round()
	var angle = 45 * sign(_direction.angle_to(new_dir))
	while _direction != new_dir:
		_direction = _direction.rotated(angle).round().normalized().round()
		blend_position(_direction)
		yield(get_tree().create_timer(rot_speed), "timeout")

# Override
func start_continuous_damage(damage: int, damage_variance: = 0, hit_direct: = Vector2.ZERO, status = null):
	.start_continuous_damage(damage, damage_variance, hit_direct, status)
	_hit_direct = hit_direct

# Override
func damage(damage: int, damage_variance := 0, hit_direct := Vector2.ZERO, cant_kill := true):
	camera.shake_camera(1, 0.2, Vector2(1, 0))
	global.start_joy_vibration(0, 0.6, 0.8, 0.1)
	.damage(damage, damage_variance, hit_direct, cant_kill)

func game_over():
	pause()
	uiManager.game_over()

# Override
func ladder():
	.ladder()
	_state = MOVE
	if audioManager.get_sfx("run") != null:
		audioManager.get_sfx("run").stop()

# Override
func unladder():
	.unladder()
	if _running:
		_set_running(true)

func set_speed(value: float):
	_speed = value

func _set_running(enabled: bool):
	_running = enabled
	if !_paused and _state == MOVE:
		if enabled and !_climbing:
			var sfx = load("res://Audio/Sound effects/Footsteps/" + run_sound + ".mp3")
			if audioManager.get_sfx("run") != null and audioManager.get_sfx("run").stream == sfx:
				if !audioManager.get_sfx("run").playing :
					audioManager.get_sfx("run").play()
			else:
				audioManager.play_sfx(sfx, "run")
	if audioManager.get_sfx("run") != null and audioManager.get_sfx("run").playing and !enabled:
		audioManager.get_sfx("run").stop()

func _start_landing():
	global.party_call("set_collisions", false)
	_running = true
	_state = LANDING
	_speed = SPEED_LANDING

func start_teleport(tp_mode: int):
	_speed = SPEED_RUNNING
	_set_running(true)
	_state = TELEPORTING
	_tp_crouch_timer_done = false
	_tp_max_speed_reached = false
	_tp_take_off_timer_done = false
	_tp_mode = tp_mode
	_velocity = _direction * _speed
	$OutlineAnim.play("Normal")

func pause(stop_running := false, start_idle := true, emit_signal := true):
	global.party_call("pause_flash_anim")
	global.party_call("stop_creating_afterimage")
	global.party_call("pause_timers")
	
	_anim_play_pause(false, start_idle)
	_crouch = false
	_walk = false
	if !(_state == TELEPORTING and _tp_take_off_timer_done):
		_state = MOVE
	_paused = true
	if _tp_take_off_timer:
		_tp_take_off_timer.stop()
	_input_vector = Vector2.ZERO
	$AudioStreamPlayer.playing = false
	$AudioStreamPlayer.stream_paused = true
	$MiscTimer.set_paused(true)
	if stop_running or !_tap_run:
		_tap_run = false
		_set_running(false)
	_set_collision_masks(false)
	
	if emit_signal: emit_signal("paused")

func unpause(emit_signal: = true):
	if not global.currentScene is AreaRoom:
		return
	
	_anim_play_pause(true)
	$AudioStreamPlayer.stream_paused = false
	$MiscTimer.set_paused(false)
	global.party_call("resume_flash_anim")
	global.party_call("resume_timers")
	_paused = false
	_set_collision_masks(true)
	if _state == TELEPORTING:
		_start_landing()
	else:
		_state = MOVE
	
	if emit_signal: emit_signal("unpaused")
	_check_event_collider()
	if _running:
		_set_running(true)

func on_dialogue_done(result := 0):
	unpause()

func is_paused() -> bool:
	return _paused

func is_walking() -> bool:
	return _walk

func is_running() -> bool:
	return _running

func is_crouching() -> bool:
	return _crouch

func exit_camera():
	_state = MOVE
	blend_position(_direction)
	set_anim_state("Idle")

func _set_collision_masks(enabled: bool):
	set_collision_mask_bit(0, enabled)
	set_collision_mask_bit(8, enabled)

func _on_BlinkTime_timeout():
	_idle = true

func _on_PKTime_timeout():
	if _state != ATTACK_PREP:
		return
	
	var skill_actions: = _get_skills_button_actions()
	var current_skill_index = skill_actions.find(_current_skill_action)
	current_skill_index = (current_skill_index + 1) % skill_actions.size()
	_current_skill_action = skill_actions[current_skill_index]
	match _current_skill_action:
		"pkfire":
			$EffectsAnim.play("Fire")
		"pkfreeze":
			$EffectsAnim.play("Freeze")
		"pkthunder":
			$EffectsAnim.play("Thunder")
	$OutlineAnim.play("Flash")
	$PKTime.wait_time = 1
	$PKTime.start()

func _on_OutlineAnim_animation_finished(anim_name: String):
	if anim_name != "Flash":
		return
	match _current_skill_action:
		"pkfire":
			$OutlineAnim.play("Fire")
		"pkfreeze":
			$OutlineAnim.play("Freeze")
		"pkthunder":
			$OutlineAnim.play("Thunder")

func get_state() -> int:
	return _state

func get_velocity() -> Vector2:
	return _velocity

func get_current_skill_action() -> String:
	return _current_skill_action

func can_see(object: KinematicBody2D) -> bool:
	for body in $EventDetector/ViewArea.get_overlapping_bodies():
		if object == body:
			return true
	return false

func has_substantial_movement() -> bool:
	return _substantial_movement

func _on_AimTime_timeout():
	if _state == ATTACK_PREP:
		camera.move_offset(Vector2(_direction.x * 30, _direction.y * 20), 0.3)

func set_direction_and_input(new_dir: Vector2):
	_input_vector = new_dir
	set_direction(new_dir)

# Override
func set_direction(new_dir: Vector2):
	_direction = new_dir
	eventRayCaster.rotation = _direction.angle() - TAU / 4
	blend_position(new_dir)

func set_debug_speed(enabled: bool):
	_debug_speed = enabled

# Override
func get_direction() -> Vector2:
	return _direction

func _update_party_positions(oldpos: Vector2, multiplier := 1.0):
	var maxDist = round(max(abs(oldpos.x-self.position.x), abs(oldpos.y-self.position.y)) * multiplier)
	for i in maxDist:
		global.partySpace.push_front(lerp(oldpos, position.round(), (i+1)/maxDist))
		global.partySpace.pop_back()

func _on_TPCrouchTime_timeout():
	if _crouch:
		_tp_crouch_timer_done = true
		global.party_call("play_flash_anim", "TeleportFlash")

func _on_TPTakeOffTime_timeout():
	global.party_call("set_collisions", false)
	_tp_take_off_timer_done = true
	uiManager.fix_camera()
	yield(get_tree().create_timer(.6), "timeout")
	pause()

	camera.set_current()
	camera.reset()

func turn_to(target, cardinal):
	var rel_position = target.global_position - global_position
	if cardinal and target.get("player_turn") != null:
		if (abs(rel_position.x) > abs(rel_position.y) or not target.player_turn.y) and rel_position.x != 0 and target.player_turn.x:
			_direction = Vector2(sign(rel_position.x), 0)
		elif target.player_turn.y and rel_position.y != 0:
			_direction = Vector2(0, sign(rel_position.y))
	else:
		_direction = rel_position
	blend_animation("Idle", _direction)
	set_anim_state("Idle")
	
func _turn_to(target):
	var rel_position = global_position.direction_to(target.global_position)
	var _direction = rel_position
	if (abs(rel_position.x) > abs(rel_position.y) or not target.player_turn.y)\
	and rel_position.x != 0 and target.player_turn.x:
		_direction = Vector2(sign(rel_position.x), 0)
	elif target.player_turn.y and rel_position.y != 0:
		_direction = Vector2(0, sign(rel_position.y))

	blend_animation("Idle", _direction)
	set_anim_state("Idle")

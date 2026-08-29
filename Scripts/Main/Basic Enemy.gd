extends KinematicBody2D
class_name OverworldEnemy

signal enemy_erased

export (String) var enemy = ""
export (String) var anim = "" #animation json
export (Array, PoolStringArray) var connections = [] 
export var spriteOffset = [0, 0]
export var shadow = true
export var returning = true
export var maxDistance = 128
export var maxSpeed: int = 64
export var acceleration: int = 200
export var friction: int = 200
export var walk_frequency = 1.0


onready var eventRayCaster = $EventDetector
onready var character_sprite = $CharacterSprite
onready var emotes = $CharacterSprite/emotes
onready var wander_radius = $WanderRadius/CollisionShape2D2

const KNOCKBACK := 200
const KNOCKBACK_DECELERATION := 7
const MIN_MOVEMENT_LENGTH := 8
const MIN_DISINTEREST_TIME := 2

var _vector_sprite_offset = Vector2.ZERO
var sprite = ""
var _enemy_char: Enemy
var _seeing = false
var _blind = false
var _underlevel = false
var drafted = false
var _direction = Vector2.ZERO
var _input_vector  = Vector2.ZERO
var velocity = Vector2.ZERO
var start_pos = Vector2.ZERO
var _knockback = Vector2.ZERO
var new_pos = null
#var startingHP = 0
var _on_screen_enemy: OnScreenEnemy = null
var changingParents = false
var _tween: SceneTreeTween
var _disinterest_time: = 0.0


enum {
	WANDER,
	RETURN
	CHASE,
	STUNNED
}
var state = WANDER

func _ready():
	_enemy_char = Enemy.new(enemy.replace(" ", ""))
	var enemy_data = _enemy_char.get_data()
	if _enemy_char and enemy_data.has("ov"):
		for i in enemy_data["ov"]:
			set(i, enemy_data["ov"][i])
	_set_underlevel()
	new_pos = position
	character_sprite.animationTree.active = true
	set_spritesheet()
	set_physics_process(false)
	$Shadow.visible = shadow
	start_pos = position
	_input_vector.x = round(rand_range(-1, 1))
	_input_vector.y = round(rand_range(-1, 1))
	set_direction(_input_vector)
	if walk_frequency != 0:
		$WanderRadius/Timer.wait_time = rand_range(0.1, walk_frequency)
	state = WANDER
	
func _physics_process(delta: float):
	if global.get_player().is_paused() or global.entering_door:
		if global.get_player().is_paused():
			character_sprite.animationTree.active = false
		return
	character_sprite.animationTree.active = true
	eventRayCaster.look_at(global.get_player().get_ground_position())
	if is_raycast_on_player() and position.distance_to(start_pos) <= maxDistance:
		_disinterest_time = 0
		if not state in [CHASE, STUNNED]:
			if (_seeing or (global.get_player().is_running() and global.get_player().has_substantial_movement())) and not _blind:
				start_chase()
	elif state == CHASE:
		_disinterest_time += delta
		if _disinterest_time >= MIN_DISINTEREST_TIME:
			chase_stop()
	
	var old_pos = position
	var difference = max(ceil(abs(maxSpeed * delta)), 1.0)
	match state:
		WANDER:
			if abs(global_position.x - new_pos.x) > difference or abs(global_position.y - new_pos.y) > difference:
				_input_vector = position.direction_to(new_pos)
				velocity = velocity.move_toward(_input_vector * maxSpeed, acceleration * delta)
			else:
				velocity = Vector2.ZERO
		RETURN:
			if $Timer.time_left == 0:
				_input_vector = position.direction_to(new_pos)
				velocity = velocity.move_toward(_input_vector * maxSpeed, acceleration * delta)
			if abs(global_position.x - new_pos.x) > difference or abs(global_position.y - new_pos.y) > difference:
				_input_vector = Vector2.ZERO
				start_wander()
		CHASE:
			if _underlevel:
				_input_vector = global.partyObjects[int(global.partyObjects.size() / 2)].global_position.direction_to(global_position)
			else:
				_input_vector = global_position.direction_to(global.partyObjects[int(global.partyObjects.size() / 2)].global_position)
			if $ChaseTimer.time_left == 0:
				velocity = velocity.move_toward(_input_vector * maxSpeed, acceleration * delta)
	
	_input_vector = _input_vector.round()
	
	velocity = move_and_slide(velocity)
	_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECELERATION * delta)
	_knockback = move_and_slide(_knockback)
	
	position = position.round()
	if velocity != Vector2.ZERO and position != old_pos:
		_direction = velocity.normalized().round()
		character_sprite.travel("Walk")
	else:
		character_sprite.travel("Idle")
	
	$RayCast2D.rotation = _direction.angle() - TAU / 4
	character_sprite.blend_position(_direction)

func _choose_movement_direction():
	var old_pos = position
	
	var x = position.x
	var y = position.y
	
	if randi()%2 == 1: 
		x = rand_range(start_pos.x - wander_radius.shape.radius/2, start_pos.x + wander_radius.shape.radius/2)
	else:
		y = rand_range(start_pos.y - wander_radius.shape.radius / 2, start_pos.y + wander_radius.shape.radius / 2)
	var travel_pos = Vector2(round(x), round(y))
	$RayCast2D.enabled = true
	$RayCast2D.set_cast_to(travel_pos - position)
	var ample_distance_x = abs(travel_pos.x - old_pos.x)
	var ample_distance_y = abs(travel_pos.y - old_pos.y)
	if (ample_distance_x > MIN_MOVEMENT_LENGTH or ample_distance_y > MIN_MOVEMENT_LENGTH):
		if $RayCast2D.get_collider() == null:
			new_pos = travel_pos
			_input_vector = old_pos.direction_to(new_pos)
	else:
		_choose_movement_direction()

func set_direction_and_input(value: Vector2):
	_input_vector = value
	set_direction(value)

func set_direction(value: Vector2):
	_direction = value

func get_direction() -> Vector2:
	return _direction

func jump():
	character_sprite.travel("Walk")
	if not _tween or not _tween.is_running(): _tween = get_tree().create_tween()
	_tween.tween_property(character_sprite, "offset", _vector_sprite_offset - Vector2(0, 5), 0.1)\
	.from(_vector_sprite_offset).set_ease(Tween.EASE_OUT)
	_tween.tween_property(character_sprite, "offset", _vector_sprite_offset, 0.1)\
	.set_ease(Tween.EASE_IN)

func start_chase():
	if (state == WANDER or state == RETURN) and !emotes.animaPlayer.is_playing() and !global.get_player().is_paused():
		state = CHASE
		stop_wander()
		jump()
		emotes.animaPlayer.play("exclamation" if not _underlevel else "blueExclamation")
		$ChaseTimer.start()

func chase_stop():
	velocity = velocity.move_toward(Vector2.ZERO, friction)
	character_sprite.travel("Idle")
	$Timer.start()
	if returning == true:
		state = RETURN
		new_pos = start_pos
	else: 
		state = WANDER

func start_wander():
	_choose_movement_direction()
	state = WANDER
	$WanderRadius/Timer.wait_time = rand_range(walk_frequency - 0.5, walk_frequency + 0.5)
	$WanderRadius/Timer.start()

func stop_wander():
	$WanderRadius/Timer.stop()

func is_raycast_on_player() -> bool:
	return eventRayCaster.get_collider() == global.get_player()

func _on_Timer_timeout():
	if walk_frequency != 0 and $VisibilityNotifier2D.is_on_screen():
		if state == WANDER and start_pos != null:
			_choose_movement_direction()
			start_wander()

func _on_ViewArea_body_entered(body: KinematicBody2D):
	if body == global.get_player():
		_seeing = true

func _on_ViewArea_body_exited(body: KinematicBody2D):
	if body == global.get_player():
		_seeing = false

func _on_blindSpot_body_entered(body: KinematicBody2D):
	if body == global.get_player():
		_blind = true

func _on_blindSpot_body_exited(body: KinematicBody2D):
	if body == global.get_player():
		_blind = false

func _on_interact_body_entered(body: KinematicBody2D):
	if not (visible and body is PartyObject and not uiManager.is_in_cutscene() and not uiManager.is_battle_queued() and not global.entering_door and global.can_pause):
		return

	if global.get_player().is_paused():
		yield(global.get_player(), "unpaused")

	if not enemy: return
	if _underlevel and global.get_player().is_running() and global.get_player().has_substantial_movement():
		_handle_underlevel()
		return

	if $DamageAnimation.current_animation == "Flash":
		return
	$interact / CollisionShape2D.set_deferred("disabled", true)
	chase_stop()
	_start_battle()

func _handle_underlevel():
	if state == STUNNED:
		return
	global.currentCamera.shake_camera(2, 0.2)
	global.start_joy_vibration(0, 0.5, 0.6, 0.2)
	$AudioStreamPlayer.play()
	flash(1, 0.08, 0.6, true)
	if _tween: _tween.kill()
	_tween = create_tween().set_ease(Tween.TRANS_SINE)
	_tween.tween_property(character_sprite, "position", Vector2(0, character_sprite.position.y - 64), 0.2)\
	.set_ease(Tween.EASE_OUT)
	_tween.tween_property(character_sprite, "position", character_sprite.position, 0.3)\
	.set_ease(Tween.EASE_IN).set_delay(0.1)
	state = STUNNED
	stop_wander()
	character_sprite.animationTree.active = false
	velocity = Vector2.ZERO

func _start_battle():
	push_to_front_battle()
	if global.get_player().can_see(self):
		uiManager.start_battle(BattleSystem.Advantage.NEUTRAL if _seeing else BattleSystem.Advantage.PLAYER)
	else:
		uiManager.start_battle(BattleSystem.Advantage.ENEMY)

func _on_Hurtbox_area_entered(area: Area2D):
	if not _can_receive_damage():
		return

	if area.get_collision_layer_bit(7):
		_do_damage(300 + randi() % 7, false)
	elif (area.get_collision_layer_bit(1) and $EventDetector.get_collider() == global.get_player()) or area.get_collision_layer_bit(3):
		_do_damage(0)
	elif area.get_collision_layer_bit(2):
		
		area.get_parent().create_spark("Explosion")
		area.get_parent().disappear()
		stun()

func _can_receive_damage() -> bool:
	return not global.get_player().is_paused() and not uiManager.is_in_cutscene() and not drafted

func _do_damage(val: int, player_hit := true):
	uiManager.set_battle_queued(true)
	
	$AudioStreamPlayer.play()
	global.start_joy_vibration(0, 0.6, 0.6, 0.2)
	global.currentCamera.shake_camera(8, 0.15, Vector2.ZERO, 0.01)
	
	Shaker.new(character_sprite, "offset")\
	.set_shake_magnitude(8)\
	.set_shake_direction(Vector2.ZERO)\
	.set_shake_length(0.4)\
	.set_shake_interval(0.02).start()
	
	if player_hit:
		val = _calculate_damage(val)
	
	_enemy_char.set_hp(_enemy_char.get_hp() - val)
	uiManager.create_flying_num(val, global_position)
	_knockback = global.get_player().get_direction() * KNOCKBACK
	$DamageAnimation.stop()
	$DamageAnimation.play("Flash")
	$interact/CollisionShape2D.set_deferred("disabled", true)
	print("startflash")
	yield($DamageAnimation, "animation_finished")
	print("done")
	uiManager.set_battle_queued(false)
	if _enemy_char.get_hp() <= 0:
		die(false)
		global.party_give_exp(_enemy_char.get_exp())
	elif not uiManager.is_in_cutscene():
		push_to_front_battle()
		uiManager.start_battle(BattleSystem.Advantage.NEUTRAL)
	
	_knockback = Vector2.ZERO
	$interact / CollisionShape2D.set_deferred("disabled", false)

func _calculate_damage(val: int) -> int:
	var bash = globaldata.get_battle_skill(globaldata.SKILL_BASH)
	var mod = global.party[0].get_stat(Character.OFFENSE)
	var defense = _enemy_char.get_stat(Character.DEFENSE)
	val += int(max(1, bash.damage_or_heal + mod - (defense / 2.0)))
	
	val = val + (randf() * bash.variance) - bash.variance / 2.0
	val = int(round(val))
	if global.party[0].is_incapacitated():
		val = int(round(val / 4))
	return val

func _on_DamageAnimation_animation_finished(anim_name: String):
	if anim_name == "Stun":
		start_wander()
		if is_raycast_on_player():
			start_chase()
		character_sprite.animationTree.active = true

func stun():
	$DamageAnimation.stop()
	$DamageAnimation.play("Stun")
	Shaker.new(character_sprite, "offset")\
	.set_shake_magnitude(3)\
	.set_shake_direction(Vector2.RIGHT)\
	.set_shake_length(1)\
	.set_shake_interval(0.04).start()\
	.set_shake_diminish(false)
	
	state = STUNNED
	stop_wander()
	character_sprite.animationTree.active = false
	velocity = Vector2.ZERO

func flash(length = 1, interval = 0.08, delay = 0, stun = false):
	if stun:
		set_physics_process(false)
		state = STUNNED
		stop_wander()
		character_sprite.animationTree.active = false
		velocity = Vector2.ZERO
		$interact / CollisionShape2D.set_deferred("disabled", true)
	yield(get_tree().create_timer(delay), "timeout")
	for i in length / (interval * 2):
		character_sprite.hide()
		yield(get_tree().create_timer(interval), "timeout")
		character_sprite.show()
		yield(get_tree().create_timer(interval), "timeout")
	if stun:
		start_wander()
		set_physics_process(true)
		$interact / CollisionShape2D.set_deferred("disabled", false)
		if is_raycast_on_player():
			start_chase()
		character_sprite.animationTree.active = true

func die(in_battle := true):
	if uiManager.is_in_battle() == in_battle:
		queue_free()
		emit_signal("enemy_erased")

func duplicate_sprite():
	return character_sprite.duplicate()

func set_spritesheet():
	var path = "res://Graphics/Character Sprites/Enemies/" + sprite + ".png"
	character_sprite.set_sprite(path)
	if anim == "":
		anim = "BasicEnemy"
	var animPath = "res://Data/Animations/%s.yaml" % anim
	character_sprite.set_animation(animPath, connections)
	
	character_sprite.set_spritesheet()
	character_sprite.set_sprite_offset(Vector2(spriteOffset[0], spriteOffset[1]))
	_vector_sprite_offset = character_sprite.offset

func _set_underlevel():
	var highestLevel = 0
	for i in global.party.size():
		if global.party[i].get_level() > highestLevel:
			highestLevel = global.party[i].get_level()
	if highestLevel >= _enemy_char.get_level() + 10:
		_underlevel = true

func _check_screen_entered():
	if $VisibilityNotifier2D.is_on_screen():
		start_wander()
		set_physics_process(true)
		add_battle()

func _on_screen_entered():
	print("Enemy entered on screen")
	$interact / CollisionShape2D.set_deferred("disabled", false)
	start_wander()
	set_physics_process(true)
	add_battle()

func _on_screen_exited():
	print("Enemy exited screen")
	stop_wander()
	set_physics_process(false)
	remove_battle()

func add_battle():
	_on_screen_enemy = uiManager.add_on_screen_enemy(_enemy_char, self)

func remove_battle():
	uiManager.erase_on_screen_enemy(_on_screen_enemy)
	_on_screen_enemy = null

func push_to_front_battle():
	drafted = true
	if _on_screen_enemy:
		if uiManager.has_on_screen_enemy(_on_screen_enemy):
			uiManager.move_on_screen_enemy_to_front(_on_screen_enemy)
	else:
		_on_screen_enemy = uiManager.add_on_screen_enemy_to_front(_enemy_char, self)

func activate():
	set_physics_process(true)
	drafted = false
	show()
	emotes.show()
	velocity = Vector2.ZERO
	_knockback = Vector2.ZERO
	$interact / CollisionShape2D.set_deferred("disabled", false)
	_enemy_char.set_hp(_enemy_char.get_stat("maxhp"))
	_enemy_char.set_pp(_enemy_char.get_stat("maxpp"))

func _on_Enemy_tree_exiting():
	if !changingParents:
		die(false)


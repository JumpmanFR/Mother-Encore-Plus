extends ControlledTwoStatesObject
class_name JumpArea

signal jump

const TWEEN_TIME := 0.5
const ARROW_FURTHER_OFFSET := - Vector2(0, 20)

export var jump_height := 20
export var player_turn := { 
	"y": true, #Make "x" true if you want the player to turn left/right when jumping
	"x": true #Make "y" true if you want the player to turn up/down when jumping
}  #Putting both to true will apply both effects and enable diagonals

var _is_player_jumping := false
var _is_player_nearby := false
var _is_player_inside := false

var _is_enabled := true

var _arrow_pos := Vector2.ZERO

func _ready():
	_arrow_pos = $Sprite.position
	$Sprite.scale = Vector2.ZERO

func _input(event):
	if event.is_action_pressed("ui_accept") and (_get_ray_to_player() or _is_player_jumping):
		_start_jump_process()

func _process(delta):
	if _get_ray_to_player():
		_update()

func _start_jump_process():
	var player = global.get_player()
	if _can_jump() and player.get_state() == player.MOVE and !player.is_paused() and uiManager.is_stack_empty():
		$Camera2D.set_current()
		_is_player_jumping = true
		player.pause(false, true, false)
		player.set_collision_layer_bit(0, false)
		_on_Close_body_exited(player)
		#pauses all characters in party
		for i in range(1, global.partyObjects.size()):
			global.partyObjects[i].jumps += 1
			if global.partyObjects[i].is_physics_processing():
				global.partyObjects[i].set_idle()
				global.partyObjects[i].set_physics_process(false)
		#now it's time to make them jump!
		for j in global.partyObjects:
			if j is PartyFollower:
				if !j.active:
					yield(j, "action_done")
				j.active = false
			_jump(j)
			if j == global.partyObjects[0]:
				emit_signal("jump")
			#else:
			#	yield(self, "jump") # Causes issues with 4 characters
			yield(get_tree().create_timer(0.5), "timeout")
	elif _is_player_jumping:
		emit_signal("jump")

func _jump(jumper: PartyObject):
	for i in $"Jump Points".get_children():
		if not i is Position2D:
			continue
		if jumper == global.get_player():
			global.start_joy_vibration(0, 0.4, 0, 0.2)
		var direction: = jumper.global_position.direction_to(i.global_position)
		if not player_turn.x:
			direction.x = 0
		if not player_turn.y:
			direction.y = 0
		jumper.set_direction(direction)
		jumper.set_idle()
		if _is_player_jumping:
			if jumper is PartyMemberPlayer or jumper.jumps == 1:
				yield(self, "jump")
		jumper.jump(jump_height, 0.3, true)
		var tween = create_tween()
		tween.tween_property(jumper, "global_position", i.global_position - jumper.get_node("Shadow").position, 0.525)\
		.set_ease(Tween.EASE_IN).set_delay(0.1)
		if jumper == global.get_player():
			global.start_joy_vibration(0, 0.4, 0, 0.2)
			if i.get_index() != $"Jump Points".get_child_count() - 1:
				var next_point = $"Jump Points".get_child(i.get_index() + 1)
				global.currentCamera.move_camera((i.global_position + next_point.global_position) / 2 + Vector2(0, - 7), 0.6)
			else:
				global.currentCamera.move_camera(i.global_position + Vector2(0, - 7), 0.6)
		yield(tween, "finished")
	
	if jumper == global.get_player():
		global.start_joy_vibration(0, 0.4, 0, 0.2)
		jumper.set_direction(jumper.get_direction().round())
		global.get_player().set_collision_layer_bit(0, true)
		global.get_player().unpause()
		global.get_player().camera.set_current()
		global.currentCamera.return_camera(0.5)
		_is_player_jumping = false
		emit_signal("jump")
		global.reset_party_positions()
	else:
		jumper.set_idle()
		jumper.active = true
		jumper.emit_signal("action_done")
		jumper.jumps -= 1
		if global.get_player().get_state() != global.get_player().JUMPING and jumper.jumps == 0:
			jumper.set_physics_process(true)
			jumper.find_path()

func _on_Jump_Area_body_entered(body):
	if body == global.get_player():
		_is_player_inside = true
		_update()

func _on_Jump_Area_body_exited(body):
	if body == global.get_player():
		_is_player_inside = false
		_update()
		
func _on_Close_body_entered(body):
	if body == global.get_player():
		_is_player_nearby = true
		if global.get_player().is_running() and _get_ray_to_player():
			$Inside/CollisionShape2D.scale = Vector2(1.5, 1.5)
			yield(get_tree().create_timer(0.5),"timeout")
			$Inside/CollisionShape2D.scale = Vector2.ONE

func _on_Close_body_exited(body):
	if body == global.get_player():
		_is_player_nearby = false
		_update()

func _has_skill():
	return globaldata.flags.get("eagle_feather")

func _are_prompts_enabled():
	return globaldata.button_prompts in ["Objects", "Both"]

func _can_jump():
	return _is_player_inside and _has_skill() and _is_enabled

# Override
func update_state(silent: bool = false):
	yield(_update(), "completed")
	.update_state(silent)

func _get_ray_to_player() -> bool:
	$RayCast2D.look_at(global.get_player().get_ground_position())
	
	return $RayCast2D.get_collider() == global.get_player() and _is_player_nearby

func _update():
	_is_enabled = _get_state()
	var nearby := _get_ray_to_player()
	var offset := ARROW_FURTHER_OFFSET if _is_player_inside else Vector2.ZERO
	var size := Vector2.ONE if (nearby and _has_skill() and _is_enabled and _are_prompts_enabled()) else Vector2.ZERO
	global.get_player().can_interact = !_can_jump()
	var tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property($Sprite, "position" , _arrow_pos + offset, TWEEN_TIME)
	tween.tween_property($Sprite, "scale", size, TWEEN_TIME)
	if size == Vector2.ONE:
		$AnimationPlayer.play("Arrow")
		yield(get_tree(), "idle_frame")
	else:
		yield(tween, "finished")
		if scale == Vector2.ZERO:
			$AnimationPlayer.stop()

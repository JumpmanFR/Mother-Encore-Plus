extends Bomb
class_name BombBigger

const MOVE_AMOUNT = 235
const DECELERATION = 648
var pushing = false
var velocity = 0
var direction = Vector2.ZERO

func _physics_process(delta):
	if pushing:
		move_and_collide(direction * velocity * delta)
		velocity -= DECELERATION * delta
		
		if velocity <= 0:
			pushing = false
			position = position.round()

func bat_interaction():
	var dir = Vector2(global.get_player().get_direction()).normalized()
	push(dir)
	jump(8, 0.08, 0.05, 0.05, false)
	start_explosion()
	Shaker.new($main, "offset")\
	.set_shake_direction(Vector2.RIGHT)\
	.set_shake_magnitude(3)\
	.set_shake_length(0.2)\
	.set_shake_interval(0.05).start()

func start_explosion():
	if _animation_player.current_animation != "Blink":
		_animation_player.play("Blink")
		yield(_animation_player, "animation_finished")
		explode()

#
#func _on_VerticalPush_body_entered(body):
#	if body == global.get_player():
#		print("push vertically")
#		var dir = Vector2(0, sign(global.get_player().global_position.direction_to(global_position).y)).round()
#		print(dir)
#		if dir.y == global.get_player().get_direction().y:
#			push(dir)
#			global.get_player().bounce(10, 0.135, "Run")
#			start_explosion()
#
#
#func _on_HorizontalPush_body_entered(body):
#	if body == global.get_player() and global.get_player().is_running() and !pushing:
#		print("push horizontally")
#		var dir = Vector2(sign(global.get_player().global_position.direction_to(global_position).x), 0).round()
#		print(dir)
#		if dir.x == global.get_player().get_direction().x:
#
#			_run_push(dir)
#
#func _run_push(dir: Vector2):
#	global.get_player().is_running() = false
#	global.get_player().bounce(10, 0.135, "Run")
#	push(dir)
#	start_explosion()

func push(dir : Vector2):
	if !pushing:
		direction = dir
		velocity = MOVE_AMOUNT
		pushing = true

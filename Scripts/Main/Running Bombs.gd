extends Bomb
class_name RunningBomb

onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
var running = false
var input_vector = Vector2.ZERO
var velocity = Vector2.ZERO

const TURN_PITCH_SCALE_CHANGE = 0.08
const TURN_PITCH_SCALE_MAX = 1.8

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationTree.active = true
	$AudioStreamPlayer2D.pitch_scale -= TURN_PITCH_SCALE_CHANGE
	connect("jump_done", self, "explode")

func _physics_process(_delta):
	if $RunTimer.time_left != 0:
		return
	velocity = input_vector * 96
	velocity = move_and_slide(velocity)
	var collided = get_slide_count() > 0
	if running == true and collided:
		explode()

func change_dir(dir: Vector2):
	input_vector = dir
	if $AudioStreamPlayer2D.pitch_scale < TURN_PITCH_SCALE_MAX:
		$AudioStreamPlayer2D.pitch_scale += TURN_PITCH_SCALE_CHANGE
	$AudioStreamPlayer2D.play()
	animationTree.set("parameters/Run/Run/blend_position", input_vector)
	animationState.travel("Run")

func bat_interaction():
	$DamageAnimation.play("Flash")
	input_vector = global.get_player().get_direction()
	animationTree.set("parameters/Flying/Flying/blend_position", input_vector)
	animationState.travel("Flying")
	jump()

func beam_interaction(beamArea):
	if running:
		explode()
	$DamageAnimation.play("Flash")
	var beam = beamArea.get_parent()
	input_vector = beam.inputVector
	if input_vector.x != 0 and input_vector.y != 0:
		var rel_position = self.global_position - (beam.global_position - beam.input_vector * 8)
		if abs(rel_position.x) > abs(rel_position.y):
			input_vector = Vector2(sign(rel_position.x), 0)
		else:
			input_vector = Vector2(0, sign(rel_position.y))
	beam.disappear()
	animationTree.set("parameters/Run/Run/blend_position", input_vector)
	$RunTimer.start()
	animationState.travel("Run")
	running = true

func _on_Hurtbox_body_entered(body):
	if running:
		explode()

func _on_player_pause():
	animationTree.set("parameters/Run/TimeScale/scale", 0)
	animationTree.set("parameters/Flying/TimeScale/scale", 0)
	._on_player_pause()

func _on_player_unpause():
	animationTree.set("parameters/Run/TimeScale/scale", 1)
	animationTree.set("parameters/Flying/TimeScale/scale", 1)
	._on_player_unpause()

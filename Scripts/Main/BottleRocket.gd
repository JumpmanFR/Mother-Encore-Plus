extends Sprite


onready var animation_player = $AnimationPlayer

func set_base():
	frame = 0

func set_wings():
	frame = 1

func set_head():
	frame = 2

func set_bow():
	frame = 3

func set_frame(f: int) -> void:
	frame = f

func start_blinking() -> void:
	animation_player.play("Blink")

func blink_faster() -> void:
	animation_player.playback_speed *= 1.5

func start_shaking() -> void :
	var shaker = Shaker.new(self, "offset")\
	.set_shake_direction(Vector2.UP)\
	.set_shake_interval(0.05)\
	.set_shake_diminish(false).start()

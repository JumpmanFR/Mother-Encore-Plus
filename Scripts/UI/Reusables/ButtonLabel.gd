extends HBoxContainer

export var show_on_press = false

var _tween: SceneTreeTween = null

func _ready():
	if show_on_press:
		reset()

func _input(event: InputEvent):
	if event.is_action_pressed("ui_accept") and show_on_press:
		fade_in()

func fade_in():
	if _tween and _tween.is_running(): _tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_QUART)
	_tween.tween_property(self, "modulate", Color.white, 1).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate", Color.transparent, 1).set_ease(Tween.EASE_IN_OUT)\
	.from(Color.white).set_delay(3)

func reset():
	if _tween and _tween.is_running(): _tween.kill()
	modulate = Color.transparent

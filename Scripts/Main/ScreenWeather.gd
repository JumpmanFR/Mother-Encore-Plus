extends CanvasLayer

var _tween: SceneTreeTween

func _ready():
	uiManager.connect("ov_to_battle", self, "fadeout")
	uiManager.connect("battle_to_ov", self, "fadein")
	

func fadein():
	if _tween:
		_tween.kill()
	_tween = create_tween()
	for i in get_children():
		if i.get("modulate") != null:
			_tween.tween_property(i, "modulate", Color.white, 0.4)

func fadeout():
	if _tween:
		_tween.kill()
	_tween = create_tween()
	for i in get_children():
		if i.get("modulate") != null:
			_tween.tween_property(i, "modulate", Color.transparent, 0.4)

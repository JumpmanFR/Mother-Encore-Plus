extends CanvasLayer

var _tween: SceneTreeTween

func show_language():
	$Label.modulate = Color.white
	$Label.show()
	$Label.text = tr("OPTIONS_LANGUAGE_" + tr("LANGUAGE_CODE").to_upper())
	
	if _tween and _tween.is_running(): _tween.kill()
	
	_tween = create_tween()
	_tween.tween_interval(0.2)
	_tween.tween_property($Label, "modulate", Color.transparent, 1.0)
	_tween.tween_callback($Label, "hide")

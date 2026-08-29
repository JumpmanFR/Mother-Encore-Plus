extends CanvasLayer

var _is_open = false
var _tween: SceneTreeTween

func open():
	update()
	if _is_open:
		return
	
	_is_open = true
	$HBoxContainer.show()
	if _tween: _tween.kill()
	_tween = create_tween()
	_tween.tween_property($HBoxContainer, "rect_position:x", 280, 0.2)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func close():
	if not _is_open:
		return
	
	_is_open = false
	if _tween: _tween.kill()
	_tween = create_tween()
	yield(_tween.tween_property($HBoxContainer, "rect_position:x", 320, 0.2)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT), "finished")
	$HBoxContainer.hide()

func update():
	$HBoxContainer/Money.text = "x %s" % uiManager.get_key_count()
	if $HBoxContainer.rect_position.x == 280:
		if !_tween or !_tween.is_running(): _tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_tween.tween_property($HBoxContainer, "rect_position:y", $HBoxContainer.rect_position.y + 3, 0.1) \
				.from($HBoxContainer.rect_position.y - 4)
		_tween.tween_property($HBoxContainer, "rect_position:y", $HBoxContainer.rect_position.y, 0.2)

extends NinePatchRect

export (NodePath) onready var desc_label = get_node(desc_label) as Control

var _hide_offset := 0.0
var _tween: SceneTreeTween
var _is_active := false
var _is_visible := true
var _init_pos: float

func _ready():
	_init_pos = rect_position.y

func _input(event: InputEvent):
	if _is_active and event.is_action_pressed("ui_scope"):
		if _is_visible: _hide_info()
		else: _show_info()
		_is_visible = not _is_visible

func activate():
	show()
	_is_active = true
	if _is_visible: _show_info()

func deactivate():
	_is_active = false
	_hide_info()

func is_visible() -> bool:
	return _is_visible

func set_offset(offset: float):
	_hide_offset = offset

func _hide_info():
	if _tween: _tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "rect_position:y", _init_pos, 0.1) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _show_info():
	if _tween: _tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "rect_position:y", _init_pos - _hide_offset, 0.1) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func update_info(text: String):
	desc_label.set_text(text)

func update_item(item: Item):
	desc_label.set_item_from_inv(item)

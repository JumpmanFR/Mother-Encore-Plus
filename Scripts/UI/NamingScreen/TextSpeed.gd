extends NinePatchRect

var _t := 0.0
var _text_speed: float = globaldata.TEXT_SPEEDS[0]
var _finished := true
onready var _dialogue_label := $VBoxContainer/Fast

func _process(delta: float):
	if !_finished and _dialogue_label != null:
		_t += delta
		if _t > _text_speed:
			_dialogue_label.visible_characters += 1
			_t = 0
		if _dialogue_label.visible_characters >= len(tr(_dialogue_label.text)):
			_finished = true
			_dialogue_label.visible_characters = len(tr(_dialogue_label.text))
			_t = 0

func _on_TextSpeedArrow_moved(dir):
	_dialogue_label.percent_visible = 1
	var cur_index: int = $TextSpeedArrow.cursor_index
	_text_speed = globaldata.TEXT_SPEEDS[cur_index]
	_dialogue_label = [$VBoxContainer/Fast, $VBoxContainer/Medium, $VBoxContainer/Slow][cur_index]
	
	if !_is_animation_worth_it():
		_dialogue_label.percent_visible = 1
		_finished = true
	else:
		_dialogue_label.percent_visible = 0
		_finished = false


func _is_animation_worth_it() -> bool:
	return len(tr($VBoxContainer/Fast.text)) > 5 \
		and len(tr($VBoxContainer/Medium.text)) > 5 \
		and len(tr($VBoxContainer/Slow.text)) > 5

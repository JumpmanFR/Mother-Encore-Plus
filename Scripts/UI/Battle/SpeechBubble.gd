extends Control

onready var _dialogue_box: PanelContainer = $PanelContainer
onready var _text_label: RichTextLabel = $PanelContainer / Speech
onready var _tail: TextureRect = $Tail
onready var _debug_box_rect: ColorRect = $DebugBoxRect
onready var _debug_text_rect: ColorRect = $DebugTextRect
onready var _cursor_down_sprite: AnimatedSprite = $CursorDown

const TEXT_SPEED := 0.03
const UP_DOWN = - 10
const MIN_WIDTH = 40
const MAX_WIDTH = 100
const PADDING = Vector2(8, 0)
const SPEED_UP_FROM_PRESS_A := 3
const SPEED_UP_FROM_PRESS_B := 1000
const AUTO_ADVANCE_DELAY := 1.25

var _t := 0.0
var _dialogue := ""
var tail_pos := Vector2.LEFT
var _measuring_text_label: RichTextLabel

var _dialog := {}
var _curr_phrase := {}
var _phrase_num := "0"
var _finished := true
var _speed_multiplier_from_input := 1
var _speed_multiplier_from_tags := 1
var _auto_advance := false
var _is_waiting_between_phrases := false

signal done

func _ready():
	_measuring_text_label = _text_label.duplicate()
	_measuring_text_label.hide()
	_measuring_text_label.fit_content_height = true
	_measuring_text_label.visible_characters = - 1
	add_child(_measuring_text_label)
	
	_dialogue_box.hide()
	set_process_input(false)
	
	set_physics_process(false)

func _physics_process(delta):
	_advance_printing(delta)

func _process(_delta):
	_debug_box_rect.rect_position = _dialogue_box.rect_position
	_debug_box_rect.rect_size = _dialogue_box.rect_size
	
	_debug_text_rect.rect_global_position = _measuring_text_label.rect_global_position
	_debug_text_rect.rect_size = _measuring_text_label.rect_size

func _advance_printing(delta):
	if !_finished:
		_t += delta
		_cursor_down_sprite.hide()
		while _t > _get_text_speed() and !_finished:
			_text_label.visible_characters += 1
			if _text_label.visible_characters > len(_get_no_br_dialog_content()):
				_finish_phrase()
			_t -= _get_text_speed()
			if $AudioStreamPlayer.stream:
				$AudioStreamPlayer.set_pitch_scale(rand_range(0.85, 1.0))
				$AudioStreamPlayer.play()
	else:
		_speed_multiplier_from_tags = 1

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		var btn_next = event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")
		var btn_cancel = event.is_action_pressed("ui_cancel")
		_action_press(btn_next, btn_cancel)
		get_tree().set_input_as_handled()
	
	if event.is_action_pressed("ui_accept"):
		var btn_next = event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")
		var btn_cancel = event.is_action_pressed("ui_cancel")
		_action_press(btn_next, btn_cancel)
		get_tree().set_input_as_handled()
	
	if event.is_action_pressed("ui_q") and OS.is_debug_build():
		start_from_scripted_dialog(YAMLParser.parse_file("res://Data/BattleScripts/fishtext.yaml"))

func _action_press(btn_next := false, btn_cancel := false):
	if !_is_waiting_between_phrases:
		if !_finished:
			if btn_cancel:
				_speed_multiplier_from_input = SPEED_UP_FROM_PRESS_B
			else:
				_speed_multiplier_from_input = SPEED_UP_FROM_PRESS_A
		elif btn_next:
			if _finished:
				_next_phrase()

func _set_text(text: String):
	_dialogue = TextTools.replace_text(text)
	_text_label.rect_position = Vector2(3, 3)
	_set_box_size()
	_text_label.bbcode_text = "[center]%s[/center]" % _dialogue
	_text_label.visible_characters = 0
	
	set_tail(tail_pos)
	_set_cursor_position()
	yield(get_tree(), "idle_frame")
	_text_label.rect_position.y += PADDING.y

func _get_text_speed() -> float:
	return TEXT_SPEED / _speed_multiplier_from_input / _speed_multiplier_from_tags

func _get_no_br_dialog_content() -> String:
	return _text_label.text.replace("\n", "")

func _handle_phrase():
	_curr_phrase = _dialog[str(_phrase_num)]
	
	_finished = false
	_speed_multiplier_from_input = 1
	_speed_multiplier_from_tags = 1
	_cursor_down_sprite.hide()
	
	if _curr_phrase.get("sound", null):
		if !_curr_phrase["sound"].begins_with("res://"):
			_curr_phrase["sound"] = "res://Audio/Sound effects/text/" + _curr_phrase["sound"]
		$AudioStreamPlayer.stream = load(_curr_phrase["sound"] + ".mp3")
	else:
		$AudioStreamPlayer.stream = null
	
	if _curr_phrase.get("text", "") != "":
		speech(_curr_phrase["text"])

func _next_phrase():
	if _curr_phrase.has("goto"):
		_phrase_num = _curr_phrase["goto"]
		_handle_phrase()
	else:
		_end_dialogue()

func _finish_phrase():
	_t = 0
	_finished = true
	if _auto_advance:
		_is_waiting_between_phrases = true
		yield(get_tree().create_timer(AUTO_ADVANCE_DELAY), "timeout")
		_is_waiting_between_phrases = false
		_next_phrase()
	else:
		_cursor_down_sprite.show()

func manual_end_dialogue():
	_end_dialogue()

func _end_dialogue():
	set_physics_process(false)
	set_process_input(false)
	_dialogue_box.hide()
	hide()
	_reset()
	emit_signal("done")

func _reset():
	_dialog = {}
	_finished = true
	_t = 0
	_phrase_num = "0"
	_curr_phrase = {}
	_text_label.bbcode_text = ""
	_speed_multiplier_from_input = 1
	_speed_multiplier_from_tags = 1
	_auto_advance = false
	_is_waiting_between_phrases = false

func speech(text: String):
	_set_text(text)
	_dialogue_box.show()
	_finished = false
	_cursor_down_sprite.hide()
	set_physics_process(true)

func start_from_string(dialog_string: String, auto_advance := false):
	yield(start_from_array([dialog_string], auto_advance), "completed")

func start_from_array(dialog_array: Array, auto_advance := false):
	var dialog := {}
	for i in dialog_array.size():
		dialog[str(i)] = {"text": dialog_array[i]}
		if i < dialog_array.size() - 1:
			dialog[str(i)]["goto"] = str(i + 1)
	yield(start_from_scripted_dialog(dialog, auto_advance), "completed")

func start_from_scripted_dialog(dialog := {}, auto_advance := false):
	_auto_advance = auto_advance
	show()
	_text_label.visible_characters = 0
	_text_label.bbcode_text = ""
	if dialog:
		_dialog = dialog
	
	set_process_input(true)
	set_physics_process(true)
	_dialogue_box.show()
	_handle_phrase()
	yield(self, "done")

func _set_box_size():
	var font = _text_label.get_font("normal_font")
	var added_width = 40 if tail_pos in [Vector2.UP, Vector2.DOWN] else 0
	
	var text_size = _get_box_width(MIN_WIDTH + added_width, MAX_WIDTH + added_width)
	var visual_lines = int(ceil(text_size.y / font.get_height()))
	
	var panel_style = _dialogue_box.get_stylebox("panel")
	var panel_margin_size = panel_style.get_minimum_size()
	
	var final_size = text_size + panel_margin_size
	final_size += Vector2(PADDING.x, PADDING.y - 1)
	_dialogue_box.rect_size = final_size

func _get_box_width(min_width, max_width) -> Vector2:
	var font = _text_label.get_font("normal_font")
	_dialogue = _add_line_breaks(_dialogue, max_width, font)
	var measure_dialogue = TextTools.strip_bbcode(_dialogue)
	_force_update_measuring_text_label(max_width, measure_dialogue)
	var size = Vector2(font.get_wordwrap_string_size(measure_dialogue, max_width).x, _measuring_text_label.rect_size.y)
	var lines = int(floor(size.y / font.get_height()))
	
	var panel_style = _dialogue_box.get_stylebox("panel")
	var panel_margin_size = panel_style.get_minimum_size()
	
	var low = min_width
	var high = max_width
	var best_width = max_width
	
	var temp_lines
	while low <= high:
		var mid = low + (high - low) / 2
		
		_force_update_measuring_text_label(mid, measure_dialogue)
		
		temp_lines = int(floor(_measuring_text_label.rect_size.y / font.get_height()))
		
		if temp_lines <= lines:
			best_width = mid
			high = mid - 1
		else:
			low = mid + 1
	
	
	
	
	
	
	_force_update_measuring_text_label(best_width, measure_dialogue)
	size = Vector2(font.get_wordwrap_string_size(measure_dialogue, best_width).x, _measuring_text_label.rect_size.y)
	return size + PADDING

func _add_line_breaks(phrase: String, max_length: int, font: Font) -> String:
	var sep := tr("WORD_SEPARATOR")
	var result := ""
	var existing_segments := phrase.split("\n")
	for segment in existing_segments:
		var words := (segment as String).split(sep)
		var result_line := ""
		if words.size() > 0:
			result_line += words[0]
			for i in range(1, words.size()):
				if font.get_string_size(TextTools.strip_bbcode(result_line + sep + words[i])).x > max_length:
					result += ("\n" if result != "" else "") + result_line
					result_line = ""
				else:
					result_line += sep
				result_line += words[i]
		if result_line != "":
			result += ("\n" if result != "" else "") + result_line
	return result

func _force_update_measuring_text_label(size, text):
	
	_measuring_text_label.rect_size.x = size
	_measuring_text_label.clear()
	_measuring_text_label.add_text(text)
	
	_measuring_text_label.minimum_size_changed()
	_measuring_text_label.rect_size = Vector2.ZERO

func set_tail(vector: Vector2):
	tail_pos = vector
	var box_size = _dialogue_box.rect_size
	match vector:
		Vector2.UP:
			_tail.rect_rotation = 90
			_tail.rect_position = Vector2.RIGHT * 6
			_dialogue_box.rect_position = Vector2( - box_size.x / 2, 10)
		
		Vector2.DOWN:
			_tail.rect_rotation = 270
			_tail.rect_position = Vector2.LEFT * 6
			_dialogue_box.rect_position = Vector2( - box_size.x / 2, - box_size.y - 10)
		
		Vector2.LEFT:
			_tail.rect_rotation = 0
			_tail.rect_position = Vector2.UP * 6
			_dialogue_box.rect_position = Vector2(10, - box_size.y / 2)
		
		Vector2.RIGHT:
			_tail.rect_rotation = 180
			_tail.rect_position = Vector2.DOWN * 6
			_dialogue_box.rect_position = Vector2( - _dialogue_box.rect_size.x + UP_DOWN, - box_size.y / 2)

func _set_cursor_position():
	var box_size = _dialogue_box.rect_size
	var box_pos = _dialogue_box.rect_position
	_cursor_down_sprite.position = (box_pos + Vector2(box_size.x - 7, box_size.y - 2)).round()

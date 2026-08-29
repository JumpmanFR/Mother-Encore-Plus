extends NinePatchRect

signal hp_scroll_done
signal pp_scroll_done

class Digit:
	var _sprite: Sprite
	var _num := 0
	var hidden_zero := false setget _set_hidden_zero
	var hidden := false setget _set_hidden
	
	func _init(sprite: Sprite, hide_zero := false):
		_sprite = sprite
		_set_hidden_zero(hide_zero)
	
	func set_value(row: int, fr := 0):
		_sprite.frame_coords.x = wrapi(fr, 0, TRANSITION_FRAMES)
		_num = wrapi(row, 0, 10)
		_sprite.frame_coords.y = _num
		_refresh_visibility()

	func is_zero():
		return _sprite.frame == 0

	func _set_hidden(value: bool):
		hidden = value
		_refresh_visibility()

	func _set_hidden_zero(value: bool):
		hidden_zero = value
		_refresh_visibility()

	func _refresh_visibility():
		_sprite.visible = !hidden and !(_sprite.frame == 0 and hidden_zero)


const TRANSITION_FRAMES := 8 #  The transition frame between digits

const PLATE_WIDTH_MENUS := 77
const PLATE_OFFSET_MENUS := -9
const PLATE_WIDTH_BATTLE := 65
const PLATE_OFFSET_BATTLE := 0

var _max_hp := 999
var _max_pp := 999

var _target_hp := 999
var _cur_hp := 999
var _dhp_frame := 0 # always between 0 and TRANSITION_FRAMES - 1

onready var _huns_digit_hp_node := $ContentBattle/Counter/HP_H
onready var _tens_digit_hp_node := $ContentBattle/Counter/HP_T
onready var _ones_digit_hp_node := $ContentBattle/Counter/HP_O

onready var _huns_digit_pp_node := $ContentBattle/Counter/PP_H
onready var _tens_digit_pp_node := $ContentBattle/Counter/PP_T
onready var _ones_digit_pp_node := $ContentBattle/Counter/PP_O

onready var _huns_digit_hp = Digit.new(_huns_digit_hp_node, true)
onready var _tens_digit_hp = Digit.new(_tens_digit_hp_node)
onready var _ones_digit_hp = Digit.new(_ones_digit_hp_node)

var _target_pp := 999
var _cur_pp := 999 setget _set_dpp
var _dpp_frame := 0 # same deal as _cur_hp

onready var _huns_digit_pp = Digit.new(_huns_digit_pp_node, true)
onready var _tens_digit_pp = Digit.new(_tens_digit_pp_node)
onready var _ones_digit_pp = Digit.new(_ones_digit_pp_node)

var _are_hp_scrolling := false
var _are_pp_scrolling := false
var _hp_timer: float = 0
var _pp_timer: float = 0
var _are_hp_increasing := false
var _are_pp_increasing := false

var _frame_time = 1.0/30.0 #LOL Division by zero oops. #Engine.target_fps
var _character: PartyMember = null

var _ailment_scroll_multiplier: = 1.0
var base_scroll_speed: = 1.0
var user_fast_mode: = false
var _init_rect_pos_y: float

var _tween: SceneTreeTween

# Called when the node enters the scene tree for the first time.
func _ready():
	$Name.text = ""
	hide_max_num()
	connect("hp_scroll_done", self, "_hide_exclamation")
	
	yield(get_tree(), "idle_frame")
	_init_rect_pos_y = rect_position.y

func set_character(character: PartyMember):
	_character = character
	$Name.text = TextTools.replace_text(_character.get_nickname())
	refresh_battle_plate()

func refresh_battle_plate(scroll := false):
	_max_hp = _character.get_stat(Character.MAXHP)
	_max_pp = _character.get_stat(Character.MAXPP)
	if scroll:
		set_target_hp(_character.get_hp())
		set_target_pp(_character.get_pp())
	else:
		set_instant_hp(_character.get_hp())
		set_instant_pp(_character.get_pp())
	refresh_ailments()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	if _are_hp_scrolling:
		_process_hp(delta)
	if _are_pp_scrolling:
		_process_pp(delta)


func set_instant_hp(value: int):
	_target_hp = int(clamp(value, 0, _max_hp))
	_cur_hp = value
	var ones = _cur_hp % 10
	var tens = int(_cur_hp / 10.0) % 10
	var huns = int(_cur_hp / 100.0) % 10 # to defeat, the _
	_ones_digit_hp.set_value(ones)
	_tens_digit_hp.set_value(tens)
	_huns_digit_hp.set_value(huns)
	_hide_leading_zeros(_huns_digit_hp, _tens_digit_hp)

func set_target_hp(value: int):
	_target_hp = int(clamp(value, 0, _max_hp))
	# hp is increasing IF current HP is BIGGER than display!
	if _target_hp == 0:
		$HPExclamation.show()
		$HPExclamation/AnimationPlayer.play("Shake")
	else:
		_hide_exclamation()
	_are_hp_increasing = _target_hp > _cur_hp
	_are_hp_scrolling = true

func set_instant_pp(value: int):
	_refresh_show_pp()
	_target_pp = int(clamp(value, 0, _max_pp))
	_cur_pp = value
	_ones_digit_pp.set_value(_cur_pp % 10)
	_tens_digit_pp.set_value((_cur_pp / 10) % 10)
	_huns_digit_pp.set_value((_cur_pp / 100) % 10)
	_hide_leading_zeros(_huns_digit_pp, _tens_digit_pp)

func set_target_pp(value: int):
	_refresh_show_pp()
	_target_pp = int(clamp(value, 0, _max_pp))
	_are_pp_increasing = _target_pp > _cur_pp
	_are_pp_scrolling = true

func _refresh_show_pp():
	_ones_digit_pp.hidden = (_max_pp == 0)
	_tens_digit_pp.hidden = (_max_pp == 0)
	_huns_digit_pp.hidden = (_max_pp == 0)
	$ContentBattle/Counter/NoPPCounterBG.visible = (_max_pp == 0)

func _set_dpp(value: int):
	_cur_pp = value
	_character.set_pp(value)

func _process_hp(delta):
	_hp_timer += delta
	var scroll_speed := _get_scroll_speed(_are_hp_increasing, false)
	
	# enough time has passed for at least a frame of scrolling
	if _hp_timer >= (_frame_time / scroll_speed):
		var frames_passed = floor(_hp_timer / (_frame_time/scroll_speed))
		_hp_timer -= frames_passed * (_frame_time/scroll_speed)
		
		for i in frames_passed:
			# check to see if we are done!
			if _dhp_frame == 0 and _target_hp == _cur_hp:
				_hp_timer = 0.0
				_are_hp_scrolling = false
				$HPExclamation.hide()
				$HPExclamation/AnimationPlayer.stop()
				set_instant_hp(_target_hp)
				emit_signal("hp_scroll_done")
				break
			
			# Update HP either up or down
			var increment := 1 if _are_hp_increasing else -1
			
			# - first, increment/decrement the _dhp_frame. We keep in within 8 frames
			#   since it takes 8 frames to transition from like, 1 to 2
			_dhp_frame += increment
			_dhp_frame = wrapi(_dhp_frame, 0, TRANSITION_FRAMES)
			
			# if we hit first frame , we change the what the display HP represents
			# its kinda like the progress of your hp, from one digit to another
			if (_are_hp_increasing and _dhp_frame == 0) or \
			   (!_are_hp_increasing and _dhp_frame == 7):
				_cur_hp += increment
			
			# process frames for each digit slot!
			# - basically, if any digit is showing a "9", it means the next digit
			#   to the left should ALSO transition
			# - e.g. If we are going from _cur_hp 9 -> 10, 
			#   The ONES place will be on frame_coords.y == 9
			#   So the TENS place will also update!
			var ones = _cur_hp % 10
			var tens = int(_cur_hp / 10.0) % 10
			var huns = int(_cur_hp / 100.0) % 10 # to defeat, the _
			
			_ones_digit_hp.set_value(ones, _dhp_frame)
			if ones == 9 or (ones == 0 and _dhp_frame == 0):
				_tens_digit_hp.set_value(tens, _dhp_frame)
				if tens == 9 or (ones == 0 and _dhp_frame == 0):
					_huns_digit_hp.set_value(huns, _dhp_frame)
			
			_hide_leading_zeros(_huns_digit_hp, _tens_digit_hp)

			refresh_menu_plate()

func _process_pp(delta):
	_pp_timer += delta
	var scroll_speed := _get_scroll_speed(_are_pp_increasing, true)
	
	if _pp_timer >= (_frame_time / scroll_speed):
		var frames_passed = floor(_pp_timer / (_frame_time/scroll_speed))
		_pp_timer -= frames_passed * (_frame_time/scroll_speed)
		
		for i in frames_passed:
			# check to see if we are done!
			if _dpp_frame == 0 and _target_pp == _cur_pp:
				_pp_timer = 0.0
				_are_pp_scrolling = false
				set_instant_pp(_target_pp)
				emit_signal("pp_scroll_done")
				break
			
			#  *uncreatively copies HP code*
			var increment := 1 if _are_pp_increasing else -1

			_dpp_frame += increment
			_dpp_frame = wrapi(_dpp_frame, 0, TRANSITION_FRAMES)
			
			if (_are_pp_increasing and _dpp_frame == 0) or \
			   (!_are_pp_increasing and _dpp_frame == 7):
				_cur_pp += increment
			
			var ones = _cur_pp % 10
			var tens = int(_cur_pp / 10.0) % 10
			var huns = int(_cur_pp / 100.0) % 10 # to defeat, the _
			
			_ones_digit_pp.set_value(ones, _dpp_frame)
			if ones == 9 or (ones == 0 and _dpp_frame == 0):
				_tens_digit_pp.set_value(tens, _dpp_frame)
				if tens == 9 or (ones == 0 and _dpp_frame == 0):
					_huns_digit_pp.set_value(huns, _dpp_frame)
						
			_hide_leading_zeros(_huns_digit_pp, _tens_digit_pp)

			refresh_menu_plate()

func _hide_leading_zeros(huns: Digit, tens: Digit):
	tens.hidden_zero = huns.is_zero()

func refresh_ailments():
	_ailment_scroll_multiplier = _character.get_combined_status_effect("hp_scroll_multiplier")
	var color_val = _character.get_combined_status_effect("info_plate_color")
	var color := Color(color_val)
	_huns_digit_hp_node.modulate = color_val
	_tens_digit_hp_node.modulate = color_val
	_ones_digit_hp_node.modulate = color_val

func _get_scroll_speed(is_increasing: bool, is_pp: bool) -> float:
	var ret := base_scroll_speed
	if !(is_pp or is_increasing):
		ret *=  _ailment_scroll_multiplier
	if user_fast_mode:
		ret *= 4
	return ret

func show_max_num():
	rect_min_size.x = PLATE_WIDTH_MENUS
	rect_size.x = PLATE_WIDTH_MENUS
	rect_position.x = PLATE_OFFSET_MENUS
	refresh_menu_plate()
	$ContentMenus.show()
	$ContentBattle.hide()
	_refresh_bg()

func hide_max_num():
	rect_min_size.x = PLATE_WIDTH_BATTLE
	rect_size.x = PLATE_WIDTH_BATTLE
	rect_position.x = PLATE_OFFSET_BATTLE
	$ContentMenus.hide()
	$ContentBattle.show()
	_refresh_bg()

func refresh_menu_plate():
	$ContentMenus/MaxHP.text = "%s / %s" % [_cur_hp, _max_hp]
	$ContentMenus/MaxPP.text = "%s / %s" %  [_cur_pp, _max_pp]
	$ContentMenus/MaxPP.visible = _max_pp > 0

func stop_scrolling():
	_are_hp_scrolling = false
	$HPExclamation.hide()
	$HPExclamation/AnimationPlayer.stop()
	set_instant_hp(_cur_hp)
	emit_signal("hp_scroll_done")
	emit_signal("pp_scroll_done")
#	set_instant_pp(_target_pp)

func _hide_exclamation():
	$HPExclamation.hide()
	$HPExclamation/AnimationPlayer.stop()

func quake(delay = 0, intensity = 1):
	var offset = 8 * intensity
	if _tween: _tween.kill()
	
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 4 shakes version
	rect_position.y = _init_rect_pos_y
	_tween.tween_property(self, "rect_position:y", _init_rect_pos_y + offset, 0.05).set_trans(Tween.TRANS_LINEAR).set_delay(delay)
	_tween.tween_property(self, "rect_position:y", _init_rect_pos_y - offset, 0.1)
	_tween.tween_property(self, "rect_position:y", _init_rect_pos_y + offset / 2, 0.1).from(_init_rect_pos_y - offset / 2)
	_tween.tween_property(self, "rect_position:y", _init_rect_pos_y - offset / 2, 0.1)
	_tween.tween_property(self, "rect_position:y", _init_rect_pos_y, 0.15)

func select(dark := false):
	if dark:
		$HighlightBlack.show()
	else:
		$Highlight.show()

func deselect():
	$Highlight.hide()
	$HighlightBlack.hide()
	$Name.add_color_override("font_color", Color.black)

func get_current_hp():
	return _cur_hp + min(_dhp_frame, 1)

func get_current_pp():
	return _cur_pp + min(_dpp_frame, 1)

func get_target_hp():
	return _target_hp

func get_target_pp():
	return _target_pp

func are_hp_scrolling():
	return _are_hp_scrolling

func are_pp_scrolling():
	return _are_pp_scrolling

func _refresh_bg():
	var content_bg_width := int(rect_size.x / 6) * 6 - 1
	for content_bg in [$ContentBattle/BG, $ContentMenus/BG]:
		content_bg.rect_size.x = content_bg_width
		content_bg.rect_position.x = (content_bg.get_parent().rect_size.x - content_bg_width) / 2



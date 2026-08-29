extends CanvasLayer

signal scroll_done

onready var _hbox = $Control/HBox
onready var _anim_player := $AnimationPlayer

var _showing := false
var _show_max_num := true

func _ready():
	_reset_party_infos()
	global.connect("party_changed", self, "_reset_party_infos")
	for plate in _hbox.get_children():
		plate.connect("hp_scroll_done", self, "_on_scroll_done")
		plate.connect("pp_scroll_done", self, "_on_scroll_done")

func _reset_party_infos():
	for i in _hbox.get_child_count():
		var plate = _hbox.get_child(i)
		if i >= global.POSSIBLE_PLAYABLE_MEMBERS.size():
			plate.hide()
			continue
		var chara = globaldata.characters.get(global.POSSIBLE_PLAYABLE_MEMBERS[i])
		plate.visible = chara in global.party
		plate.set_character(chara)
	_refresh_show_max_num()

func refresh_stats(scroll := false):
	for plate in _hbox.get_children():
		plate.refresh_battle_plate(scroll)
		plate.refresh_menu_plate()

func select_characters(char_names: Array):
	for i in _hbox.get_child_count():
		var plate_char_name: String = global.POSSIBLE_PLAYABLE_MEMBERS[i]
		if plate_char_name in char_names:
			_hbox.get_child(i).select()
		else:
			_hbox.get_child(i).deselect()

func _refresh_show_max_num():
	_hbox.add_constant_override("separation", -1 if _show_max_num else 1)
	for plate in _hbox.get_children():
		if _show_max_num:
			plate.show_max_num()
		else:
			plate.hide_max_num()

func _on_scroll_done():
	if !is_any_plate_scrolling():
		emit_signal("scroll_done")

func is_any_plate_scrolling():
	for plate in _hbox.get_children():
		if plate.visible and (plate.are_hp_scrolling() or plate.are_pp_scrolling()):
			return true
	return false

func open(value := _show_max_num):
	if !_showing:
		if value != _show_max_num:
			_show_max_num = value
			_refresh_show_max_num()
		_showing = true
		_anim_player.play("Open")
	elif _showing and value != _show_max_num:
		_anim_player.play("Close")
		yield(_anim_player, "animation_finished")
		_show_max_num = value
		_refresh_show_max_num()
		_anim_player.play("Open")

func close():
	if _showing:
		_showing = false
		_anim_player.play("Close")

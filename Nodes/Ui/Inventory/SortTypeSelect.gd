extends NinePatchRect

signal back (accept, current_action, current_character, target_character, current_item)


onready var arrow = $arrow
onready var SortTypeLabel = $SortTypeLabel

var _current_character = globaldata.characters.ninten
var _target_character = globaldata.characters.ninten
var _current_action := "give"
var _current_item: Item = null

var _active := false

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	pass

func show_confirmation_select(pos: Vector2, curr_action: String, cur_char, target_char, item: Item):
	_current_action = curr_action
	_current_item = item
	_current_character = cur_char
	_target_character = target_char
	visible = true
	_active = true
	arrow.on = true
	_on_VBoxContainer_resized()
	
func _on_arrow_cancel():
	if _active:
		visible = false
		_active = false
		arrow.on = false
		emit_signal("back", false, "back", _current_character, _target_character, _current_item)

func _on_arrow_selected(cursor_index):
	if _active:
		visible = false
		_active = false
		arrow.on = false
		if arrow.cursor_index == 0:
			emit_signal("back", true, "SortManual", _current_character, _target_character, _current_item)
		else:
			emit_signal("back", false, "SortAuto", _current_character, _target_character, _current_item)
	
func _on_VBoxContainer_resized():
	yield(get_tree(), "idle_frame")
	$MarginContainer.set_size(Vector2(0, 0))
	rect_size.x = $MarginContainer.rect_size.x
	#rect_size.y = $MarginContainer.rect_size.y
	_move_to_fit()

func _move_to_fit():
	var offscreen_part = rect_global_position.x + rect_size.x - get_viewport_rect().size.x
	if offscreen_part > 0:
		var parentMenu = find_parent("ActionSelect")
		create_tween().tween_property(parentMenu, "rect_position:x", parentMenu.rect_position.x - offscreen_part, 0.1).set_ease(Tween.EASE_IN_OUT)

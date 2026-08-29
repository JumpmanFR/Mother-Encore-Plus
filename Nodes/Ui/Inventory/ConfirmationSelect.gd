extends NinePatchRect

signal back (accept, current_action, current_character, target_character, current_item)

onready var arrow = $arrow
onready var confirmation_label = $TitleMarginContainer/ConfirmationLabel

var current_character = globaldata.characters.ninten
var target_character = globaldata.characters.ninten
var current_action := "give"
var back_action := "back"
var current_item: Item = null

var active = false

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false

func show_confirmation_select(pos: Vector2, curr_action: String, back_act: String, cur_char: PartyMember, target_char: PartyMember, item: Item):
	_move_to_fit()

	current_action = curr_action
	confirmation_label.text = "INVENTORY_ACTION_EQUIP_CONFIRM" if curr_action == "equipgive"\
	else "INVENTORY_ACTION_%s_CONFIRM" % curr_action.to_upper()
	
	current_item = item
	back_action = back_act
	current_character = cur_char
	target_character = target_char
	visible = true
	active = true
	arrow.on = true
	
func _on_arrow_cancel():
	if active:
		visible = false
		active = false
		arrow.on = false
		emit_signal("back", false, back_action, current_character, target_character, current_item)

func _on_arrow_selected(cursor_index):
	if active:
		visible = false
		active = false
		arrow.on = false
		emit_signal("back", arrow.cursor_index == 0, current_action, current_character, target_character, current_item)
		
func _on_content_resized():
	yield(get_tree(), "idle_frame")
	_bg_resize()

func _bg_resize():
	$TitleMarginContainer.set_size(Vector2(0, 0))
	var right_width = $TitleMarginContainer.rect_size.x
	rect_size.x = right_width
	$MarginContainer.set_size(Vector2(right_width, 0))
	_move_to_fit()

func _move_to_fit():
	var offscreen_part = rect_global_position.x + rect_size.x - get_viewport_rect().size.x
	if offscreen_part > 0:
		var parentMenu = find_parent("ActionSelect")
		create_tween().tween_property(parentMenu, "rect_position:x", parentMenu.rect_position.x - offscreen_part, 0.1).set_ease(Tween.EASE_IN_OUT)

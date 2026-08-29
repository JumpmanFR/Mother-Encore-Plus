extends BattleMenuBox

export (NodePath) var _info_box

const ITEM_PAGE_SIZE_X := 2
const ITEM_PAGE_SIZE_Y := 5

onready var _anim_player: AnimationPlayer = $AnimationPlayer
onready var _scrollbar: EncoreScrollBar = $Scrollbar

var _item_page_y_offset := 0
var _item_list := []

var _user: BattleParticipant

func _ready():
	_info_box = get_node_or_null(_info_box)
	cursor.connect("failed_move", self, "_box_boundary_moved")
	_scrollbar.nb_visible_rows = ITEM_PAGE_SIZE_Y
	global.connect("locale_changed", self, "_update_info_box")

func enter(reset := false, _action = null):
	.enter(reset, _action)
	_anim_player.play("Open")
	_scrollbar.on = true
	_user = action.user
	if reset:
		_item_list.clear()
		_item_list.append_array(_user.character.inv.get_items())
		cursor.set_cursor_from_index(0, false)
		_item_page_y_offset = 0
		_scrollbar.position = _item_page_y_offset
		_update_items(0)
		_update_info_box()
	if _info_box and !_item_list.empty():
		_info_box.activate()

func hide():
	if visible: _anim_player.play("Close")
	.hide()
	_scrollbar.on = false
	if _info_box: _info_box.deactivate()

func _move(dir: Vector2):
	if _item_list.size() - 1 < cursor.cursor_index + _item_page_y_offset * ITEM_PAGE_SIZE_X:
		cursor.cursor_index = _item_list.size() - _item_page_y_offset * ITEM_PAGE_SIZE_X - 1
		cursor.set_cursor_from_index(cursor.cursor_index)
	if !_item_list.empty() and dir != Vector2.ZERO:
		var item_idx = cursor.cursor_index + _item_page_y_offset * ITEM_PAGE_SIZE_X
		# if we move to skill that doesn't exist, move back
		if item_idx > _item_list.size() - 1:
			cursor.set_cursor_from_index((_item_list.size() % ITEM_PAGE_SIZE_X) - 1, false)
		_update_info_box()

func _select(idx: int):
	var i := idx + _item_page_y_offset * ITEM_PAGE_SIZE_X
	if !globaldata.does_item_exist(_item_list[i].item_name) or !_can_be_selected(_item_list[i]):
		cursor.play_sfx("restricted")
	else:
		cursor.play_sfx("cursor2")
		action.item = _item_list[i]
		action.inv_idx = i
		emit_signal("next")

func _update_items(y_offset: int):
	_item_page_y_offset = y_offset
	var items_on_page = _item_list.slice(_item_page_y_offset * ITEM_PAGE_SIZE_X, (_item_page_y_offset + ITEM_PAGE_SIZE_Y) * ITEM_PAGE_SIZE_X)
	for item_label in $GridContainer.get_children():
		if items_on_page.empty():
			item_label.text = ""
			item_label.show_equipped(false)
		else:
			var item = items_on_page.pop_front()
			item_label.text = TextTools.replace_text(item.get_data()["name"])
			item_label.set_self_modulate(Color.white if _can_be_selected(item) else Color("bfb4cd"))
			item_label.show_equipped(item.equipped)
	_move(Vector2.ZERO)
	_scrollbar.nb_rows = int(ceil(_item_list.size() / float(ITEM_PAGE_SIZE_X)))

func _box_boundary_moved(dir: Vector2):
	if dir.y != 0:
		if cursor.cursor_index + (dir.y * ITEM_PAGE_SIZE_X) < 0:
			cursor.play_sfx("cursor1")
			if _item_page_y_offset > 0:
				_update_items(_item_page_y_offset - 1)
			else:
				if _item_list.size() > ITEM_PAGE_SIZE_X * ITEM_PAGE_SIZE_Y:
					_update_items(int(ceil(_item_list.size() / float(ITEM_PAGE_SIZE_X)) - ITEM_PAGE_SIZE_Y))
				var x_pos := posmod(cursor.cursor_index, ITEM_PAGE_SIZE_X)
				var y_pos := ceil((_item_list.size() - x_pos) / float(ITEM_PAGE_SIZE_X)) - 1
				cursor.set_cursor_from_index((y_pos - _item_page_y_offset) * ITEM_PAGE_SIZE_X + x_pos, false)
		elif cursor.cursor_index + (dir.y * ITEM_PAGE_SIZE_X) >= min(ITEM_PAGE_SIZE_X * ITEM_PAGE_SIZE_Y, _item_list.size() - _item_page_y_offset * ITEM_PAGE_SIZE_X):
			cursor.play_sfx("cursor1")
			if (_item_page_y_offset + ITEM_PAGE_SIZE_Y) * ITEM_PAGE_SIZE_X < _item_list.size():
				_update_items(_item_page_y_offset + 1)
			else:
				_update_items(0)
				cursor.set_cursor_from_index(posmod(cursor.cursor_index, ITEM_PAGE_SIZE_X), false)
		_scrollbar.position = _item_page_y_offset
	if dir.x != 0:
		cursor.play_sfx("cursor1")
		var x_pos := posmod(cursor.cursor_index + dir.x, ITEM_PAGE_SIZE_X)
		var y_pos := floor(cursor.cursor_index / ITEM_PAGE_SIZE_X)
		cursor.set_cursor_from_index(y_pos * ITEM_PAGE_SIZE_X + x_pos, false)
	_update_info_box()

func _update_info_box():
	if visible and _info_box:
		if cursor.cursor_index in range(_item_list.size()):
			var item = _item_list[cursor.cursor_index + _item_page_y_offset * 2]
			if !globaldata.does_item_exist(item.item_name):
				return
			_info_box.update_item(item)
		else:
			_info_box.update_item(null)

func _can_be_selected(item: Item) -> bool:
	return item.is_battle_usable() and _user.character.can_use_item(item)

func _on_Arrow_moved(_dir: Vector2):
	_update_info_box()

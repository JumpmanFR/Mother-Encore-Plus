extends BattleMenuBox

export (NodePath) var _info_box
export (NodePath) var spMeter

const PAGE_SIZE := Vector2(2, 3)

onready var _anim_player = $AnimationPlayer
onready var scrollbar = $Scrollbar


var _page_y_offset = 0
var _skill_list = []

var _recent_choice_pagination = {}
var _recent_choice_skill = {}
var _current_chara

func _ready():
	_info_box = get_node_or_null(_info_box)
	spMeter = get_node_or_null(spMeter)
	cursor.connect("failed_move", self, "_box_boundary_moved")
	scrollbar.nb_visible_rows = PAGE_SIZE.y
	global.connect("locale_changed", self, "_update_info_box")
	$CostLabel.set_visible(true, false)

func enter(reset := false, _action = null):
	.enter(reset, _action)
	_anim_player.play("Open")
	scrollbar.on = true
	if reset:
		_skill_list.clear()
		for skill_name in action.user.character.get_usable_skills():
			var skill = globaldata.get_battle_skill(skill_name)
			if skill.has("skill_type") and skill.skill_type == "skill":
				_skill_list.append(skill)
		_current_chara = action.user.character.get_name()
		_page_y_offset = _recent_choice_pagination.get(_current_chara, 0)
		scrollbar.position = _page_y_offset
		update_skills(_page_y_offset)
		cursor.set_cursor_from_index(_recent_choice_skill.get(_current_chara, 0), false)
	if _info_box != null and !_skill_list.empty():
		_info_box.activate()

func hide():
	if visible:
		_anim_player.play("Close")
	.hide()
	scrollbar.on = false
	if _info_box != null:
		_info_box.deactivate()

func _move(_dir := Vector2.ZERO):
	if _skill_list.size() - 1 < cursor.cursor_index + _page_y_offset * PAGE_SIZE.x:
		cursor.cursor_index = _skill_list.size() - _page_y_offset * PAGE_SIZE.x - 1
		cursor.set_cursor_from_index(cursor.cursor_index)
	if !_skill_list.empty():
		var skillIdx = cursor.cursor_index + _page_y_offset * PAGE_SIZE.x
		# if we move to skill that doesn't exist, move back
		if skillIdx > _skill_list.size() - 1:
			cursor.set_cursor_from_index((int(_skill_list.size()) % int(PAGE_SIZE.x)) - 1, false)
		_recent_choice_pagination[_current_chara] = _page_y_offset
		_recent_choice_skill[_current_chara] = cursor.cursor_index
	_update_info_box()

func _select(idx: int):
	if !_skill_list.empty():
		var skill = _skill_list[idx + _page_y_offset * PAGE_SIZE.x]
		if _can_be_selected(skill):
			action.skill = skill
			emit_signal("next")

func update_skills(y_offset: float):
	_page_y_offset = y_offset
	var skills_on_page = _skill_list.slice(_page_y_offset * PAGE_SIZE.x, _page_y_offset * PAGE_SIZE.x + PAGE_SIZE.x * PAGE_SIZE.y)
	for skill_label in $GridContainer.get_children():
		if skills_on_page.empty():
			skill_label.text = ""
		else:
			var skill = skills_on_page.pop_front()
			skill_label.text = skill.name
			skill_label.set_self_modulate(Color.white if _can_be_selected(skill) else Color("bfb4cd"))
	
	_move()
	
	scrollbar.nb_rows = ceil(_skill_list.size() / float(PAGE_SIZE.x))

func _box_boundary_moved(dir: Vector2):
	if dir.y != 0:
		if cursor.cursor_index + (dir.y * PAGE_SIZE.x) < 0:
			cursor.play_sfx("cursor1")
			if _page_y_offset > 0:
				update_skills(_page_y_offset - 1)
			else:
				if _skill_list.size() > PAGE_SIZE.x * PAGE_SIZE.y:
					update_skills(ceil(_skill_list.size() / PAGE_SIZE.x) - PAGE_SIZE.y)
				var xPos = posmod(cursor.cursor_index, int(PAGE_SIZE.x))
				var yPos = ceil((_skill_list.size() - xPos) / PAGE_SIZE.x) - 1
				cursor.set_cursor_from_index((yPos - _page_y_offset) * PAGE_SIZE.x + xPos, false)
		elif cursor.cursor_index + (dir.y * PAGE_SIZE.x) >= min(PAGE_SIZE.x * PAGE_SIZE.y, _skill_list.size() - _page_y_offset * PAGE_SIZE.x):
			cursor.play_sfx("cursor1")
			if (_page_y_offset + PAGE_SIZE.y) * PAGE_SIZE.x < _skill_list.size():
				update_skills(_page_y_offset + 1)
			else:
				update_skills(0)
				cursor.set_cursor_from_index(posmod(cursor.cursor_index, int(PAGE_SIZE.x)), false)
		scrollbar.position = _page_y_offset
	if dir.x != 0:
		cursor.play_sfx("cursor1")
		var xPos = posmod(int(cursor.cursor_index + dir.x), int(PAGE_SIZE.x))
		var yPos = floor(cursor.cursor_index / PAGE_SIZE.x)
		cursor.set_cursor_from_index(yPos * PAGE_SIZE.x + xPos, false)
	_update_info_box()

func _update_info_box():
	if visible and _info_box != null:
		var skill = _skill_list[cursor.cursor_index + _page_y_offset * PAGE_SIZE.x]
		_info_box.update_info(tr(skill.description))
		_update_sp_cost(skill)

func _update_sp_cost(skill: Dictionary):
	$CostLabel.set_cost(skill.get("sp_cost", 0))

func _can_be_selected(skill: Dictionary) -> bool:
	# check if we have enough pp
	return skill.get("sp_cost", 0) <= spMeter.get_filled_bars()

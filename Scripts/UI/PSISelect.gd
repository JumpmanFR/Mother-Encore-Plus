extends NinePatchRect

const psiSkillLineTscn = preload("res://Nodes/Ui/PSISkillLine.tscn")

export(int) var linesPerPage := 3 setget _set_lines_per_page
enum PSIType {Overworld = -1, Both, Battle}
export(PSIType) var _psi_type := 1


onready var _scroll_bar = $Scrollbar

var _skills := []
var _skills_condensed := []
var _lines := []
var _active := false
var _index := 0
var page := 0
onready var cursor = $Arrow
var _cursor_to_0 := false
var user: Character

signal moved
signal selected
signal use
signal using_skill_failed

func _ready():
	_build_node_list()
	cursor.on = false
	cursor.hide()
	cursor.connect("selected", self, "_cursor_selected")
	cursor.connect("moved", self, "_cursor_moved_to_skill")
	global.connect("locale_changed", self, "_cursor_moved_to_skill", [Vector2.ZERO])

func is_empty() -> bool:
	return _skills.empty()

func _set_lines_per_page(value):
	if linesPerPage != value:
		linesPerPage = value
		_build_node_list()
		if _index >= linesPerPage:
			_update_page(+1)
			_set_line_active(_index - 1, false)
		elif page + linesPerPage > _lines.size():
			_update_page(-1)
			_set_line_active(_index + 1, false)
		else:
			_update_page(0)

func _build_node_list():
	var child_count = $MarginContainer/VBoxContainer.get_child_count()
	for i in range(child_count, linesPerPage):
		var line = psiSkillLineTscn.instance()
		_lines.append(line)
		$MarginContainer/VBoxContainer.add_child(line)
	for i in child_count:
		$MarginContainer/VBoxContainer.get_child(i).visible = (i < linesPerPage)

func set_active(active, reset = true):
	_active = active
	if _skills.size() > 0:
		cursor.visible = active
		cursor.on = active

func is_active():
	return _active

func set_PP_visible(enabled: bool, animated := true):
	$CostLabel.set_visible(enabled, animated)

func reset():
	_set_line_active(0, false)
	_on_box_sort()

func _set_line_active(i: int, play_sfx := true):
	if i >= 0 and i < linesPerPage and i < _skills_condensed.size(): # no scroll, no loop
		_index = i
	else:
		if i + page >= _skills_condensed.size(): # loop up
			i = 0
			_index = 0
			_update_page(+1)
		elif i + page < 0: # loop down
			i = int(min(_skills_condensed.size(), linesPerPage) - 1)
			_index = i
			_update_page(-1)
		elif i < 0: # scroll up (no loop)
			_update_page(-1)
		elif i >= _lines.size(): # scroll down (no loop)
			_update_page(+1)
	
	# set cursor in place
	cursor.change_parent_same_index(_lines[_index].get_hbox(), play_sfx)
	_cursor_moved_to_skill(Vector2(i, 0))

func update_skills(new_skills: Array, new_page := 0):
	#clear out skills and add new skills
	_skills.clear()
	for skill in new_skills:
		skill = globaldata.get_battle_skill(skill)
		if skill and skill.skill_type == "psi":
			match(_psi_type):
				PSIType.Overworld:
					if (skill.use_cases <= 0):
						_skills.append(skill)
				PSIType.Battle:
					if (skill.use_cases >= 0):
						_skills.append(skill)
				_:
					_skills.append(skill)
	_skills_condensed = _condense_skills()
	page = new_page
	_update_page(0)
	if is_instance_valid(_lines[_index].get_hbox()):
		_set_line_active(0, false)
		if !_lines[_index].get_hbox().get_signal_connection_list("sort_children").empty():
			_lines[_index].get_hbox().disconnect("sort_children", self, "_on_box_sort")
		_lines[_index].get_hbox().connect("sort_children", self, "_on_box_sort", [], CONNECT_ONESHOT)
#	_on_box_sort()
	_cursor_to_0 = true

func refresh_selectable():
	_update_page(0)

func set_cursor_to_skill(skill: Dictionary):
	if skill:
		for i in _skills_condensed.size():
			if skill.name == _skills_condensed[i][0].name:
				_set_line_active(i - page, false)
				for j in _skills_condensed[i].size():
					if skill.level == _skills_condensed[i][j].level:
						cursor.set_cursor_from_index(j, false)
						return
				cursor.set_cursor_from_index(0, false)
				return
		
	_set_line_active(0, false)
	cursor.set_cursor_from_index(0, false) #(cursor.cursor_index)


func _update_page(dir: int):
	page += dir

	var maxPage = _skills_condensed.size() - linesPerPage
	if maxPage <= 0:
		page = 0
	else:
		page = posmod(page, maxPage + 1)
	
	for i in linesPerPage:
		var line = _lines[i]
		if i + page >= _skills_condensed.size():
			line.hide()
		else:
			line.show()
			line.init(_skills_condensed[i + page][0], cursor)
			for skill in _skills_condensed[i + page]:
				if skill.has("level"):
					line.addLevel(skill.level, _does_it_do_anything(skill))
	
	if _scroll_bar:
		_scroll_bar.nb_rows = _skills_condensed.size()
		_scroll_bar.nb_visible_rows = linesPerPage
		_scroll_bar.position = page

func _condense_skills():
	var condensedArray = []
	# For each new KIND of skill (e.g. Lifeup), put into skillBase
	for skill in _skills:
		var newSkill = true
		# If this skill is already in, add this other level to the same array
		for skillBase in condensedArray:
			if skillBase[0].name == skill.name:
				skillBase.append(skill)
				newSkill = false
		if newSkill:
			condensedArray.append([skill])
	
	return condensedArray


func _update_pp_cost(skill: Dictionary):
	$CostLabel.set_cost(skill.get("pp_cost", 0))

func _cursor_selected(i: int):
	for skill in _skills:
		if skill.name == _lines[_index].get_skill_name() and (not "level" in skill or skill.level == _lines[_index].get_selected_level()):
			if !_does_it_do_anything(skill):
				emit_signal("using_skill_failed", skill)
				break
			if skill.target_type == BattleSystem.TargetType.SELF:
				emit_signal("use", skill)
			else:
				emit_signal("selected", skill)
			break

func _on_box_sort():
	if _cursor_to_0:
		_cursor_to_0 = false
		cursor.set_cursor_from_index(0, false)

func _does_it_do_anything(skill: Dictionary):
	
	if user and user.has_status("forgetful"):
		return false
	
	# check if we have enough pp
	elif user and skill.get("pp_cost", 0) <= user.get_pp():
		return true
	else:
		return false

func _cursor_moved_to_skill(dir := Vector2.ZERO):
	var skill_name = _lines[_index].get_skill_name()
	var skill_level = _lines[_index].get_selected_level()
	for skill in _skills:
		if skill.name == skill_name and\
		(not "level" in skill or skill.level == skill_level):
			_update_pp_cost(skill)
			emit_signal("moved", skill)
			break


func _on_Arrow_failed_move(dir: Vector2):
	if _active:
		if dir.y > 0:
			_set_line_active(_index + 1)
		elif dir.y < 0:
			_set_line_active(_index - 1)

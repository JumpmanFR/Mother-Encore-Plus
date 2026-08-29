extends BattleMenuBox

export (NodePath) var _info_box

const CAT_OFFENSE = "Offense"
const CAT_RECOVERY = "Recovery"
const CAT_ASSIST = "Assist"
const CATEGORIES = [CAT_OFFENSE, CAT_RECOVERY, CAT_ASSIST]

const _skill_list = {
	CAT_OFFENSE: [],
	CAT_RECOVERY: [],
	CAT_ASSIST: []
}

onready var _anim_player = $AnimationPlayer

var _recent_choice_cat = {}
var _recent_choice_pagination = {}
var _recent_choice_psi = {}
var _current_chara

func _ready():
	_info_box = get_node_or_null(_info_box)
	$PSISelect.connect("selected", self, "_select_skill")
	$PSISelect.connect("moved", self, "_on_cursor_moved_to_psi")
	$VBox.connect("sort_children", self, "_on_vbox_sort")

func _input(event: InputEvent):
	if visible and $PSISelect.is_active():
		if event.is_action_pressed("ui_cancel"):
			Input.action_release("ui_cancel")
			get_tree().set_input_as_handled()
			audioManager.play_sfx_by_name("back", "BattleSfx")
			
			$PSISelect.set_active(false)
			$PSISelect.set_PP_visible(false)
			cursor.on = true
			if _info_box != null:
				_info_box.deactivate()

func enter(reset := false, _action = null):
	.enter(reset, _action)
	_anim_player.play("Open")
	if reset:
		# set user here so psi select knows when the user doesn't have enough pp
		$PSISelect.user = action.user.character
		_current_chara = action.user.character.get_name()
		_update_psi(action.user.character.get_learned_skills())
				
		#Default on Recovery first for quick access to Lifeup (YOU'RE WELCOME)
		var cur_idx = 0
		if _recent_choice_cat.has(_current_chara):
			cur_idx = _recent_choice_cat[_current_chara]
		else:
			for i in [CAT_RECOVERY, CAT_OFFENSE, CAT_ASSIST]:
				if _skill_list[i].size() > 0:
					cur_idx = CATEGORIES.find(i)
					break

		cursor.set_cursor_from_index(cur_idx, false)
		
		_update_skills_box()
		$PSISelect.set_active(false)
		$PSISelect.set_PP_visible(false, false)
		if _info_box != null:
			_info_box.deactivate()

		yield(_anim_player, "animation_finished")

	else:
		$PSISelect.set_active(true, false)
		$PSISelect.set_PP_visible(true)
		_info_box.activate()
		cursor.on = false

func exit():
	.exit()
	$PSISelect.reset()

func hide():
	if visible:
		_anim_player.play("Close")
	.hide()
	if _info_box != null:
		_info_box.deactivate()
		#_info_box.hide()

func _move(_dir := Vector2.ZERO):
	_recent_choice_cat[_current_chara] = cursor.cursor_index
	_update_skills_box()

func _on_vbox_sort():
	
	cursor.set_cursor_from_index(cursor.cursor_index, false)

func _select(idx: int):
	# first, check if there's even a skill here lmao
	if _skill_list[CATEGORIES[cursor.cursor_index]].empty():
		return
	cursor.on = false
	if _recent_choice_psi.has(_current_chara) and _recent_choice_psi[_current_chara].psi_category == CATEGORIES[cursor.cursor_index]:
		$PSISelect.set_cursor_to_skill(_recent_choice_psi[_current_chara])
	else:
		$PSISelect.set_cursor_to_skill({})
	
	$PSISelect.set_active(true, false)
	$PSISelect.set_PP_visible(true)
	if _info_box != null:
		_info_box.activate()

func _update_psi(skills: Array):
	#clear skills
	for i in _skill_list: _skill_list[i].clear()
	for skill_name in skills:
		var skill = globaldata.get_battle_skill(skill_name)
		if skill.has("psi_category"):
			if skill.use_cases > -1: # -1 is field only
				_skill_list[skill.psi_category].append(skill_name)
	for i in $VBox.get_child_count():
		if _skill_list[CATEGORIES[i]].empty():
			$VBox.get_child(i).hide()
		else:
			$VBox.get_child(i).show()

func _update_skills_box():
	var psi_select_page = 0
	if _recent_choice_pagination.has(_current_chara) and _recent_choice_psi[_current_chara].psi_category == CATEGORIES[cursor.cursor_index]:
		psi_select_page = _recent_choice_pagination[_current_chara]
	var category = CATEGORIES[cursor.cursor_index]
	$PSISelect.update_skills(_skill_list[category], psi_select_page)

func _select_skill(skill: Dictionary):
	$PSISelect.set_active(false, false)
	$PSISelect.set_PP_visible(false)
	if _info_box != null:
		_info_box.deactivate()
	action.skill = skill
	emit_signal("next")

func _on_cursor_moved_to_psi(skill: Dictionary):
	if $PSISelect.is_active():
		_recent_choice_pagination[_current_chara] = $PSISelect.page
		_recent_choice_psi[_current_chara] = skill
	if _info_box:
		var category = CATEGORIES[cursor.cursor_index]
		_info_box.update_info(tr(skill.description))

# useless?
#func _on_Arrow_moved_direction(dir):
#	_move(dir)

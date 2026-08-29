extends BattleMenuBox

export (NodePath) var _name_box

const ACTION_BASIC := "Basic"
const ACTION_SKILLS := "Skills"
const ACTION_PSI := "PSI"
const ACTION_ITEMS := "Items"
const ACTION_DEFEND := "Defend"
const ACTION_RUN := "Run"

const _actions := [ACTION_BASIC, ACTION_SKILLS, ACTION_PSI, ACTION_ITEMS, ACTION_DEFEND, ACTION_RUN]
var _active_actions := [ACTION_BASIC, "", "", ACTION_ITEMS, ACTION_DEFEND, ""]
var _basic_action: Dictionary = globaldata.get_battle_skill("attack")
var _skill_action_name := ""
onready var _icons = $ActionIcons.get_children()

func _ready():
	_name_box = get_node_or_null(_name_box)

func enter(reset := false, _action = null):
	.enter(reset, _action)
	if reset:
		var i = 0
		for a in _active_actions:
			if a: break
			i += 1
		cursor.set_cursor_from_index(i, false)
	if _name_box: _name_box.show()
	_update_name_box()

func hide():
	.hide()
	cursor.on = false
	if _name_box != null:
		_name_box.hide()

func _move(dir: Vector2):
	var original = cursor.cursor_index
	var i = original
	# try to the right
	while _active_actions[i] == "":
		if dir.x > 0:
			if i == _actions.size() - 1:
				print("Outta bounds! wtf")
				i = 0
			else:
				i += 1
		# try to the left
		elif dir.x < 0:
			if i == 0:
				print("Outta bounds again! wtf")
				i = _active_actions.size() - 1
			else:
				i -= 1
	
	if i != original:
		cursor.set_cursor_from_index(i)
	_update_name_box()

func _select(i: int):
	emit_signal("next", _actions[i])

func _add_action(action: String):
	var idx = _actions.find(action)
	if idx > - 1:
		_active_actions[idx] = action
		_icons[idx].show()
		_icons[idx].modulate = Color.white
	else:
		print("Added Action %s doesn't exist :(" % action)

func _reset_actions():
	for icon in _icons:
		icon.hide()
	for i in range(_active_actions.size()):
		_active_actions[i] = ""
	for action in [ACTION_BASIC, ACTION_DEFEND, ACTION_ITEMS]:
		_add_action(action)

func _add_unselectable_actions(new_actions: Array):
	for action in new_actions:
		var idx = _actions.find(action)
		if idx > - 1:
			_active_actions[idx] = ""
			_icons[idx].modulate = Color.darkgray

func set_actions_for_user(bp: BattleParticipant, with_run: bool):
	_reset_actions()
	
	if bp:
		var pm := bp.character
		_basic_action = globaldata.get_battle_skill(pm.get_basic_skill())
		_skill_action_name = "BATTLE_ACTION_SKILLS_%s" % pm.get_id().to_upper()
		
		if !pm.get_usable_skills("skill").empty():
			_add_action(ACTION_SKILLS)
		
		if !pm.get_usable_skills("psi").empty():
			_add_action(ACTION_PSI)
		
		_add_unselectable_actions(bp.get_combined_status_effect("cant_select").keys())
		
		if with_run:
			_add_action(ACTION_RUN)
	
	cursor.set_cursor_from_index(0)
	
	_update_name_box()

func _update_name_box():
	var action_id = _active_actions[cursor.cursor_index]
	if _name_box:
		match action_id:
			ACTION_BASIC:
				_name_box.get_child(0).text = _basic_action.name
			ACTION_SKILLS:
				_name_box.get_child(0).text = _skill_action_name
			_:
				_name_box.get_child(0).text = "BATTLE_ACTION_%s" % action_id.to_upper()

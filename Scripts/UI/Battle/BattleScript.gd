const CUSTOM_FUNCS = ["_on_hit_call", "_on_choose_action_call", "_on_encore_call"]
const CUSTOM_FUNCS_PARAMS = ["_on_hit_params", "_on_choose_action_params", "_on_encore_params"]
const CUSTOM_VARS = ["on_hit", "on_choose_action", "on_encore"]

var _turns_count := - 1
var _enemy
var _party = []
var _enemy_party := []
var _handler = ECSHandler.new()

var _on_hit_call: FuncRef
var _on_hit_params: Array
var _on_choose_action_call: FuncRef
var _on_choose_action_params: Array
var _on_encore_call: FuncRef
var _on_encore_params: Array

signal check_script
signal do_skill(bp, skill_name, overwrite_skill)
signal turn

func _init(enemy, yaml_file: String, battle_obj):
	_enemy = enemy
	_set_cutscene(yaml_file)
	_set_start_label()
	
	connect("check_script", self, "_on_check_script")
	_enemy.connect("bp_hit", self, "_on_hit")
	_enemy.connect("action_choice", self, "_on_choose_action")
	
	battle_obj.connect("round_done", self, "set_turns_count")
	battle_obj.connect("enemy_party_changed", self, "set_enemy_party")
	battle_obj.connect("party_changed", self, "set_party")
	battle_obj.connect("encore_activated", self, "_on_encore")
	connect("do_skill", battle_obj, "add_action")
	
	_handler.set_custom_command_func(funcref(self, "_handle_battle_command"))
	_handler.handle_current_block()

func _set_cutscene(yaml_file: String):
	_handler.set_script(ECSInterpreter.get_ecscript("BattleScripts/%s" % yaml_file))
	for i in CUSTOM_VARS.size():
		if _handler.get_script().variables.has(CUSTOM_VARS[i]):
			var variable = _handler.get_script().variables[CUSTOM_VARS[i]]
			if variable is ECSClasses.ScriptCommand:
				set(CUSTOM_FUNCS[i], funcref(_handler, "handle_command"))
				set(CUSTOM_FUNCS_PARAMS[i], [variable])
			else:
				set(CUSTOM_FUNCS[i], funcref(_handler, "handle_block"))
				set(CUSTOM_FUNCS_PARAMS[i], [_handler.get_script().get_label(variable)])
			
	if _handler.get_script().variables.has("on_hit"):
		var variable = _handler.get_script().variables["on_hit"]
		if variable is ECSClasses.ScriptCommand:
			_on_hit_call = funcref(_handler, "handle_command")
			_on_hit_params = [variable]
		else:
			_on_hit_call = funcref(_handler, "handle_block")
			_on_hit_params = [_handler.get_script().get_label(variable)]
	
	if _handler.get_script().variables.has("on_choose_action"):
		var variable = _handler.get_script().variables["on_choose_action"]
		if variable is ECSClasses.ScriptCommand:
			_on_choose_action_call = funcref(_handler, "handle_command")
			_on_choose_action_params = [variable]
		else:
			_on_choose_action_call = funcref(_handler, "handle_block")
			_on_choose_action_params = [_handler.get_script().get_label(variable)]
		

func _set_start_label():
	var labels = _handler.get_script().labels
	if labels.has("start"):
		_handler.get_script().cur_block = "start"
	else:
		_handler.get_script().cur_block = labels.keys()[0]

func set_turns_count(value: int):
	_turns_count = value
	emit_signal("turn")

func set_party(party: Array):
	_party = party

func set_enemy_party(enemy_party: Array):
	_enemy_party = enemy_party

func _handle_battle_command(command: ECSClasses.ScriptCommand):
	match command.command_name:
		"get_enemy":
			var enemy = command.args[0]
			for i in _enemy_party:
				if i.get_character().get_id() == enemy:
					return i
			return null
		"get_enemy_count":
			return _enemy_party.size()
		"get_party_count":
			return _party.size()
		"changephase":
			pass
		"die":
			_enemy.defeat()
		"get_script_bp":
			return _enemy
		"wait_turns":
			for i in range(command.args[0]):
				yield(self, "turn")
















func _on_check_script():
	_handler.emit_signal("check_script")

func _on_hit():
	if _on_hit_call: _on_hit_call.call_funcv(_on_hit_params)

func _on_choose_action():
	if _on_choose_action_call: _on_choose_action_call.call_funcv(_on_choose_action_params)

func _on_encore():
	if _on_encore_call: _on_encore_call.call_funcv(_on_encore_params)

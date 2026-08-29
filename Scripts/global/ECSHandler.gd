extends Node
class_name ECSHandler

var _goto_label := ""
var _script: ECSClasses.ScriptFile

var _command_func: FuncRef
var _text_func: FuncRef

enum ScriptType{CUTSCENE, BATTLE_SCRIPT}

signal label_finished
signal check_script

func _init(give_script: ECSClasses.ScriptFile = null):
	if give_script:
		_script = give_script
	connect("label_finished", self, "_handle_label_finished")

func set_script(value):
	_script = value

func get_script() -> ECSClasses.ScriptFile:
	return _script

func set_custom_command_func(com_func: FuncRef):
	_command_func = com_func

func should_yield(result) -> bool:
	return result is GDScriptFunctionState

func handle_current_block():
	handle_block(_script.get_label(_script.cur_block))

func handle_block(block: Array):
	for part in block:
		if part is ECSClasses.ScriptConditional:
			if handle_cond(part.condition):
				var result = handle_block(part.then_block)
				if should_yield(result): yield(result, "completed")
			elif part.else_block != null:
				var result = handle_block(part.else_block)
				if should_yield(result): yield(result, "completed")
		
		elif part is ECSClasses.ScriptAssignment:
			var result = handle_assignment(part)
			if should_yield(result): yield(result, "completed")

		elif part is ECSClasses.ScriptYield:
			while true:
				var cond_result = handle_cond(part.condition)
				if should_yield(cond_result): cond_result = yield(cond_result, "completed")
				if cond_result: break
				yield(self, "check_script")
		
		elif part is ECSClasses.ScriptText:
			_text_func.call_func(part)

		elif part is ECSClasses.ScriptReturn:
			return _retrieve_var(part.value)

		elif part is ECSClasses.ScriptCommand:
			var command = part.command_name
			match command:
				"goto":
					_goto_label = part.args[0]
					break
				"call":
					var result = handle_block(_script.get_label(part.args[0]))
					if should_yield(result): yield(result, "completed")
				_:
					var result = handle_command(part)
					if should_yield(result):
						result = yield(result, "completed")
	
	if block == _script.get_label(_script.cur_block) or _goto_label != "":
		emit_signal("label_finished")

func handle_assignment(assignment: ECSClasses.ScriptAssignment):
	var result = _retrieve_var(assignment.variable)
	if should_yield(result): result = yield(result, "completed")
	var variable = result
	
	result = _retrieve_var(assignment.value)
	if should_yield(result): result = yield(result, "completed")
	var value = result
	
	var new_value = value
	match assignment.operation:
		"+", "+=":
			new_value = variable + value
		"-", "-=":
			new_value = variable - value
		"*", "*=":
			new_value = variable * value
		"/", "/=":
			new_value = variable / value
		"%", "%=":
			new_value = variable % value
		_:
			pass
	if "=" in assignment.operation:
		ECSInterpreter.set_variable(assignment.variable, new_value, _script)
	return new_value


func handle_cond(cond: ECSClasses.ScriptComparation) -> bool:
	var result := false

	var r = _retrieve_var(cond.left_op)
	if should_yield(r): r = yield(r, "completed")
	var left_op = r

	r = _retrieve_var(cond.left_op)
	if should_yield(r): r = yield(r, "completed")
	var right_op = _retrieve_var(cond.right_op)

	match cond.operator:
		"<":
			if left_op < right_op:
				result = true
		"<=":
			if left_op <= right_op:
				result = true
		">=":
			if left_op >= right_op:
				result = true
		"==":
			if left_op == right_op:
				result = true
		"!=":
			if left_op != right_op:
				result = true
	return result

func handle_command(command: ECSClasses.ScriptCommand):
	var try = ECSInterpreter.get_command(command.command_name, _script)
	if try is ECSClasses.ScriptCommandDefinition:
		var result = handle_custom_command(try, command.args)
		if should_yield(result): return yield(result, "completed")
		return result
	
	command.command_name = ECSInterpreter.get_command(command.command_name, _script)
	match command.command_name:
		"breakpoint":
			breakpoint
		"flag":
			return globaldata.flags.has(command.args[0]) and globaldata.flags[command.args[0]]
		"print":
			print("ECScript Print: " + str(_retrieve_var(command.args[0])))
		"random_chance":
			var chance = _retrieve_var(command.args[0])
			if should_yield(chance): chance = yield(chance, "completed")
			return randi() % 100 + 1 < chance
		"str":
			var result = _retrieve_var(command.args[0])
			if should_yield(result): result = yield(result, "completed")
			return str(result)
		"toggle":
			var flag = _retrieve_var(command.args[0])
			if should_yield(flag): flag = yield(flag, "completed")
			
			ECSInterpreter.set_variable(command.args[0], not flag, _script)
		_:
			if command.is_nested():
				var result = _handle_nested(command)
				if should_yield(result): return yield(result, "completed")
				return result
	
	var result = _command_func.call_func(command)
	if should_yield(result): return yield(result, "completed")
	return result

func handle_custom_command(command: ECSClasses.ScriptCommandDefinition, args: Array):
	var block = command.get_replaced_block(args)
	var result = handle_block(block)
	if should_yield(result): return yield(result, "completed")
	return result

func _retrieve_text(path: String) -> Dictionary:
	return YAMLParser.parse_file("res://Data/BattleScripts/%s.yaml" % path)

func _retrieve_var(variable):
	if variable is ECSClasses.ScriptCommand:
		var result = handle_command(variable)
		if should_yield(result): return yield(result, "completed")
		return result
	elif variable is ECSClasses.ScriptAssignment:
		var result = handle_assignment(variable)
		if should_yield(result): return yield(result, "completed")
		return result
	elif variable is ECSClasses.ScriptComparation:
		var result = handle_cond(variable)
		if should_yield(result): return yield(result, "completed")
		return result

	match variable:
		_:
			pass
		
		
	if variable is String:
		if "." in variable:
			var result = _handle_nested(variable)
			if should_yield(result): result = yield(result, "completed")
			return result
		else:
			return ECSInterpreter.get_variable(variable, _script)
	return variable

func _handle_label_finished():
	if _goto_label != "":
		_script.cur_block = _goto_label
		_goto_label = ""
		handle_current_block()

func _handle_nested(val):
	var variable
	var is_method = false
	
	if val is ECSClasses.ScriptCommand:
		variable = val.command_name
		is_method = true
	else:
		variable = val
	
	var parts = variable.split(".")
	var current = _retrieve_var(parts[0])
	if should_yield(current): current = yield(current, "completed")
	
	if !current: return null
	
	for i in range(1, parts.size() - 1):
		var part = parts[i]
		if current is Object:
			current = current.get(part)
		elif current is Dictionary and current.has(part):
			current = current[part]
		else:
			return null
	
	var final_member = parts[ - 1]
	if is_method:
		var args = []
		for arg in val.args:
			var value = _retrieve_var(arg)
			if should_yield(value): value = yield(value, "completed")
			args.append(value)
		
		if current is Object and current.has_method(final_member):
			var result
			if args.empty():
				result = current.call(final_member)
			else:
				result = current.callv(final_member, args)
			if should_yield(result): return yield(result, "completed")
			return result
		else:
			return null
	else:
		if current is Object:
			return current.get(final_member)
		elif current is Dictionary and current.has(final_member):
			return current[final_member]
		else:
			return null

extends Node
class_name ECSClasses

class ScriptFile:
	var labels = {}
	var variables = {}
	var commands = {}

	var cur_block

	func file_to_dict() -> Dictionary:
		var dict := {}
		
		if labels: dict["labels"] = {}
		for label_name in labels:
			dict["labels"][label_name] = []
			for line in labels[label_name]:
				dict["labels"][label_name].append(line.to_dict())
		
		if variables: dict["variables"] = {}
		for v in variables:
			if variables[v] is Object:
				dict["variables"][v] = variables[v].to_dict()
			else:
				dict["variables"][v] = variables[v]
		
		if commands: dict["commands"] = {}
		for command_name in commands:
			dict["commands"][command_name] = commands[command_name].to_dict()
		
		return dict
	
	func get_variable(var_name: String):
		return variables.get(var_name)
	
	func has_variable(var_name: String) -> bool:
		return variables.has(var_name)

	func set_variable(var_name: String, value):
		variables[var_name] = value

	func get_label(label_name: String) -> Array:
		return labels.get(label_name)

	func get_label_name(label: Array) -> String:
		for i in labels:
			if get_label(i) == label:
				return i
		return ""

	func get_command(command_name: String) -> ScriptCommandDefinition:
		return commands.get(command_name)
		
	func get_location(resource_path := false) -> String:
		var result := _iterate(ECSInterpreter.modules, "")
		result = result.trim_prefix("/")
		if resource_path:
			result = "res://Data/%s.ecs" % result
		return result

	func _iterate(dict: Dictionary, path: String) -> String:
		for key in dict:
			var new_path = path + "/" + str(key)

			if dict[key] is Dictionary:
				var found = _iterate(dict[key], new_path)
				if found != "":
					return found
			
			elif dict[key] == self:
				return new_path

		return ""
	
	func reset():
		var new_self = ECSInterpreter.parse_file(get_location(true))
		labels = new_self.labels
		variables = new_self.variables
		commands = new_self.commands
		cur_block = null

class ScriptCommandDefinition:
	var args := []
	var lines := []
	
	func to_dict() -> Dictionary:
		var dict = {}
		if args:
			dict["args"] = args.duplicate()
		dict["lines"] = []
		for line in lines:
			dict["lines"].append(line.to_dict())
		return dict
	
	func get_replaced_block(replace_args := []) -> Array:
		var new_lines = lines.duplicate(true)
		var new_args = {}
		for i in range(args.size()):
			new_args[args[i]] = replace_args[i]
		
		for line in new_lines:
			line.replace_args(new_args)
		return new_lines

class ScriptLine:
	var parent_script = ECSInterpreter.parser.current_script
	
	func get_script_file() -> ScriptFile:
		return parent_script

class ScriptCommand extends ScriptLine:
	var command_name: String
	var args := []
	
	func to_dict() -> Dictionary:
		var dict = {}
		dict["type"] = "command"
		dict["name"] = command_name
		if args:
			dict["args"] = []
			for arg in args:
				if arg is ScriptLine:
					dict["args"].append(arg.to_dict())
				else:
					dict["args"].append(str(arg))
		return dict
	
	func to_string() -> String:
		var result = command_name + "("
		for i in range(args.size()):
			if args[i] is ScriptLine:
				result += args[i].to_string()
			else:
				result += str(args[i])
			if i < args.size() - 1:
				result += ", "
		result += ")"
		return result
	
	func get_nested_command() -> PoolStringArray:
		return command_name.split(".")
	
	func is_nested() -> bool:
		return get_nested_command().size() > 1
	
	func replace_args(new_args := {}):
		for i in range(args.size()):
			if new_args.has(args[i]):
				args[i] = new_args[args[i]]
		

class ScriptText extends ScriptLine:
	var value: String
	
	func to_dict() -> Dictionary:
		var dict = {}
		dict["type"] = "text"
		dict["value"] = value
		return dict
	
	func to_string() -> String:
		return "\"" + value + "\""

class ScriptConditional extends ScriptLine:
	var condition: ScriptComparation
	var then_block: Array
	var else_block: Array
	
	func to_dict() -> Dictionary:
		var dict = {}
		dict["type"] = "if"
		dict["condition"] = condition.to_dict()
		dict["then"] = []
		for line in then_block:
			dict["then"].append(line.to_dict())
		if else_block:
			dict["else"] = []
			for line in else_block:
				dict["else"].append(line.to_dict())
		return dict
	
	func to_string() -> String:
		var result = "if " + condition.to_string() + " {\n"
		for line in then_block:
			result += "\t" + line.to_string() + "\n"
		result += "}"
		if else_block:
			result += " else {\n"
			for line in else_block:
				result += "\t" + line.to_string() + "\n"
			result += "}"
		return result
	
	func replace_args(new_args := {}):
		condition.replace_args(new_args)
		for line in then_block + else_block:
			if line.has_method("replace_args"):
				line.replace_args(new_args)

class ScriptAssignment extends ScriptLine:
	var variable
	var operation: String
	var value
	
	func to_dict() -> Dictionary:
		var dict = {}
		dict["type"] = "assignment"
		dict["var"] = variable
		dict["operation"] = operation
		if value is ScriptCommand:
			dict["value"] = value.to_dict()
		else:
			dict["value"] = str(value)
		return dict
	
	func to_string() -> String:
		var result = ""
		if variable is ScriptLine:
			result += variable.to_string()
		else:
			result += str(variable)
		result += " " + operation + " "
		if value is ScriptLine:
			result += value.to_string()
		else:
			result += str(value)
		return result
	
	func replace_args(new_args := {}):
		if variable is ScriptLine and variable.has_method("replace_args"):
			variable.replace_args(new_args)
		if value is ScriptLine and value.has_method("replace_args"):
			value.replace_args(new_args)

class ScriptYield extends ScriptLine:
	var condition: ScriptComparation

	func to_dict() -> Dictionary:
		var dict = {}
		dict["type"] = "yield"
		dict["condition"] = condition.to_dict()
		return dict
	
	func to_string() -> String:
		return "yield " + condition.to_string()
	
	func replace_args(new_args := {}):
		condition.replace_args(new_args)

class ScriptReturn extends ScriptLine:
	var value
	
	func to_dict() -> Dictionary:
		var dict = {}
		dict["type"] = "return"
		dict["value"] = value.to_dict() if value is ScriptLine else value
		return dict
	
	func to_string() -> String:
		if value is ScriptLine:
			return "return " + value.to_string()
		else:
			return "return " + str(value)
	
	func replace_args(new_args := {}):
		if value is ScriptLine and value.has_method("replace_args"):
			value.replace_args(new_args)

class ScriptComparation extends ScriptLine:
	var left_op
	var operator: String
	var right_op

	func to_dict() -> Dictionary:
		var dict = {}
		dict["left_op"] = ""
		if left_op is ScriptCommand:
			dict["left_op"] = left_op.to_dict()
		else:
			dict["left_op"] = str(left_op)
		dict["operator"] = operator
		dict["right_op"] = ""
		if right_op is ScriptCommand:
			dict["right_op"] = right_op.to_dict()
		else:
			dict["right_op"] = str(right_op)
		return dict
	
	func to_string() -> String:
		var result = ""
		if left_op is ScriptLine:
			result += left_op.to_string()
		else:
			result += str(left_op)
		result += " " + operator + " "
		if right_op is ScriptLine:
			result += right_op.to_string()
		else:
			result += str(right_op)
		return result
	
	func replace_args(new_args := {}):
		if left_op is ScriptLine and left_op.has_method("replace_args"):
			left_op.replace_args(new_args)
		if right_op is ScriptLine and right_op.has_method("replace_args"):
			right_op.replace_args(new_args)

class ScriptMenu extends ScriptLine:
	var columns: int
	var default_option: int
	var options: Dictionary

	func to_dict() -> Dictionary:
		var dict = {}
		dict["type"] = "menu"
		dict["columns"] = columns
		dict["default"] = default_option
		dict["options"] = {}
		for option_text in options.keys():
			dict["options"][option_text] = []
			for line in options[option_text]:
				dict["options"][option_text].append(line.to_dict())
		return dict
	
	func to_string() -> String:
		var result = "menu " + str(columns) + " {\n"
		for option_text in options.keys():
			result += "\t\"" + option_text + "\": {\n"
			for line in options[option_text]:
				result += "\t\t" + line.to_string() + "\n"
			result += "\t}\n"
		result += "}"
		return result
	
	func replace_args(new_args := {}):
		for opt in options:
			for line in options[opt]:
				if line.has_method("replace_args"):
					line.replace_args(new_args)

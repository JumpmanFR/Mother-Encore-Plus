extends Node

class ScriptTokenizer:
	enum TokenType{
		IDENTIFIER, 
		NUMBER, 
		STRING, 
		BOOLEAN, 
		NULL, 
		
		DOT, 
		COMMA, 
		COLON, 
		PAREN_OPEN, 
		PAREN_CLOSE, 
		
		DEFINE, 
		COMMAND_DEF, 
		IF, 
		ELSE, 
		RETURN, 
		YIELD, 
		MENU, 
		DEFAULT, 
		
		INDENT, 
		DEDENT, 
		NEWLINE, 
		EOF, 
		COMPARATOR, 
		MATH_OPERATOR, 
		ASSIGNMENT, 
		NEGATION
	}
	
	const KEYWORDS = {
	"define": TokenType.DEFINE, 
	"command": TokenType.COMMAND_DEF, 
	"if": TokenType.IF, 
	"else": TokenType.ELSE, 
	"return": TokenType.RETURN, 
	"yield": TokenType.YIELD, 
	"menu": TokenType.MENU, 
	"default": TokenType.DEFAULT, 
	"true": TokenType.BOOLEAN, 
	"false": TokenType.BOOLEAN, 
	"null": TokenType.NULL}
	
	const PUNCTUATIONS = {
		".": TokenType.DOT, 
		",": TokenType.COMMA, 
		":": TokenType.COLON, 
		"(": TokenType.PAREN_OPEN, 
		")": TokenType.PAREN_CLOSE}
	
	const NEGATION_OPERATORS = ["!", "not"]
	const MATH_OPERATORS = ["+", "-", "*", "/", "%"]
	const COMPARATORS = ["==", "!=", "<=", ">=", "<", ">"]
	const ASSIGNERS = ["=", "+=", "-=", "*=", "/=", "%=", "++", "--"]

	const CANT_BE_ALONE_TOKENS = [TokenType.NEWLINE, TokenType.INDENT, TokenType.DEDENT, TokenType.EOF]
	
	var indent = 0
	
	class Token:
		var type: int
		var value
		
		func _init(t_type: int, t_value = null):
			type = t_type
			value = t_value
		
		func to_string() -> String:
			return "%s, '%s'" % [TokenType.keys()[type], str(value)]
	
	func _get_indent_level(line: String) -> int:
		var count = 0
		for character in line:
			if character == "\t":
				count += 1
			else: break
		return count
	
	func tokenize_line(line: String):
		var regex = RegEx.new()
		regex.compile("^\\w+")
		var tokens = []
		var i = 0
		var current_indent = _get_indent_level(line)
		if current_indent > indent:
			while current_indent > indent:
				tokens.append(Token.new(TokenType.INDENT))
				indent += 1
		
		elif current_indent < indent:
			while current_indent < indent:
				tokens.append(Token.new(TokenType.DEDENT))
				indent -= 1
		
		line = line.strip_edges()
		while i < line.length():
			var character = line[i]
			
			
			if character == "\"":
				i += 1
				var string = ""
				while i < line.length() and line[i] != "\"":
					string += line[i]
					i += 1
				if i < line.length():
					i += 1
				
				tokens.append(Token.new(TokenType.STRING, string))
				continue
			
			
			if character == " ":
				i += 1
				continue
			
			
			if i + 1 < line.length():
				var two = line.substr(i, 2)
				if two in COMPARATORS:
					tokens.append(Token.new(TokenType.COMPARATOR, two))
					i += 2
					continue
				elif two in ASSIGNERS:
					tokens.append(Token.new(TokenType.ASSIGNMENT, two))
					i += 2
					continue
			
			
			if character.is_valid_integer():
				var number = ""
				
				while i < line.length() and line[i].is_valid_integer():
					number += line[i]
					i += 1
				
				
				if i < line.length() and line[i] == ".":
					if i + 1 < line.length() and line[i + 1].is_valid_integer():
						number += "."
						i += 1
						while i < line.length() and line[i].is_valid_integer():
							number += line[i]
							i += 1
				
				if "." in number:
					tokens.append(Token.new(TokenType.NUMBER, float(number)))
				else:
					tokens.append(Token.new(TokenType.NUMBER, int(number)))
				continue
			
			
			if character == "." and i + 1 < line.length() and line[i + 1].is_valid_integer():
				var number = "."
				i += 1
				while i < line.length() and line[i].is_valid_integer():
					number += line[i]
					i += 1
				
				tokens.append(Token.new(TokenType.NUMBER, float(number)))
				continue
			
			
			var mat = regex.search(line.substr(i))
			if mat:
				var word = mat.get_string()
				if word in KEYWORDS:
					if KEYWORDS[word] == TokenType.BOOLEAN:
						tokens.append(Token.new(TokenType.BOOLEAN, word.to_lower() == "true"))
					elif KEYWORDS[word] == TokenType.NULL:
						tokens.append(Token.new(TokenType.NULL, null))
					else:
						tokens.append(Token.new(KEYWORDS[word], word))
				elif word in NEGATION_OPERATORS:
					tokens.append(Token.new(TokenType.NEGATION, word))
				else:
					tokens.append(Token.new(TokenType.IDENTIFIER, word))
				i += word.length()
				continue
			
			
			if character in PUNCTUATIONS:
				tokens.append(Token.new(PUNCTUATIONS[character], character))
				i += 1
				continue
			elif character in MATH_OPERATORS:
				tokens.append(Token.new(TokenType.MATH_OPERATOR, character))
				i += 1
				continue
			elif character in COMPARATORS:
				tokens.append(Token.new(TokenType.COMPARATOR, character))
				i += 1
				continue
			elif character in ASSIGNERS:
				tokens.append(Token.new(TokenType.ASSIGNMENT, character))
				i += 1
				continue
			elif character in NEGATION_OPERATORS:
				tokens.append(Token.new(TokenType.NEGATION, character))
				i += 1
				continue
			
			
			print("+No token???? Are you stupid??")
			print("-No, I'm %s" % character)
			i += 1

		for t in tokens:
			if !t.type in CANT_BE_ALONE_TOKENS:
				tokens.append(Token.new(TokenType.NEWLINE, ""))
				return tokens
			
		return []
	
	func tokenize(source: String) -> Array:
		var tokens = []
		var lines = source.split("\n", false)
		indent = 0
		for line in lines:
			var tokenized_line = tokenize_line(line)
			if tokenized_line:
				tokens += tokenized_line
		tokens.append(Token.new(TokenType.EOF, ""))
		return tokens

class ScriptReader:
	
	var tokenizer := ScriptTokenizer.new()
	
	var current_script: ECSClasses.ScriptFile
	
	var comment_regex = RegEx.new()
	var multi_line_comment_regex = RegEx.new()
	var tab_regex = RegEx.new()
	
	var menu_option_counter = - 1
	
	var command_block = []
	
	var tokens: Array
	var cur_token_index = - 1
	
	func _init():
		_set_regexes()
	
	func _set_regexes():
		comment_regex.compile("\\/\\/.*")
		multi_line_comment_regex.compile("\\*[\\s\\S]*?\\*")
		tab_regex.compile("(?m)^[ \\t]*\\r?\\n")
	
	func parse_script(source: String) -> ECSClasses.ScriptFile:
		var result = ECSClasses.ScriptFile.new()
		current_script = result
		var labels = result.labels
		var variables = result.variables
		var commands = result.commands
		
		tokens = _adapt_source(source)
		
		menu_option_counter = - 1
		
		cur_token_index = - 1
		
		while true:
			var token = _next_token(false)
			if !token or token.type == ScriptTokenizer.TokenType.EOF:
				break
			
			
			if token.type == ScriptTokenizer.TokenType.IDENTIFIER:
				var second_token = _next_number_of_tokens(2, false)
				if second_token and second_token.type == ScriptTokenizer.TokenType.COLON:
					_next_number_of_tokens(2)
					_parse_label(token.value, labels)
					continue
			
			
			if token.type == ScriptTokenizer.TokenType.DEFINE:
				_next_token()
				var var_token = _next_token()
				if var_token and var_token.type == ScriptTokenizer.TokenType.IDENTIFIER:
					_parse_variable(var_token.value, variables)
					continue
			
			
			if token.type == ScriptTokenizer.TokenType.COMMAND_DEF:
				_next_token()
				var cmd_def_token = _next_token()
				if cmd_def_token and cmd_def_token.type == ScriptTokenizer.TokenType.IDENTIFIER:
					_parse_command_definition(cmd_def_token.value, commands)
					continue
			
			
			_next_token( not not "true if benichi doesn't know how to make a fucking good parser")
		
		return result
	
	func _parse_label(label_name: String, labels: Dictionary):
		labels[label_name] = []
		
		var t = _next_token(false)
		if t and t.type == ScriptTokenizer.TokenType.NEWLINE:
			_next_token()
			t = _next_token(false)
			if t and t.type == ScriptTokenizer.TokenType.INDENT:
				_next_token()
				command_block.append(labels[label_name])
				_parse_block()
				command_block.pop_back()
	
	func _parse_variable(var_name: String, variables: Dictionary):
		var t = _next_token(false)
		var var_val = null
		
		if t and t.type == ScriptTokenizer.TokenType.ASSIGNMENT:
			_next_token()
			var_val = _parse_expression()
		
		t = _next_token(false)
		if t and t.type == ScriptTokenizer.TokenType.NEWLINE:
			_next_token()
		
		if var_val is String and var_val.begins_with("flag"):
			globaldata.flags[var_name] = false
		else:
			variables[var_name] = var_val
	
	func _parse_command_definition(command_name: String, commands: Dictionary):
		var command_definition = ECSClasses.ScriptCommandDefinition.new()
		
		var token_group = _get_tokens_until_type(ScriptTokenizer.TokenType.COLON)
		var _args = []
		var arg_taken = false
		for token in token_group:
			if !arg_taken and token.type == ScriptTokenizer.TokenType.IDENTIFIER:
				_args.append(token.value)
				arg_taken = true
			elif token.type == ScriptTokenizer.TokenType.COMMA:
				arg_taken = false
		
		command_definition.args = _args
		
		commands[command_name] = command_definition
		
		var t = _next_token(false)
		if t and t.type == ScriptTokenizer.TokenType.NEWLINE:
			_next_token()
			t = _next_token(false)
			if t and t.type == ScriptTokenizer.TokenType.INDENT:
				_next_token()
				command_block.append(command_definition.lines)
				_parse_block()
				command_block.pop_back()
	
	func _parse_block():
		while true:
			var token = _next_token(false)
			
			if !token or token.type == ScriptTokenizer.TokenType.DEDENT:
				_next_token()
				break
			
			if token.type == ScriptTokenizer.TokenType.EOF:
				break
			
			if token.type == ScriptTokenizer.TokenType.NEWLINE:
				_next_token()
				continue
			
			match token.type:
				ScriptTokenizer.TokenType.EOF: break
				ScriptTokenizer.TokenType.NEWLINE: _next_token()
				ScriptTokenizer.TokenType.IF: _parse_if()
				ScriptTokenizer.TokenType.RETURN: _parse_return()
				ScriptTokenizer.TokenType.YIELD: _parse_yield()
				ScriptTokenizer.TokenType.MENU: _parse_menu()
				ScriptTokenizer.TokenType.DEFAULT: _parse_menu_option(true)
				ScriptTokenizer.TokenType.STRING:
					
					var peek_after = _next_number_of_tokens(2, false)
					if peek_after and peek_after.type == ScriptTokenizer.TokenType.COLON:
						_parse_menu_option()
					else:
						_parse_text()
				ScriptTokenizer.TokenType.IDENTIFIER:
					
					var is_assignment = false
					var i = 1
					
					while true:
						var temp_token = _next_number_of_tokens(i + 1, false)
						if temp_token and temp_token.type == ScriptTokenizer.TokenType.DOT:
							var after_dot = _next_number_of_tokens(i + 2, false)
							if after_dot and after_dot.type == ScriptTokenizer.TokenType.IDENTIFIER:
								i += 2
							else:
								breakpoint
						else:
							break
					
					var check_token = _next_number_of_tokens(i + 1, false)
					if check_token and check_token.type == ScriptTokenizer.TokenType.ASSIGNMENT:
						is_assignment = true
					
					if is_assignment:
						_parse_assignment()
					else:
						_parse_command_line()
				_:
					
					push_error("Weird token: %s" % token.to_string())
					breakpoint
	
	func _parse_menu_option(default := false):
		var menu = null
		
		for i in range(command_block[ - 1].size() - 1, - 1, - 1):
			if command_block[ - 1][i] is ECSClasses.ScriptMenu:
				menu = command_block[ - 1][i]
				break
		
		if !menu:
			_get_tokens_until_newline()
			return
		
		menu_option_counter += 1
		var option_token
		if default:
			option_token = _next_number_of_tokens(2)
			menu.default = menu_option_counter
		else: option_token = _next_token()
		
		var colon_token = _next_token()
		if !colon_token or colon_token.type != ScriptTokenizer.TokenType.COLON:
			_get_tokens_until_newline()
			return
		
		menu.options[option_token.value] = []
		
		var t = _next_token(false)
		if t and t.type == ScriptTokenizer.TokenType.NEWLINE:
			_next_token()
			t = _next_token(false)
			if t and t.type == ScriptTokenizer.TokenType.INDENT:
				_next_token()
				command_block.append(menu.options[option_token.value])
				_parse_block()
				command_block.pop_back()
	
	func _parse_return():
		var rtrn = ECSClasses.ScriptReturn.new()
		_next_token()
		
		var next_token = _next_token(false)
		if next_token and next_token.type != ScriptTokenizer.TokenType.NEWLINE:
			rtrn.value = _parse_expression()
		
		command_block[ - 1].append(rtrn)
		
		var t = _next_token(false)
		if t and t.type == ScriptTokenizer.TokenType.NEWLINE:
			_next_token()
	
	func _parse_assignment():
		var assignment = ECSClasses.ScriptAssignment.new()
		
		var var_name = ""
		var token = _next_token()
		if token:
			var_name = token.value
		
		
		while true:
			var peek = _next_token(false)
			if peek and peek.type == ScriptTokenizer.TokenType.DOT:
				_next_token()
				var member = _next_token()
				if member and member.type == ScriptTokenizer.TokenType.IDENTIFIER:
					var_name += "." + member.value
				else:
					push_error("Expected identifier after dot")
					breakpoint
			
			else:
				break
		
		assignment.variable = var_name
		
		var op_token = _next_token()
		match op_token.value:
			"++":
				assignment.operation = "+="
				assignment.value = 1
			"--":
				assignment.operation = "-="
				assignment.value = 1
			_:
				assignment.operation = op_token.value
				assignment.value = _parse_expression()
		
		command_block[ - 1].append(assignment)
		
		var tok = _next_token(false)
		if tok and tok.type == ScriptTokenizer.TokenType.NEWLINE:
			_next_token()
	
	func _parse_if():
		var if_stmt = ECSClasses.ScriptConditional.new()
		_next_token()
		
		var cond = _parse_expression()
		if !cond is ECSClasses.ScriptComparation:
			var ition = ECSClasses.ScriptComparation.new()
			ition.left_op = cond;ition.operator = "==";ition.right_op = true
			cond = ition
		if_stmt.condition = cond
		
		var t = _next_token(false)
		if !t or t.type != ScriptTokenizer.TokenType.COLON:
			push_error("Must put ':' after if condition")
			breakpoint
		_next_token()
		
		t = _next_token(false)
		if !t or t.type != ScriptTokenizer.TokenType.NEWLINE:
			push_error("Must newline after if condition")
			breakpoint
		_next_token()
		
		t = _next_token(false)
		if !t or t.type != ScriptTokenizer.TokenType.INDENT:
			push_error("La sangría ha de ser llevada a cabo tras la declaración de la condición «if»")
			breakpoint
		_next_token()
		
		command_block.append(if_stmt.then_block)
		_parse_block()
		command_block.pop_back()
		
		command_block[ - 1].append(if_stmt)
		
		
		var else_token = _next_token(false)
		if else_token and else_token.type == ScriptTokenizer.TokenType.ELSE:
			_next_token()
			
			t = _next_token(false)
			if t and t.type == ScriptTokenizer.TokenType.COLON:
				_next_token()
			
			t = _next_token(false)
			if t and t.type == ScriptTokenizer.TokenType.NEWLINE:
				_next_token()
			
			t = _next_token(false)
			if t and t.type == ScriptTokenizer.TokenType.INDENT:
				_next_token()
				command_block.append(if_stmt.else_block)
				_parse_block()
				command_block.pop_back()
	
	func _parse_yield():
		var yield_stmt = ECSClasses.ScriptYield.new()
		_next_token()
		
		yield_stmt.condition = _parse_expression()
		
		command_block[ - 1].append(yield_stmt)
		
		var t = _next_token(false)
		if t and t.type == ScriptTokenizer.TokenType.NEWLINE:
			_next_token()
	
	func _parse_menu():
		var menu = ECSClasses.ScriptMenu.new()
		_next_token()
		
		
		var next_token = _next_token(false)
		if next_token and next_token.type == ScriptTokenizer.TokenType.NUMBER:
			menu.columns = int(next_token.value)
			_next_token()
		else:
			menu.columns = 1
			
		var t = _next_token(false)
		if !t or t.type != ScriptTokenizer.TokenType.COLON:
			push_error("Must put ':' after menu")
			breakpoint
		_next_token()
		
		t = _next_token(false)
		if !t or t.type != ScriptTokenizer.TokenType.NEWLINE:
			push_error("Must newline after menu")
			breakpoint
		_next_token()
		
		t = _next_token(false)
		if !t or t.type != ScriptTokenizer.TokenType.INDENT:
			push_error("Moist indentdent fafafter meniuuuu")
			breakpoint
		_next_token()
		
		command_block.append(menu)
		_parse_block()
		command_block.pop_back()
		
		command_block[ - 1].append(menu)
		menu_option_counter = - 1
	
	func _parse_text():
		var text_command = ECSClasses.ScriptText.new()
		var string_token = _next_token()
		
		
		text_command.value = string_token.value
		
		command_block[ - 1].append(text_command)
		
		var t = _next_token(false)
		if t and t.type == ScriptTokenizer.TokenType.NEWLINE:
			_next_token()
	
	func _parse_command_line():
		var command = _parse_expression()
		command_block[ - 1].append(command)
		
		var tok = _next_token(false)
		if tok and tok.type == ScriptTokenizer.TokenType.NEWLINE:
			_next_token()
	
	func _parse_expression():
		var left = _parse_primary()
		
		while true:
			var op_token = _next_token(false)
			if !op_token or not op_token.type in [ScriptTokenizer.TokenType.COMPARATOR, ScriptTokenizer.TokenType.MATH_OPERATOR]:
				break
			
			_next_token()
			var comp_or_assign
			var right = _parse_primary()
			if op_token.type == ScriptTokenizer.TokenType.COMPARATOR:
				comp_or_assign = ECSClasses.ScriptComparation.new()
				comp_or_assign.left_op = left
				comp_or_assign.operator = op_token.value
				comp_or_assign.right_op = right
				
			elif op_token.type == ScriptTokenizer.TokenType.MATH_OPERATOR:
				comp_or_assign = ECSClasses.ScriptAssignment.new()
				comp_or_assign.variable = left
				comp_or_assign.operation = op_token.value
				comp_or_assign.value = right
			
			left = comp_or_assign
			
		return left
	
	func _parse_primary():
		var token = _next_token()
		if !token: return null
		
		match token.type:
			ScriptTokenizer.TokenType.STRING, ScriptTokenizer.TokenType.BOOLEAN, ScriptTokenizer.TokenType.NULL, ScriptTokenizer.TokenType.NUMBER:
				return token.value
			ScriptTokenizer.TokenType.PAREN_OPEN:
				var expression = _parse_expression()
				var next = _next_token()
				if !next or next.type != ScriptTokenizer.TokenType.PAREN_CLOSE:
					push_error("Must close parentheses after expression")
					breakpoint
				return expression
			ScriptTokenizer.TokenType.NEGATION:
				var expression = _parse_primary()
				var negation = ECSClasses.ScriptComparation.new()
				negation.left_op = expression
				negation.operator = "=="
				negation.right_op = false
				return negation
			ScriptTokenizer.TokenType.MATH_OPERATOR:
				if token.value == "-":
					var expression = _parse_primary()
					if expression is int or expression is float:
						return - expression
					else:
						var minus = ECSClasses.ScriptAssignment.new()
						minus.variable = 0
						minus.operation = "-"
						minus.value = expression
						return minus
				return null
			ScriptTokenizer.TokenType.IDENTIFIER:
				var id_value = token.value
				
				
				while true:
					var peek = _next_token(false)
					if peek and peek.type == ScriptTokenizer.TokenType.DOT:
						_next_token()
						var member = _next_token()
						if member and member.type == ScriptTokenizer.TokenType.IDENTIFIER:
							id_value += "." + member.value
						else:
							push_error("Must put identifier after dot")
							breakpoint
					else:
						break
				
				
				var next_token = _next_token(false)
				if next_token and next_token.type == ScriptTokenizer.TokenType.PAREN_OPEN:
					return _parse_command_call(id_value)
				
				return id_value
		
		return null
	
	func _parse_command_call(command_name: String) -> ECSClasses.ScriptCommand:
		var cmd = ECSClasses.ScriptCommand.new()
		cmd.command_name = command_name
		
		var open_paren = _next_token()
		if !open_paren or open_paren.type != ScriptTokenizer.TokenType.PAREN_OPEN:
			push_error("Must open parentheses in command call")
			breakpoint
		
		var next_token = _next_token(false)
		if next_token and next_token.type != ScriptTokenizer.TokenType.PAREN_CLOSE:
			while true:
				cmd.args.append(_parse_expression())
				var t = _next_token(false)
				if t and t.type == ScriptTokenizer.TokenType.COMMA:
					_next_token()
				elif t and t.type == ScriptTokenizer.TokenType.PAREN_CLOSE:
					break
				else:
					push_error("Must use comma or close parentheses")
					breakpoint
		
		var close_paren = _next_token()
		if !close_paren or close_paren.type != ScriptTokenizer.TokenType.PAREN_CLOSE:
			push_error("Must close parentheses to close command call")
			breakpoint
		
		return cmd
	
	func _add_commands_to_string(input: String):
		var in_string = false
		var reading_command = false
		var command = ""
		var output = ""
		
		for i in input:
			if i == "\"":
				in_string = not in_string
				continue
			
			if !in_string:
				if i == " ":
					if reading_command:
						command = command + "}"
						output = output + command
						command = ""
					else:
						command = command + "{"
					reading_command = not reading_command
				
				if reading_command and i != " ":
					command = command + i
			else:
				output = output + i
		
		return output
	
	func _get_indent_level(line: String) -> int:
		var count = 0
		for character in line:
			if character == "\t":
				count += 1
			else:
				break
		return count
	
	func _get_next_token() -> ScriptTokenizer.Token:
		if cur_token_index + 1 < tokens.size():
			return tokens[cur_token_index + 1]
		return null
	
	func _next_token(advance := true) -> ScriptTokenizer.Token:
		
		
		var token = _get_next_token()
		if token and advance:
			cur_token_index += 1
		return token
	
	func _next_number_of_tokens(number: int, advance := true) -> ScriptTokenizer.Token:
		if advance:
			var token
			for i in range(number):
				token = _next_token(true)
			return token
		else:
			var target_index = cur_token_index + number
			if target_index < tokens.size():
				return tokens[target_index]
			return null
	
	func _get_tokens_until_type(token_type: int, advance := true) -> Array:
		var result = []
		while cur_token_index < tokens.size():
			var token = _next_token(advance)
			if !token: break
			result.append(token)
			if token.type == token_type: break
		return result
	
	func _get_tokens_until_newline(advance := true) -> Array:
		return _get_tokens_until_type(ScriptTokenizer.TokenType.NEWLINE, advance)
	
	func _adapt_source(source: String) -> Array:
		
		var result = tab_regex.sub(source, "", true)
		
		result = multi_line_comment_regex.sub(result, "", true)
		result = comment_regex.sub(result, "", true)
		result = result.replace("  ", "\t")
		return tokenizer.tokenize(result)

const COMMANDS = [
	"next", 
	"end", 
	"eob", 
	"pause", 
	"call", 
	"goto", 
	"toggle", 
	"set", 
	"unset", 
	"linebreak", 
	"window_open", 
	"wait", 
	"hp", 
	"text_blips", 
	"change_sprite", 
	"get_enemy_count"
	]


const ACTION_COMMANDS = [
	"m_pause", 
	"m_disable_collision", 
	"m_enable_collision", 
	"m_set_facing_anim", 
	"m_jmp", 
	"do_skill"
	]


var modules = {}
var parsing := true
var parser: ScriptReader = ScriptReader.new()
var unresolved_references := []


var executer_curr_line = 0
var executer_curr_modu = ""
var executer_curr_label = ""

func _ready():
	load_scripts()
	parsing = false
	_handle_unresolved_references()
	

func load_scripts():
	var root := "res://Data"
	var dir := Directory.new()
	if dir.open(root) != OK:
		push_error("ECSInterpreter couldn't load %s" % root)
		return
	
	_scan_folder(root, modules)

func _scan_folder(folder_path: String, parent_dict: Dictionary) -> void :
	var dir := Directory.new()
	if dir.open(folder_path) != OK:
		return
	
	dir.list_dir_begin(true, true)
	
	var module_labels := {}
	
	while true:
		var _name := dir.get_next()
		if _name == "":
			break
		
		if dir.current_is_dir():
			_scan_folder(folder_path.plus_file(_name), module_labels)
			continue
		
		
		if _name.to_lower().ends_with(".ecs"):
			var full_path := folder_path.plus_file(_name)
			var parsed = parse_file(full_path)
			module_labels[_name.replace(".ecs", "")] = parsed
	
	if module_labels:
		var module_key := folder_path.replace("res://Data/", "").replace("res://Data", "")
		while module_key.ends_with("/"):
			module_key = module_key.substr(0, module_key.length() - 1)
		if module_key == "":
			modules = module_labels
		else:
			module_key = module_key.get_file()
			parent_dict[module_key] = module_labels

func get_ecscript(path: String) -> ECSClasses.ScriptFile:
	var result = modules
	var parts = path.replace("res://Data/", "").trim_suffix(".ecs").split("/")
	for i in parts:
		if result.has(i):
			result = result[i]
		else:
			push_warning("Script path '%s' not found!" % path)
			return null
	return result

func parse_file(path: String) -> ECSClasses.ScriptFile:
	var result
	var file := File.new()
	if file.open(path, File.READ) == OK:
		result = parser.parse_script(file.get_as_text())
		file.close()
	return result

func _handle_unresolved_references():
	for ref in unresolved_references:
		if ref is Dictionary:
			var obj = ref["script"].get_variable(ref["name"])
			if !obj:
				obj = ref["script"].get_label(ref["name"])
			
			obj = get_variable(ref["name"], ref["script"])
			if !obj:
				obj = get_label(ref["name"], ref["script"])
		
		elif ref is ECSClasses.ScriptCommand:
			ref.command_name = get_command(ref.command_name, ref.get_script_file())
		
	unresolved_references.clear()

func _debug_get_label(modu, lab_name):
	if !modules.has(modu):
		assert (false, ("Module '%s' does not exist" % modu) + " in label '" + executer_curr_label + "' of module '" + executer_curr_modu + "'")
		return []
	if !modules[modu].labels.has(lab_name):
		assert (false, ("Label '%s' does not exist" % lab_name) + " in label '" + executer_curr_label + "' of module '" + executer_curr_modu + "'")
		return []
	return modules[modu].labels[lab_name]


func modules_to_dict(dict := modules) -> Dictionary:
	var result = dict.duplicate()
	for key in result.keys():
		if result[key] is Dictionary:
			result[key] = modules_to_dict(result[key])
		elif result[key] is Object:
			result[key] = result[key].file_to_dict()
	return result

func get_command(command_name: String, script: ECSClasses.ScriptFile):
	var custom = _get_custom_command(command_name, script)
	if custom:
		return custom
	
	return command_name

func _get_custom_command(command_name: String, script: ECSClasses.ScriptFile) -> ECSClasses.ScriptCommandDefinition:
	var command = script.get_command(command_name)
	if command:
		return command
	var no_parentheses = command_name.split("(")[0]

	var parent_folder = modules[script.get_location().split("/")[0]]
	var split_command = no_parentheses.split(".")
	var real_command = split_command[ - 1]

	var m = modules.get(parent_folder)
	if m:
		for i in split_command:
			var element = m.get(i)
			if element is Dictionary:
				m = element
				continue
			if element is ECSClasses.ScriptFile:
				return element.get_command(real_command)
	return null

func get_variable(variable_name: String, script: ECSClasses.ScriptFile):
	if script.has_variable(variable_name):
		return script.get_variable(variable_name)
	
	var parent_folder = modules[script.get_location().split("/")[0]]
	var split_variable = variable_name.split(".")
	var real_variable = split_variable[ - 1]
	
	var v = modules.get(parent_folder)
	if v:
		for i in split_variable:
			var element = v.get(i)
			if element is Dictionary:
				v = element
				continue
			elif element is ECSClasses.ScriptFile:
				return element.get_variable(real_variable)
	
	return variable_name

func set_variable(variable_name: String, value, script: ECSClasses.ScriptFile):
	if script.has_variable(variable_name):
		script.set_variable(variable_name, value)
		return
	
	var parent_folder = modules[script.get_location().split("/")[0]]
	var split_variable = variable_name.split(".")
	var real_variable = split_variable[ - 1]
	
	var v = modules.get(parent_folder)
	if v:
		for i in split_variable:
			var element = v.get(i)
			if element is Dictionary:
				v = element
				continue
			elif element is ECSClasses.ScriptFile:
				element.set_variable(real_variable, value)
				return


func get_label(label_name: String, script: ECSClasses.ScriptFile) -> Dictionary:
	var label = script.get_label(label_name)
	if label:
		return label
	var parent_folder = modules[script.get_location().split("/")[0]]
	var split_label = label_name.split(".")
	var real_label = split_label[ - 1]
	
	var l = modules.get(parent_folder)
	if l:
		for i in split_label:
			var element = l.get(i)
			if element is Dictionary:
				l = element
				continue
			if element is ECSClasses.ScriptFile:
				return element.get_label(real_label)
	return {}

func _pretty_print_json(json_data) -> void :
	var json_string = JSON.print(json_data)
	var pretty_json = _format_json_tree(json_string)
	print(pretty_json)

func _get_indent(indent: int) -> String:
		return " ".repeat(indent)

func _format_json_tree(json_string: String, indent: int = 4) -> String:
	var result = ""
	var current_indent = 0
	var in_quotes = false
	var escape = false
	
	for i in range(json_string.length()):
		var chr = json_string[i]
		
		if escape:
			result += chr
			escape = false
		elif chr == "\\":
			escape = true
			result += chr
		elif chr == "\"":
			in_quotes = not in_quotes
			result += chr
		elif chr == "{" or chr == "[":
			if !in_quotes:
				result += chr + "\n" + _get_indent(current_indent + indent)
				current_indent += indent
			else:
				result += chr
		elif chr == "}" or chr == "]":
			if !in_quotes:
				current_indent -= indent
				result += "\n" + _get_indent(current_indent) + chr
			else:
				result += chr
		elif chr == ",":
			if !in_quotes:
				result += chr + "\n" + _get_indent(current_indent)
			else:
				result += chr
		else:
			result += chr
	
	return result

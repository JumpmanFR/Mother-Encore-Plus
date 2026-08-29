class_name YAMLParser

# Ignores comments and empty lines
class SmartFileReader:
	var _file := File.new()
	var _buffer := ""
	var _line_number := 0

	func open(path: String) -> int:
		if _file.file_exists(path):
			return _file.open(path, File.READ)
		else:
			return ERR_FILE_NOT_FOUND

	func get_file_name() -> String:
		return _file.get_path().get_basename()

	func get_line_number() -> int:
		return _line_number

	func _is_line_significant(line: String) -> bool:
		var stripped := line.strip_edges()
		return !(stripped == "" or stripped.begins_with("#"))

	func _read_next_significant_line() -> String:
		while !_file.eof_reached():
			var line := _file.get_line()
			_line_number += 1
			if _is_line_significant(line):
				return line
		return ""

	func next_line(stripped := true) -> String:
		var result: String
		if _buffer == "":
			result = _read_next_significant_line()
		else:
			result = _buffer
			_buffer = ""
		return _strip_by_indent(result) if stripped else result

	func _peek_line(stripped := true) -> String:
		if _buffer == "":
			_buffer = _read_next_significant_line()
		return _strip_by_indent(_buffer) if stripped else _buffer

	func peek_indent() -> int:
		return _get_indent_level(_peek_line(false))

	func peek_dashes() -> int:
		var line := _peek_line(false)
		var indent_level := _get_indent_level(line)
		return line.count("- ", 0, indent_level)

	func peek_first_dash_pos() -> int:
		var line := _peek_line(false)
		var indent_level := _get_indent_level(line)
		var line_indent := line.substr(0, indent_level)
		var first_dash_pos := line_indent.find("- ")
		return first_dash_pos

	func end_reached() -> bool:
		return _peek_line(false) == "" and _file.eof_reached()

	func close():
		_file.close()

	static func _get_indent_level(line: String) -> int:
		var stripped := line.lstrip(" ")
		while stripped.begins_with("- "):
			stripped = stripped.trim_prefix("- ")
		return line.length() - stripped.length()

	static func _strip_by_indent(line: String) -> String:
		return line.substr(_get_indent_level(line)).strip_edges()


static func parse_file(path: String):
	var result = null

	if !path.ends_with(".yaml") and !path.ends_with(".yml"):
		push_error("No valid yaml file at path: %s" % path)
		return result
		
	var reader := SmartFileReader.new()
	var open_result := reader.open(path)
	if open_result != OK:
		push_error("Couldn't open yaml file at path: %s" % path)
		return result

	if reader.end_reached():
		return result

	if reader.peek_dashes() > 0:
		result = _parse_list(reader, reader.peek_indent())
	else:
		result = _parse_dict(reader, reader.peek_indent())

	reader.close()
	
	return result


static func _parse_dict(reader: SmartFileReader, indent: int) -> Dictionary:
	var result := {}
	while !reader.end_reached() and reader.peek_indent() == indent:
		var pair := _parse_dict_entry(reader, indent)
		if pair.size() == 2:
			result[pair[0]] = pair[1]

	return result

static func _parse_list(reader: SmartFileReader, indent: int) -> Array:
	var root := []
	var stack := [root]
	var dash_pos_stack := [-1]  # stack of first dash positions

	while !reader.end_reached() and reader.peek_indent() >= indent and reader.peek_dashes() > 0:
		var current_first_dash_pos := reader.peek_first_dash_pos()
		var dash_count := reader.peek_dashes()
		var line := _strip_comment(reader.next_line())
		var colon_index := _find_first_unquoted_char(line, ":")

		while dash_pos_stack.size() > 1 and current_first_dash_pos <= dash_pos_stack[-1]:
			stack.pop_back()
			dash_pos_stack.pop_back()

		# Push new nested lists for each additional dash beyond the first
		for i in range(dash_count - 1):
			var new_list := []
			stack[-1].append(new_list)
			stack.append(new_list)
			dash_pos_stack.append(current_first_dash_pos)

		var current_list = stack[-1]

		var item := {}
		var is_dict := false

		if colon_index != -1:
			var key := _unquote(line.substr(0, colon_index).strip_edges())
			var value_text := line.substr(colon_index + 1).strip_edges()

			if value_text != "":
				item[key] = _parse_scalar(value_text)
			elif !reader.end_reached() and reader.peek_indent() > indent:
				if reader.peek_dashes() > 0:
					item[key] = _parse_list(reader, reader.peek_indent())
				else:
					item[key] = _parse_dict(reader, reader.peek_indent())
			else:
				item[key] = null

			is_dict = true

		elif line != "":
			current_list.append(_parse_scalar(line))
			continue
		else:
			current_list.append(null)
			continue

		# Now get the following dictionary lines that are part of the same list item
		while !reader.end_reached():
			var next_indent := reader.peek_indent()

			if next_indent == indent and reader.peek_dashes() > 0:
				break
			if next_indent < indent:
				break

			var pair := _parse_dict_entry(reader, next_indent)
			if pair.size() == 2:
				item[pair[0]] = pair[1]

		current_list.append(item)

	return root

static func _parse_dict_entry(reader: SmartFileReader, indent: int) -> Array:
	var line := _strip_comment(reader.next_line())
	var colon_index := _find_first_unquoted_char(line, ":")

	if colon_index == -1:
		push_error("Expected ':' at line: %s of file %s" % [line, reader.get_file_name()])
		return []

	var key := _unquote(line.substr(0, colon_index).strip_edges())
	var yaml_value := line.substr(colon_index + 1).strip_edges()

	var return_value

	if yaml_value != "":
		return_value = _parse_scalar(yaml_value)
	else:
		if reader.end_reached():
			return_value = null
		elif reader.peek_indent() > indent:
			if reader.peek_dashes() > 0:
				return_value = _parse_list(reader, reader.peek_indent())
			else:
				return_value = _parse_dict(reader, reader.peek_indent())
		else:
			return_value = null

	return [key, return_value]


static func _parse_scalar(text: String):
	text = text.strip_edges()

	if text in ["null", "~"]:
		return null
	elif text == "true":
		return true
	elif text == "false":
		return false
	elif text.is_valid_integer():
		return int(text)
	elif text.is_valid_float():
		return float(text)
	elif text.begins_with("[") and text.ends_with("]"):
		return _parse_inline_list(text.substr(1, text.length() - 2))
	else:
		return _unquote(text)

static func _parse_inline_list(content: String) -> Array:
	var result := []
	var current := ""
	var in_single_quotes := false
	var in_double_quotes := false
	var escaped := false

	for i in content.length():
		var c := content[i]

		if escaped:
			current += c
			escaped = false
			continue
		if c == "\\":
			escaped = true
			continue
		if c == '"' and not in_single_quotes:
			in_double_quotes = not in_double_quotes
			current += c
			continue
		if c == "'" and not in_double_quotes:
			in_single_quotes = not in_single_quotes
			current += c
			continue

		if c == "," and not in_single_quotes and not in_double_quotes:
			result.append(_parse_scalar(current.strip_edges()))
			current = ""
		else:
			current += c

	if current.strip_edges() != "":
		result.append(_parse_scalar(current.strip_edges()))

	return result


# --- Helpers ---

static func _find_first_unquoted_char(text: String, char_to_find: String) -> int:
	var in_single_quotes := false
	var in_double_quotes := false
	var is_escaped := false

	for i in range(text.length()):
		var c := text[i]
		if is_escaped:
			is_escaped = false
			continue
		if c == '\\':
			is_escaped = true
			continue
		if c == '"' and !in_single_quotes:
			in_double_quotes = !in_double_quotes
		elif c == "'" and !in_double_quotes:
			in_single_quotes = !in_single_quotes
		elif c == char_to_find and !in_single_quotes and !in_double_quotes:
			return i
	return -1

static func _unquote(s: String) -> String:
	if s.begins_with('"') and s.ends_with('"'):
		var unescaped := s.substr(1, s.length() - 2)
		return _decode_escaped_double_quotes(unescaped)
	elif s.begins_with("'") and s.ends_with("'"):
		return s.substr(1, s.length() - 2).replace("''", "'")
	return s

static func _decode_escaped_double_quotes(text: String) -> String:
	return text\
		.replace("\\n", "\n")\
		.replace("\\t", "\t")\
		.replace("\\r", "\r")\
		.replace('\\"', '"')\
		.replace("\\\\", "\\")

static func _strip_comment(text: String) -> String:
	var hash_index := _find_first_unquoted_char(text, "#")
	if hash_index == -1:
		return text
	return text.substr(0, hash_index).strip_edges()

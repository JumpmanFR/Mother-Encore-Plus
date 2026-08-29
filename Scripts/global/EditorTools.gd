
tool 
extends Node
class_name EditorTools


static func get_json_data(file_path: String, fallback: String = "") -> Dictionary:
	var file := File.new()
	if file.file_exists(file_path):
		file.open(file_path, File.READ)
		var file_content := file.get_as_text()
		var res = YAMLParser.parse_file(file_path)
		if res == null:
			push_warning("Couldn’t parse yaml file at %s" % file_path)
			return {}
		return res
	else:
		if fallback:
			return get_json_data(fallback)
		else:
			push_warning("Couldn’t find yaml file at %s" % file_path)
			return {}

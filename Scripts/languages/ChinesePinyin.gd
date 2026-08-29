class_name ChinesePinyin

const PINYIN_RES_PATH = "res://Scripts/languages/pinyin_data_zh_CN.res"
const PAGE_SIZE = 55

static func _load_pinyin_data(txt_path: String):
	var data = load(txt_path)
	if data.has_meta("pinyin_to_hanzi") and data.has_meta("valid_pinyins") and data.has_meta("initial_to_hanzi"):
		var pinyin_to_hanzi = data.get_meta("pinyin_to_hanzi")
		var valid_pinyins = data.get_meta("valid_pinyins")
		var initial_to_hanzi = data.get_meta("initial_to_hanzi")
		
		return [pinyin_to_hanzi, valid_pinyins, initial_to_hanzi]


static func get_candidates_for_input(s: String) -> Array:
	var result = _load_pinyin_data(PINYIN_RES_PATH)
	var pinyin_to_hanzi = result[0]
	var valid_pinyins = result[1]
	var initial_to_hanzi = result[2]
	
	if s.empty():
		return []
	
	if valid_pinyins.has(s):
		return pinyin_to_hanzi[s]
	
	if s.length() == 1 and s[0] >= "a" and s[0] <= "z":
		return initial_to_hanzi.get(s, [])
	return []

static func show_candidates_on_grid(candidates: Array, pinyin_page: int, _keyboard_grid_1: GridContainer, _keyboard_grid_2: GridContainer, _keyboard_grid_3: GridContainer):
	var start = PAGE_SIZE * pinyin_page
	var total = candidates.size()
	
	if total > PAGE_SIZE:
		print("lol")
		var first_given = false
		var already_has = false
		for i in range(_keyboard_grid_1.get_child_count()):
			var label = _keyboard_grid_1.get_child(i)
			if label.get_child(0).text in ["◂", "▸"]:
				already_has = true
				break
		if not already_has:
			for i in range(_keyboard_grid_1.get_child_count()):
				var label = _keyboard_grid_1.get_child(i)
				if label.text == "A":
					continue
				if label.get_child(0).text in ["◂", "▸"]:
					break
				else:
					if not first_given:
						label.text = "A"
						label.get_child(0).text = "◂"
						first_given = true
					else:
						label.text = "A"
						label.get_child(0).text = "▸"
						break
	else:
		
		var first_cleared = false
		for i in range(_keyboard_grid_1.get_child_count() - 1, - 1, - 1):
			var label = _keyboard_grid_1.get_child(i)
			if label.text == "A" and label.get_child(0).text in ["◂", "▸"]:
				label.text = ""
				label.get_child(0).text = ""
				if not first_cleared:
					first_cleared = true
				else:
					break

	
	var grid2 = _keyboard_grid_2
	var cells2 = grid2.get_child_count()
	for i in range(cells2):
		var label = grid2.get_child(i)
		var lower_label = label.get_child(0)
		var idx = start + i
		lower_label.text = candidates[idx] if idx < total else ""
		label.text = "A" if lower_label.text != "" else ""
	
	
	var grid3 = _keyboard_grid_3
	var cells3 = grid3.get_child_count()
	for i in range(cells3):
		var label = grid3.get_child(i)
		var lower_label = label.get_child(0)
		var idx = start + 30 + i
		lower_label.text = candidates[idx] if idx < total else ""
		label.text = "A" if lower_label.text != "" else ""

static func is_pinyin_char(character: String) -> bool:
	var allowed_upper = "ABCDEFGHIJKLMNOPQRSTUÜWXYZ"
	return character in allowed_upper

static func compare_page(pinyin_page: int, character: String, candidates: Array) -> int:
	match character:
		"◂":
			if pinyin_page > 0:
				return pinyin_page - 1
			elif candidates.size() > 0:
				return int((candidates.size() - 1) / PAGE_SIZE)
			else:
				return 0
		"▸":
			if candidates.size() > PAGE_SIZE * (pinyin_page + 1):
				return pinyin_page + 1
			else:
				return 0
	return pinyin_page

class_name TextTools

const DIALOG_HINT_COLOR := "ea8b2c"
const SPECIAL_KEY_LABELS := {KEY_UP: "↑", KEY_DOWN: "↓", KEY_LEFT: "←", KEY_RIGHT: "→", KEY_KP_MULTIPLY: "*", KEY_KP_DIVIDE: "/", KEY_KP_SUBTRACT: "-", KEY_KP_PERIOD: ".", KEY_KP_ADD: "+", KEY_KP_0: "0", KEY_KP_1: "1", KEY_KP_2: "2", KEY_KP_3: "3", KEY_KP_4: "4", KEY_KP_5: "5", KEY_KP_6: "6", KEY_KP_7: "7", KEY_KP_8: "8", KEY_KP_9: "9", KEY_SPACE: "KEYBOARD_SPACE"}
const PSI_LEVELS := "αβγΩΣ"

const KNOWN_BB_TAGS := ["i", "b", "img", "font", "color", "rainbow", "tornado"]
const CHAR_DELAY := "​"
const CHAR_PRINTING_FASTER := "⁪"
const CHAR_PRINTING_SLOWER := "⁦"
const CHAR_PRINTING_NORMAL := "⁫"
const CHAR_WAIT := "⁣"
const CHAR_BULLET := "⁤"

static func replace_text(string: String, context = globaldata, without_brackets := false) -> String:
	string = _tr(string)
	string = _replace_ifs(string)
	string = _replace_tags(string, context, without_brackets)
	string = _apply_text_substitutions(string)
	return string
	
# General syntax: [Tag], [Tag:Param1,Param2,...], or [Tag123] (numeric parameter)
static func _replace_tags(string: String, context = globaldata, without_brackets := false) -> String:
	var startIndex := 0
	var regex := RegEx.new()
	regex.compile("\\[([A-Za-z_@/]+)(:[^\\]]+|\\d+)?\\]" if !without_brackets else "^([A-Za-z_]+)(:[^\\]]+|\\d+)?$")
	var receiver: PartyMember = Inventory.get_item_owner(global.item, true)
	var tag := regex.search(string)
	while tag:
		var result := tag.get_string()
		var tag_content := tag.get_string(1).to_lower()
		var tag_param := tag.get_string(2).trim_prefix(":")
		var tag_params := tag_param.split(":") if tag_param else PoolStringArray()
		var str_before := string.substr(0, tag.get_start())
		var str_after := string.substr(tag.get_end())
		match tag_content:
			"favfood":		# [FavFood] returns the favorite food
				result = _cut_custom_name(context.favorite_food, tag_content)
			"playername":	# [PlayerName] returns the player’s name
				result = _cut_custom_name(context.player_name, tag_content)
			"itemname": 	# [ItemName] returns the current item name
				result = _tr(global.item.get_data().get("name", ""))
			"itemreceiver":	# [ItemReceiver] returns the nickname of the party member receiving an item
				result = _cut_custom_name(receiver.get_nickname(), tag_content) if receiver else ""
			"itemart":		# [ItemArt0], [ItemArt1], etc., return the current item articles
				result = get_item_or_skill_articles(global.item.get_data(), int(tag_param)) if global.item and tag_param else ""
			"itemvalue":
				result = "%s" % _get_item_value(global.item, tag_param)
			"itemvalart":
				result = get_number_articles(_get_item_value(global.item, tag_params[0]), int(tag_params[1])) if tag_params.size() > 1 else get_number_articles(_get_item_value(global.item), int(tag_param))
			"partylead":	# [PartyLead] returns the party leader's nickname
				result = _cut_custom_name(global.party[0].get_nickname(), tag_content)
			"leadart":		# [LeadArt0], [LeadArt1], etc., return the party leader's articles
				result = get_battler_articles(global.party[0], int(tag_param))
			"receiverart":	# [ReceiverArt0], [ReceiverArt1], etc., return the item receiver's articles
				result = get_battler_articles(receiver, int(tag_param))
			"earnedcash":	# [EarnedCash] returns - and resets - the amount of money you've just earned
				result = var2str(context.earned_cash) # Dollar sign not included
				context.earned_cash = 0
				context.flags["earned_cash"] = false
			"currentcash":	# [CurrentCash] returns the amount of money on hand (without dollar sign)
				result = var2str(context.cash)
			"halfcash":
				result = var2str(context.cash / 2)
			"bankcash":		# [BankCash] returns the amount of money on bank (without dollar sign)
				result = var2str(context.bank)
			"tr":
				result = _tr(tag_param)
			"color", "c":		# [color] returns the opening tag to set the text color to hint color
				result = "[color=#%s]" % DIALOG_HINT_COLOR
			"/c":
				result = "[/color]"
			"br":	# [br] returns a new line
				str_before = str_before.trim_suffix("\n")
				result = "\n"
			"delay", "d":
				var duration := tag_params[0].to_float() if tag_params else 10.0 # /!\ split never returns an empty array
				var repeat := tag_params[1].to_int() if tag_params.size() > 1 else 1
				var invisible_chars := get_text_delay(duration)
				result = invisible_chars
				if repeat > 1:
					var slowed_down_part := ""
					var repeated_count := 0
					for i in range(repeat - 1):
						if i >= str_after.length() || str_after[i] in "{[":
							break
						slowed_down_part += str_after[i]
						slowed_down_part += invisible_chars
						repeated_count += 1
					str_after = slowed_down_part + str_after.substr(repeated_count)
			"slower", "sl":
				var param := int(clamp(int(tag_param), 1, 10)) if tag_param else 1
				result = CHAR_PRINTING_SLOWER.repeat(param)
			"faster", "f":
				var param := int(clamp(int(tag_param), 1, 10)) if tag_param else 1
				result = CHAR_PRINTING_FASTER.repeat(param)
			"sudden", "s":
				result = CHAR_PRINTING_FASTER.repeat(10)
			"/sudden", "/s", "/faster", "/f", "/slower", "/sl":
				result = CHAR_PRINTING_NORMAL
			"wait", "w":
				result = CHAR_WAIT
			"@", "br@":
				str_before = str_before.trim_suffix("\n")
				result = CHAR_BULLET
				if str_before:
					result = "\n" + result
			"wait@", "w@":
				str_before = str_before.trim_suffix("\n")
				result = CHAR_WAIT + "\n" + CHAR_BULLET
			"waitbr", "wbr":
				str_before = str_before.trim_suffix("\n")
				result = CHAR_WAIT + "\n"
			"elision":		# [elision] returns French elision ("e " or "'" if followed by vowel)
							# [elision:***] returns French elision where the next word is ***
				result = _get_french_elision(_replace_tags(tag_param, context, true) if tag_param else replace_text(str_after))
			"genitive":		# [genitive] returns German genitive suffix ("s" or "'" if after an s or x)
							# [genitive:***] returns German genitive suffix where the previous word is ***
				var nickname := _replace_tags(tag_param, context, true)
				result = _get_german_genitive(nickname)
			"decline":		# [decline:name:gender:case] returns declension for name (in Polish, Russian, Ukrainian)
							# where "gender" is M or F and "case" is the index of the grammar case
				var nickname := _replace_tags(tag_params[0], context, true)
				result = _get_custom_name_declension(nickname, tag_params[1], int(tag_params[2]))
			"particle":	# [particle:type] returns Korean particle for the previous word
						# where "type" is 0 to 4 (는/은, 가/이, 를/을, 와/과, 로/으로)
						# [particle:name:type] returns Korean particle for "name"
				if tag_params.size() > 1:
					var nickname := _replace_tags(tag_params[0], context, true)
					result = _get_korean_particle(nickname, int(tag_params[1]))
				else:
					result = _get_korean_particle(string.substr(0, tag.get_start()), int(tag_params[0]))
			"plur_num":
				result = _get_plural_number_suffix(int(tag_params[0]), tag_params[1], tag_params[2])
			"slav_num":
				result = _get_slavic_number_suffix(int(tag_params[0]), tag_params[1], tag_params[2], tag_params[3])
			"slav_num_strict":
				result = _get_slavic_number_suffix(int(tag_params[0]), tag_params[1], tag_params[2], tag_params[3], true)
			"ja_num":
				tag_params.resize(7)
				result = _get_japanese_number_suffix(int(tag_params[0]), tag_params[1], tag_params[2], tag_params[3], tag_params[4], tag_params[5], tag_params[6])
			"and":
				if tag_params.size() > 1:
					result = get_and_cunjunction(tag_params[0], tag_params[1])
				elif tag_params.size() == 1:
					result = get_and_cunjunction("", tag_params[0])
				else:
					result = get_and_cunjunction(replace_text(str_before), replace_text(str_after))
			_:
				if tag_content.begins_with("ui_"):	# [ui_accept], [ui_cancel], etc., returns control keys
					result = get_key_name(tag_content)
				elif tag_content in globaldata.characters:
					if context is Dictionary: 
						result = context.get(tag_content, {}).get("nickname", "")
					else:
						result = context.characters.get(tag_content).get_nickname()
					if tag_content in global.POSSIBLE_PLAYABLE_MEMBERS:
						result = _cut_custom_name(result, tag_content)
					if tag_param:
						result = result.left(tag_param.to_int())
				elif tag_content in globaldata.get_all_ailments():
					result = "[font=res://Graphics/UI/Ailments/Ailments.tres][img]res://Graphics/UI/Ailments/%s.png[/img][/font]" % tag_content.to_lower()
				else:
					startIndex = tag.get_start() + 1
					if not (tag_content in KNOWN_BB_TAGS or tag_content.trim_prefix('/') in KNOWN_BB_TAGS):
						push_warning("UNKNOWN TAG: %s" % tag_content)
		
		string = str_before + result + str_after
		
		if without_brackets:
			break
		
		tag = regex.search(string, startIndex)
	
	return string

# In case the player switches language, the max lengths are different
static func _cut_custom_name(name: String, tag: String) -> String:
	var max_length := len(_tr("LONGEST_POSSIBLE_NAME"))
	if tag == "playername":
		max_length = len(_tr("LONGEST_POSSIBLE_PLAYER_NAME"))
	elif tag == "favfood":
		max_length = len(_tr("LONGEST_POSSIBLE_FOOD"))
	return name.substr(0, max_length)

static func _replace_ifs(string: String) -> String:
	var regex := RegEx.new()
	regex.compile("\\[if (\\w+)(:\\w+)?\\]((?:(?!\\[/?if [\\w:]+\\]).)*?)(\\[else\\]((?:(?!\\[/?if [\\w:]+\\]).)*?))?\\[/if\\]")
	var tag := regex.search(string)
	
	if tag:
		var condition := tag.get_string(1)
		var params := tag.get_string(2).trim_prefix(":").split(":")
		var content_if := tag.get_string(3)
		var content_else := tag.get_string(5)
		var before := string.substr(0, tag.get_start())
		var after := string.substr(tag.get_end())
		var condition_res = true
		match condition:
			"input":
				for param in params:
					match param:
						"gamepad":
							condition_res = condition_res if globaldata.device == globaldata.GAMEPAD else false
						"keyboard":
							condition_res = condition_res if globaldata.device == globaldata.KEYBOARD else false
						_:
							push_warning("UNKNOWN CONDITION: %s=%s" % [condition, param])
			"party":
				for param in params:
					match param:
						"plural":
							condition_res = condition_res if global.party.size() > 1 else false
						"singular":
							condition_res = false if global.party.size() > 1 else condition_res
						"female_lead":
							condition_res = condition_res if global.party[0].get_name() in [PartyMember.ANA, PartyMember.PIPPI] else false
						"male_lead":
							condition_res = false if global.party[0].get_name() in [PartyMember.ANA, PartyMember.PIPPI] else condition_res
			"party_lead":
				for param in params:
					match param:
						"female":
							condition_res = condition_res if global.party[0].get_name() in [PartyMember.ANA, PartyMember.PIPPI] else false
						"male":
							condition_res = false if global.party[0].get_name() in [PartyMember.ANA, PartyMember.PIPPI] else condition_res
						_:
							condition_res = condition_res if global.party[0].get_name() == param else false
						
			
			_:
				push_warning("UNKNOWN CONDITION: %s" % condition)
				condition_res = null
		var res
		if condition_res == null:
			res = before + after
		elif condition_res:
			res = before + content_if + after
		else:
			res = before + content_else + after
		
		return res if string == res else _replace_ifs(res)
	
	else:
		return string

static func _apply_text_substitutions(string: String) -> String:
	var substitutions := {" - ": " – " , "(\\d+) (\\$)": '$1 $2',  "([   ])!": "$1¦" }
	var regex := RegEx.new()
	for pattern in substitutions:
		regex.compile(pattern)
		string = regex.sub(string, substitutions[pattern], true)
	return string

static func get_battler_articles(battler: Character, article_idx: int = - 1, battler_name = null):
	var article_str: String = _tr(battler.get_article() if battler.get_article() else "ARTICLES_DEFAULT")
	var article_array := article_str.split(",")
	
	if !battler_name: battler_name = battler.get_nickname()
	
	for i in article_array.size():
		# In case the "articles" are actually alternative names, {0} reverts to the actual nickname (useful for languages with declensions)
		article_array[i] = article_array[i].format([battler_name])
		# French elision in the case of articles (for user-defined party member names)
		article_array[i] = replace_text(article_array[i])
	
	if article_idx == -1:
		return Array(article_array)
	elif article_idx < article_array.size():
		return article_array[article_idx]
	else:
		return ""

static func get_item_or_skill_articles(item: Dictionary, article_idx := -1):
	var article_str := _tr(item.get("article", ""))
	var article_array := article_str.split(",")
	
	if article_idx == -1:
		return Array(article_array)
	elif article_idx < article_array.size():
		return article_array[article_idx]
	else:
		return ""

# requested_stat: HPrecover, PPrecover, maxhp, maxpp, offense, defense, speed, iq, guts
# if requested_stat is omitted, the most relevant stat value is automatically returned
static func _get_item_value(item: Item, requested_stat := "") -> int:
	var item_data := item.get_data()
	var boosts: Dictionary = item_data.get("boost", {})
	if requested_stat:
		return item_data.get(requested_stat, item_data.get("boost", {}).get(requested_stat, 0))
	for stat in boosts:
		if boosts.get(stat, 0) > 0:
			return boosts[stat]
	for recover in ["PPrecover", "HPrecover"]:
		if item_data.get(recover, 0) > 0:
			return item_data[recover]
	return 0

static func get_skill_level(skill: Dictionary) -> String:
	if skill.has("level") and skill.get("skill_type") == "psi":
		var skill_level = int(skill["level"])
		if skill_level in range(0, PSI_LEVELS.length()):
			return _tr("BATTLE_LETTER_SPACING").format(["", PSI_LEVELS[skill_level]])
	return ""

static func get_inline_stat_name(stat: String) -> String:
	return _tr("INLINE_STAT_%s" % stat.to_upper())

static func get_inline_stat_articles(stat: String, article_idx: int = -1):
	var article_str = _tr("INLINE_STAT_%s_ARTICLE" % stat.to_upper())
	var article_array = article_str.split(",")

	if article_idx == -1:
		return Array(article_array)
	else:
		return article_array[article_idx]

static func get_and_cunjunction(before: String, after: String, lang_code := "") -> String:
	before = before.strip_edges().to_lower()
	after = after.strip_edges().to_lower()
	before = before[-1] if before else ""
	after = after[0] if after else ""
	lang_code = lang_code if lang_code != "" else _tr("LANGUAGE_CODE")
	match lang_code:
		"it":
			return "ed" if after == "e" else "e"
		"es", "es_ES":
			return "e" if after == "i" else "y"
		"uk":
			var vowels = "аеєиіїоуюя"
			if before in vowels:
				return "і" if after in "йєїюя" else "й"
			else:
				return "й" if after in vowels else "і"
		_:
			return ""

static func get_number_articles(number: int, article_idx: int = -1):
	var article_array := _tr("ARTICLES_NUMBERS").split(",")

	for i in article_array.size():
		article_array[i] = article_array[i].format([number])
		article_array[i] = replace_text(article_array[i])
		
	if article_idx == -1:
		return Array(article_array)
	elif article_idx < article_array.size():
		return article_array[article_idx]
	else:
		return ""

static func _get_plural_number_suffix(number: int, singular: String, plural: String) -> String:
	return plural if number >= 2 else singular

static func _get_slavic_number_suffix(number: int, sing_suffix: String, paucal_suffix: String, plural_suffix: String, is_strict_singular := false) -> String:
	var units := number % 10
	var tens := (number % 100) / 10

	if units == 1 and tens != 1 and (!is_strict_singular or number == 1):
		return sing_suffix
	elif units in [2, 3, 4] and tens != 1:
		return paucal_suffix
	else:
		return plural_suffix

static func _get_japanese_number_suffix(number: int, general: String, alt: String, three := "", one := "", two := "", eight := "") -> String:
	var units := number % 10

	var exceptions_dict := { 1: one, 2: two, 3: three, 8: eight}
	for i in exceptions_dict:
		if exceptions_dict[i] and units == i:
			return exceptions_dict[i]

	if units in [1, 3, 6, 8, 0]:
		return alt

	return general

static func _get_french_elision(next_word: String) -> String:
	var vowels := "aeiouáàâäæéèêëíìîïóòôöœúùûü"
	return "'" if next_word and next_word[0].to_lower() in vowels else "e "

static func _get_german_genitive(name: String) -> String:
	return "%s'" % name if name.ends_with("s") or name.ends_with("x") else "%ss" % name

static func _get_custom_name_declension(name: String, gender: String, case: int, lang_code := "") -> String:
	if !name: return ""
	lang_code = lang_code if lang_code != "" else _tr("LANGUAGE_CODE")
	var lang_class = {"pl": PolishDeclension, "ru": RussianDeclension, "uk": UkrainianDeclension}.get(lang_code, null)
	if !lang_class: return name
	var is_all_caps := (name == name.to_upper())
	var declined_name = lang_class.decline_name(name, gender, case)
	
	return declined_name.to_upper() if is_all_caps else declined_name

static func _get_korean_particle(prevWord: String, type: int):
	return ["는", "가", "를", "와", "로"][type] if KoreanHangul.ends_with_vowel(prevWord, type == 4) else ["은", "이", "을", "과", "으로"][type]

static func get_item_doses_phrase(item: Item) -> String:
	var nb_uses: int = item.get_data().get("doses", 1)
	var csv_key := "INVENTORY_ITEM_USES_TOTAL"

	if nb_uses <= 1:
		return ""
	
	if item.doses in range(0, nb_uses):
		nb_uses = item.doses
		csv_key = "INVENTORY_ITEM_USES_LEFT"
		
	return format_text_with_context(csv_key, null, {}, nb_uses)

static func get_key_name(key: String, device: int = globaldata.device) -> String:
	
	
	if (InputMap.get_action_list(key).size() > 1):
		match device:
			globaldata.KEYBOARD:
				for event in InputMap.get_action_list(key):
					if (event is InputEventKey):
						return get_key_name_from_event(event)
			globaldata.GAMEPAD:
					for event in InputMap.get_action_list(key):
						if (event is InputEventJoypadButton)\
						or (event is InputEventJoypadMotion):
							return get_key_name_from_event(event)
	
	
	elif (InputMap.get_action_list(key).size() == 1):
		return get_key_name_from_event(InputMap.get_action_list(key)[0])
	return ""

static func get_key_name_from_event(event) -> String:
	if event is InputEventKey:
		return get_key_from_scancode(event.scancode)
	elif event is InputEventJoypadButton:
		return _get_button_name(Input.get_joy_button_string(event.button_index))
	#elif event is InputEventJoypadMotion:
	else:
		return ""

static func get_key_from_scancode(scancode) -> String:
	if scancode in SPECIAL_KEY_LABELS:
		return _tr(SPECIAL_KEY_LABELS[scancode])
	
	elif OS.is_scancode_unicode(scancode):
		return "" if char(scancode) in "            ​  　﻿\t" else char(scancode) # Filtering out non-printable characters

	elif scancode in globaldata.ALLOWED_KEYS:
		var key_str = OS.get_scancode_string(scancode)
		var key_translated = _tr("KEYBOARD_" + key_str.to_upper().replace(" ", "_"))
		return key_str if key_translated.begins_with("KEYBOARD_") else key_translated
	return ""

static func _get_button_name(button_string) -> String:
	var current_style = globaldata.buttons_style
	if current_style == globaldata.BtnStyles.DETECT:
		current_style = global.detect_buttons_style()
	match button_string:
		"Face Button Bottom":
			return "B✖A"[current_style]
		"Face Button Left":
			return "Y■X"[current_style]
		"Face Button Right":
			return "A●B"[current_style]
		"Face Button Top":
			return "X▲Y"[current_style]
		"DPAD Up":
			return "↑"
		"DPAD Down":
			return "↓"
		"DPAD Left":
			return "←"
		"DPAD Right":
			return "→"
		"L":
			return ["L", "L", "LB"][current_style]
		"R":
			return ["R", "R", "RB"][current_style]
		"L2":
			return ["ZL", "L2", "LT"][current_style]
		"R2":
			return ["ZR", "R2", "RT"][current_style]
		"L3":
			return ["LS", "L3", "L3"][current_style]
		"R3":
			return ["RS", "R3", "R3"][current_style]
		"Select":
			return ["-", "Share", "Back"][current_style]
		"Start":
			return ["+", "Optns", "Start"][current_style]
		_:
			return(button_string.replace(" ", "").substr(0, 6))

static func format_text_with_context(text: String, target: PartyMember = null, item_or_skill := {}, value := 0, stat := "") -> String:
	var target_name := target.get_nickname() if target else ""
	var target_articles = get_battler_articles(target) if target else []
	var item_or_skill_name := _tr(item_or_skill.get("name", ""))
	var item_or_skill_articles = get_item_or_skill_articles(item_or_skill) if item_or_skill else []
	var skill_level := get_skill_level(item_or_skill) if item_or_skill else ""
	var stat_name := get_inline_stat_name(stat) if stat else ""
	var stat_articles = get_inline_stat_articles(stat) if stat else []

	return _apply_text_substitutions(_tr(text)).format({
		"target": target_name,
		"item": item_or_skill_name,
		"skill":item_or_skill_name,
		"skillLevel": skill_level,
		"stat": stat_name,
		"value": value
		}).format(
			target_articles, "{t_}"
		).format(
			item_or_skill_articles, "{i_}"
		).format(
			item_or_skill_articles, "{s_}"
		).format(
			stat_articles, "{st_}"
		).format(
			get_number_articles(value), "{v_}"
		)
	
static func add_line_breaks(phrase: String, container: Control) -> String:
	var max_length: float = container.rect_size.x
	var font: Font = container.get_font("normal_font")
	var sep := _tr("WORD_SEPARATOR")
	var result := ""
	var existing_segments := phrase.split("\n")
	for segment in existing_segments:
		var words := (segment as String).split(sep)
		var result_line := ""
		if words.size() > 0:
			result_line += words[0]
			for i in range(1, words.size()):
				if font.get_string_size(strip_bbcode(result_line + sep + words[i])).x > max_length:
					result += ("\n" if result != "" else "") + result_line
					result_line = ""
				else:
					result_line += sep
				result_line += words[i]
		if result_line != "":
			result += ("\n" if result != "" else "") + result_line
	return result

static func strip_bbcode(source: String) -> String:
	var img_regex = RegEx.new()
	img_regex.compile("\\[img.*?\\].*?\\[/img\\]")
	var ret = img_regex.sub(source, "——", true)
	var regex = RegEx.new()
	regex.compile("\\[(\\/?(b|i|u|s|code|center|right|fill|indent|url|font|color|table|cell)(=[^\\]]+)?)\\]")
	ret = regex.sub(ret, "", true)
	return ret

static func get_text_delay(amount: float) -> String:
	return CHAR_DELAY.repeat(int(amount / (globaldata.text_speed * 16)))

static func _tr(message) -> String:
	return TranslationServer.translate(message)

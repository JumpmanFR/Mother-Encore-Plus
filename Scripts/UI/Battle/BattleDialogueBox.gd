extends AbstractDialogueBox

signal done

const AUTO_ADVANCE_DELAY := 1.25

var _method_target = self

var _use_battle_context := false
var _is_waiting_between_phrases := false

class FormatContext:
	var actor = null
	var targets: = []
	var item_or_skill: = {}
	var value: = 0
	var stat: = ""

	func set_actor(actor):
		self.actor = actor
		return self
	
	func set_targets(targets):
		self.targets = targets
		return self
	
	func set_item_or_skill(item_or_skill):
		self.item_or_skill = item_or_skill
		return self
	
	func set_value(value):
		self.value = value
		return self
	
	func set_stat(stat):
		self.stat = stat
		return self
	
	func reset():
		self.actor = null
		self.targets = []
		self.item_or_skill = {}
		self.value = 0
		self.stat = ""

func _ready():
	_dialogue_box_node = $Dialoguebox
	_dialogue_label = $Dialoguebox / ClipBox / HBoxContainer / Dialogue
	_bullet_label = $Dialoguebox / ClipBox / HBoxContainer / DippinDots
	_cursor_down_sprite = $Dialoguebox / Cursor_Down
	_dialogue_label.bbcode_text = ""
	_bullet_label.bbcode_text = ""
	_show_box(false, false)

func start_from_string(dialog_string: String):
	yield(start_from_array([dialog_string]), "completed")

func start_from_array(dialog_array: Array):
	var dialog := {}
	for i in dialog_array.size():
		dialog[str(i)] = {"text": TextTools.add_line_breaks(dialog_array[i], _dialogue_label)}
		if i < dialog_array.size() - 1:
			dialog[str(i)].goto = str(i + 1)
	yield(start_from_scripted_dialog(dialog), "completed")

func append(dialog_string: String, sfx := ""):
	var new_entry := {"text": TextTools.add_line_breaks(dialog_string, _dialogue_label)}
	if sfx:
		new_entry["soundeffect"] = sfx
	var latest_idx := - 1
	for idx in _dialog.keys():
		if int(idx) > latest_idx:
			latest_idx = int(idx)
	if latest_idx > - 1:
		_dialog[str(latest_idx)]["goto"] = str(latest_idx + 1)
	_dialog[str(latest_idx + 1)] = new_entry

func start_from_appended():
	if _dialog:
		yield(start_from_scripted_dialog(_dialog), "completed")
	else:
		call_deferred("_end_dialogue")
		yield(self, "done")

# Override
func start_from_scripted_dialog(dialog := {}, is_battle_msg := true, is_spoken := false):
	_use_battle_context = is_battle_msg
	$AnimationPlayer.play("RESET")
	_reset()
	_show_box(true)
	_bullet_label.visible = is_spoken
	if dialog:
		_dialog = dialog
	
	_dialogue_label.visible_characters = 0
	_handle_phrase()
	yield(self, "done")

# Override
func _handle_phrase():
	$Dialoguebox / Arrow.position = Vector2(104, 43)
	_curr_phrase = _dialog[str(_phrase_num)]
	
	_finished = false
	_speed_multiplier_from_input = 1
	_speed_multiplier_from_tags = 1

	if _phrase_num == "0":
		_dialogue_label.remove_line(1)
		_bullet_label.remove_line(1)

	if _curr_phrase.get("text", "") != "":
		if !_use_battle_context:
			_curr_phrase["text"] = TextTools.replace_text(_curr_phrase["text"])
		_curr_phrase["text"] = TextTools.add_line_breaks(_curr_phrase["text"], _dialogue_label)
		_print_dialogue_segment(true)
	
	# Parse Commands
	if _curr_phrase.has("commands"):
		for command in _curr_phrase["commands"]:
			if _method_target.has_method(command.method):
				_method_target.call(command.method, command.param)
	
	if _curr_phrase.has("font"):
		if _curr_phrase["font"] == "EBZ":
			_dialogue_label.add_font_override("font", load("res://Fonts/saturn.tres"))
			_bullet_label.add_font_override("font", load("res://Fonts/saturn.tres"))
	
	if _curr_phrase.has("soundeffect"):
		if !_curr_phrase["soundeffect"].begins_with("res://"):
			_curr_phrase["soundeffect"] = "res://Audio/Sound effects/" + _curr_phrase["soundeffect"]
		$SoundEffect.stream = load(_curr_phrase["soundeffect"])
		$SoundEffect.play()
	
	if _curr_phrase.get("sound", null):
		if !_curr_phrase["sound"].begins_with("res://"):
			_curr_phrase["sound"] = "res://Audio/Sound effects/text/" + _curr_phrase["sound"]
		$AudioStreamPlayer.stream = load(_curr_phrase["sound"] + ".mp3")
	else:
		$AudioStreamPlayer.stream = null

func _finish_phrase():
	_t = 0
	_finished = true
	_cursor_down_sprite.show()
	if _auto_advance:
		_is_waiting_between_phrases = true
		yield(get_tree().create_timer(AUTO_ADVANCE_DELAY), "timeout")
		_is_waiting_between_phrases = false
		_next_phrase()

func did_finish() -> bool:
	return _finished

# Override
func _action_press(btn_next := false, btn_cancel := false):
	if !_is_waiting_between_phrases:
		._action_press(btn_next, btn_cancel)

func _reset():
	_dialog = {}
	_finished = true
	_t = 0
	_phrase_num = "0"
	_segment_num = 0
	_curr_phrase = {}
	_dialogue_label.bbcode_text = ""
	_bullet_label.bbcode_text = ""
	_method_target = self

# Override
func _end_dialogue():
	get_tree().set_input_as_handled()
	_show_box(false)
	_reset()
	emit_signal("done")

func play_win():
	$Dialoguebox / ClipBox / HBoxContainer.hide()
	_dialogue_box_node.show()
	$AnimationPlayer.play("YouWin")
	yield(get_tree().create_timer(3), "timeout")

# Handle formatting of battlers, items and articles in battle text
# {name} is the actor's name, {target} is the target's name, {item} is the item name
# {n0}, {n1}, etc. are the articles for {name}
# {t0}, {t1}, etc. are the articles for the {target}
# {i0}, {i1}, etc. are the articles for the {item}
# {s0}, {s1}, etc. are the articles for {skill}
# {st0}, {st1}, etc. are the articles for {stat}
# {v0}, {v1}, etc. are the articles for {value}
# See list of articles (which also include pronouns and suffixes) in articles.txt
# Just use these tags in your strings this way and this method will format them
func format_battle_text(text: String, context: FormatContext) -> String:
	var actor_name = ""
	var actor_articles = []
	if context.actor:
		if context.actor is BattleParticipant:
			actor_name = context.actor.get_name()
			actor_articles = TextTools.get_battler_articles(context.actor.character, - 1, context.actor.get_name())
		elif context.actor is PartyMember:
			actor_name = TextTools.replace_text(context.actor.get_nickname())
			actor_articles = TextTools.get_battler_articles(context.actor)
	
	var target_name = ""
	var target_articles = []
	if (context.targets.size() == 1):
		if context.targets[0] is BattleParticipant:
			target_name = context.targets[0].get_name()
			target_articles = TextTools.get_battler_articles(context.targets[0].character, - 1, context.targets[0].get_name())
		elif context.targets[0] is Enemy:
			target_name = tr(context.targets[0].get_id().to_upper() + "_NAME")
			target_articles = TextTools.get_battler_articles(context.targets[0], - 1, context.targets[0].get_name())
	elif (context.targets.size() > 1):
		if context.targets[0].is_type(Character.Type.ENEMY):
			target_name = "BATTLE_NAME_ENEMIES"
			target_articles = "BATTLE_NAME_ENEMIES_ART"
		else:
			target_name = "BATTLE_NAME_ALLIES"
			target_articles = "BATTLE_NAME_ALLIES_ART"
		target_name = format_battle_text(target_name, FormatContext.new().set_targets([context.targets[0]]))
		target_articles = Array(tr(target_articles).split(","))
		for i in target_articles.size():
			target_articles[i] = format_battle_text(target_articles[i], FormatContext.new().set_targets([context.targets[0]]))
	
	var ret: = tr(text).format({
		"name": tr(actor_name), 
		"target": target_name, 
		"delay": TextTools.get_text_delay(5), 
		"wait": TextTools.CHAR_WAIT, 
		"and": TextTools.get_and_cunjunction(actor_name, target_name)
		}).format(
			actor_articles, "{n_}"
		).format(
			target_articles, "{t_}"
		)
	
	ret = TextTools.format_text_with_context(ret, null, context.item_or_skill, context.value, context.stat)
	
	ret = TextTools.replace_text(ret)
	
	context.reset()
	return ret

func start_from_formatted(dialog_string: String, context: FormatContext):
	yield(start_from_array([format_battle_text(dialog_string, context)]), "completed")

func append_formatted(dialog_string: String, context: FormatContext, sfx: = ""):
	append(format_battle_text(dialog_string, context), sfx)

extends CanvasLayer

signal back

var _psi_sounds = {
	"lifeup_a": load("res://Audio/Sound effects/EB/heal 1.wav"),
	"healing_a": load("res://Audio/Sound effects/EB/heal.wav"),
}


var _current_character: PartyMember
var active := false
var _desc_active := false
var _skill := {}
var _messages_stack := []

onready var _psi_select = $PSIMenu/PSISelect
onready var _desc_label = $PSIMenu/Description/Desc
onready var _character_tab = $PSIMenu/PSICharacterTab

func _ready():
	_reset_current_character()
	$PSIMenu.hide()
	_character_tab.show()
	_update_desc_label("")
	_psi_select.connect("selected", self, "_on_who")
	_psi_select.connect("use", self, "_use_skill")
	_psi_select.connect("using_skill_failed", self, "_use_skill_failed")
	_psi_select.connect("moved", self, "_update_psi_description")
	_psi_select.set_PP_visible(false, false)
	$PSIMenu/TargetCharacterMenu.connect("back", self, "_on_psi_cancel")
	$PSIMenu/TargetCharacterMenu.connect("next", self, "_on_psi_target_confirmed")

func open():
	_reset_current_character()
	active = true
	audioManager.play_sfx_by_name("menu_open", "menu_open")
	$AnimationPlayer.play("Open")
	_update_psi_box()
	uiManager.info_plates_update()
	_psi_select.set_active(true)

func _close(silent := false):
	_psi_select.set_active(false)
	_character_tab.active = false
	active = false
	if !silent: audioManager.play_sfx_by_name("menu_close", "menu_close")
	$AnimationPlayer.play("Close")
	emit_signal("back")

func _input(event: InputEvent):
	if active:
		if Input.is_action_just_pressed("ui_cancel"):
			get_tree().set_input_as_handled()
			Input.action_release("ui_cancel")
			_close()
	elif _desc_active:
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel"):
			if _messages_stack.empty():
				Input.action_release("ui_accept")
				Input.action_release("ui_cancel")
				_desc_active = false
				active = true
				_on_psi_cancel()
				_update_psi_description(_skill)

func _reset_current_character():
	for member in global.get_party_in_natural_order():
		if member.get_stat(Character.MAXPP) > 0:
			_current_character = member
			break

func _update_psi_box():
	# kind of a hack, since im stealing this menu from battle system
	_character_tab.init_from_character(_current_character.get_name())
	_psi_select.set_active(false)
	_psi_select.user = _current_character
	_psi_select.update_skills(_current_character.get_learned_skills())
	_psi_select.set_active(true)
	if _psi_select.is_empty():
		_update_desc_label("")
#	psiBox.exit()
#	psiBox.enter({"user": {"stats": _current_character}})

func _use_skill(selected_skill):
	_skill = selected_skill

	Input.action_release("ui_accept")

	_current_character.set_pp(_current_character.get_pp() - _skill.get("pp_cost", 0))
	_psi_select.refresh_selectable()

	if _skill.id == globaldata.SKILL_TELEPATHY:
		
		_close(true)
		uiManager.close_commands_menu(false, false, true)
		global.get_player().use_telepathy()
	elif _skill.id == globaldata.SKILL_TELEPORT_A:
		_close(true)
		uiManager.close_commands_menu(false, true, true)
		global.get_player().start_teleport(int(_skill.level))

func _use_skill_failed(selected_skill):
	_desc_active = true
	active = false
	_psi_select.set_active(false)
	if _current_character.has_status("forgetful"):
		_update_desc_label("Ninten forgot how to use PSI moves!")
	else: _update_desc_label("PSI_PP_NOTENOUGH")

func _on_who(selected_skill: Dictionary):
	Input.action_release("ui_accept")
#	_skill = psiBox.action.skill
	_skill = selected_skill
	# get all current party member names
	var char_list := []
	match(int(_skill.target_type)):
		BattleSystem.TargetType.SELF:
			char_list = [_current_character.get_name()]
		BattleSystem.TargetType.ALL_ALLIES:
			char_list = ["all"]
		_:
			for mem_name in global.POSSIBLE_PLAYABLE_MEMBERS:
				var party_mem: PartyMember = globaldata.characters[mem_name]
				if party_mem in global.party and _can_skill_target(party_mem):
					char_list.append(party_mem.get_name())
	$PSIMenu/TargetCharacterMenu.show_target_chara_select(_psi_select.cursor.global_position, char_list)
	active = false
#	psiBox.cursor2.on = false
	_character_tab.active = false
	_psi_select.set_active(false)

func _on_psi_cancel(someVar = null):
	uiManager.info_plates_highlight([])
	active = true
#	psiBox.cursor2.on = true
	_character_tab.active = true
	_psi_select.set_active(true)

func _on_psi_target_confirmed(menu_target):
	uiManager.info_plates_highlight([])
	# TODO: Check for if a character is either full hp or no status ailments
	# do skill stuff
	# first, handle pp:
	_current_character.set_pp(_current_character.get_pp() - _skill.get("pp_cost", 0))

	_psi_select.refresh_selectable()
	
	# Whos targeted?
	var targets := []
	for character in global.party:
		if menu_target == character.get_name() or\
		(menu_target == "all" and _can_skill_target(character)):
			targets.append(character)
	
	for target in targets:
		_desc_active = true
		if _skill.action_type == 1:
			play_sfx("lifeup_a")
			var old_hp := target.get_hp() as int
			var new_hp := old_hp + _calculate_heal_value(_skill, target)
			target.set_hp(new_hp)
			var diff := new_hp - old_hp
			if new_hp >= target.get_stat(Character.MAXHP):
				_messages_stack.push_front(TextTools.format_text_with_context("ACTION_RESULT_HP_MAX", target))
			else:
				_messages_stack.push_front(TextTools.format_text_with_context("ACTION_RESULT_HP_UP", target, {}, diff))
		elif !_skill.get("status_heals", []).empty():
			var status_heals = _skill.get("status_heals", [])
			if status_heals.has("all"): status_heals = ["asthma", "blinded", "burned", "cold", "confused", "forgetful", "mushroomized", "nausea", "numb", "poisoned", "sleeping", "stone", "sunstroked", "unconscious"]
			play_sfx("healing_a")
			var heals_performed := []
			var was_unconscious := target.is_unconscious() as bool
			for status in status_heals:
				if target.has_status(status):
					heals_performed.append(status)
					target.remove_status(status)
					var heal_amount = _skill.get("status_amount_healed", -1)
					if heal_amount > 0 and heals_performed.size() >= heal_amount:
						break
			if was_unconscious and !target.is_unconscious():
				if _skill.get("heal_on_revive", false):
					var old_hp := target.get_hp() as int
					var new_hp := old_hp + _calculate_heal_value(_skill, target)
					target.set_hp(new_hp)
			if heals_performed.size() == 1 or target.has_any_status():
				for heal_performed in heals_performed:
					_messages_stack.push_front(TextTools.format_text_with_context(Status.get_status_message(heal_performed, "heal_overworld"), target))
			else:
				_messages_stack.push_front(TextTools.format_text_with_context("ACTION_RESULT_HEAL_ALL", target))

		uiManager.info_plates_update()

	_process_messages()


func _calculate_heal_value(skill: Dictionary, target: PartyMember) -> int:
	var spec_value := skill.get("damage_or_heal", 0) as int
	var value_type := skill.get("value_type", "normal") as String
	var variance := skill.get("variance", 0) as int
	var val: float
	match value_type:
		"fixed":
			val = floor(spec_value + (randf() * variance) - variance/2.0)
		"percentage":
			val = spec_value * target.get_hp() / 100.0
			val = floor(val + (randf() * variance) - variance/2.0)
		"reach_full_percent": # Reach for a specific percentage of max HP
			var max_hp := target.get_stat(Character.MAXHP)
			var value_to_reach := spec_value * max_hp / 100.0
			val = value_to_reach - target.get_hp()
			val = floor(val + (randf() * variance) - variance/2.0)
		"normal", "guts_based":
			val = int(spec_value)
			if value_type == "guts_based":
				val += _current_character.get_stat(Character.GUTS) / 2
			elif skill.skill_type == "psi":
				val += _current_character.get_stat(Character.IQ) / 5
			
			val = floor(val + (randf() * variance) - variance/2.0)
	
	if val <= 0:
		return 0
	else:
		val = max(1, round(val))
		return int(val)
	

func _has_trait(trait: String, skill) -> bool:
	return skill.get("traits", []).has(trait)


func _process_messages():
	if _messages_stack.empty():
		return
	var message = _messages_stack.pop_back()
	_update_desc_label(message)
	yield(get_tree().create_timer(0.5), "timeout")
	_process_messages()

func _on_PSICharacterTab_character_changed(char_name: String):
	if active:
		for member in global.party:
			if member.get_name() == char_name:
				_current_character = member
				_update_psi_box()

func _on_TargetCharacterMenu_show_statsbar(char_name: String):
	if char_name == "all":
		var targets := []
		for char_name in global.POSSIBLE_PLAYABLE_MEMBERS:
			if _can_skill_target(globaldata.characters[char_name]):
				targets.append(char_name)
		uiManager.info_plates_highlight(targets)
	else:
		uiManager.info_plates_highlight([char_name])

func _update_psi_description(newSkill):
	_psi_select.set_PP_visible(true, false)
	if newSkill:
		_update_desc_label(tr(newSkill.description))
	else:
		_update_desc_label("missing description")

func _update_desc_label(text):
	var font = _desc_label.get_font("font")
	_desc_label.autowrap = (font.get_string_size(text).x > _desc_label.get_parent_area_size().x)
	if _desc_label.autowrap:
		var line_height = font.get_wordwrap_string_size(text, _desc_label.rect_size.x).y
		if line_height > font.get_height():
			_psi_select.linesPerPage = 3
		else:
			_psi_select.linesPerPage = 4
	else:
		_psi_select.linesPerPage = 4
	_desc_label.text = text

func _can_skill_target(character: Character):
	var target_unconscious = _has_trait("target_unconscious", _skill)
	var target_incapacitated = _has_trait("target_incapacitated", _skill)
	return ( !character.is_unconscious() or target_unconscious) and \
	( !character.is_incapacitated() or target_incapacitated)

func play_sfx(sfx_name, channel := 0):
	if !_psi_sounds.has(sfx_name):
		return
	audioManager.play_sfx(_psi_sounds[sfx_name], "PSIMenu" + str(channel))

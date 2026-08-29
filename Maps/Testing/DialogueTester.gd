extends Control

var DialogueBoxRes := preload("res://Nodes/Ui/DialogueBox.tscn")

const MAX_PARTY_SIZE := 4
const NB_SAVES := 10

const VOICE_SFXS = ["Adult", "Kid", "Robot", "Sexy", "Shy", "Strange", ""]

var _keyboard_shortcuts := {
	"ok": [
		{ "key": KEY_ENTER, "modifiers": ["control"], "button": "ButtonOK" }
	],
	"options": [
		{ "key": KEY_ESCAPE, "button": "ButtonOptions" },
		{ "key": KEY_COMMA, "modifiers": ["control"], "button": "ButtonOptions" },
		{ "key": KEY_ENTER, "modifiers": ["alt"], "mac_remap": false , "button": "ButtonOptions"},
		{ "key": KEY_I, "modifiers": ["meta"], "button": "ButtonOptions" }
	],
	"copy": [
		{ "key": KEY_C, "modifiers": ["control", "shift"], "button": "ButtonCopy" }
	],
	"party_size": [
		{ "key": KEY_UP, "modifiers": ["control", "alt"], "params": [1], "button": "ButtonPartyIncr" },
		{ "key": KEY_PLUS, "modifiers": ["control"], "params": [1], "button": "ButtonPartyIncr"  },
		{ "key": KEY_DOWN, "modifiers": ["control", "alt"], "params": [-1], "button": "ButtonPartyDecr"  },
		{ "key": KEY_MINUS, "modifiers": ["control"], "params": [-1], "button": "ButtonPartyDecr"  }
	],
	"switch_lead": [
		{ "key": KEY_LEFT, "modifiers": ["control", "alt"], "params": [1], "button": "ButtonLeadLeft" },
		{ "key": KEY_RIGHT, "modifiers": ["control", "alt"], "params": [-1], "button": "ButtonLeadRight" }
	],
	"rename_member": [
		{ "key": KEY_1, "modifiers": ["control"], "physical": true, "params": [0], "button": "Leader" },
		{ "key": KEY_2, "modifiers": ["control"], "physical": true, "params": [1], "button": "Follower1" },
		{ "key": KEY_3, "modifiers": ["control"], "physical": true, "params": [2], "button": "Follower2" },
		{ "key": KEY_4, "modifiers": ["control"], "physical": true, "params": [3], "button": "Follower3" },
		{ "key": KEY_P, "modifiers": ["control"], "params": ["playerName"], "button": "Player" },
		{ "key": KEY_F, "modifiers": ["control"], "params": ["favoriteFood"], "button": "FavFood" }
	],
	"insert_tag": [
		{ "key": KEY_1, "modifiers": ["control", "alt"], "physical": true, "params": [0], "button": "Leader" },
		{ "key": KEY_1, "modifiers": ["control", "shift"], "physical": true, "params": [0], "button": "Leader" },
		{ "key": KEY_2, "modifiers": ["control", "alt"], "physical": true, "params": [1], "button": "Follower1" },
		{ "key": KEY_2, "modifiers": ["control", "shift"], "physical": true, "params": [1], "button": "Follower1" },
		{ "key": KEY_3, "modifiers": ["control", "alt"], "physical": true, "params": [2], "button": "Follower2" },
		{ "key": KEY_3, "modifiers": ["control", "shift"], "physical": true, "params": [2], "button": "Follower2" },
		{ "key": KEY_4, "modifiers": ["control", "alt"], "physical": true, "params": [3], "button": "Follower3" },
		{ "key": KEY_4, "modifiers": ["control", "shift"], "physical": true, "params": [3], "button": "Follower3" },
		{ "key": KEY_P, "modifiers": ["control", "alt"], "params": ["PlayerName"], "button": "Player" },
		{ "key": KEY_P, "modifiers": ["control", "shift"], "params": ["PlayerName"], "button": "Player" },
		{ "key": KEY_F, "modifiers": ["control", "alt"], "params": ["FavFood"], "button": "FavFood" },
		{ "key": KEY_F, "modifiers": ["control", "shift"], "params": ["FavFood"], "button": "FavFood" },
		{ "key": KEY_G, "modifiers": ["control", "alt"], "params": ["ui_"], "button": "GamePad" },
		{ "key": KEY_G, "modifiers": ["control", "shift"], "params": ["ui_"], "button": "GamePad" },
		{ "key": KEY_K, "modifiers": ["control", "alt"], "params": ["ui_"], "button": "Keyboard" },
		{ "key": KEY_K, "modifiers": ["control", "shift"], "params": ["ui_"], "button": "Keyboard" }
	],
	"toggle_input_device": [
		{ "key": KEY_G, "modifiers": ["control"], "params": [true], "button": "GamePad" },
		{ "key": KEY_K, "modifiers": ["control"], "params": [false], "button": "Keyboard" }
	],
	"toggle_saturn_font": [
		{ "key": KEY_S, "modifiers": ["control", "alt"], "button": "Saturn"},
		{ "key": KEY_S, "modifiers": ["control", "shift"], "button": "Saturn"}
	],
	"load_open": [
		{ "key": KEY_L, "modifiers": ["control"], "button": "LoadButton" }
	],
	"save": [
		{ "key": KEY_S, "modifiers": ["control"], "button": "SaveButton" }
	]
}

export (Array, NodePath) var _all_buttons := []

var _edit_mode := true
var _rename_mode := false
var _save_select_mode := false
var _dialogue_box
var _saved_inputs := {}
var _btn_styles := {}
var _current_save_index := 0
var _longest_names_mode := false
var _selected_input_device = null
var _current_save = null
var _is_saturn_font := false

onready var _tools := DialogueTestingTools.new($TextEdit.get_font("normal"))

func _ready():
	global.get_player().pause()
	global.currentCamera.anchor_mode = 0
	_btn_styles["normal"] = $ButtonOptions.get_stylebox("normal")
	_btn_styles["disabled"] = $ButtonOptions.get_stylebox("disabled")
	$TextEdit.cursor_set_column($TextEdit.text.length())
	_refresh_navigation()
	global.connect("locale_changed", self, "_on_locale_changed")
	global.connect("party_changed", self, "_refresh_party_icons")
	$OptionsUI.connect("back", self, "_on_options_done")
	$Save/LoadButton.get_popup().connect("id_pressed", self, "_on_save_selected")
	$Save/LoadButton.get_popup().connect("popup_hide", self, "_on_close_save_select")
	_refresh_party_icons()
	_refresh_save_list()

func _refresh_save_list():
	$Save/LoadButton.get_popup().clear()
	for i in range(1, NB_SAVES + 1):
		$Save/LoadButton.get_popup().add_item("#%d" % i)
		$Save/LoadButton.get_popup().set_item_metadata(i - 1, i)
	$Save/LoadButton.get_popup().add_item("Longest names")
	$Save/LoadButton.get_popup().set_item_metadata(NB_SAVES, "longest")
	_refresh_save_buttons()

func _refresh_navigation():
	if _edit_mode and !_rename_mode:
		# Unlocking the UI
		_refresh_game_controls()
		$TextEdit.focus_mode = Control.FOCUS_CLICK
		$TextEdit.readonly = false
		$TextEdit.grab_focus()
		for node_path in _all_buttons:
			var button = get_node(node_path)
			if button in [$ButtonOK, $ButtonCopy]:
				button.disabled = !$TextEdit.text
			elif button == $Save/SaveButton:
				button.disabled = !_current_save_index
			else:
				button.disabled = false
	else:
		# Locking the UI while the dialogue box is open
		$TextEdit.focus_mode = Control.FOCUS_NONE
		$TextEdit.readonly = true
		for node_path in _all_buttons:
			get_node(node_path).disabled = true
		_refresh_game_controls()
	_refresh_texture_buttons_visuals()

func _refresh_party_icons():
	var node_char_icons = $PartyPrefs/Members
	for i in node_char_icons.get_child_count():
		var node = node_char_icons.get_child(i)
		if i < global.party.size():
			node.show()
			node.texture_normal = load("res://Graphics/UI/Inventory/characters/%s.png" % global.party[i].get_name())
			node.texture_pressed = load("res://Graphics/UI/Inventory/characters/%s_hl.png" % global.party[i].get_name())
			node.texture_hover = load("res://Graphics/UI/Inventory/characters/%s_gr.png" % global.party[i].get_name())
		else:
			node.hide()
	$PartyPrefs/ButtonPartyDecr.disabled = (global.party.size() <= 1)
	$PartyPrefs/ButtonPartyIncr.disabled = (global.party.size() >= MAX_PARTY_SIZE)

func _refresh_controls_icons():
	yield(get_tree(), "idle_frame")
	$InputPrefs/GamePad.set_pressed_no_signal(_selected_input_device == globaldata.GAMEPAD)
	$InputPrefs/Keyboard.set_pressed_no_signal(_selected_input_device == globaldata.KEYBOARD)

func _refresh_saturn_icon():
	yield(get_tree(), "idle_frame")
	$Saturn.set_pressed_no_signal(_is_saturn_font)

func _refresh_save_buttons():
	if _current_save_index:
		$Save/LoadButton.text = "Loaded (#%s)" % _current_save_index
		$Save/SaveButton.text = "%s → #%s" % [tr("MENU_SAVE"), _current_save_index]
	else:
		if _longest_names_mode:
			$Save/LoadButton.text = "Loaded (longest)"
		else:
			$Save/LoadButton.text = "%s..." % tr("MENU_LOAD")
		$Save/SaveButton.text = "MENU_SAVE"
	_refresh_navigation()

func _refresh_longest_names():
	globaldata.playerName = tr("LONGEST_POSSIBLE_PLAYER_NAME")
	globaldata.favoriteFood = tr("LONGEST_POSSIBLE_FOOD")
	for chara_name in global.POSSIBLE_PLAYABLE_MEMBERS:
		globaldata.characters.get(chara_name).set_nickname(tr("LONGEST_POSSIBLE_NAME"))

func _refresh_game_controls():
	if _edit_mode or _rename_mode:
		# Disable all game controls
		if !_saved_inputs:
			for action in InputMap.get_actions():
				_saved_inputs[action] = InputMap.get_action_list(action)
				InputMap.action_erase_events(action)
	else:
		# Restore all game controls
		if _saved_inputs:
			for action in _saved_inputs.keys():
				for event in _saved_inputs[action]:
					InputMap.action_add_event(action, event)
			_saved_inputs.clear()

func _refresh_popup_button():
	$RenameDialog.get_ok().disabled = $RenameDialog/LineEdit.text == ""

func _refresh_texture_buttons_visuals():
	for node_path in _all_buttons:
		var button = get_node(node_path)
		if button is TextureButton:
			button.modulate = Color(1, 1, 1, .4 if button.disabled else 1.0)

func _on_action_ok():
	if $TextEdit.text:
		_dialogue_box = DialogueBoxRes.instance()
		uiManager.add_ui(_dialogue_box)
		_edit_mode = false
		_refresh_navigation()
		yield(_dialogue_box, "ready")
		_prepare_dialogue_context()
		var voice_sfx = VOICE_SFXS[randi() % (VOICE_SFXS.size())]
		var dialog_dict = { "0": {"text": _prepare_text($TextEdit.text), "font": "Saturn" if _is_saturn_font else "", "sound": voice_sfx} }
		_dialogue_box.start_from_dict(dialog_dict)
		_on_dialogue_done(yield(_dialogue_box, "done"))

func _on_action_options():
	_edit_mode = false
	_dialogue_box = null
	_refresh_navigation()
	$OptionsUI.show_options()
	return true

func _on_action_copy() -> bool:
	OS.clipboard = $TextEdit.text
	audioManager.play_sfx_by_name("save", "menu")
	return true

func _on_action_switch_lead(delta: int) -> bool:
	var party_lead_index = global.POSSIBLE_PLAYABLE_MEMBERS.find(global.party[0].get_name())
	party_lead_index = (party_lead_index + delta) % global.POSSIBLE_PLAYABLE_MEMBERS.size()
	var party_lead = global.POSSIBLE_PLAYABLE_MEMBERS[party_lead_index]
	_set_party(party_lead, global.party.size())
	return true

func _on_action_party_size(delta: int) -> bool:
	var party_size = global.party.size() + delta
	if party_size in range(1, MAX_PARTY_SIZE + 1):
		_set_party(global.party[0].get_name(), party_size)
		return true
	else:
		return false

func _on_action_save() -> bool:
	if _current_save:
		global.save_from_dict(_current_save_index, _current_save)
		_refresh_save_list()
		return true
	else:
		return false

func _on_action_load_open() -> bool:
	_save_select_mode = true
	$Save/LoadButton.get_popup().popup()
	return true

func _on_action_rename_member(key) -> bool:
	var current_name = null
	var placeholder_name = null
	if key is String and key in globaldata:
		current_name = globaldata.get(key)
		placeholder_name = key
	elif key is int and key < global.party.size():
		current_name = global.party[key].get_nickname()
		placeholder_name = global.party[key].get_name()
	else:
		return false
	_rename_mode = true
	$RenameDialog.popup()
	$RenameDialog/LineEdit.text = current_name
	$RenameDialog/LineEdit.caret_position = current_name.length()
	$RenameDialog/LineEdit.grab_focus()
	$RenameDialog/LineEdit.select_all()
	$RenameDialog/LineEdit.placeholder_text = placeholder_name.capitalize()
	_refresh_popup_button()
	if $RenameDialog.is_connected("confirmed", self, "_on_rename"):
		$RenameDialog.disconnect("confirmed", self, "_on_rename")
	$RenameDialog.connect("confirmed", self, "_on_rename", [key], CONNECT_ONESHOT)
	_refresh_navigation()
	return true

func _on_action_toggle_input_device(is_toggle_gamepad: bool) -> bool:
	if is_toggle_gamepad:
		if _selected_input_device == globaldata.GAMEPAD:
			_selected_input_device = null
		else:
			_selected_input_device = globaldata.GAMEPAD
	else:
		if _selected_input_device == globaldata.KEYBOARD:
			_selected_input_device = null
		else:
			_selected_input_device = globaldata.KEYBOARD
	_refresh_controls_icons()
	return true

func _on_action_toggle_saturn_font() -> bool:
	_is_saturn_font = !_is_saturn_font
	_refresh_saturn_icon()
	return true

func _on_action_insert_tag(tag_id) -> bool:
	if _edit_mode:
		if tag_id is int:
			if tag_id >= global.party.size():
				return false
			tag_id = global.party[tag_id].get_name().capitalize()
		var tag = "[%s]" % tag_id
		$TextEdit.insert_text_at_cursor(tag)
		return true
	else:
		return false

func _on_dialogue_done(res: int):
	yield(get_tree(), "idle_frame")
	_edit_mode = true
	_refresh_navigation()

func _on_options_done():
	_edit_mode = true
	_refresh_navigation()

func _on_popup_text_changed(new_text):
	_refresh_popup_button()

func _on_locale_changed():
	_refresh_save_list()
	if _longest_names_mode:
		_refresh_longest_names()

func _on_open_save_select():
	_save_select_mode = true

func _on_close_save_select():
	_save_select_mode = false

func _on_save_selected(index: int):
	var id = $Save/LoadButton.get_popup().get_item_metadata(index)
	_load_save(id)

func _on_rename(key):
	var new_name = $RenameDialog/LineEdit.text
	if key is String:
		globaldata.set(key, new_name)
		if _current_save:
			_current_save[key] = new_name
	else:
		global.party[key].set_nickname(new_name)
		if _current_save:
			_current_save[global.party[key].get_name()].nickname = new_name
	_longest_names_mode = false
	_refresh_save_buttons()

func _on_rename_popup_closed():
	_rename_mode = false
	_refresh_navigation()

func _on_naming_icon_pressed(param, secondary_click := false):
	if !secondary_click:
		_on_action_rename_member(param)
	else:
		_on_action_insert_tag(param)

func _on_naming_icon_interact(event, button_name, param := ""):
	if !_find_button(button_name).disabled and event is InputEventMouseButton and event.button_index != BUTTON_LEFT and !event.button_mask and !event.pressed:
		_on_naming_icon_pressed(param, true)

func _on_controls_icon_pressed(is_gamepad_icon, secondary_click := false):
		if !secondary_click:
			_on_action_toggle_input_device(is_gamepad_icon)
		else:
			_on_action_insert_tag("ui_")

func _on_controls_icon_interact(event, button_name: String, is_gamepad_icon := false):
	if !_find_button(button_name).disabled and event is InputEventMouseButton and event.button_index != BUTTON_LEFT and !event.button_mask and !event.pressed:
		_on_controls_icon_pressed(is_gamepad_icon, true)

func _input(event):
	if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
		if _save_select_mode:
			if event is InputEventKey and !(event.control or event.alt or event.meta):
				var popup = $Save/LoadButton.get_popup()
				var current_index = popup.get_current_index()
				match event.scancode:
					KEY_ESCAPE:
						_save_select_mode = false
						popup.hide()
						get_tree().set_input_as_handled()
					KEY_ENTER:
						if current_index != -1:
							_on_save_selected(current_index)
							popup.hide()
							get_tree().set_input_as_handled()
					KEY_L:
						_load_save("longest")
						popup.hide()
						get_tree().set_input_as_handled()
					_:
						var physical_key_name = OS.get_scancode_string(event.physical_scancode)
						if physical_key_name.is_valid_integer():
							var save_num = int(physical_key_name)
							_load_save(save_num if save_num != 0 else 10)
							popup.hide()
							get_tree().set_input_as_handled()
		elif _rename_mode:
			if event is InputEventKey:
				match event.scancode:
					KEY_ESCAPE:
						$RenameDialog.hide()
						_rename_mode = false
						get_tree().set_input_as_handled()
					KEY_ENTER:
						if $RenameDialog/LineEdit.text != "":
							$RenameDialog.emit_signal("confirmed")
							$RenameDialog.hide()
							_rename_mode = false
							get_tree().set_input_as_handled()
		elif _edit_mode:
			if event is InputEventKey:
				for action in _keyboard_shortcuts:
					for shortcut in _keyboard_shortcuts[action]:
						var event_scancode = event.physical_scancode if shortcut.get("physical", false) else event.scancode
						if event_scancode == shortcut.key:
							var mac_remap = OS.get_name() == "OSX" and shortcut.get("mac_remap", true)
							var expected_modifiers = shortcut.get("modifiers", [])
							var match_result = true
							# Check if all expected modifiers are pressed
							for mod in expected_modifiers:
								var is_pressed = event.get(mod)
								if mac_remap and mod != "shift":
									is_pressed = event.get("command")
									mac_remap = false
								if !is_pressed:
									match_result = false
							# Check if no unexpected modifiers are pressed
							for mod in ["control", "alt", "shift", "meta"]:
								if not expected_modifiers.has(mod):
									if mod == "meta" and event.command:
										continue
									if event.get(mod):
										match_result = false
							if match_result:
								var button = _find_button(shortcut.button)
								if !button.disabled:
									var method_name = "_on_action_%s" % action
									var result = callv(method_name, shortcut.get("params", []))
									get_tree().set_input_as_handled()
									if result:
										_highlight_button(button)
								break
		elif _dialogue_box or $OptionsUI/OptionsMenu.visible:
			if (event is InputEventMouseButton and event.button_index == BUTTON_LEFT)\
				or (event is InputEventKey and event.scancode == KEY_ENTER):
					var action_event = InputEventAction.new()
					action_event.action = "ui_accept"
					action_event.pressed = true
					Input.parse_input_event(action_event)
					get_tree().set_input_as_handled()
			elif (event is InputEventMouseButton and event.button_index != BUTTON_LEFT)\
				or (event is InputEventKey and event.scancode == KEY_ESCAPE):
					var action_event = InputEventAction.new()
					action_event.action = "ui_cancel"
					action_event.pressed = true
					Input.parse_input_event(action_event)
					get_tree().set_input_as_handled()

func _find_button(button_name):
	for node_path in _all_buttons:
		if node_path.get_name(node_path.get_name_count() - 1) == button_name:
			return get_node(node_path)
	return null

func _prepare_dialogue_context():
	var party_dicts := []
	var receiver: PartyMember
	for name in globaldata.characters:
		var mem: Character = globaldata.characters[name]
		if mem in global.party:
			party_dicts.append(mem.to_dict())
			party_dicts.back()["id"] = name
	if _longest_names_mode:
		var receiver_id := _tools.find_longest_in_array(party_dicts, "nickname")
		global.item = Item.new(_tools.find_longest_item())
		receiver = globaldata.characters[receiver_id]
	else:
		global.item = _tools.get_random_item()
		receiver = global.party[randi() % global.party.size()]
	if receiver.inv.is_full():
		receiver.inv.drop_item(receiver.inv.get_items().back())
	receiver.inv.add_item(global.item)

func _prepare_text(text: String) -> String:
	var substitutions := { "\\n": "\n", "\\t": "\t", "\\r": "\r", "\\\"": "\"", "\\'": "'", "\\\\": "\\" }
	for sub in substitutions.keys():
		text = text.replace(sub, substitutions[sub])
	globaldata.device = _selected_input_device if _selected_input_device != null else globaldata.device
	text = _tools.replace_key_names(text, _longest_names_mode, globaldata.device)
	return text

func _set_party(lead_name: String, size: int):
	var party_names = []
	var start_index = global.POSSIBLE_PLAYABLE_MEMBERS.find(lead_name)
	var max_size = global.POSSIBLE_PLAYABLE_MEMBERS.size()
	for i in range(start_index, start_index + size):
		party_names.append(global.POSSIBLE_PLAYABLE_MEMBERS[i % max_size])
	global.party.clear()
	for name in party_names:
		global.party.append(globaldata.characters.get(name))
	global.emit_signal("party_changed")

func _load_save(id):
	if id is int:
		_current_save = global.load_to_dict(id)
		global.load_game(id, false)
		_current_save_index = id
		_longest_names_mode = false
	elif id == "longest":
		_current_save = null
		_current_save_index = 0
		_longest_names_mode = true
		_refresh_longest_names()
	_refresh_save_buttons()
	_refresh_party_icons()

func _highlight_button(button: BaseButton):
	var cur_state = "disabled" if button.disabled else "normal"
	if button is TextureButton:
		if button.get_parent() == $PartyPrefs/Members:
			var index = button.get_index()
			print("res://Graphics/UI/Inventory/characters/%s_hl.png" % global.party[index].get_name())
			button.texture_normal = load("res://Graphics/UI/Inventory/characters/%s_hl.png" % global.party[index].get_name())
			yield(get_tree().create_timer(.1), "timeout")
			_refresh_party_icons()
		else:
			var cur_texture_path = button.texture_normal.resource_path
			if not cur_texture_path.ends_with("_hl.png"):
				button.texture_normal = load(cur_texture_path.replace(".png", "_hl.png"))
			yield(get_tree().create_timer(.1), "timeout")
			button.texture_normal = load(cur_texture_path.replace("_hl.png", ".png"))
	else:
		var theme_orig = _btn_styles[cur_state]
		var theme_override = button.get_stylebox("pressed")
		button.add_stylebox_override(cur_state, theme_override)
		yield(get_tree().create_timer(.1), "timeout")
		button.add_stylebox_override(cur_state, theme_orig)


extends CanvasLayer

const InventorySelect = preload("res://Nodes/Ui/Inventory/InventorySelect.gd")
const SkillsMenu = preload("res://Scripts/UI/SkillsMenuUI.gd")

export (NodePath) onready var anim = get_node(anim) as AnimationPlayer
export (NodePath) onready var label_name = get_node(label_name) as Label
export (NodePath) onready var label_hp = get_node(label_hp) as Label
export (NodePath) onready var label_pp = get_node(label_pp) as Label
export (NodePath) onready var box_stats = get_node(box_stats) as BoxContainer
export (NodePath) onready var label_level = get_node(label_level) as Label
export (NodePath) onready var label_exp = get_node(label_exp) as Label
export (NodePath) onready var box_equip = get_node(box_equip) as BoxContainer
export (NodePath) onready var box_ailments = get_node(box_ailments) as BoxContainer
export (NodePath) onready var label_unconscious = get_node(label_unconscious) as Label
export (NodePath) onready var panel_select = get_node(panel_select) as InventorySelect
export (NodePath) onready var panel_skills = get_node(panel_skills) as SkillsMenu

signal back

const MAX_STATUS_DISPLAYED = 11

var active = false
var _character: PartyMember = null

func _ready():
	global.connect("locale_changed", self, "update")
	panel_skills.connect("exited", self, "_on_skills_exited")

func show_stats(party_member: PartyMember): 
	_character = party_member
	panel_select.init_from_character(_character.get_name())
	panel_skills.current_character = _character
	audioManager.play_sfx_by_name("menu_open", "menu_open")
	anim.play("Open")
	panel_select.visible = true
	panel_select.active = true
	active = true
	
	update()

func _hide_stats():
	audioManager.play_sfx_by_name("menu_close", "menu_close")
	anim.play("Close")
	panel_select.active = false
	active = false
	emit_signal("back")

func _input(event):
	if active:
		if event.is_action_pressed("ui_cancel"):
			Input.action_release("ui_cancel")
			get_tree().set_input_as_handled()
			_hide_stats()
		elif event.is_action_pressed("ui_accept"):
			active = false
			audioManager.play_sfx_by_name("menu_open", "menu_open")
			panel_skills.activate()
		
func update():
	if _character == null:
		return
		
	# Character name
	label_name.text = _character.get_nickname()
	
	# HP, PP
	label_hp.text = "%s / %s" % [_character.get_hp(), _character.get_stat(_character.MAXHP)]
	label_pp.text = "%s / %s" % [_character.get_pp(), _character.get_stat(_character.MAXPP)]
	
	# Battle stats: Offense, Defense, Speed, IQ, Guts
	for node in box_stats.get_children():
		if node is Label:
			var stat = node.get_name()
			node.text = str(int(_character.get_stat(stat)))
	
	# Level, EXP
	var exp_needed := _character.get_exp_for_next_level()
	label_level.text = str(int(_character.get_level()))
	label_exp.text = str(int(_character.get_exp())) + " / " + str(exp_needed)
	
	# Equip
	for node in box_equip.get_children():
		if node is Label:
			var slot = node.get_name()
			if _character.get_equipped_item(slot):
				#globaldata.fit_item_name_to_label(node, globaldata.get_item_data(charData["equipment"][slot]))
				node.text = globaldata.get_item_data(_character.get_equipped_item(slot).item_name).name
			else:
				node.text = "EQUIP_NONE"
	
	# Status ailments
	var ailments_to_show = _character.get_status_ailments()
	while MAX_STATUS_DISPLAYED > 0 and ailments_to_show.size() > MAX_STATUS_DISPLAYED:
		ailments_to_show = ailments_to_show.slice(1, -1)
	for node in box_ailments.get_children():
		var status_name = node.get_name().to_lower()
		node.visible = _character.has_status(status_name) and !globaldata.get_ailment_data(status_name).get("hidden", false)
	var text_unconscious = TextTools.format_text_with_context("AILMENT_UNCONSCIOUS", _character)
	label_unconscious.text = text_unconscious[0].to_upper() + text_unconscious.substr(1)
	label_unconscious.visible = _character.has_status(Status.AILMENT_UNCONSCIOUS)

func _on_InventorySelect_character_changed(char_name: String):
	_character = globaldata.characters[char_name]
	update()

func _on_skills_exited():
	active = true

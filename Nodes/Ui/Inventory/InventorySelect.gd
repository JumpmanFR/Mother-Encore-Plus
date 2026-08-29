extends NinePatchRect

signal character_changed (char_name)

var active = false setget _set_active
var _swap_mode = false

export var psiOnly = false
export var noKey = false setget _set_no_key
export var include_storage = false setget _set_include_storage
export var playSfx = true
export var menuName = ""

onready var portraits_texture = [
	preload("res://Graphics/UI/Inventory/characters/ninten.png"),
	preload("res://Graphics/UI/Inventory/characters/ana.png"),
	preload("res://Graphics/UI/Inventory/characters/lloyd.png"),
	preload("res://Graphics/UI/Inventory/characters/teddy.png"),
	preload("res://Graphics/UI/Inventory/characters/pippi.png"),
	preload("res://Graphics/UI/Inventory/characters/flyingman.png"),
	preload("res://Graphics/UI/Inventory/characters/eve.png"),
	preload("res://Graphics/UI/Inventory/characters/canarychick.png"),
	preload("res://Graphics/UI/Inventory/characters/key.png"),
	preload("res://Graphics/UI/Inventory/characters/storage.png")
]

onready var hl_portraits_texture = [
	preload("res://Graphics/UI/Inventory/characters/ninten_hl.png"),
	preload("res://Graphics/UI/Inventory/characters/ana_hl.png"),
	preload("res://Graphics/UI/Inventory/characters/lloyd_hl.png"),
	preload("res://Graphics/UI/Inventory/characters/teddy_hl.png"),
	preload("res://Graphics/UI/Inventory/characters/pippi_hl.png"),
	preload("res://Graphics/UI/Inventory/characters/flyingman_hl.png"),
	preload("res://Graphics/UI/Inventory/characters/eve_hl.png"),
	preload("res://Graphics/UI/Inventory/characters/canarychick_hl.png"),
	preload("res://Graphics/UI/Inventory/characters/key_hl.png"),
	preload("res://Graphics/UI/Inventory/characters/storage_hl.png")
]

onready var gr_portraits_texture = [
	preload("res://Graphics/UI/Inventory/characters/ninten_gr.png"),
	preload("res://Graphics/UI/Inventory/characters/ana_gr.png"),
	preload("res://Graphics/UI/Inventory/characters/lloyd_gr.png"),
	preload("res://Graphics/UI/Inventory/characters/teddy_gr.png"),
	preload("res://Graphics/UI/Inventory/characters/pippi_gr.png"),
	preload("res://Graphics/UI/Inventory/characters/flyingman_gr.png"),
	preload("res://Graphics/UI/Inventory/characters/eve_gr.png"),
	preload("res://Graphics/UI/Inventory/characters/canarychick_gr.png")
	
]

onready var portrait_nodes = [
	$CharacterPortraits/Ninten,
	$CharacterPortraits/Ana,
	$CharacterPortraits/Lloyd,
	$CharacterPortraits/Teddy,
	$CharacterPortraits/Pippi,
	$CharacterPortraits/FlyingMan,
	$CharacterPortraits/Eve,
	$CharacterPortraits/CanaryChick,
	$CharacterPortraits/Key,
	$CharacterPortraits/Storage
]

var _presence := {
	PartyMember.NINTEN: false,
	PartyMember.ANA: false,
	PartyMember.LLOYD: false,
	PartyMember.TEDDY: false,
	PartyMember.PIPPI: false,
	PartyNPC.FLYING_MAN: false,
	PartyNPC.EVE: false,
	PartyNPC.CANARY_CHICK: false,
	"key_items": true,
	"storage": false
}
func _reset_presence():
	_presence = {
		PartyMember.NINTEN: false,
		PartyMember.ANA: false,
		PartyMember.LLOYD: false,
		PartyMember.TEDDY: false,
		PartyMember.PIPPI: false,
		PartyNPC.FLYING_MAN: false,
		PartyNPC.EVE: false,
		PartyNPC.CANARY_CHICK: false,
		"key_items": !noKey,
		"storage": include_storage
	}

var inv_indexes = {
		PartyMember.NINTEN: 0,
		PartyMember.ANA: 1,
		PartyMember.LLOYD: 2,
		PartyMember.TEDDY: 3,
		PartyMember.PIPPI: 4,
		PartyNPC.FLYING_MAN: 5,
		PartyNPC.EVE: 6,
		PartyNPC.CANARY_CHICK: 7,
		"key_items": 8,
		"storage": 9
}

var show_inv = {}

func _get_inv_name(idx: int) -> String:
	var names = _presence.keys()
	return names[idx]

const INV_OFFSET = 1

var inv_nb = 2
var current_inv_idx = 0
var current_inventory = 0
var party = []


# Called when the node enters the scene tree for the first time.
func _ready():
	#if noKey:
	#	#portrait_nodes.pop_back()
	#	_presence["key"] = false
	_reset_presence()
	_refresh_title()
	_get_data()
	global.connect("party_changed", self, "_get_data")
	visible = false
	_update_portraits()

func _get_data():
	party = global.get_party_in_natural_order()
	inv_nb = party.size() - 1

func _set_no_key(val: bool):
	noKey = val
	_reset_presence()

func _set_include_storage(val: bool):
	include_storage = val
	_reset_presence()

func _set_active(val: bool):
	active = val
	_update_indicators()

func set_swap_mode(val: bool, source: PartyMember, target: PartyMember):
	_swap_mode = val
	if val:
		init_from_character(target.get_name())
		portrait_nodes[inv_indexes[source.get_name()]].texture = gr_portraits_texture[inv_indexes[source.get_name()]]
		portrait_nodes[inv_indexes[target.get_name()]].texture = hl_portraits_texture[inv_indexes[target.get_name()]]
	else:
		init_from_character(source.get_name())

	_update_indicators()
	_refresh_title()


func _refresh_title():
	$CenterContainer/MenuName.text = "INVENTORY_SWAP" if _swap_mode else menuName
	$CenterContainer.visible = ($CenterContainer/MenuName.text != "")

func init_from_character(char_name: String):
	current_inventory = _presence.keys().find(char_name)
	current_inv_idx = 0
	for i in _presence:
		if _presence[i] and inv_indexes[i] < current_inventory:
			current_inv_idx += 1
	active = true
	
func _update_portraits():
	show_inv = {}
	#hide portraits
	for node in portrait_nodes:
		node.visible = false
	
	_reset_presence()
	for member in party:
		if member.get_stat(Character.MAXPP) == 0 and psiOnly:
			continue
		var member_name = member.get_name()
		_presence[member_name] = true
	
	var portraits_visible = 0
	for char_name in _presence.keys():
		if _presence[char_name] == true:
			portraits_visible += 1
			portrait_nodes[_presence.keys().find(char_name)].visible = true
			show_inv[_presence.keys().find(char_name)] = char_name
		
	for index in show_inv.keys():
		portrait_nodes[index].texture = hl_portraits_texture[index] if index == current_inventory else portraits_texture[index]
	
	$CharacterPortraits/Key.visible = !noKey
	_update_indicators()

func _update_indicators():
	var nb_elements = _presence.values().count(true)
	var multiple_elements = nb_elements > 1
	var visible = multiple_elements and active and !_swap_mode 
	$CharacterPortraits/IndicatorL.visible = visible
	$CharacterPortraits/IndicatorR.visible = visible

func update_portrait_modifiers(character: Character, is_suitable: = false, is_equipped: = false, is_better: = false, is_lower: = false, is_inventory_full: = false):
	var node = portrait_nodes[_presence.keys().find(character.get_name())]
	node.show_is_item_suitable(is_suitable and not is_equipped and not is_inventory_full)
	node.show_is_item_equipped(is_equipped)
	node.show_is_item_better(is_better)
	node.show_is_item_lower(is_lower)
	node.show_is_inventory_full(is_inventory_full)

func _input(event: InputEvent):
	if !_swap_mode:
		if active:
			var visible_portraits = 0
			for char_name in _presence.keys():
				if _presence[char_name] == true:
					visible_portraits += 1
					portrait_nodes[_presence.keys().find(char_name)].visible = true
					show_inv[_presence.keys().find(char_name)] = char_name
			if visible_portraits > 1 and active:
				if event.is_action_pressed("ui_focus_next"):
					current_inv_idx += 1
					if current_inv_idx > show_inv.size()-1:
						current_inv_idx = 0
					if show_inv[show_inv.keys()[current_inv_idx]] in [PartyNPC.FLYING_MAN, PartyNPC.EVE, PartyNPC.CANARY_CHICK]:
						current_inv_idx += 1
						if current_inv_idx > show_inv.size()-1:
							current_inv_idx = 0
					if playSfx:
						audioManager.play_sfx_by_name("menu_open", "menu")
					current_inventory = show_inv.keys()[current_inv_idx]
					emit_signal("character_changed", show_inv[current_inventory])
				if event.is_action_pressed("ui_focus_prev"):
					current_inv_idx -=1
					if current_inv_idx < 0:
						current_inv_idx = show_inv.size()-1
					if show_inv[show_inv.keys()[current_inv_idx]] in [PartyNPC.FLYING_MAN, PartyNPC.EVE, PartyNPC.CANARY_CHICK]:
						current_inv_idx -= 1
						if current_inv_idx < 0:
							current_inv_idx = show_inv.size()-1
					if playSfx:
						audioManager.play_sfx_by_name("menu_open", "menu")
					current_inventory = show_inv.keys()[current_inv_idx]
					emit_signal("character_changed", show_inv[current_inventory])

		_update_portraits()

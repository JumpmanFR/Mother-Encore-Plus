extends Control

const ITEM_ICONS_PATHS = "res://Graphics/Objects/Items/%s.png"

export (NodePath) onready var _text_label = get_node(_text_label) as RichTextLabel
export (NodePath) onready var _sprite_container = get_node(_sprite_container) as NinePatchRect
export (NodePath) onready var _sprite = get_node(_sprite) as Sprite

var _text: String = ""
var _icon_path: String = ""

func _ready():
	_text_label.connect("resized", self, "_on_resized")

func _on_resized():
	_update()

func _set_text_with_item(text: String, item_name: String):
	_text = text
	_icon_path = ITEM_ICONS_PATHS % item_name if item_name else ""
	_update()

func set_item(item: Item, remaining_doses: int = 0):
	if item != null:
		global.item = item
		var text := TextTools.replace_text(item.get_data().get("description"))
		text += TextTools.get_item_doses_phrase(item)
		_set_text_with_item(text, item.item_name)
	else:
		_set_text_with_item("", "")

func set_item_from_inv(inv_item: Item):
	if inv_item != null:
		set_item(inv_item)
	else:
		set_item(null)

func set_text(text):
	_set_text_with_item(text, "")

func _update():
	_text_label.bbcode_text = TextTools.add_line_breaks(_text, _text_label)

	if !_icon_path:
		_sprite_container.hide()
		_sprite.texture = null
	else:
		_sprite_container.show()
		if ResourceLoader.exists(_icon_path):
			_sprite.texture = load(_icon_path)
		else:
			_sprite.texture = null

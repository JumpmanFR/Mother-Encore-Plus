extends TextureRect

export (NodePath)onready var _act_label = get_node_or_null(_act_label) as Label
export (NodePath)onready var _version_label = get_node_or_null(_version_label) as Label


func _ready():
	_refresh()
	global.connect("locale_changed", self, "_refresh")

func _refresh():
	_act_label.text = (tr("TITLE_ACT") % String(global.ACT))
	_version_label.text = global.GAME_VERSION

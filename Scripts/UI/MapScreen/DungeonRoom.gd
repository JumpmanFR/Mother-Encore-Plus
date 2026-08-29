tool 
extends TileMap
class_name DungeonMapRoom





















export var texture: Texture setget _set_texture
onready var tileset: TileSet = load("res://Tilesets/PauseMap.tres")

onready var font = load("res://Fonts/BottleRocket.tres")

onready var label := $Label

func _ready():
	if Engine.is_editor_hint():
		label.add_font_override("font", font)
		_update_texture()
		_update_debug_text()
		self.connect("draw", self, "_update_debug_text")
		self.connect("item_rect_changed", self, "_update_debug_text")
		self.connect("child_order_changed", self, "_update_debug_text")
	else:
		label.queue_free()
		label = null
		update_visibility()

func update_visibility():
	var flag_status = _get_flag_status()
	var mix = 0 if flag_status else 1
	material.set_shader_param("color_mix", mix)
	for i in get_children():
		i.visible = flag_status

func _update_debug_text():
	if label:
		var id = get_index()
		var rect = get_used_rect()
		label.text = str(id)
		label.rect_position = rect.position * cell_size
		label.rect_size = rect.size * cell_size
		label.align = Label.ALIGN_CENTER
		label.valign = Label.VALIGN_CENTER

func _get_flag_status() -> bool:
	if !Engine.is_editor_hint() and get_parent() is DungeonMapRoomManager:
		var flag = get_parent().get("room_name") + "/room_" + str(get_index())
		return globaldata.object_flags.get(flag, false)
	return false

func _set_texture(tex):
	texture = tex
	_update_texture()

func _update_texture():
	if texture and tileset:
		tile_set = tileset.duplicate(true)
		material = material.duplicate()
		for i in tile_set.get_tiles_ids():
			tile_set.call_deferred("tile_set_texture", i, texture)

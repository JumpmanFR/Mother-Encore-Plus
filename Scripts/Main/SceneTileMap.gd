extends TileMap
class_name SceneTileMap

var _scene_tiles: Dictionary
var _tile_ids: Array

func _ready() -> void:
	_scene_tiles = tile_set.get("scene_tiles")
	if _scene_tiles:
		for k in _scene_tiles:
			_tile_ids.append(k)
		_replace_cells()

func _replace_cells() -> void:
	for cell_coords in get_used_cells():
		var tile_id = get_cellv(cell_coords)
		if tile_id in _tile_ids:
			_replace_cell(cell_coords, _scene_tiles[tile_id], tile_id)

func _replace_cell(cell_coords: Vector2, scene: PackedScene, tile_id: int) -> void:
	# Delete cell
	set_cellv(cell_coords, -1)
	
	# Calculate position
	var tile_region = tile_set.tile_get_region(tile_id)
	var tile_size = tile_region.size
	var tile_offset = tile_set.tile_get_texture_offset(tile_id)
	var obj_position = map_to_world(cell_coords) + tile_size/2 + tile_offset
	
	# Add scene replacement
	var object = scene.instance()
	object.name = object.name + str(cell_coords)
	object.position = obj_position
	add_child(object)

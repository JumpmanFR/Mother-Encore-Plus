tool
extends Control

func _ready():
	var dir = Directory.new()
	if dir.open('res://Tilesets/') == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != '':
			if file_name.ends_with('.tres'):
				_convert_tileset('res://Tilesets/%s' % file_name)
			file_name = dir.get_next()
	else:
		print('Couldn’t access the Tilesets folder')

func _convert_tileset(tileset_path: String):
	var tileset = load(tileset_path)
	if tileset == null:
		push_error('Wrong tileset ' + tileset_path)
		return

	if tileset is TileSet:
		print("CONVERTING TILESET %s" % tileset_path)
		for tile_id in tileset.get_tiles_ids():
			print(tileset.tile_get_name(tile_id))
			var tex_offset = tileset.tile_get_texture_offset(tile_id)

			var shape_count = tileset.tile_get_shape_count(tile_id)
			for i in range(shape_count):
				var shape_offset = tileset.tile_get_shape_offset(tile_id, i)

				tileset.tile_set_shape_offset(tile_id, i, shape_offset - tex_offset)

		var err = ResourceSaver.save(tileset_path, tileset, ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
		if err != OK:
			push_error('Failed: ' + str(err))
		else:
			print('Done')
		print()

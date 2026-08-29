class_name MapScreen
extends Control

const SCREEN_SIZE := Vector2(320, 180)
const MISSING_MAP := "404"
const WRIGGLE_PERIOD := 0.5

var _active := false
var _map_name := MISSING_MAP
var _nameplate_name := ""
var _close_cb: FuncRef = null
var _scroll_offset := Vector2.ZERO
var _markers_visible := true
var _marker_time := 0.0
	
var _map_cache := {}

var _loaded_map: TextureRect = null
var _player_marker: TextureRect = null
var _map_markers: Control = null
var _tween: SceneTreeTween

func _ready():
	_on_ready()

# Overridden
func _on_ready():
	hide()
	$PlayerMarkerTemplate.hide()
	$Reticle.visible = false
	$Prompts/PromptFast.visible = false
	$Prompts/PromptMarkers.visible = false
	$Prompts/PromptOK.visible = false
	_preload_all_maps()
	_load_map(MISSING_MAP)

static func set_reticle_mode(instance: MapScreen, value := true):
	var script := load("res://Scripts/UI/MapScreen/MapScreen%s.gd" % ("WithReticle" if value else ""))
	instance.set_script(script)

func _preload_all_maps():
	var root := "res://Nodes/Ui/MapScreen"
	for i in ["DungeonMaps", "Maps"]:
		var dir := Directory.new()
		var path := root.plus_file(i)
		if dir.open(path) != OK:
			breakpoint
		dir.list_dir_begin(true, true)
		
		while true:
			var _name: = dir.get_next()
			if not _name: break
			if not _name.to_lower().ends_with(".tscn"): continue
			var full_path: = path.plus_file(_name)
			var map_res: PackedScene = load(full_path)
			var map_instance = map_res.instance()
			_setup_new_map_instance(map_instance)
			_map_cache[full_path] = map_instance

func enter(area_name: String, name_plate_name: String, close_cb: FuncRef = null):
	_active = true
	audioManager.play_sfx_by_name("menu_open", "menu")
	
	_nameplate_name = name_plate_name
	
	if area_name == "":
		area_name = MISSING_MAP
		_nameplate_name = ""
	if area_name != _map_name:
		_load_map(area_name)

	_close_cb = close_cb
	_refresh_map_state()
	
	_update_player_marker()
	_toggle_markers(true)
	show()
	_init_position()
	_show_plate()	

func _load_map(area_name: String):
	if _loaded_map:
		remove_child(_loaded_map)
		_loaded_map.queue_free()

	_map_name = area_name
	var map_type = "DungeonMaps" if _is_in_dungeon() else "Maps"
	var path := "res://Nodes/Ui/MapScreen/%s/%s.tscn" % [map_type, area_name]
	
	if _map_cache.get(path):
		_loaded_map = _map_cache[path]
		_player_marker = _loaded_map.get_node("PlayerMarker")
		_map_markers = _loaded_map.get_node("MarkersContainer")
	else:
		path = "res://Nodes/Ui/MapScreen/%s/%s.tscn" % ["DungeonMaps", area_name]
		if _map_cache.get(path):
			_loaded_map = _map_cache[path]
			_player_marker = _loaded_map.get_node("PlayerMarker")
			_map_markers = _loaded_map.get_node("MarkersContainer")
	
	_loaded_map.show()
	add_child(_loaded_map)
	move_child(_loaded_map, 0)
	
	_loaded_map.rect_size.x = max(_loaded_map.rect_size.x, 320)
	_loaded_map.rect_size.y = max(_loaded_map.rect_size.y, 180)
	
	_update_prompts()
	$MapArrows.set_bounds((_get_map_size() - SCREEN_SIZE) / 2)

func _refresh_map_state():
	if _loaded_map:
		for child in _loaded_map.get_children():
			_update_node_status(child)

func _update_node_status(node: Node):
	if node is DungeonMapRoom:
		node.update_visibility()
	elif node is MarkerPresent:
		node.update()
	elif node is Label:
		var translation_key = node.text
		node.text = "";node.text = translation_key
	
	for child in node.get_children():
		_update_node_status(child)

func _setup_new_map_instance(map_instance: Node):
	var player_marker_instance = $PlayerMarkerTemplate.duplicate()
	player_marker_instance.name = "PlayerMarker"
	map_instance.add_child(player_marker_instance, true)
	player_marker_instance.show()
	
	var markers_container_instance = Control.new()
	markers_container_instance.name = "MarkersContainer"
	map_instance.add_child(markers_container_instance, true)
	
	if map_instance.filename.get_file().get_basename() == MISSING_MAP:
		return
	
	var children := map_instance.get_children().duplicate()
	for child in children:
		if child in [player_marker_instance, markers_container_instance] or child is Node2D:
			continue
		var g_pos: Vector2 = child.rect_global_position
		child.get_parent().remove_child(child)
		markers_container_instance.add_child(child, true)
		child.rect_global_position = g_pos

func _physics_process(delta: float):
	if not _active:
		return
	var move_vec: Vector2 = controlsManager.get_controls_vector()
	if move_vec:
		var speed: = 1 + int(Input.is_action_pressed("ui_toggle"))
		_move_by(move_vec * speed)
	
	if _is_missing_map():
		return
	if _marker_time >= WRIGGLE_PERIOD:
		_map_markers.rect_position.y = - 1 - _map_markers.rect_position.y
		_marker_time = 0.0
	_marker_time += delta

func _input(event):
	if _active:
		_handle_inputs(event)

# Because Godot doesn’t let me override _input directly in inherited classes
# Overridden
func _handle_inputs(event):
	if event.is_action_pressed("ui_scope"):
		_toggle_markers()
	
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_map"):
		Input.action_release("ui_cancel")
		Input.action_release("ui_map")
		get_tree().set_input_as_handled()
		_leave()
	
	$MapArrows.handle_input_events()

func _show_plate():
	$MapNamePlate.texture = load("res://Graphics/UI/Maps/%s_namePlate.png" % _nameplate_name)
	$MapNamePlate.position.y = 0
	if _tween: _tween.kill()
	_tween = create_tween()
	_tween.tween_property($MapNamePlate, "position:y", -SCREEN_SIZE.y, 1.0) \
			.set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN_OUT).set_delay(1.5)

# Overridden
func _init_position():
	_move_to(_get_player_position())
	_update_arrows()

# Overridden
func _move_to(pos: Vector2):
	var map_size := _get_map_size()

	var pos_clamp_scroll := _clamp_position(pos, (map_size - SCREEN_SIZE) / 2)
	_loaded_map.rect_position = - pos_clamp_scroll - _loaded_map.rect_size / 2 + SCREEN_SIZE / 2
	_scroll_offset = pos_clamp_scroll

	_update_arrows()
	_update_player_marker()

# Overridden
func _move_by(delta: Vector2):
	_move_to(_scroll_offset + delta)

func _clamp_position(pos: Vector2, abs_bounds: Vector2) -> Vector2:
	var clamped_pos := pos

	if abs_bounds.x < 0:
		clamped_pos.x = 0
	else:
		clamped_pos.x = clamp(clamped_pos.x, - abs_bounds.x, abs_bounds.x)
	if abs_bounds.y < 0:
		clamped_pos.y = 0
	else:
		clamped_pos.y = clamp(clamped_pos.y, - abs_bounds.y, abs_bounds.y)

	return clamped_pos

func _get_player_position() -> Vector2:
	if not _is_current_scene():
		return Vector2.ZERO
	
	var ret: = Vector2.ZERO
	ret -= _get_map_size() / 2
	if global.currentScene is DungeonAreaRoom:
		var current_floor = global.currentScene.current_floor
		var loaded_floor = _loaded_map.get_child(current_floor)
		if loaded_floor is DungeonMapRoomManager:
			var room_id = global.currentScene.get_current_room_id()
			var offset = loaded_floor.get_room_offset(room_id)
			ret += offset
			if global.get_player() != null and not _is_in_sub_area():
				ret += global.currentScene.get_player_position_relative_to_current_room() / 16
	else:
		if global.currentScene is AreaRoom:
			ret += global.currentScene.get_player_map_offset()
		if global.get_player() != null and not _is_in_sub_area():
			ret += global.get_player().position / 16
	return ret

func _get_map_size() -> Vector2:
	return _loaded_map.get_rect().size

func _is_missing_map() -> bool:
	return _map_name == MISSING_MAP

func _is_current_scene() -> bool:
	return !_is_missing_map() and global.currentScene is AreaRoom and global.currentScene.get_map_name(true, true) == _map_name

func _is_in_sub_area() -> bool:
	return _is_current_scene() and global.currentScene is AreaRoom and global.currentScene.is_sub_area()

func _is_in_dungeon() -> bool:
	return _is_current_scene() and global.currentScene is DungeonAreaRoom

func _update_arrows():
	$MapArrows.set_offset(_scroll_offset)

func _update_player_marker():
	_player_marker.rect_position = _get_player_position() - _player_marker.rect_size / 2 + _loaded_map.rect_size / 2

# Overridden
func _update_prompts():
	$Prompts / PromptFast.visible = (_get_map_size().x > SCREEN_SIZE.x or _get_map_size().y > SCREEN_SIZE.y)
	$Prompts / PromptMarkers.visible = not (_map_markers.get_children().empty() or _is_missing_map())
	$Prompts / PromptClose.rect_global_position.y = $Prompts / PromptMarkers.rect_global_position.y - 10 if ($Prompts / PromptMarkers.visible) else $Prompts / PromptMarkers.rect_global_position.y
	$Prompts / PromptOK.visible = false

# Overridden
func _toggle_markers(show := !_markers_visible):
	_markers_visible = (show or _is_missing_map())
	_map_markers.visible = _markers_visible
	_player_marker.visible = _is_current_scene()

func close():
	_active = false
	hide()

func _leave():
	_active = false
	hide()
	audioManager.play_sfx_by_name("menu_close", "menu")
	uiManager.remove_ui(self)
	if _close_cb and _close_cb.is_valid():
		_close_cb.call_func()
		_close_cb = null

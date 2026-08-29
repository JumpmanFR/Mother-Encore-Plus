extends Node

export (String, FILE) var room
export (bool) var preview := false setget set_preview

var zone_id
var zone_trigger
var _preview_node: Node = null
var loadedRoom = null

var map = null

func _ready():
	set_process(false)
		

func _on_loader_area_entered(area):
		
	if Engine.editor_hint:
		return
		
	
	if area == global.get_player().get_node("Camera2D").get_node("Area2D"):
		goto_scene(room)

func _on_loader_area_exited(area):
	
	if Engine.editor_hint:
		return
		
	
	if area == global.get_player().get_node("Camera2D").get_node("Area2D"):
		if map != null:
			map.queue_free()
			map = null


func set_preview(value: bool):
	
	if !Engine.editor_hint or preview == value:
		return
		
	preview = value

	
	if _preview_node:
		_preview_node.queue_free()
		_preview_node = null

	
	if preview and room:
		
		var scene: PackedScene = load(room)
		
		
		if !scene:
			return
			
		_preview_node = scene.instance()
		
		add_child(_preview_node)
		
		
		_preview_node.owner = null

func goto_scene(path):
	loadedRoom = ResourceLoader.load_interactive(room)
	if loadedRoom == null:
		return
	set_process(true)

	

func _process(time):
	if loadedRoom == null:
		set_process(false)
		return
	
	var t = Time.get_ticks_msec()
	
	while Time.get_ticks_msec() < t + 100:
	
		var err = loadedRoom.poll()
		if err == ERR_FILE_EOF:
			var resource = loadedRoom.get_resource()
			loadedRoom = null
			add_map(resource)
			break
		elif err == OK:
			pass
		else:
			loadedRoom = null
			break

func add_map(rm):
	map = rm.instance()
	add_child(map)

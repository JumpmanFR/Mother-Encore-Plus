extends ParallaxBackground
class_name ParallaxBackgroundViewport

onready var camFollowerNode2DScript = preload("res://Scripts/Main/CamFollowerNode2D.gd")
onready var camFollowerControlScript = preload("res://Scripts/Main/CamFollowerControl.gd")

func _ready():
	yield(get_tree(), "idle_frame")
	
	var parent = get_parent()
	
	var viewportContainer = ViewportContainer.new()
	var screen_size = get_viewport().get_visible_rect().size
	
	viewportContainer.rect_size = screen_size
	viewportContainer.light_mask = parent.light_mask
	viewportContainer.set_script(camFollowerControlScript)
	
	parent.add_child(viewportContainer)
	parent.move_child(viewportContainer, self.get_index())
	
	
	var viewport = Viewport.new()
	viewport.size = screen_size
	viewport.usage = Viewport.USAGE_2D
	
	viewportContainer.add_child(viewport)
	
	var camera = Camera2D.new()
	camera.current = true
	camera.set_script(camFollowerNode2DScript)
	
	viewport.add_child(camera)
	
	parent.remove_child(self)
	viewport.add_child(self)

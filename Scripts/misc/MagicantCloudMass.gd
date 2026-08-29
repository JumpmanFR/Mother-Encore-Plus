extends Node2D


export (PackedScene) var cloud_scene
export var cloud_density: int = 20

export var polygon2d_path: NodePath = "ViewportContainer/Viewport/Polygon2D"

export var ysort_path: NodePath = "ViewportContainer/Viewport/Polygon2D/YSort"

onready var polygon2d = get_node_or_null(polygon2d_path)
onready var ysort = get_node_or_null(ysort_path)


func _ready():
	
	for i in cloud_density:
		
		var travel_distance: float = (i / float(cloud_density))
		_create_cloud(polygon2d.get_point_at_offset(travel_distance))
	pass



func _process(delta):

	pass
	
func _create_cloud(pos: Vector2):
	print("Cloud Instanced at ", pos, " ...")
	var new_cloud = cloud_scene.instance()
	new_cloud.position = pos
	ysort.add_child(new_cloud)

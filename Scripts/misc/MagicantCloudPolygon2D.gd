extends Polygon2D


func _ready():
	print(get_perimeter_length())
	pass



func get_perimeter_length() -> float:
	var total: float = 0.0
	var points = polygon
	for i in range(points.size()):
		total += points[i].distance_to(points[(i + 1) % points.size()])
	return total



func get_point_at_offset(offset: float) -> Vector2:
	
	offset = clamp(offset, 0.0, 1.0)
	var perimeter = get_perimeter_length()
	var target_distance = offset * perimeter
	
	var accumulated_dist = 0.0
	var points = polygon
	
	
	for i in range(points.size()):
		var p1 = points[i]
		var p2 = points[(i + 1) % points.size()]
		var segment_length = p1.distance_to(p2)
		
		if accumulated_dist + segment_length >= target_distance:
			var local_offset = (target_distance - accumulated_dist) / segment_length
			return p1.linear_interpolate(p2, local_offset)
		accumulated_dist += segment_length
	return points[0]





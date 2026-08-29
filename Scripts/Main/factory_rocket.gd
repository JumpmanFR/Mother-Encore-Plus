extends InteractDialog

export var move_speed: float = 0.015
export var pathfollow2d_path: NodePath
export var bottle_rocket_sprite_path: NodePath

onready var bottle_rocket_path: PathFollow2D = get_node(pathfollow2d_path)
onready var bottle_rocket_sprite = get_node(bottle_rocket_sprite_path)

var current_state: int = 0
var current_room_index: int = 0
var is_moving: bool = false




const arrived_state_flags = [
	"br_progress_1_arrived", 
	"br_progress_2_arrived", 
	"br_progress_3_arrived"
]
const progress_state_flags = [
	"br_progress_1", 
	"br_progress_2", 
	"br_progress_3"
]

const state_rooms = [0, 1, 2, 4]




const void_boundaries = [
	Vector2(0.0803, 0.1605), 
	Vector2(0.293, 0.3918), 
	Vector2(0.5113, 0.6594), 
	Vector2(0.7829, 0.8649), 
	Vector2(1.1, 1.1), 
]




const stop_coordinates = [
	0.0, 
	0.2411, 
	0.4754, 
	1.0
]

func teleport_in_void(add_room = true):
	bottle_rocket_path.unit_offset = void_boundaries[current_room_index].y
	print("teleported rocket to: ", void_boundaries[current_room_index].y)
	if add_room:
		current_room_index += 1

func progress_rocket():
	bottle_rocket_sprite.frame = current_state
	current_state += 1
	is_moving = true
	print("progressing rocket to stage: ", current_state)
	print("Current stop point is", stop_coordinates[current_state])

func _ready():
	bottle_rocket_sprite.visible = true
	_check_progress_flags()

func _stop_rocket():
	is_moving = false
	globaldata.flags[arrived_state_flags[current_state - 1]] = true
	bottle_rocket_path.unit_offset = stop_coordinates[current_state]
	print("Current state is", stop_coordinates[current_state])

func _check_progress_flags():
	for i in progress_state_flags.size():
		if !_get_flag_status(progress_state_flags[i]):
			break
		current_state += 1
	if current_state != 0:
		current_room_index = state_rooms[current_state]
		teleport_in_void(false)
		bottle_rocket_path.unit_offset = stop_coordinates[current_state]
		_stop_rocket()

func _get_flag_status(flag) -> bool:
	return globaldata.flags.get(flag, false)


func _process(delta):

	if is_moving:
		bottle_rocket_path.unit_offset += (move_speed * delta)

		
		if bottle_rocket_path.unit_offset >= stop_coordinates[current_state]:
			_stop_rocket()
	
	if bottle_rocket_path.unit_offset >= void_boundaries[current_room_index].x:
		teleport_in_void()

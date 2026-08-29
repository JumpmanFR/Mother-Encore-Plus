extends Sprite

onready var special:SpriteDataFetcher = get_node_or_null("../../SpriteDataFetcher2")

# Really quick and hacky script for Ninten's bat to
# render as a seperate object.

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global.get_player().get_current_skill_action() == "swing":
		visible = true;
	else:
		visible = false;
	if (special):
		frame = special.get_frames()
		# Determine if the bat should render behind Ninten
		show_behind_parent = true;
		if frame_coords.x > 1:
			show_behind_parent = false;
		if frame_coords.y > 2:
			show_behind_parent = !show_behind_parent

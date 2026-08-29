extends FlaggableObject

export var red_door_flag: String
export var blue_door_flag: String

class LightDoor:
	var light: CutsceneObject
	var door: AnimatedSprite
	var flag: String
	
	func _init(l: Node, d: AnimatedSprite, f: String):
		light = l
		door = d
		flag = f

onready var red = LightDoor.new($RedLight, $RedDoor, red_door_flag)
onready var blue = LightDoor.new($BlueLight, $BlueDoor, blue_door_flag)
onready var anim_player = $AnimationPlayer
onready var sfx = $AudioStreamPlayer

func _ready():
	red.door.play("default")
	blue.door.play("default")
	_check_flags()

func _check_flags():
	if _get_flag_status():
		lighten(red)
		lighten(blue)
		anim_player.play("Opened")
	else:
		if globaldata.flags.get(red_door_flag, false):
			lighten(red)
		if globaldata.flags.get(blue_door_flag, false):
			lighten(blue)

func open_door():
	anim_player.play("Open")

func lighten(l: LightDoor, with_sound := false):
	l.light.play_anim()
	l.door.play("Lighten")
	globaldata.flags[l.flag] = true
	if with_sound: sfx.play()

func light_color(c: String):
	lighten(get(c), true)

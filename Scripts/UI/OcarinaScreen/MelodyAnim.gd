extends Control

const WIGGLE_SEED := 12345
const WIGGLE_OCTAVES := 1
const WIGGLE_PERSISTENCE := 0.1
const WIGGLE_PERIOD := 35.0
const WIGGLE_SPEED := 40.0
const WIGGLE_AMPLITUDE_VERTICAL := 4.0
const WIGGLE_WAVE_OFFSET_MULTIPLIER := 0.15

const COLOR_UNKNOWN := Color("C0C0C0")
const LIGHTEN_AMOUNT := 0.5
const INTERPOLATE_DURATION := 0.5

export (int) var _melody_number := 0
export (Color) var _color := Color.white

export (NodePath) onready var _anim_player = get_node(_anim_player) as AnimationPlayer
export (NodePath) onready var _bubble = get_node(_bubble) as AnimatedSprite
#export (NodePath) onready var  = get_node(_bubble_outline) as AnimatedSprite
export (NodePath) onready var _icon = get_node(_icon) as Sprite

onready var _base_pos := rect_position

var _noise := OpenSimplexNoise.new()
var _time := 0.0

var _got_melody: bool

var center_pos: Vector2 setget _set_center_pos, _get_center_pos

func init_melody(learned: bool):
	_got_melody = learned
	var icon_id := _melody_number as String# if _got_melody else "empty"
	_icon.texture = load("res://Graphics/UI/MelodyIcons/melody_icon_%s.png" % icon_id)
	_icon.visible = _got_melody
	_bubble.material.set_shader_param("target_color", _color if _got_melody else COLOR_UNKNOWN)
	_bubble.material.set_shader_param("lighten", LIGHTEN_AMOUNT)
	_bubble.material.set_shader_param("strength", 0.0)

func _ready():
	_bubble.material = _bubble.material.duplicate()
	_icon.material = _icon.material.duplicate()
	_noise.seed = WIGGLE_SEED
	_noise.persistence = WIGGLE_PERSISTENCE
	_noise.octaves = WIGGLE_OCTAVES
	_noise.period = WIGGLE_PERIOD

func _process(delta: float):
	#_bubble_outline.frame = _bubble.frame
	
	_time += delta * WIGGLE_SPEED
	#var x := _noise.get_noise_1d(_time) * WIGGLE_AMPLITUDE_HORIZONTAL
	var y := _noise.get_noise_1d(_time + (_base_pos.y * WIGGLE_WAVE_OFFSET_MULTIPLIER) + 100) * WIGGLE_AMPLITUDE_VERTICAL
	
	rect_position.y = _base_pos.y + y

func play():
	var tween = create_tween().set_parallel()
	tween.tween_property(_bubble, "material:shader_param/strength", 1.0, INTERPOLATE_DURATION)
	tween.tween_property(_icon, "material:shader_param/strength", 0.0, INTERPOLATE_DURATION).from(1.0)
	#_anim_player.play("%sknown_melody" % ("" if _got_melody else "un"))

func stop():
	pass #_anim_player.stop(false)

func get_tint() -> Color:
	if _got_melody:
		return _color
	else:
		return COLOR_UNKNOWN

func _set_center_pos(new_pos: Vector2):
	rect_position = new_pos - rect_size / 2

func _get_center_pos() -> Vector2:
	return rect_position + rect_size / 2

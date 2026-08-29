extends "res://Scripts/UI/Battle/EnemySprite.gd"

const ROCKET_LAUNCHER_SPRITE = "res://Graphics/Battle Sprites/rocket launcher sprites/rocket launcher.png"
const RED_ROCKET_SPRITE = "res://Graphics/Battle Sprites/rocket launcher sprites/rocket launcher red.png"
const BLUE_ROCKET_SPRITE = "res://Graphics/Battle Sprites/rocket launcher sprites/rocket launcher blue.png"

onready var counter = $Counter
onready var counter_number = $Counter / CounterNumber
var _right := false

func _ready():
	_static = true
	set_texture(ROCKET_LAUNCHER_SPRITE)
	appear()

func set_right(value: bool):
	_right = value
	rect_position = Vector2(320 - rect_size.x if _right else 0, 47)
	rect_position.y = 67
	_sprite.flip_h = _right;counter.flip_h = not _right

func set_counter_number(num: int):
	counter_number.frame = num

func set_rocket_sprite(toggled: bool):
	$AnimationPlayer.play("fade_in");yield($AnimationPlayer, "animation_finished")
	set_texture(BLUE_ROCKET_SPRITE if toggled else RED_ROCKET_SPRITE)
	counter.position = Vector2(_sprite.texture.get_size().x / 2, _sprite.texture.get_size().y + counter.texture.get_size().y / 2)
	$AnimationPlayer.play("fade_out");yield($AnimationPlayer, "animation_finished")

func play_hit_anim(toggled: bool):
	set_texture(BLUE_ROCKET_SPRITE if toggled else RED_ROCKET_SPRITE)
	$AnimationPlayer.play("hit_blue" if toggled else "hit_red");yield($AnimationPlayer, "animation_finished")

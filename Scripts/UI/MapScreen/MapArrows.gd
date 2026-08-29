extends Node2D

onready var _direction_arrows := {
	Vector2.UP: $arrowU,
	Vector2.DOWN: $arrowD,
	Vector2.LEFT: $arrowL,
	Vector2.RIGHT: $arrowR
}

var _offset: Vector2
var _bounds := Vector2.ZERO
var _show_arrows: bool

func _ready():
	for arrow in _direction_arrows.values():
		arrow.get_node("AnimationPlayer").connect("animation_finished", self, "_on_anim_finished", [arrow])
	_show_arrows = visible
	_refresh_show_hide(true)

func show():
	if !_show_arrows:
		_show_arrows = true
		_refresh_show_hide(visible)

func hide():
	if _show_arrows:
		_show_arrows = false
		_refresh_show_hide(!visible)

func _refresh_show_hide(instant := false):
	var anim_name := "Come %s" % ("In" if _show_arrows else "Out")
	if instant:
		$AnimationPlayer.play(anim_name, -1, 0, true)
	else:
		$AnimationPlayer.play(anim_name)

func handle_input_events():
	point_directions(controlsManager.get_just_pressed_directions())
	unpoint_directions(controlsManager.get_just_released_directions())

func point_directions(directions: Array):
	for dir in directions:
		var anim_player: AnimationPlayer = _direction_arrows[dir].get_node("AnimationPlayer")
		if anim_player.assigned_animation != "Point":
			anim_player.play("Point")

func unpoint_directions(directions: Array):
	for dir in directions:
		var anim_player: AnimationPlayer = _direction_arrows[dir].get_node("AnimationPlayer")
		if anim_player.assigned_animation != "UnPoint":
			anim_player.play("UnPoint")

func point_dir_sum(dir_sum: Vector2):
	var dir_array := [Vector2(sign(dir_sum.x), 0), Vector2(0, sign(dir_sum.y))]
	for dir in _direction_arrows:
		if dir in dir_array:
			point_directions([dir])
		else:
			unpoint_directions([dir])

func set_offset(offset: Vector2):
	_offset = offset
	_refresh_visibility()

func set_bounds(bounds: Vector2):
	_bounds = bounds
	_refresh_visibility()

func _refresh_visibility():
	$arrowU.visible = _bounds and _offset.y > - _bounds.y
	$arrowD.visible = _bounds and _offset.y < _bounds.y
	$arrowL.visible = _bounds and _offset.x > - _bounds.x
	$arrowR.visible = _bounds and _offset.x < _bounds.x

func set_arrow_visible(direction: Vector2, visibility: bool):
	_direction_arrows[direction].visible = visibility

# Resyncing arrow frames
func _on_anim_finished(anim_name: String, arrow: AnimatedSprite):
	if anim_name == "UnPoint":
		for other_arrow in _direction_arrows.values():
			if arrow != other_arrow and other_arrow.visible and other_arrow.playing:
				yield(other_arrow, "frame_changed")
				arrow.frame = other_arrow.frame
				return

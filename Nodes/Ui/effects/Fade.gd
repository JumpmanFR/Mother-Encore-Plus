extends CanvasLayer

const SCREEN_SIZE := Vector2(320, 180)

onready var _color_rect = $Path2D / PathFollow2D / ColorRect
onready var _anim_player = $Path2D / PathFollow2D / ColorRect / AnimationPlayer

signal fade_in_done
signal fade_in_mostly_done
signal fade_out_mostly_done
signal fade_out_done
signal cut_done

var _cut_tween: SceneTreeTween
var _fade_tween: SceneTreeTween

func toggle_spin(speed := 1.0):
	if $PathAnim.is_playing():
		$PathAnim.stop()
		$Path2D / PathFollow2D.unit_offset = 0
	else:
		$PathAnim.play("Rotate", - 1, float(speed))

func set_spin(enabled: bool, speed := 1.0):
	if enabled: $PathAnim.play("Rotate", - 1, float(speed))
	else:
		if $PathAnim.is_playing(): $PathAnim.stop()
		$Path2D / PathFollow2D.unit_offset = 0
		

func set_cut(size: float, speed := 1.0, type := 1, tween_ease := Tween.EASE_IN_OUT):
	_color_rect.material.set_shader_param("fade", type)
	if _cut_tween and _cut_tween.is_running(): _cut_tween.kill()
	_cut_tween = create_tween()
	_cut_tween.tween_property(_color_rect.material, "shader_param/cut", size, speed).set_trans(Tween.TRANS_QUAD).set_ease(tween_ease)
	_cut_tween.tween_callback(self, "emit_signal", ["cut_done"])

func focus_object(object = global.get_player()):
	_recenter()
	_color_rect.rect_position += object.global_position - global.currentCamera.get_camera_screen_center()

func _recenter():
	_color_rect.rect_position = - (_color_rect.rect_size - SCREEN_SIZE) / 2

func set_color(color := Color.black):
	_color_rect.modulate = color

func init_cut():
	_color_rect.material.set_shader_param("cut", 0)

func fade_in(anim_name := "Fade", color := Color.black, animation_speed := 1.0):
	set_color(color)
	if anim_name == "Circle Focus":
		focus_object()
		anim_name = "Circle"
	else:
		_recenter()
	_anim_player.play(anim_name + " In", - 1, animation_speed)
	yield(_anim_player, "animation_finished")
	_recenter()
	emit_signal("fade_in_done")

func fade_out(anim_name := "Fade", color := Color.black, animation_speed := 1.0):
	if _color_rect.modulate != color:
		if _fade_tween and _fade_tween.is_running(): _fade_tween.kill()
		_fade_tween = create_tween()
		_fade_tween.tween_property(_color_rect, "modulate", color, animation_speed / 4)
		animation_speed = animation_speed * 0.75
		yield(_fade_tween, "finished")
	if anim_name == "Circle Focus":
		focus_object()
		anim_name = "Circle"
	else:
		_recenter()
	_anim_player.play(anim_name + " Out", - 1, animation_speed)
	yield(_anim_player, "animation_finished")
	_recenter()
	emit_signal("fade_out_done")

func _on_fade_in_mostly_done():
	emit_signal("fade_in_mostly_done")

func _on_fade_out_mostly_done():
	emit_signal("fade_out_mostly_done")

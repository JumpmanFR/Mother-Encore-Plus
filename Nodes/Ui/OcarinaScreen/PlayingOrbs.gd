extends Control

const ORBS_DIAM_S := 40.0
const ORBS_DIAM_L := 60.0
const ORBS_DIAM_XL := 400.0
const DURATION_PULSE := 0.2
const DURATION_FADE := 0.2
const DURATION_TINT := 0.2
const DURATION_SCATTER := 0.6

var _is_visible: bool = true

var center_pos: Vector2 setget _set_center_pos, _get_center_pos

func _ready():
	modulate.a = 0.0
	material = material.duplicate()
	material.set_shader_param("strength", 1)
	material.set_shader_param("lighten", 0)
	_resize(ORBS_DIAM_S)

func pulse():
	var diam_diff := Vector2(ORBS_DIAM_L - ORBS_DIAM_S, ORBS_DIAM_L - ORBS_DIAM_S) / 2
	var tween = create_tween()
	tween.tween_method(self, "_resize", ORBS_DIAM_S, ORBS_DIAM_L, DURATION_PULSE)
	tween.tween_method(self, "_resize", ORBS_DIAM_L, ORBS_DIAM_S, DURATION_PULSE).set_ease(Tween.EASE_IN_OUT)

func scatter_away():
	_is_visible = false
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "modulate:a", 0.0, DURATION_SCATTER).set_ease(Tween.EASE_IN)
	tween.tween_method(self, "_resize", rect_size.x, ORBS_DIAM_XL, DURATION_SCATTER).set_ease(Tween.EASE_IN)

func set_visible(value: bool):
	if value != _is_visible:
		_is_visible = value
		create_tween().tween_property(self, "modulate:a", 1.0 if _is_visible else 0.0, DURATION_FADE)

func is_visible() -> bool:
	return _is_visible

func set_tint(new_color: Color):
	create_tween().tween_property(material, "shader_param/target_color", new_color, DURATION_TINT)

func _set_center_pos(new_pos: Vector2):
	rect_position = new_pos - rect_size / 2

func _get_center_pos() -> Vector2:
	return rect_position + rect_size / 2

func _resize(new_diam: float):
	var diam_diff := (Vector2(new_diam, new_diam) - rect_size) / 2
	rect_position -= diam_diff
	rect_size = Vector2(new_diam, new_diam)
	rect_pivot_offset = Vector2(new_diam, new_diam) / 2

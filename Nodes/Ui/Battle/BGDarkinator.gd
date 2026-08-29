extends ColorRect

export var _focus_spotlight_start_offset: Vector2
export var _focus_spotlight_start_radius: float
export var _focus_spotlight_end_radius: float
export var _focus_spotlight_end_time: float
export var _focus_spotlight_duration: float






var _tween: SceneTreeTween = null

func _ready():
	material.set("textureSize", self.rect_size)
	reset_spotlight()


func darken_bg() -> void:
	reset_spotlight()
	$AnimationPlayer.play("darken")

func undarken_bg() -> void:
	$AnimationPlayer.play("undarken")
	yield($AnimationPlayer, "animation_finished")
	if _tween and _tween.is_running():
		_tween.kill()
	reset_spotlight()

func reset_spotlight() -> void:
	set_spotlight_visible(false)
	set_spotlight_radius(0)
	set_spotlight_position(Vector2(160, 90))
	set_spotlight_offset(Vector2.ZERO)
	set_spotlight_animated(false)
	set_spotlight_speed(1)
	set_spotlight_time(0)

func set_spotlight_visible(enabled) -> void:
	material.set("circle_visible", enabled)


func focus_spotlight_on_position(pos: Vector2, duration = 0.7) -> void:
	pos.y -= _focus_spotlight_start_offset.y
	set_spotlight_position(pos)
	set_spotlight_offset(_focus_spotlight_start_offset)
	set_spotlight_radius(_focus_spotlight_start_radius)
	_interpolate_spotlight_property("time", _focus_spotlight_end_time, duration)
	_interpolate_spotlight_property("radius", _focus_spotlight_end_radius, duration)
	set_spotlight_visible(true)

func set_spotlight_radius(rad: float):
	material.set_shader_param("radius", rad)

func set_spotlight_position(pos: Vector2) -> void:
	material.set_shader_param("position", pos)

func set_spotlight_offset(off: Vector2) -> void:
	material.set_shader_param("offset", off)

func set_spotlight_animated(enabled: bool) -> void:
	material.set_shader_param("animated", enabled)

func set_spotlight_speed(spd: float) -> void:
	material.set_shader_param("speed", spd)

func set_spotlight_time(time: float) -> void:
	material.set_shader_param("time", time)

func _interpolate_spotlight_property(prop: String, value, duration: float) -> void :
	
	if _tween and _tween.is_running():
		_tween.set_parallel()
	else:
		_tween = create_tween()
	_tween.tween_property(material, "shader_param/" + prop, value, duration)\
	.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

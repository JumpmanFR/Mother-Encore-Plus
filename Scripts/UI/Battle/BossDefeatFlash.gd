extends CanvasLayer

signal defeat_enemies
signal animation_finished

export (NodePath)onready var animation_player = get_node_or_null(animation_player) as AnimationPlayer
export (NodePath)onready var color_rect = get_node_or_null(color_rect) as ColorRect

func _ready():
	color_rect.material.set_shader_param("radius", 0)

func start_defeat_animation(center: Vector2):
	color_rect.material.set_shader_param("position", center)
	animation_player.play("DefeatFlash")

func defeat_enemies():
	emit_signal("defeat_enemies")


func _on_AnimationPlayer_animation_finished(anim_name):
	emit_signal("animation_finished")

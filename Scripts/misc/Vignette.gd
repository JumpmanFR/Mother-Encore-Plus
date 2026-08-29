extends CanvasLayer

onready var mat = $ColorRect.material
onready var mult = $ColorRect.material.get_shader_param("multiplier")
onready var battle_mult = $ColorRect.material.get_shader_param("softness")

const BATTLE_TRANSITION_LENGTH := 1;

func _ready():
	uiManager.connect("ov_to_battle", self, "_battle_started")
	uiManager.connect("battle_to_ov", self, "_battle_ended")

func _battle_started():
	create_tween().tween_property(mat, "shader_param/multiplier", battle_mult, BATTLE_TRANSITION_LENGTH)\
	.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)

func _battle_ended():
	mat.set_shader_param("multiplier", mult)

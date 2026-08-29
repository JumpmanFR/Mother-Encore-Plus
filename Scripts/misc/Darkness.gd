extends CanvasLayer

onready var mat = $ColorRect.material
onready var radius = $ColorRect.material.get_shader_param("minimumRadius")

const BATTLE_TRANSITION_LENGTH := 1;
const BATTLE_TRANSITION_SIZE := 500;

func _ready():
	uiManager.connect("ov_to_battle", self, "_battle_started")
	uiManager.connect("battle_to_ov", self, "_battle_ended")

func _battle_started():
	create_tween().tween_property(mat, "shader_param/minimumRadius", BATTLE_TRANSITION_SIZE, BATTLE_TRANSITION_LENGTH)\
	.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)

func _battle_ended():
	mat.set_shader_param("minimumRadius", radius)

func _process(delta):
	var player_pos = global.get_player().global_position - global.currentCamera.get_camera_screen_center() + Vector2(160, 90)
	mat.set_shader_param("position", player_pos)

extends Node
class_name CutsceneObject

signal animation_ended

export var anim_name: String
export var anim_player: NodePath
onready var anim_player_node: AnimationPlayer = get_node_or_null(anim_player)

func _ready():
	anim_player_node.connect("animation_finished", self, "emit_signal", ["animation_ended"])

func _input(event: InputEvent):
	if OS.is_debug_build() and event.is_action_pressed("ui_F1"):
		play_anim()

func play_anim(animation = ""):
	var anim = anim_name if animation == "" else animation
	anim_player_node.play(anim)

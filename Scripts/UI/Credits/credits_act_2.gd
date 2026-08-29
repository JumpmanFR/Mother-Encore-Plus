extends Credits

export (NodePath) onready var _landscape_path = get_node(_landscape_path)
export (NodePath)onready var _black_bg = get_node(_black_bg) as ColorRect

const TRAIN_OFFSET := 20
const PAN_HEIGHT := 112
const PAN_LENGTH := 2.0

var train_cutscene: TrainCutscene

func _start_credits():
	yield(._start_credits(), "completed")
	if !playing: return
	yield(get_tree().create_timer(15.5), "timeout")
	if !playing: return
	_go_to_train_cutscene()

# Overridden
func _init_credits_content():
	_refresh_credits_headers()
	_refresh_scrolling_amount()

func _refresh_credits_headers():
	for header_label in get_tree().get_nodes_in_group("CreditsHeader"):
		header_label.visible = !tr(header_label.text).strip_edges().empty()

func _go_to_train_cutscene():
	_canvas_group.layer = uiManager.get_fade().layer + 1
	uiManager.get_fade().fade_in("Fade", Color.white, 1.5)
	yield(uiManager.get_fade(), "fade_in_done")
	if !playing: return
	_encore_logo.hide()
	_black_bg.hide()
	var TrainCutscene := load("res://Maps/misc/TrainCutscene.tscn")
	train_cutscene = TrainCutscene.instance()
	train_cutscene.init_params("Merrysville", "Reindeer", 0, TRAIN_OFFSET)
	_landscape_path.add_child(train_cutscene)
	uiManager.get_fade().fade_out("Fade", Color.white, 1.3)
	yield(uiManager.get_fade(), "fade_in_done")
	if !playing: return
	_reset_canvas_group_layer()


func _input(event):
	if OS.is_debug_build() and event.is_action_pressed("ui_F1"):
		pan_up(1)

func pan_up(length: float):
	train_cutscene.pan_height(PAN_HEIGHT, length)

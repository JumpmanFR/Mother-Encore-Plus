extends Control

onready var note = preload("res://Nodes/Ui/Battle/MusicNote.tscn")

const START_POS := Vector2(110, 180)
const END_POS := Vector2(132, 165)
const EXIT_POS := Vector2(200, 165)

var _notes_visible := false

func _spawn_notes() -> void:
	_spawn_note(1)
	_spawn_note(-1)

func _spawn_note(dir: int) -> void:
	var new_note : MusicNote = note.instance()
	new_note.direction = dir
	add_child(new_note)
	new_note.do_movement(START_POS, END_POS)

func _hide_notes() -> void:
	for i in get_children():
		i.do_movement(END_POS, EXIT_POS, true)

func set_notes_visible(enabled: bool) -> void :
	if enabled: _spawn_notes()
	else: _hide_notes()
	_notes_visible = enabled

func are_notes_visible() -> bool:
	return _notes_visible

extends Control

var current_text: int = 0
var finished := true
var t: float = 0
var text_speed := 0.08
var text := [
	"INTRO_CUTSCENE_NOW_01", 
	"INTRO_CUTSCENE_NOW_02"
]

onready var dialogue_label = $Text / HBoxContainer / ScrollingText

func _ready():
	global.get_player().pause()
	reset_text()
	$Timer.connect("timeout", self, "set_process", [true])
	yield(get_tree().create_timer(0.8), "timeout")
	$AnimationPlayer.play("Introduction")
	$Blackbars.toggle(true)

func _process(delta: float):
	if !finished:
		var spaceless_test = _get_spaceless_text(dialogue_label.text)
		t += delta
		if t > text_speed:
			dialogue_label.visible_characters += 1
			t = 0
			if $AudioStreamPlayer.stream != null:
				$AudioStreamPlayer.set_pitch_scale(rand_range(0.85,1.0))
				$AudioStreamPlayer.play()
			if _get_last_visible_character(dialogue_label) in tr("INTRO_CUTSCENE_PUNCTUATION") and dialogue_label.visible_characters < len(spaceless_test):
				$Timer.start()
				set_process(false)
		if dialogue_label.visible_characters >= len(spaceless_test):
			finished = true
			dialogue_label.visible_characters = len(spaceless_test)
			t = 0
			$Timer.start()
			set_process(false)
	elif current_text == text.size():
		hide_text()

func _input(event: InputEvent):
	if event.is_action_pressed("ui_select") and $AnimationPlayer.is_playing():
		$AnimationPlayer.stop()
		Input.action_release("ui_select")
		finish_intro()

func _get_last_visible_character(label: Label):
	var spaceless_text = _get_spaceless_text(label.text)
	return spaceless_text[min(label.visible_characters, spaceless_text.length()) - 1]

func _get_spaceless_text(string: String):
	return string.replace(" ", "").replace("\n", "")

func hide_text():
	var tween = create_tween()
	tween.tween_property(dialogue_label, "rect_position:y", - 36, 0.5).set_ease(Tween.EASE_OUT)
	tween.connect("finished", self, "_on_tween_completed", [], CONNECT_ONESHOT)

func reset_text():
	dialogue_label.text = ""
	dialogue_label.visible_characters = 0
	dialogue_label.rect_position.y = 0
	finished = true

func next_text():
	reset_text()
	set_process(true)
	if dialogue_label.text != "":
		dialogue_label.text += "\n"
	
	var current_text_str = tr(text[current_text])
	dialogue_label.text += current_text_str
	finished = false
	current_text += 1

func play_sound(sound: String, node_name: String):
	audioManager.play_sfx(load(sound), node_name)

func stop_sound(node_name: String):
	if audioManager.get_sfx(node_name) != null:
		audioManager.get_sfx(node_name).stop()

func finish_intro():
	stop_sound("teleport")
	$Objects/Door.enter()
	global.start_playtime()

func _on_tween_completed():
	if current_text == text.size():
		finish_intro()

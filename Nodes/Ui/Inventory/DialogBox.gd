extends NinePatchRect

signal back

var active = false
var doingAction = false

func show_dialog_box(dialog: String, character: PartyMember, value := 0, stat := "", item := {}):
	active = true
	$TextLabel.text = TextTools.format_text_with_context(dialog, character, item, value, stat)
	$AnimationPlayer.play("Open")
	
func update_dialog_box(dialog: String, character: PartyMember, value := 0, stat := "", item := {}):
	$TextLabel.text = TextTools.format_text_with_context(dialog, character, item, value, stat)

func _input(event):
	if !doingAction and active and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
		active = false
		Input.action_release("ui_accept")
		Input.action_release("ui_cancel")
		get_tree().set_input_as_handled()
		$AnimationPlayer.play("Close")
		emit_signal("back")

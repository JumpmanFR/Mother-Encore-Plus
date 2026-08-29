extends NinePatchRect


func _ready():
	$Present/ButtonPrompt.force_show()
	$NPC/ButtonPrompt.force_hide()

func refresh(quick := false):
	match $ButtonPromptsArrow.cursor_index:
		0:
			$Present/ButtonPrompt.force_show(quick)
			$NPC/ButtonPrompt.force_show(quick)
		1:
			$Present/ButtonPrompt.force_show(quick)
			$NPC/ButtonPrompt.force_hide(quick)
		2:
			$Present/ButtonPrompt.force_hide(quick)
			$NPC/ButtonPrompt.force_show(quick)
		3:
			$Present/ButtonPrompt.force_hide(quick)
			$NPC/ButtonPrompt.force_hide(quick)

func _on_ButtonPromptsArrow_moved(dir):
	refresh()

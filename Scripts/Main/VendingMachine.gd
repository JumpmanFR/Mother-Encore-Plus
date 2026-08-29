extends Sprite

export var shop: String

const DIALOG = "Reusable/vendingmachine"

func interact():
	uiManager.set_current_shop(shop)
	uiManager.open_dialogue_box(DIALOG)

func _end():
	global.get_player().unpause()

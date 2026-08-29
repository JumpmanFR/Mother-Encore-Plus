extends InteractDialog

export (bool) var _is_payphone: bool
export var _save_location := ""

onready var _anim_player = $AnimationPlayer
onready var _audio = $AudioStreamPlayer2D

func _ring():
	if _anim_player.current_animation != "Ring":
		_audio.stream = ResourceLoader.load("res://Audio/Sound effects/phonering.wav")
		_anim_player.play("Ring")


func interact():
	var phone_card := Inventory.find_item_for_all("PhoneCard")
	_use_phone(phone_card)


func interact_item(item: Item):
	if item.item_name == _key_item:
		_use_phone(item)

func _use_phone(phone_card: Item):
	_audio.stream = ResourceLoader.load("res://Audio/Sound effects/phonehangup.wav")
	_anim_player.play("Idle")
	global.set_phone_location(_save_location)
	if _is_payphone:
		if phone_card != null:
			_show_amount_box(true, true)
			_audio.playing = true
			uiManager.open_dialogue_box(_get_right_dialog())
			Inventory.reduce_or_drop_item_for_all(phone_card)
		else:
			_show_amount_box(false, true)
			if globaldata.cash >= 5:
				_audio.playing = true
				uiManager.open_dialogue_box(_get_right_dialog())
				globaldata.cash -= 5
			else:
				uiManager.open_dialogue_box("Reusable/payphonenomoney")
	else:
		uiManager.open_dialogue_box(_get_right_dialog())
		_audio.playing = true

func _show_amount_box(is_phone_units: bool, update: bool):
	var box := uiManager.get_cash_box(is_phone_units)
	box.open()
	if update:
		yield(get_tree().create_timer(0.5), "timeout")
		box.update()
	yield(get_tree().create_timer(1), "timeout")
	uiManager.close_item(box)
